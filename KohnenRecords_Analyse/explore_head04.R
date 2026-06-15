library(readr); library(dplyr); library(lubridate)

d <- read_csv("./data/decoded_head04_231710.csv", show_col_types = FALSE)

ntc_cols <- grep("^n[0-9]+\\.ntc1_temp_C", names(d), value = TRUE)
nodes    <- as.integer(sub("n(\\d+)\\..*", "\\1", ntc_cols))

cat("NTC1 Temperaturen pro Node:\n")
for (col in ntc_cols) {
  node <- sub("n(\\d+)\\..*", "\\1", col)
  cat(sprintf("  n%-2s: %6.2f bis %6.2f  C  (sd = %.4f  NA = %d)\n",
              node,
              min(d[[col]], na.rm = TRUE),
              max(d[[col]], na.rm = TRUE),
              sd(d[[col]],  na.rm = TRUE),
              sum(is.na(d[[col]]))))
}

cat("\ntestSB Werte (sollen sie ~konstant sein?):\n")
sb_cols <- grep("testSB", names(d), value = TRUE)
for (col in sb_cols) {
  cat(sprintf("  %-20s: %.1f bis %.1f\n", col,
              min(d[[col]], na.rm=TRUE), max(d[[col]], na.rm=TRUE)))
}
