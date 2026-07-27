# fetch_antarctic_cloudloop.R — pull FULL Kohnen (Antarctic) payloads from the
# Cloudloop API and write them to data/results-api-full.csv in the same column
# shape as the web export (results-*.csv), but with UNtruncated Payload hex.
#
# WHY: the Cloudloop *web CSV* export truncates payloads at 128 B, so
# decode_combined.R only recovered ~15/~11 of the 35/25 nodes. The API returns the
# full message. This script is the drop-in "new" source for decode_combined.R,
# which then merges it with the old (Jan–Mar) full-payload CSV and decodes every
# node across the whole record.
#
# head03 = modem 231709 (340 B + 54 B pair), head04 = modem 231710 (284 B single).
# The two Antarctic Things are identified by latitude ≈ −75 and message size
# (Cloudloop Thing IDs are opaque). AUTH: $CLOUDLOOP_TOKEN or ../cloudloop/.token.
#
# Run from KohnenRecords_Analyse/:  Rscript fetch_antarctic_cloudloop.R
#   then:                            Rscript decode_combined.R

suppressMessages({library(httr2); library(jsonlite); library(base64enc)
                  library(dplyr); library(purrr); library(lubridate); library(readr)})
`%||%` <- function(a, b) if (is.null(a)) b else a
FROM <- "2026-01-01T00:00:00"; TO <- "2026-09-01T00:00:00"

tok <- Sys.getenv("CLOUDLOOP_TOKEN", unset=NA)
if (is.na(tok) || !nzchar(tok)) tok <- trimws(readLines("../cloudloop/.token", warn=FALSE)[1])
base <- "https://api.cloudloop.com"
P <- function(ep,q=list()) request(paste0(base,"/",ep)) |> req_url_query(!!!c(list(token=tok),q)) |>
  req_method("POST") |> req_retry(max_tries=5) |> req_perform(verbosity=0) |> resp_body_json()
lingo_hex <- function(id){ m<-P("Data/GetLingoMo",list(messageRecord=id))$message %||% NA
  if (is.na(m)) return(NA_character_); paste(sprintf("%02x",as.integer(base64decode(m))),collapse="") }

things <- P("Data/GetThings")$things
ant <- Filter(function(t){ la<-suppressWarnings(as.numeric(t$latitude%||%NA)); !is.na(la)&&la< -60 }, things)
cat(sprintf("Antarctic things: %d\n", length(ant)))

pull <- function(id){
  mo <- Filter(function(x)(x$direction%||%"")=="MO",
               P("Data/GetMessageRecordsForThing",list(thing=id,from=FROM,to=TO))$messageRecords)
  tibble(id=map_chr(mo,~.x$id), at=ymd_hms(map_chr(mo,~.x$at%||%NA),tz="UTC"),
         size=map_int(mo,~as.integer(.x$size%||%NA)))
}
meta <- map(ant, ~ { df<-pull(.x$id); list(id=.x$id, df=df, sizes=sort(unique(df$size))) })
th03 <- meta[[which(map_lgl(meta, ~ all(c(340L,54L) %in% .x$sizes)))[1]]]
th04 <- meta[[which(map_lgl(meta, ~ 284L %in% .x$sizes && !all(c(340L,54L)%in%.x$sizes)))[1]]]
cat(sprintf("head03 %s (%d msgs) | head04 %s (%d msgs)\n",
    substr(th03$id,1,8),nrow(th03$df),substr(th04$id,1,8),nrow(th04$df)))

emit <- function(th, serial){
  th$df |> mutate(modem=serial, Payload=map_chr(id, lingo_hex)) |>
    filter(!is.na(Payload), nchar(Payload)>=16) |>
    transmute(`At (UTC)`=format(at, "%d %b %Y %H:%M:%S"),  # dmy, matches web export
              Direction="MO", Thing=as.character(serial),
              Size=size, Payload=toupper(Payload))
}
out <- bind_rows(emit(th03, 231709L), emit(th04, 231710L))
write_csv(out, "./data/results-api-full.csv")
cat(sprintf("Wrote data/results-api-full.csv: %d rows\n", nrow(out)))
cat("  by (modem,size):\n"); print(count(out, Thing, Size))
cat("  hex-length check (should be 680/108 for 231709, 568 for 231710):\n")
print(count(mutate(out, hl=nchar(Payload)), Thing, hl))
