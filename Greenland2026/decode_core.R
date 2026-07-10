## decode_core.R — shared decode + calibration for the Greenland 2026 field heads.
##
## Sourced by BOTH report documents:
##   * decode_snowmelt.qmd — IMEI 300434065508020 (vertical snowmelt profile)
##   * decode_chain.qmd     — IMEI 301434062008130 (Doppelkette, borehole chains)
##
## Everything here is config-agnostic: functions take `fields` / `n_nodes` /
## `lab_cal` explicitly, so each report supplies its own head_config and just
## calls these. Identification is ALWAYS by IMEI (filename prefix); this file
## never hard-codes a device.

# field name → NTC number (which physical thermistor the channel reads)
ntc_channel <- c(ntc1 = 1L, ntc2 = 2L, testSB = 3L)

# ---- Field widths & expected file size --------------------------------------

# Per-field value width in BYTES (binary) — gnd is int16, the rest int24/uint24.
bin_field_bytes <- function(f) {
  if (f %in% c("ntc1", "ntc2", "testSB", "pressure")) return(3L)
  if (f == "gnd") return(2L)
  stop("Unknown field: ", f)
}

# Expected binary file size for N nodes with these fields, in two firmware
# variants: each field is either preceded by a 0x7C separator byte ("sep") or
# the fields are concatenated directly ("nosep"). Layout in both cases:
#   4 B timestamp + adc(3) + N × node + battery(2), separators add +1 B/field.
bin_expected_len <- function(n_nodes, fields) {
  w <- sapply(fields, bin_field_bytes)
  list(sep   = 4L + (1L + 3L) + n_nodes * sum(1L + w) + (1L + 2L),
       nosep = 4L +        3L  + n_nodes * sum(w)       +        2L)
}

# ---- Counts → physical units ------------------------------------------------

adc2temp     <- function(c) 6.101e-5 * c - 256.6
pressure2hPa <- function(p) p / 1000
unix2utc     <- function(t) as.POSIXct(t, origin = "1970-01-01", tz = "UTC")

# counts → NTC resistance (Ω). Shared by both calibrations below.
NTCcounts2R <- function(c) {
  H <- (-c * 1e6) / (c - 33554432)
  (H * 499000) / (499000 - H)
}
# Per-sensor lab calibration: 4-parameter Steinhart–Hart on ln(R).
NTC_s4 <- function(c, co) {
  lr <- log(NTCcounts2R(c))
  1 / (co[1] + co[2] * lr + co[3] * lr^2 + co[4] * lr^3) - 273.15
}
# Universal FALLBACK calibration: the MEAN lab-S4 coefficient set, i.e. the
# average of the 62 healthy GRIP sensors (a,b,c,d averaged after dropping the
# 10 a_suspect fits from GRIP_calibration_assignment.csv). Because 1/T is LINEAR
# in (a,b,c,d), the mean coefficients reproduce the mean 1/T curve EXACTLY; that
# curve represents every healthy sensor to ±0.03–0.05 °C (SD) over −40…0 °C.
# Used where a head has no per-sensor lab table (head_config `calibration` = NA)
# or where an individual lab fit is missing/numerically broken. Derivation:
# Greenland2026/derive_mean_calibration.R.
NTC_MEAN_COEF <- c(8.4229499262e-04, 2.7615486685e-04,
                   -3.1654916185e-06, 3.0727486494e-07)
NTC_mean <- function(c) NTC_s4(c, NTC_MEAN_COEF)
# Legacy universal Beta curve (β = 3380, R25 = 10 kΩ). NO LONGER the decoding
# fallback (it reads systematically too warm: −0.7 °C at 0 °C growing to −3.2 °C
# at −40 °C vs. the mean lab curve). Kept only for the lab-vs-Beta diagnostic.
NTC_beta <- function(c) {
  r <- NTCcounts2R(c)
  1 / ((1 / 3380) * log(r / 10000) + 1 / 298.15) - 273.15
}
# Back-compat alias so any external caller still resolves → mean lab curve.
NTCcounts2temp <- NTC_mean

# ---- Binary snowchain/snowmelt decoder --------------------------------------
# Field-driven by `fields`:
#   4-byte BE timestamp + adc(int24) + N × node + battery(uint16)
# Each node holds one value per entry of `fields`, in order:
#   ntc1/ntc2/testSB → 3-byte signed int24, gnd → 2-byte signed int16,
#   pressure → 3-byte unsigned uint24.
# Two firmware variants:
#   sep   — every value is preceded by a 0x7C separator byte. Fields are read
#           BETWEEN separators (variable length): a defective sensor can emit an
#           out-of-range value that needs >3 bytes; such wrong-width fields are
#           returned as NA so the rest stays aligned.
#   nosep — values concatenated directly, fixed width (no recovery possible).
# Detected from byte 5 (== 0x7C ⇒ sep), since a sentinel/defective field shifts
# the file size. n_nodes comes from head_config (authoritative).
read_snowchain_bin <- function(path, fields, n_nodes) {
  raw  <- readBin(path, what = "raw", n = file.info(path)$size)
  n    <- length(raw)
  ints <- as.integer(raw)

  has_sep <- ints[5] == 0x7CL

  be_uint <- function(b) sum(as.integer(b) * 256^rev(seq_along(b) - 1L))
  be_sint <- function(b) {
    v <- be_uint(b); bits <- 8L * length(b)
    if (v >= 2^(bits - 1L)) v - 2^bits else v
  }

  nf     <- length(fields)
  widths <- c(3L, rep(sapply(fields, bin_field_bytes), n_nodes), 2L)  # adc, nodes…, battery
  signed <- c(TRUE, rep(fields != "pressure", n_nodes), FALSE)
  ftype  <- c("adc", rep(fields, n_nodes), "battery")   # field kind per value slot
  is_ntc <- ftype %in% c("ntc1", "ntc2", "testSB")       # NTC channels (overflow-eligible)
  n_val  <- length(widths)

  # Decode one field's bytes; wrong length (defective sensor / sentinel) → NA.
  decode_one <- function(b, w, sgn) {
    if (length(b) != w) return(NA_real_)
    if (sgn) be_sint(b) else be_uint(b)
  }

  time_unix   <- be_uint(raw[1:4])
  bat_lo <- NA_integer_; bat_hi <- NA_integer_; bat_partial <- FALSE

  if (has_sep) {
    sep_pos <- which(ints == 0x7CL); sep_pos <- sep_pos[sep_pos >= 5L]
    if (length(sep_pos) != n_val)
      warning(sprintf("Found %d separators, expected %d (adc + %d×%d fields + battery) — alignment may be off (0x7C in data?)",
                      length(sep_pos), n_val, n_nodes, nf))
    fstart <- sep_pos + 1L
    fend   <- c(sep_pos[-1] - 1L, n)
    vals   <- lapply(seq_len(min(length(sep_pos), n_val)), function(i)
      decode_one(raw[fstart[i]:fend[i]], widths[i], signed[i]))
  } else {
    # nosep is fixed-width, BUT a defective sensor emits a 4-byte overflow in a
    # 3-byte NTC field, which shifts the rest of the stream. Two signatures seen:
    #   • 0x01000000   — high byte 0x01 (e.g. msg -142 sep-variant sibling)
    #   • 0x008x xxxx  — high byte 0x00, i.e. counts < 2^16 → non-physical (>+90 °C);
    #                    a healthy NTC reading never has a 0x00 high byte (msg -143,
    #                    where node 16's ntc1 AND ntc2 both overflow → +2 B).
    # Detect either, set NA, and consume 4 B to re-align. Restricted to NTC fields
    # so a genuine small pressure/gnd value is never mistaken for a sentinel.
    pos  <- 5L
    vals <- vector("list", n_val)
    for (i in seq_len(n_val)) {
      w <- widths[i]
      ntc_overflow <- w == 3L && is_ntc[i] && pos + 3L <= n &&
        (all(ints[pos:(pos + 3L)] == c(1L, 0L, 0L, 0L)) || ints[pos] == 0L)
      if (ntc_overflow) {
        vals[[i]] <- NA_real_                       # defective sensor → NA, skip 4 B
        pos <- pos + 4L
      } else if (i == n_val && pos + w - 1L > n && pos <= n) {
        # battery low byte(s) lost to a sentinel shift: only the high byte(s)
        # survived → reconstruct a 256-mV range from what is left.
        navail <- n - pos + 1L
        hb     <- be_uint(raw[pos:n]) * 256L^(w - navail)
        bat_lo <- as.integer(hb)
        bat_hi <- as.integer(hb + 256L^(w - navail) - 1L)
        bat_partial <- TRUE
        vals[[i]] <- hb
        pos <- n + 1L
      } else {
        vals[[i]] <- decode_one(raw[pos:(pos + w - 1L)], w, signed[i])
        pos <- pos + w
      }
    }
  }

  node_vals  <- vals[2:(1L + n_nodes * nf)]
  nodes_raw  <- lapply(seq_len(n_nodes), function(i)
    setNames(node_vals[((i - 1L) * nf + 1L):(i * nf)], fields))
  battery_mv <- as.integer(vals[[n_val]])
  if (!bat_partial) { bat_lo <- battery_mv; bat_hi <- battery_mv }

  list(time_unix = time_unix, adc_temp = vals[[1]], nodes = nodes_raw,
       battery_mv = battery_mv, battery_lo = bat_lo, battery_hi = bat_hi,
       battery_partial = bat_partial, n_nodes = n_nodes, has_sep = has_sep)
}

# ---- Per-sensor lab calibration ---------------------------------------------
# Load a lab table (columns position,node,ntc,a,b,c,d) into a nested list
# lab_cal[[field]][[position]] = c(a,b,c,d) — or NULL where a fit is missing or
# numerically broken. `position` is the decode order (1 = first node in stream),
# so it indexes node 1:1. Returns NULL if the path is NA/missing.
load_lab_cal <- function(cal_path, n_nodes) {
  if (is.null(cal_path) || is.na(cal_path)) return(NULL)
  if (!file.exists(cal_path)) {
    warning(sprintf("Calibration table '%s' not found — using mean lab curve.", cal_path))
    return(NULL)
  }
  ca <- read.csv(cal_path)
  setNames(lapply(names(ntc_channel), function(fld) {
    k <- ntc_channel[[fld]]
    lapply(seq_len(n_nodes), function(p) {
      r  <- ca[ca$position == p & ca$ntc == k, c("a", "b", "c", "d")]
      co <- if (nrow(r) == 1L) as.numeric(r) else NULL
      if (!is.null(co) && all(is.finite(co))) co else NULL
    })
  }), names(ntc_channel))
}

# counts → °C for one NTC channel across all nodes: the per-sensor lab fit where
# available (and numerically sane), else the universal mean lab-S4 fallback
# (NTC_mean). `counts` is in node (= decode = calibration `position`) order, so
# index p selects the right sensor. `lab_cal` may be NULL (mean curve everywhere).
calibrate_channel <- function(counts, field, lab_cal = NULL) {
  out <- NTC_mean(counts)                         # default: mean lab curve everywhere
  if (!is.null(lab_cal) && field %in% names(ntc_channel)) {
    for (p in seq_along(counts)) {
      co <- lab_cal[[field]][[p]]
      if (is.null(co) || is.na(counts[p])) next
      t <- NTC_s4(counts[p], co)
      if (is.finite(t) && t > -80 && t < 60) out[p] <- t   # sane lab fit → use it
    }
  }
  out
}

# Turn one decoded message into a tidy per-node data.frame. Both the raw counts
# (before calibration, *_counts) and the calibrated value are kept. The *_C value
# uses the per-sensor lab calibration when a `lab_cal` is supplied.
bin_to_nodes <- function(b, fields, lab_cal = NULL) {
  n_nodes <- length(b$nodes)
  df <- data.frame(node = seq_len(n_nodes))
  for (f in fields) {
    vals <- sapply(b$nodes, function(nd) nd[[f]])
    if (f %in% c("ntc1", "ntc2", "testSB")) {
      df[[paste0(f, "_counts")]] <- vals
      df[[paste0(f, "_C")]]      <- calibrate_channel(vals, f, lab_cal)
    } else if (f == "pressure") {
      df$pressure_counts <- vals
      df$pressure_hPa    <- pressure2hPa(vals)
    } else {                       # gnd → raw counts (already uncalibrated)
      df[[f]] <- vals
    }
  }
  df
}

# ---- Hex e-mail payload path (legacy; some heads mail hex, not a .bin) -------
hex_to_uint <- function(h) {
  if (is.na(h) || nchar(h) == 0L) return(NA_real_)
  chars  <- strsplit(toupper(h), "", fixed = TRUE)[[1]]
  nibble <- match(chars, c(as.character(0:9), LETTERS[1:6])) - 1L
  if (any(is.na(nibble))) return(NA_real_)
  v <- 0; for (d in nibble) v <- v * 16 + d; v
}

hex_to_int <- function(h, bits) {
  v <- hex_to_uint(h)
  if (is.na(v)) return(NA_integer_)
  s <- 2^(bits - 1L)
  if (v >= s) v <- v - 2^bits
  as.integer(v)
}

field_spec <- function(name) {
  if (name == "time_unix")  return(list(n = 8L, fn = hex_to_uint))
  if (name == "adc_temp")   return(list(n = 6L, fn = function(h) hex_to_int(h, 24L)))
  if (name == "battery_mv") return(list(n = 4L, fn = hex_to_uint))
  if (grepl("\\.(ntc1|ntc2|testSB)$", name))
    return(list(n = 6L, fn = function(h) hex_to_int(h, 24L)))
  if (grepl("\\.pressure$", name))
    return(list(n = 6L, fn = hex_to_uint))
  if (grepl("\\.gnd$", name))
    return(list(n = 4L, fn = function(h) hex_to_int(h, 16L)))
  stop("Unknown field: ", name)
}

build_schema <- function(n_nodes, fields) {
  node_fields <- paste(
    sapply(seq_len(n_nodes), function(i)
      paste(paste0("n", i, ".", fields), collapse = " ")),
    collapse = " "
  )
  paste("time_unix adc_temp", node_fields, "battery_mv")
}

decode_hex <- function(schema, hex) {
  fnames <- strsplit(trimws(schema), "\\s+")[[1]]
  pos    <- 1L
  out    <- setNames(vector("list", length(fnames)), fnames)
  for (i in seq_along(fnames)) {
    sp      <- field_spec(fnames[i])
    block   <- substr(hex, pos, pos + sp$n - 1L)
    out[[i]] <- if (nchar(block) == sp$n) sp$fn(block) else NA
    pos <- pos + sp$n
  }
  out
}
