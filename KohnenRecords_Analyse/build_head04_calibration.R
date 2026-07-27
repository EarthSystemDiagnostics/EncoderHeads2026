# build_head04_calibration.R — extract the 2023 lab calibration for head04 (modem
# 231710, the Kohnen borehole chain) into a self-contained CSV, so the decode no
# longer needs the external Calibrations.RData at render time.
#
# Source: /Users/tlaepple/data/KohnenThermal/Calibrations.RData  (Nora Hirsch, 2023)
#   Calibrations$Kette1$<variant> is a 50×4 S4 matrix (a,b,c,d): rows 1–25 = NTC1,
#   rows 26–50 = NTC2 of the SAME 25 physical sensors. The counts→resistance and
#   S4→°C formulas are byte-identical to Greenland2026/decode_core.R (verified).
# Node→sensor order + depths are taken from Calibrations.R::predictChain (the order
# kept from the deployment Excel sheet): head04 nodes n1–n20 = Kette1 borehole
# (1–201 m), n21–n25 = the shallow 10 m-chain (1–6 m).
#
# head04 ONLY — head03 keeps the universal (Beta) curve.
# Run from KohnenRecords_Analyse/:  Rscript build_head04_calibration.R

suppressMessages({library(dplyr); library(readr); library(tidyr); library(readxl)})

VARIANT <- "Both"     # chosen 2026-07-27 (Fluke+CC combined; deep firn → −44.5 °C = Kohnen mean-annual)
RDATA   <- "/Users/tlaepple/data/KohnenThermal/Calibrations.RData"
# Authoritative node↔sensor↔depth sheet (Belegung). Borehole ("Tiefe ist") depths
# come from here; the shallow 10 m-chain has no depth here → fall back to Calibrations.R.
BELEGUNG <- "/Users/tlaepple/data/KohnenThermal/data/Temp-Node-Sensor_Belegung_AWI.xlsx"

e <- new.env(); load(RDATA, envir = e)
K1 <- e$Calibrations$Kette1[[VARIANT]]        # 50×4 (a,b,c,d)
stopifnot(nrow(K1) == 50L, ncol(K1) == 4L)

# --- node → calibration-row + depth, from Calibrations.R::predictChain ---
r_main <- c(11,12,20,6,8,13,16,18,19,21,22,25,28,29,5,7,9,15,24,26) - 4      # borehole (20)
d_main <- c(1,2,5.02,8.03,10.04,13.05,16.06,21.07,26.085,32.1,40.135,50.18,
            62.23,75.31,92.39,111.48,133.56,157.66,187.17,201.31)
r_10m  <- c(10,14,17,23,27) - 4                                             # shallow 10 m-chain (5)
d_10m  <- c(1.000,1.355,1.865,2.879,5.904)

cal_row <- c(r_main, r_10m); depth <- c(d_main, d_10m)          # head04 n1..n25 order
stopifnot(length(cal_row) == 25L)

# Override the borehole depths with the authoritative "Tiefe ist" from the Belegung
# sheet (keyed by physical node = cal_row + 4); keep Calibrations.R for the shallow
# chain (n21–n25), where the sheet has no depth. Only differs by ~7 cm at n19/n20.
if (file.exists(BELEGUNG)) {
  tz <- suppressMessages(as.data.frame(read_excel(BELEGUNG, sheet = "Tiefenzuordnung")))
  names(tz) <- as.character(unlist(tz[1, ])); tz <- tz[-1, 1:4]
  names(tz) <- c("position", "node", "tiefe_ist", "tiefe_soll")
  tz$node <- suppressWarnings(as.integer(tz$node))
  tz$tiefe_ist <- suppressWarnings(as.numeric(tz$tiefe_ist))
  d_ist <- setNames(tz$tiefe_ist, tz$node)              # physical node → actual depth
  phys  <- cal_row + 4L
  hit   <- !is.na(d_ist[as.character(phys)])
  depth[hit] <- unname(d_ist[as.character(phys)][hit])
  cat(sprintf("Depths from Belegung 'Tiefe ist' for %d borehole nodes.\n", sum(hit)))
}

# NTC1 = row cal_row; NTC2 = row cal_row + 25 (per predictChain)
mk <- function(ntc, rowoff) {
  rr <- cal_row + rowoff                     # precompute (avoid tibble self-reference)
  tibble(node = 1:25, depth_m = depth, ntc = ntc, cal_row = rr,
         a = K1[rr, 1], b = K1[rr, 2], c = K1[rr, 3], d = K1[rr, 4])
}
assign <- bind_rows(mk(1L, 0L), mk(2L, 25L)) |> arrange(node, ntc)

write_csv(assign, "./data/head04_calibration.csv")
cat(sprintf("Wrote data/head04_calibration.csv: %d rows (25 nodes × NTC1/NTC2), variant=%s\n",
            nrow(assign), VARIANT))

# --- SD cross-check of the node order (user's suggestion: large SD = shallow) ---
NTC_s4 <- function(cnt, co){ H <- (-cnt*1e6)/(cnt-33554432); r <- (H*499000)/(499000-H)
  1/(co[1]+co[2]*log(r)+co[3]*log(r)^2+co[4]*log(r)^3) - 273.15 }
if (file.exists("data/decoded_head04_231710_combined.csv")) {
  d <- read_csv("data/decoded_head04_231710_combined.csv", show_col_types = FALSE)
  sd_by_node <- sapply(1:25, function(n){ c <- sprintf("n%d.ntc1_temp_C", n)
    if (c %in% names(d)) sd(d[[c]], na.rm = TRUE) else NA })
  chk <- tibble(node = 1:25, depth_m = depth, sd_C = round(sd_by_node, 3)) |>
    filter(node <= 20) |> arrange(depth_m)
  rho <- cor(chk$depth_m, chk$sd_C, method = "spearman")
  cat(sprintf("\nSD cross-check (borehole n1–n20): Spearman(depth, SD) = %.3f (expect strongly negative: deeper = smaller SD)\n", rho))
  print(chk, n = 20)
}
