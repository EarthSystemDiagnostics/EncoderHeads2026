library(readr)
library(dplyr)
library(lubridate)
library(purrr)
library(tidyr)

# ---- Helper / decode functions (identical to decode_results3.R) ----

hex_block        <- function(s, pos, n) substr(s, pos, pos + n - 1L)

hex_to_uint <- function(h) {
  if (is.na(h) || h == "" || nchar(h) == 0L) return(NA_real_)
  h <- toupper(h)
  chars <- strsplit(h, "", fixed = TRUE)[[1]]
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
  if (name == "time_unix")                         return(list(n_hex = 8L, decode = hex_to_uint))
  if (name == "adc_temp")                          return(list(n_hex = 6L, decode = function(h) hex_to_int(h, 24L)))
  if (name == "battery_mv")                        return(list(n_hex = 4L, decode = hex_to_uint))
  if (grepl("\\.gnd$",    name))                   return(list(n_hex = 4L, decode = function(h) hex_to_int(h, 16L)))
  if (grepl("\\.(ntc1|ntc2|pressure|testSB)$", name))
                                                   return(list(n_hex = 6L, decode = function(h) hex_to_int(h, 24L)))
  stop("No decoding rule for: ", name)
}

decode_hex_line <- function(schema, hex_string) {
  fields <- strsplit(trimws(schema), "\\s+")[[1]]
  out <- vector("list", length(fields)); names(out) <- fields
  pos <- 1L
  for (i in seq_along(fields)) {
    sp    <- field_spec(fields[i])
    block <- hex_block(hex_string, pos, sp$n_hex)
    out[[i]] <- if (nchar(block) == sp$n_hex) sp$decode(block) else NA
    pos <- pos + sp$n_hex
  }
  out
}

adc2temp       <- function(c)  6.101e-5 * c - 256.6
NTCcounts2temp <- function(c)  {
  H <- (-c * 1000000) / (c - 33554432)
  r <- (H * 499000) / (499000 - H)
  1 / ((1/3380) * log(r / 10000) + 1/298.15) - 273.15
}
pressure2hPa   <- function(p)  p / 1000
unix2utc       <- function(t)  as.POSIXct(t, origin = "1970-01-01", tz = "UTC")

schema_head03 <- paste(
  "time_unix adc_temp",
  paste(sapply(1:35, function(i)
    paste0("n", i, ".ntc1 n", i, ".ntc2 n", i, ".gnd n", i, ".pressure")),
    collapse = " "),
  "battery_mv")

schema_head04 <- paste(
  "time_unix adc_temp",
  paste(sapply(1:25, function(i)
    paste0("n", i, ".ntc1 n", i, ".ntc2 n", i, ".testSB n", i, ".gnd")),
    collapse = " "),
  "battery_mv")

# ---- head04 per-node lab calibration (2023, variant 'Both'; head04 ONLY) --------
# The Kohnen borehole sensors were lab-calibrated in 2023 (Nora Hirsch); the S4
# coefficients live in data/head04_calibration.csv (built by
# build_head04_calibration.R). counts→R and S4→°C are identical to NTCcounts2temp's
# resistance step, so we only swap the ln(R) polynomial for the per-sensor one.
# head03 has no such table and keeps the universal Beta curve (NTCcounts2temp).
NTC_s4 <- function(cnt, co) {
  H <- (-cnt * 1e6) / (cnt - 33554432); r <- (H * 499000) / (499000 - H)
  1 / (co[1] + co[2]*log(r) + co[3]*log(r)^2 + co[4]*log(r)^3) - 273.15
}
h04_cal  <- read_csv("./data/head04_calibration.csv", show_col_types = FALSE)
h04_coef <- setNames(
  lapply(seq_len(nrow(h04_cal)),
         function(i) c(h04_cal$a[i], h04_cal$b[i], h04_cal$c[i], h04_cal$d[i])),
  sprintf("n%d.ntc%d", h04_cal$node, h04_cal$ntc))
# Add n<node>.ntc<k>_temp_C via the per-sensor S4 fit (Beta fallback if a sensor
# is absent from the table).
calibrate_head04 <- function(df) {
  for (cc in grep("^n[0-9]+\\.ntc[12]$", names(df), value = TRUE)) {
    co <- h04_coef[[cc]]
    df[[paste0(cc, "_temp_C")]] <- if (is.null(co)) NTCcounts2temp(df[[cc]]) else NTC_s4(df[[cc]], co)
  }
  df
}

# ---- head03 per-sensor calibration via the Calibration Registry ---------------
# Die B50-Ketten sind vor dem Kohnen-Einsatz kalibriert worden: Batch
# "kohnen2526", cal_id "2025-11_vorKohnen" (34/35 Knoten, alle active; nur der
# Wetterstationsknoten N20 fehlt). ACHTUNG Batch: Node-IDs sind NICHT global
# eindeutig — dieselben IDs existieren im Batch "greenland26" (SM1/SM2 sowie die
# Rekalibrierung 07/2026 der Encoder-Heads) mit anderen Koeffizienten. Für die
# Grönland-SnowMelt-Köpfe ist "greenland26" richtig (dort gibt es auch TestSB),
# für head03 an Kohnen "kohnen2526".
HEAD03_BATCH <- "kohnen2526"
CALIB_REG    <- "/Users/tlaepple/sharedAI/CalibrationRegistry"

# Fallback für Sensoren ohne Registry-Eintrag: universelle Mean-S4-Kurve
# (Mittel aus 62 gesunden GRIP-Sensoren, ../meta/mean_calibration_coefficients.csv)
# statt der Beta-Nennkurve. Betrifft hier nur den Wetterstationsknoten N20 (n1);
# Beta liest bei diesen Temperaturen +1.3 K (-15 C) bis +4.2 K (-50 C) zu warm.
MEAN_S4 <- tryCatch({
  m <- read_csv("../meta/mean_calibration_coefficients.csv", show_col_types = FALSE)
  setNames(as.numeric(m[1, c("a","b","c","d")]), c("a","b","c","d"))
}, error = function(e) NULL)
NTC_meanS4 <- function(cnt) {
  if (is.null(MEAN_S4)) return(NTCcounts2temp(cnt))
  cnt <- ifelse(cnt > 1e7, NA, cnt)
  H <- (-cnt * 1e6) / (cnt - 33554432); r <- (H * 499000) / (499000 - H)
  1 / (MEAN_S4[1] + MEAN_S4[2]*log(r) + MEAN_S4[3]*log(r)^2 + MEAN_S4[4]*log(r)^3) - 273.15
}

h03_depths <- tryCatch(read_csv("./data/head03_depths.csv", show_col_types = FALSE),
                       error = function(e) NULL)
reg_ok <- FALSE
if (!is.null(h03_depths) && file.exists(file.path(CALIB_REG, "R/calib_registry.R"))) {
  Sys.setenv(CALIB_REGISTRY = file.path(CALIB_REG, "calibrations.csv"))
  source(file.path(CALIB_REG, "R/calib_registry.R"))
  reg_ok <- TRUE
}

calibrate_head03 <- function(df) {
  n_reg <- 0L; n_fb <- 0L
  for (cc in grep("^n[0-9]+\\.ntc[12]$", names(df), value = TRUE)) {
    pos <- as.integer(sub("^n([0-9]+)\\..*$", "\\1", cc))
    ch  <- toupper(sub("^.*\\.", "", cc))                    # NTC1 / NTC2
    key <- if (reg_ok) {
      id <- h03_depths$node_id[h03_depths$node == pos]
      if (length(id) == 1) sprintf("N%d_%s", id, ch) else NA_character_
    } else NA_character_
    val <- if (!is.na(key)) {
      tryCatch({ v <- calib_T(df[[cc]], key, batch = HEAD03_BATCH); n_reg <- n_reg + 1L; v },
               error = function(e) { n_fb <<- n_fb + 1L; NTC_meanS4(df[[cc]]) })
    } else { n_fb <- n_fb + 1L; NTC_meanS4(df[[cc]]) }
    df[[paste0(cc, "_temp_C")]] <- val
  }
  message(sprintf("head03-Kalibrierung: %d Kanäle aus der Registry (Batch %s), %d über die Mean-S4-Kurve.",
                  n_reg, HEAD03_BATCH, n_fb))
  df
}

# ---- Read old CSV (pre-Cloudloop) ----

old_raw <- read_csv(
  "./data/messages-1781290180297_old.csv",
  show_col_types = FALSE,
  col_types = cols(`Length (Bytes)` = col_integer(), .default = col_character())
) |>
  filter(grepl("231709|231710", Device)) |>
  transmute(
    datetime_utc = dmy_hms(`Date Time (UTC)`, tz = "UTC"),
    modem        = as.integer(sub(".*?(\\d{6}).*", "\\1", Device)),
    nbytes       = `Length (Bytes)`,
    payload      = Payload,
    source       = "old"
  )

# ---- Read new source: FULL payloads from the Cloudloop API ----
# data/results-api-full.csv is produced by fetch_antarctic_cloudloop.R and holds
# UNtruncated payloads (head03 680+108 hex = all 35 nodes; head04 568 hex = all 25
# nodes, battery included). This replaces the old web-export path (results-2.csv,
# 128-B truncation → only ~15/~11 nodes). Same column shape (At (UTC) dmy, Thing =
# serial, Size, Payload), so the pairing/decoding below is unchanged.

new_raw <- read_csv(
  "./data/results-api-full.csv",
  show_col_types = FALSE,
  col_types = cols(Size = col_integer(), .default = col_character())
) |>
  mutate(modem = as.integer(sub(".*?(\\d{6}).*", "\\1", Thing))) |>
  filter(modem %in% c(231709L, 231710L)) |>
  transmute(
    datetime_utc = dmy_hms(`At (UTC)`, tz = "UTC"),
    modem        = modem,
    nbytes       = Size,
    payload      = Payload,
    source       = "new"
  )

# ---- Combine and deduplicate ----

df_all <- bind_rows(old_raw, new_raw) |>
  arrange(datetime_utc) |>
  distinct(modem, datetime_utc, nbytes, .keep_all = TRUE)

cat("Combined rows (231709 + 231710):\n")
print(table(df_all$modem, df_all$nbytes))
cat("\nDate range:\n")
cat(" 231709:", format(range(df_all$datetime_utc[df_all$modem == 231709])), "\n")
cat(" 231710:", format(range(df_all$datetime_utc[df_all$modem == 231710])), "\n")

# ---- head03 (231709): pair 340 + 54-byte messages only ----

df_09 <- df_all |>
  filter(modem == 231709) |>
  arrange(datetime_utc) |>
  mutate(
    next_time   = lead(datetime_utc),
    next_nbytes = lead(nbytes),
    next_pay    = lead(payload),
    dt_min      = as.numeric(difftime(next_time, datetime_utc, units = "mins"))
  ) |>
  filter(nbytes == 340, next_nbytes == 54, !is.na(dt_min), dt_min <= 10) |>
  transmute(
    modem          = 231709L,
    recv_time_utc  = next_time,
    start_time_utc = datetime_utc,
    hex_data       = paste0(payload, next_pay)
  )

cat("\nhead03 pairs found:", nrow(df_09), "\n")

decoded_09 <- df_09 |>
  mutate(decoded = map(hex_data, ~ decode_hex_line(schema_head03, .x))) |>
  unnest_wider(decoded) |>
  mutate(
    time_utc   = unix2utc(time_unix),
    adc_temp_C = adc2temp(adc_temp),
    across(matches("\\.pressure$"), ~ pressure2hPa(.x),   .names = "{.col}_hPa")
  ) |>
  calibrate_head03() |>          # Registry-S4 pro Sensor (Fallback: Beta-Kurve)
  select(modem, recv_time_utc, start_time_utc, time_utc,
         battery_mv, adc_temp_C,
         matches("\\.ntc[12]_temp_C$"),
         matches("\\.pressure_hPa$"),
         matches("\\.gnd$")) |>
  select(where(~ !all(is.na(.)))) |>
  arrange(time_utc)

# ---- head04 (231710): 284-byte messages only ----

df_10 <- df_all |>
  filter(modem == 231710, nbytes == 284) |>
  arrange(datetime_utc) |>
  transmute(
    modem          = 231710L,
    recv_time_utc  = datetime_utc,
    start_time_utc = datetime_utc,
    hex_data       = payload
  )

cat("head04 messages found:", nrow(df_10), "\n")

decoded_10 <- df_10 |>
  mutate(decoded = map(hex_data, ~ decode_hex_line(schema_head04, .x))) |>
  unnest_wider(decoded) |>
  mutate(
    time_utc   = unix2utc(time_unix),
    adc_temp_C = adc2temp(adc_temp),
    across(matches("\\.testSB$"),  ~ pressure2hPa(.x),   .names = "{.col}_hPa")
  ) |>
  calibrate_head04() |>   # per-node 2023 lab S4 (not Beta)
  select(modem, recv_time_utc, start_time_utc, time_utc,
         battery_mv, adc_temp_C,
         matches("\\.ntc[12]_temp_C$"),
         matches("\\.testSB_hPa$"),
         matches("\\.gnd$")) |>
  select(where(~ !all(is.na(.)))) |>
  arrange(time_utc)

# ---- Quick outlier check: first 10 rows ----

cat("\n=== head03: first 10 observations ===\n")
print(decoded_09 |> select(time_utc, adc_temp_C, n1.ntc1_temp_C, n1.pressure_hPa) |> head(10))

cat("\n=== head04: first 10 observations ===\n")
print(decoded_10 |> select(time_utc, adc_temp_C, n1.ntc1_temp_C) |> head(10))

cat("\nhead03 time range:", format(range(decoded_09$time_utc)), "\n")
cat("head04 time range:", format(range(decoded_10$time_utc)), "\n")
cat("head03 rows:", nrow(decoded_09), "\n")
cat("head04 rows:", nrow(decoded_10), "\n")

# ---- Remove installation / commissioning phase (before 2026-01-18) ----
# head03: 3 test messages on Jan 17 with irregular timing and adc_temp ~-12°C
# head04: 30-min + 6-hour phase (Jan 13–17) during installation; adc_temp erratic

cutoff <- as_datetime("2026-01-18 00:00:00", tz = "UTC")

n_drop_09 <- sum(decoded_09$time_utc < cutoff)
n_drop_10 <- sum(decoded_10$time_utc < cutoff)
cat(sprintf("\nDropping pre-cutoff rows — head03: %d  head04: %d\n", n_drop_09, n_drop_10))

decoded_09_clean <- decoded_09 |> filter(time_utc >= cutoff)
decoded_10_clean <- decoded_10 |> filter(time_utc >= cutoff)

cat("head03 final:", nrow(decoded_09_clean), "rows |",
    format(min(decoded_09_clean$time_utc)), "–", format(max(decoded_09_clean$time_utc)), "\n")
cat("head04 final:", nrow(decoded_10_clean), "rows |",
    format(min(decoded_10_clean$time_utc)), "–", format(max(decoded_10_clean$time_utc)), "\n")

# ---- Save ----

write_csv(decoded_09_clean, "./data/decoded_head03_231709_combined.csv")
write_csv(decoded_10_clean, "./data/decoded_head04_231710_combined.csv")

cat("\nGespeichert:\n")
cat("  data/decoded_head03_231709_combined.csv\n")
cat("  data/decoded_head04_231710_combined.csv\n")
