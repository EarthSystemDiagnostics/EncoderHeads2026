library(readr)
library(dplyr)
library(lubridate)
library(purrr)
library(tidyr)
library(tibble)

# ---- Helper functions (from EncodingHeads.qmd) ----

hex_block <- function(s, pos, n) substr(s, pos, pos + n - 1L)

hex_to_uint <- function(h) {
  if (is.na(h) || h == "" || nchar(h) == 0L) return(NA_real_)
  h <- toupper(h)
  chars <- strsplit(h, "", fixed = TRUE)[[1]]
  nibble <- match(chars, c(as.character(0:9), LETTERS[1:6])) - 1L
  if (any(is.na(nibble))) return(NA_real_)
  v <- 0
  for (d in nibble) v <- v * 16 + d
  v
}

hex_to_int <- function(h, bits) {
  v <- hex_to_uint(h)
  if (is.na(v)) return(NA_integer_)
  sign_bit <- 2^(bits - 1L)
  if (v >= sign_bit) v <- v - 2^bits
  as.integer(v)
}

field_spec <- function(name) {
  if (name == "time_unix")   return(list(n_hex = 8L, decode = hex_to_uint))
  if (name == "adc_temp")    return(list(n_hex = 6L, decode = function(h) hex_to_int(h, 24L)))
  if (name == "battery_mv")  return(list(n_hex = 4L, decode = hex_to_uint))
  if (grepl("\\.gnd$", name))
    return(list(n_hex = 4L, decode = function(h) hex_to_int(h, 16L)))
  if (grepl("\\.(ntc1|ntc2|pressure|testSB)$", name))
    return(list(n_hex = 6L, decode = function(h) hex_to_int(h, 24L)))
  stop("No decoding rule for field: ", name)
}

decode_hex_line <- function(schema, hex_string) {
  fields <- strsplit(trimws(schema), "\\s+")[[1]]
  out <- vector("list", length(fields))
  names(out) <- fields
  pos <- 1L
  for (i in seq_along(fields)) {
    sp <- field_spec(fields[i])
    block <- hex_block(hex_string, pos, sp$n_hex)
    out[[i]] <- if (nchar(block) == sp$n_hex) sp$decode(block) else NA
    pos <- pos + sp$n_hex
  }
  out
}

# ---- Level-2 conversion functions ----

adc2temp <- function(count)        6.101e-5 * count - 256.6
NTCcounts2temp <- function(counts) {
  H <- (-counts * 1000000) / (counts - 33554432)
  resistance <- (H * 499000) / (499000 - H)
  temperatures <- 1 / ((1 / 3380) * log(resistance / 10000) + 1 / 298.15) - 273.15
  temperatures
}
pressure2hPa <- function(p)        p / 1000
unix2posix_utc <- function(t)      as.POSIXct(t, origin = "1970-01-01", tz = "UTC")

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

# ---- Read data ----

df_raw <- read_csv(
  "./data/results-2.csv",   # Cloudloop export through 2026-07 (supersedes results-3.csv)
  show_col_types = FALSE,
  col_types = cols(
    `At (UTC)` = col_character(),
    Size       = col_integer(),
    Payload    = col_character(),
    .default   = col_character()
  )
) %>%
  # `Thing` may carry a "RockBLOCK " prefix here → pull the 6-digit modem serial.
  mutate(Thing = as.integer(sub(".*?(\\d{6}).*", "\\1", Thing))) %>%
  rename(
    datetime_utc = `At (UTC)`,
    modem        = Thing,
    nbytes       = Size,
    payload      = Payload
  ) %>%
  mutate(datetime_utc = dmy_hms(datetime_utc, tz = "UTC")) %>%
  arrange(datetime_utc)

cat("Rows read:", nrow(df_raw), "\n")
cat("Modems found:", paste(unique(df_raw$modem), collapse = ", "), "\n")
cat("Message sizes:\n")
print(table(df_raw$modem, df_raw$nbytes))

# ---- Modem 231709 (head03): pair 340 + 54 byte messages ----

df_09 <- df_raw %>%
  filter(modem == 231709) %>%
  arrange(datetime_utc) %>%
  mutate(
    next_time   = lead(datetime_utc),
    next_nbytes = lead(nbytes),
    next_pay    = lead(payload),
    dt_min      = as.numeric(difftime(next_time, datetime_utc, units = "mins"))
  ) %>%
  filter(nbytes == 340, next_nbytes == 54, !is.na(dt_min), dt_min <= 10) %>%
  transmute(
    modem          = 231709L,
    recv_time_utc  = next_time,
    start_time_utc = datetime_utc,
    hex_data       = paste0(payload, next_pay)
  )

cat("\nhead03 (231709) message pairs found:", nrow(df_09), "\n")

decoded_09 <- df_09 %>%
  mutate(decoded = map(hex_data, ~ decode_hex_line(schema_head03, .x))) %>%
  unnest_wider(decoded) %>%
  mutate(
    time_utc   = unix2posix_utc(time_unix),
    adc_temp_C = adc2temp(adc_temp),
    across(matches("\\.ntc[12]$"),   ~ NTCcounts2temp(.x), .names = "{.col}_temp_C"),
    across(matches("\\.pressure$"),  ~ pressure2hPa(.x),   .names = "{.col}_hPa")
  ) %>%
  select(
    modem, recv_time_utc, start_time_utc, time_utc,
    battery_mv, adc_temp_C,
    matches("\\.ntc[12]_temp_C$"),
    matches("\\.pressure_hPa$"),
    matches("\\.gnd$")
  )

# ---- Modem 231710 (head04): single 284-byte messages ----

df_10 <- df_raw %>%
  filter(modem == 231710, nbytes == 284) %>%
  arrange(datetime_utc) %>%
  transmute(
    modem          = 231710L,
    recv_time_utc  = datetime_utc,
    start_time_utc = datetime_utc,
    hex_data       = payload
  )

cat("head04 (231710) messages found:", nrow(df_10), "\n")

decoded_10 <- df_10 %>%
  mutate(decoded = map(hex_data, ~ decode_hex_line(schema_head04, .x))) %>%
  unnest_wider(decoded) %>%
  mutate(
    time_utc   = unix2posix_utc(time_unix),
    adc_temp_C = adc2temp(adc_temp),
    across(matches("\\.ntc[12]$"),   ~ NTCcounts2temp(.x), .names = "{.col}_temp_C"),
    across(matches("\\.testSB$"),    ~ pressure2hPa(.x),   .names = "{.col}_hPa")
  ) %>%
  select(
    modem, recv_time_utc, start_time_utc, time_utc,
    battery_mv, adc_temp_C,
    matches("\\.ntc[12]_temp_C$"),
    matches("\\.testSB_hPa$"),
    matches("\\.gnd$")
  )

# ---- Save results ----

write_csv(decoded_09, "./data/decoded_head03_231709.csv")
write_csv(decoded_10, "./data/decoded_head04_231710.csv")

cat("\nINFO: Payloads in results-3.csv are truncated at 128 bytes (256 hex chars) by the Rockblock web export.\n")
cat("  head03: 256 + 108 = 364 hex chars → approx. 15 of 35 nodes decoded (n1-n15), battery_mv = NA\n")
cat("  head04: 256 hex chars → approx. 11 of 25 nodes decoded (n1-n11), battery_mv = NA\n")

# Drop columns that are entirely NA
decoded_09_clean <- decoded_09 %>% select(where(~ !all(is.na(.))))
decoded_10_clean <- decoded_10 %>% select(where(~ !all(is.na(.))))

write_csv(decoded_09_clean, "./data/decoded_head03_231709.csv")
write_csv(decoded_10_clean, "./data/decoded_head04_231710.csv")

cat("\n=== head03 (231709) — first rows ===\n")
print(decoded_09_clean %>% select(time_utc, adc_temp_C, n1.ntc1_temp_C, n1.ntc2_temp_C, n1.pressure_hPa, n1.gnd))

cat("\nDecoded columns (head03):", ncol(decoded_09_clean), "\n")
cat("Decoded columns (head04):", ncol(decoded_10_clean), "\n")

cat("\nDone. Results saved to:\n")
cat("  data/decoded_head03_231709.csv\n")
cat("  data/decoded_head04_231710.csv\n")
