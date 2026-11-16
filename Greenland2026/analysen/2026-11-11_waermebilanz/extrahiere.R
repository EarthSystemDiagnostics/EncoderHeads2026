# Zieht Messreihe (series_diag, Tape-Fenster ausgeschnitten), Höhenachse und
# Oberflächenlage aus den Report-Codes decode_snowmelt_newgrip.qmd und
# decode_snowmelt_dye3.qmd (per knitr::purl), ohne die Reports zu ändern.
# Aufruf aus Greenland2026/:  Rscript analysen/2026-11-11_waermebilanz/extrahiere.R
A  <- "analysen/2026-11-11_waermebilanz"
tf <- tempfile(fileext = ".R")
multi <- TRUE
run_until <- function(qmd, marker, objs, out) {
  knitr::purl(qmd, output = tf, documentation = 1, quiet = TRUE)
  L <- readLines(tf); k <- grep(marker, L, fixed = TRUE)[1]
  stopifnot(!is.na(k))
  e <- new.env(); eval(parse(text = L[1:k]), envir = e)
  saveRDS(mget(intersect(objs, ls(e)), envir = e), out)
}
run_until("decode_snowmelt_newgrip.qmd", "surf <- tibble(day = alltage",
          c("ser_dat", "surf", "winter", "res", "h_bot", "h_ref", "d_fix", "aws_raw", "cfg"),
          file.path(A, "grip_objekte.rds"))
run_until("decode_snowmelt_dye3.qmd", "p_hov + p_prof",
          c("series_long", "ratio_d", "h_ref", "cfg", "s", "rank_map"),
          file.path(A, "dye3_objekte.rds"))
