# decode_field.R — Einzelnachrichten-Decoder für Feldgebrauch (Grönland 2026)
#
# Anleitung:
#   1. HEAD auf "03" oder "04" setzen
#   2. Hex-Payload(s) aus der Email einfügen
#      head03: ZWEI Nachrichten (340 Bytes + 54 Bytes) → MSG1 + MSG2
#      head04: EINE Nachricht  (284 Bytes)             → nur MSG1
#   3. Script ausführen (Strg+Shift+S oder source("decode_field.R"))

# ---- Einstellungen ----
HEAD <- "03"    # "03" = head03 / 35 Nodes / Modem 231709
                # "04" = head04 / 25 Nodes / Modem 231710

MSG1 <- "69a5fb1236e6b431b3b6318bb0fcbe0a356647bdda47972cfceb0a522d479a9d47a7cffcb90a551147b647478d7afcc50a519047f8f6480f44fcc70a51c7480e2748043dfce30a54c148690a4879c9fca60a5a6448c4e0489fcffc9a0a5dd048bc5c48dca1fcba0a643f48bfa148eb1afce10a5a7148d88148fc98fcd80a6bc648d5bb491c9cfcbb0a702a409d6e40ba78fd140a465e3d76263d79eefcb40a45ac36a62a369aa2fc850a45ef359477359efcfd010a45fe37003036f589fcc10a46433bc2843bac97fca40a4621405913405f1dfcbd0a3fe343ce7b43ce2cfcbf0a468145ceaf45e0b3fcd80a49be46f55246f194fcf10a468d4777244776eafcd30a4bf047a6d447cbcefcc30a49dd47aa7647c802fcc70a4a1641c7e441f084fcb40a45a33f37483f3edafcdc0a44d13d31f13cfcc1fcd30a457a3b05b83aec70fcc70a45c93780d837904afcfd0a45d23594e8"
MSG2 <- "359db2fcdb0a466c34e6df34f54efd0e0a45fe35032034fb68fca00a469e35d08d35e5f5fcc10a457536f6e136dee2fcfc0a45e219ec"
# head04-Beispiel: MSG1 <- "...568 hex chars..."; MSG2 <- ""

# =========================================================
# Ab hier nichts ändern
# =========================================================

# ---- Decode-Primitiven (kein Package nötig) ----

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
  if (grepl("\\.gnd$", name))
    return(list(n = 4L, fn = function(h) hex_to_int(h, 16L)))
  if (grepl("\\.(ntc1|ntc2|pressure|testSB)$", name))
    return(list(n = 6L, fn = function(h) hex_to_int(h, 24L)))
  stop("Unbekanntes Feld: ", name)
}

decode_hex <- function(schema, hex) {
  fields <- strsplit(trimws(schema), "\\s+")[[1]]
  pos <- 1L
  out <- setNames(vector("list", length(fields)), fields)
  for (i in seq_along(fields)) {
    sp      <- field_spec(fields[i])
    block   <- substr(hex, pos, pos + sp$n - 1L)
    out[[i]] <- if (nchar(block) == sp$n) sp$fn(block) else NA
    pos <- pos + sp$n
  }
  out
}

# ---- Einheitenumrechnung ----

adc2temp <- function(c) 6.101e-5 * c - 256.6

NTCcounts2temp <- function(c) {
  H <- (-c * 1e6) / (c - 33554432)
  r <- (H * 499000) / (499000 - H)
  1 / ((1 / 3380) * log(r / 10000) + 1 / 298.15) - 273.15
}

pressure2hPa <- function(p) p / 1000

unix2utc <- function(t) as.POSIXct(t, origin = "1970-01-01", tz = "UTC")

# ---- Schemas ----

schema_head03 <- paste(
  "time_unix adc_temp",
  paste(sapply(1:35, function(i)
    paste0("n", i, ".ntc1 n", i, ".ntc2 n", i, ".gnd n", i, ".pressure")),
    collapse = " "),
  "battery_mv"
)

schema_head04 <- paste(
  "time_unix adc_temp",
  paste(sapply(1:25, function(i)
    paste0("n", i, ".ntc1 n", i, ".ntc2 n", i, ".testSB n", i, ".gnd")),
    collapse = " "),
  "battery_mv"
)

# ---- Dekodieren ----

if (HEAD == "03") {
  hex    <- paste0(toupper(trimws(MSG1)), toupper(trimws(MSG2)))
  schema <- schema_head03
  n_nodes <- 35L
  sensor  <- "pressure"
} else if (HEAD == "04") {
  hex    <- toupper(trimws(MSG1))
  schema <- schema_head04
  n_nodes <- 25L
  sensor  <- "testSB"
} else {
  stop("HEAD muss '03' oder '04' sein.")
}

n_hex <- nchar(hex)
cat(sprintf("Hex-Länge: %d Zeichen (%d Bytes)\n", n_hex, n_hex %/% 2L))
expected <- if (HEAD == "03") 788L else 568L
if (n_hex != expected)
  warning(sprintf("Erwartet %d Zeichen, erhalten %d — Payload unvollständig?", expected, n_hex))

raw <- decode_hex(schema, hex)

# Metadaten
time_utc   <- unix2utc(raw$time_unix)
adc_temp_C <- adc2temp(raw$adc_temp)
battery_mv <- raw$battery_mv

# Node-Tabelle aufbauen
nodes <- data.frame(
  node    = seq_len(n_nodes),
  ntc1_C  = sapply(seq_len(n_nodes), function(i) NTCcounts2temp(raw[[paste0("n", i, ".ntc1")]])),
  ntc2_C  = sapply(seq_len(n_nodes), function(i) NTCcounts2temp(raw[[paste0("n", i, ".ntc2")]])),
  sensor  = sapply(seq_len(n_nodes), function(i) {
    val <- raw[[paste0("n", i, ".", sensor)]]
    if (sensor == "pressure") pressure2hPa(val) else pressure2hPa(val)
  }),
  gnd     = sapply(seq_len(n_nodes), function(i) raw[[paste0("n", i, ".gnd")]])
)
names(nodes)[4] <- if (HEAD == "03") "pressure_hPa" else "testSB_hPa"

# ---- Ausgabe ----

cat("\n========================================\n")
cat(sprintf("  HEAD%s  |  %s UTC\n", HEAD, format(time_utc, "%Y-%m-%d %H:%M:%S")))
cat("========================================\n")
cat(sprintf("  ADC-Temp:  %6.2f °C\n", adc_temp_C))
cat(sprintf("  Batterie:  %d mV\n\n", as.integer(battery_mv)))

col4 <- if (HEAD == "03") "pres_hPa" else "tSB_hPa"
cat(sprintf("  %4s  %8s  %8s  %9s  %6s\n", "Node", "ntc1 °C", "ntc2 °C", col4, "gnd"))
cat("  ", strrep("-", 48), "\n", sep = "")
for (i in seq_len(n_nodes)) {
  r <- nodes[i, ]
  cat(sprintf("  %4d  %8.2f  %8.2f  %9.3f  %6d\n",
              r$node, r$ntc1_C, r$ntc2_C, r[[4]], as.integer(r$gnd)))
}
cat("========================================\n\n")

# Optional: als CSV speichern
outfile <- sprintf("data/decoded_field_head%s_%s.csv", HEAD,
                   format(time_utc, "%Y%m%d_%H%M%S"))
write.csv(nodes, outfile, row.names = FALSE)
cat("Gespeichert:", outfile, "\n")
