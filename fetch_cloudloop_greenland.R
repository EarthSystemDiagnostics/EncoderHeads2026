# fetch_cloudloop_greenland.R — pull FULL Greenland payloads from the Cloudloop API
# and write them as .bin into testdata/ (the decoders' data of record).
#
# WHY: the Cloudloop *web CSV* export truncates payloads at 128 B (only ~13 of 24
# nodes, no battery). The API returns the full message, so this restores complete
# 225/226/231-byte profiles. Data moved to Cloudloop after ~2026-07-22.
#
# AUTH: token is read from $CLOUDLOOP_TOKEN or ./cloudloop/.token (git-ignored).
#       Never hard-code the token; never commit it.
#
# The three Greenland heads are identified by their MESSAGE SIZE (robust across
# the opaque Cloudloop Thing IDs): 225 = GRIP, 226 = Dye3, 231 = Doppelkette.
# Antarctic heads (284/340 B, latitude −75) are skipped here.
#
# Run from the repo root:  Rscript fetch_cloudloop_greenland.R
# Idempotent: only writes messages whose embedded timestamp is not already on disk.

suppressMessages({library(httr2); library(jsonlite); library(base64enc)})
`%||%` <- function(a, b) if (is.null(a)) b else a

FROM <- "2026-07-01T00:00:00"      # widen if backfilling; dedup makes overlap safe
TO   <- "2026-09-01T00:00:00"      # open upper bound (API caps at latest)

size2imei <- c("225" = "300434065508020",   # SnowMelt GRIP
               "226" = "301434062008160",   # SnowMelt Dye3
               "231" = "301434062008130")   # Doppelkette

# ---- token ----
tok <- Sys.getenv("CLOUDLOOP_TOKEN", unset = NA)
if (is.na(tok) || !nzchar(tok)) {
  stopifnot("cloudloop/.token missing — set $CLOUDLOOP_TOKEN or create it" =
              file.exists("cloudloop/.token"))
  tok <- trimws(readLines("cloudloop/.token", warn = FALSE)[1])
}
base <- "https://api.cloudloop.com"
P <- function(ep, q = list()) request(paste0(base, "/", ep)) |>
  req_url_query(!!!c(list(token = tok), q)) |> req_method("POST") |>
  req_retry(max_tries = 5) |> req_perform(verbosity = 0) |> resp_body_json()

stopifnot("API ping failed" = identical(P("Platform/Ping")$ping, "pong"))

lingo_hex <- function(mrid) {
  m <- P("Data/GetLingoMo", list(messageRecord = mrid))$message %||% NA
  if (is.na(m)) return(NA_character_)
  paste(sprintf("%02X", as.integer(base64decode(m))), collapse = "")
}

# ---- existing embedded timestamps on disk (dedup key) ----
have_ts <- function(imei) {
  fs <- Sys.glob(file.path("testdata", paste0(imei, "-*.bin")))
  ts <- vapply(fs, function(f) { r <- readBin(f, "raw", 4L); sum(as.integer(r) * 256^(3:0)) },
               numeric(1))
  as.numeric(ts)
}

things <- P("Data/GetThings")$things
cat(sprintf("Cloudloop: %d things on account\n", length(things)))
total_new <- 0L

for (t in things) {
  recs <- P("Data/GetMessageRecordsForThing",
            list(thing = t$id, from = FROM, to = TO))$messageRecords
  mo <- Filter(function(x) (x$direction %||% "") == "MO", recs)
  if (!length(mo)) next
  sizes <- as.integer(unlist(lapply(mo, function(x) x$size %||% NA)))
  key   <- names(which.max(table(sizes)))          # modal size = head signature
  imei  <- unname(size2imei[key])                   # NA if not a Greenland head
  if (is.na(imei)) next                              # Antarctic (284/340) / other → skip

  existing <- have_ts(imei)
  added <- 0L
  for (m in mo) {
    if (as.integer(m$size %||% -1L) != as.integer(key)) next   # skip odd-sized msgs
    hx <- lingo_hex(m$id)
    if (is.na(hx) || nchar(hx) < 8L) next
    ts <- strtoi(substr(hx, 1, 8), 16L)
    if (ts %in% existing) next
    dt <- format(as.POSIXct(ts, origin = "1970-01-01", tz = "UTC"), "%y%m%d%H%M")
    writeBin(as.raw(strtoi(substring(hx, seq(1, nchar(hx), 2), seq(2, nchar(hx), 2)), 16L)),
             file.path("testdata", sprintf("%s-rb%s.bin", imei, dt)))
    existing <- c(existing, ts); added <- added + 1L
  }
  cat(sprintf("  %s (size %s): +%d new .bin\n", imei, key, added))
  total_new <- total_new + added
}
cat(sprintf("TOTAL new Greenland .bin: %d\n", total_new))
