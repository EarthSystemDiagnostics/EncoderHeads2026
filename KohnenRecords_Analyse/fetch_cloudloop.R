library(httr2)
library(base64enc)
library(readr)
library(dplyr)
library(lubridate)
library(purrr)
library(tidyr)

# ---- CONFIG — fill in before running ----
CLOUDLOOP_URL <- "https://api.cloudloop.com"  # verify under "Servers" in Swagger UI

# Token: request initially from help@groundcontrol.com
# Then generate a new one via User/DoGenerateToken (tokens cannot be recovered once set!)
CLOUDLOOP_TOKEN <- "f7ba9e62-50c9-4a72-906a-xxxxxxxxxxxx"   # your token here

# Find Thing IDs: Cloudloop UI → Things, or use Data/DoSearchThing below
# The numbers 231709/231710 are Rockblock serials, NOT Cloudloop Thing IDs
THING_ID_HEAD03 <- "XXXX"   # Thing ID for modem 231709 (head03, 35 nodes)
THING_ID_HEAD04 <- "YYYY"   # Thing ID for modem 231710 (head04, 25 nodes)

DATE_FROM <- "2026-03-01T00:00:00"
DATE_TO   <- "2026-06-13T00:00:00"
# -----------------------------------------


# ---- Validate token ----
ping <- request(paste0(CLOUDLOOP_URL, "/Platform/Ping")) |>
  req_url_query(token = CLOUDLOOP_TOKEN) |>
  req_perform() |>
  resp_body_json()
cat("Ping:", jsonlite::toJSON(ping, auto_unbox = TRUE), "\n")


# ---- Helper: call any endpoint with token as query param ----
cl_get <- function(endpoint, query_params = list()) {
  params <- c(list(token = CLOUDLOOP_TOKEN), query_params)
  request(paste0(CLOUDLOOP_URL, "/", endpoint)) |>
    req_url_query(!!!params) |>
    req_perform() |>
    resp_body_json()
}

cl_post <- function(endpoint, body = list()) {
  request(paste0(CLOUDLOOP_URL, "/", endpoint)) |>
    req_url_query(token = CLOUDLOOP_TOKEN) |>
    req_headers("Content-Type" = "application/json") |>
    req_body_json(body) |>
    req_perform() |>
    resp_body_json()
}


# ---- Optional: find your Thing IDs by searching for the modem serials ----
# Uncomment and run once to discover your Thing IDs:
# things <- cl_post("Data/DoSearchThing", list(search = "231709"))
# print(things)
# things <- cl_post("Data/DoSearchThing", list(search = "231710"))
# print(things)


# ---- Step 1: Get message record IDs for each Thing ----
get_message_ids <- function(thing_id, date_from, date_to) {
  body <- cl_post("Data/GetMessageRecordsForThing",
                  list(thing = thing_id, from = date_from, to = date_to))
  records <- body$messageRecords %||% body
  map_dfr(records, ~ tibble(
    id        = .x$id,
    at        = .x$at,
    size      = .x$size %||% NA_integer_,
    direction = .x$direction %||% NA_character_
  )) |>
    filter(direction == "MO")
}

ids_head03 <- get_message_ids(THING_ID_HEAD03, DATE_FROM, DATE_TO)
ids_head04 <- get_message_ids(THING_ID_HEAD04, DATE_FROM, DATE_TO)

cat("head03 MO messages found:", nrow(ids_head03), "\n")
cat("head04 MO messages found:", nrow(ids_head04), "\n")
cat("head03 sizes:\n"); print(table(ids_head03$size))
cat("head04 sizes:\n"); print(table(ids_head04$size))


# ---- Step 2: Fetch full payload via GetLingoMo for each message ----
get_full_payload_hex <- function(message_id) {
  body <- cl_get("Data/GetLingoMo", list(messageRecord = message_id))
  b64 <- body$message
  if (is.null(b64) || is.na(b64)) return(NA_character_)
  raw_bytes <- base64decode(b64)
  paste(toupper(format(as.hexmode(as.integer(raw_bytes)), width = 2)), collapse = "")
}

cat("\nFetching full payloads for head03 (", nrow(ids_head03), "messages)...\n")
ids_head03$payload_hex <- map_chr(
  ids_head03$id, ~ { Sys.sleep(0.1); get_full_payload_hex(.x) }
)

cat("Fetching full payloads for head04 (", nrow(ids_head04), "messages)...\n")
ids_head04$payload_hex <- map_chr(
  ids_head04$id, ~ { Sys.sleep(0.1); get_full_payload_hex(.x) }
)

cat("head03 hex lengths:\n"); print(table(nchar(ids_head03$payload_hex)))
cat("head04 hex lengths:\n"); print(table(nchar(ids_head04$payload_hex)))


# ---- Step 4: Pair head03 messages (680-hex + 108-hex) ----
df_head03 <- ids_head03 |>
  mutate(
    at      = ymd_hms(at, tz = "UTC"),
    hex_len = nchar(payload_hex)
  ) |>
  arrange(at)

pairs_head03 <- df_head03 |>
  mutate(
    next_at      = lead(at),
    next_hex_len = lead(hex_len),
    next_pay     = lead(payload_hex),
    dt_min       = as.numeric(difftime(next_at, at, units = "mins"))
  ) |>
  filter(hex_len == 680, next_hex_len == 108, !is.na(dt_min), dt_min <= 10) |>
  transmute(
    recv_time_utc  = next_at,
    start_time_utc = at,
    hex_data       = paste0(payload_hex, next_pay)
  )

cat("\nhead03 message pairs:", nrow(pairs_head03), "\n")

df_head04 <- ids_head04 |>
  mutate(
    at      = ymd_hms(at, tz = "UTC"),
    hex_len = nchar(payload_hex)
  ) |>
  filter(hex_len == 568) |>    # 284 bytes = 568 hex chars
  transmute(
    recv_time_utc  = at,
    start_time_utc = at,
    hex_data       = payload_hex
  )


# ---- Step 5: Decode (reuse functions from decode_results3.R) ----
source("decode_results3.R")

decoded_head03 <- pairs_head03 |>
  mutate(decoded = map(hex_data, ~ decode_hex_line(schema_head03, .x))) |>
  unnest_wider(decoded) |>
  mutate(
    time_utc   = unix2posix_utc(time_unix),
    adc_temp_C = adc2temp(adc_temp),
    across(matches("\\.ntc[12]$"),  ~ NTCcounts2temp(.x), .names = "{.col}_temp_C"),
    across(matches("\\.pressure$"), ~ pressure2hPa(.x),   .names = "{.col}_hPa")
  ) |>
  select(recv_time_utc, start_time_utc, time_utc, battery_mv, adc_temp_C,
         matches("\\.ntc[12]_temp_C$"), matches("\\.pressure_hPa$"), matches("\\.gnd$")) |>
  select(where(~ !all(is.na(.))))

decoded_head04 <- df_head04 |>
  mutate(decoded = map(hex_data, ~ decode_hex_line(schema_head04, .x))) |>
  unnest_wider(decoded) |>
  mutate(
    time_utc   = unix2posix_utc(time_unix),
    adc_temp_C = adc2temp(adc_temp),
    across(matches("\\.ntc[12]$"), ~ NTCcounts2temp(.x), .names = "{.col}_temp_C"),
    across(matches("\\.testSB$"),  ~ pressure2hPa(.x),   .names = "{.col}_hPa")
  ) |>
  select(recv_time_utc, start_time_utc, time_utc, battery_mv, adc_temp_C,
         matches("\\.ntc[12]_temp_C$"), matches("\\.testSB_hPa$"), matches("\\.gnd$")) |>
  select(where(~ !all(is.na(.))))


# ---- Step 6: Save ----
write_csv(decoded_head03, "./data/decoded_full_head03_231709.csv")
write_csv(decoded_head04, "./data/decoded_full_head04_231710.csv")

cat("\nFertig. Gespeichert:\n")
cat("  data/decoded_full_head03_231709.csv  (", nrow(decoded_head03), "Zeilen,", ncol(decoded_head03), "Spalten)\n")
cat("  data/decoded_full_head04_231710.csv  (", nrow(decoded_head04), "Zeilen,", ncol(decoded_head04), "Spalten)\n")
