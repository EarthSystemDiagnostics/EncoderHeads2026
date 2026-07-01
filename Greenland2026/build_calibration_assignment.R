# ---------------------------------------------------------------------------
# Assign per-node / per-NTC calibration coefficients (counts -> temperature) to
# the GRIP setup (IMEI 300434065508020).
#
# GRIP_Position_NodeNr.xlsx : satellite position 1..24 (bottom -> top, the order
#                             the satellite data arrives) -> physical node number.
# SM1/SM2_CalibrationCoefficients.csv : coefficients a,b,c,d per "N<node>_NTC<k>".
#
# Source rule: a GRIP node's coefficients are taken from SM2 if that node is in
# SM2, otherwise from SM1. For this GRIP build that means the top two positions
# (nodes 27 & 26) come from SM2 and positions 1..22 from SM1 — node 27 exists
# only in SM2, and node 26's SM1 calibration is defective (NTC2/NTC3 outliers)
# while its SM2 calibration is clean.
# ---------------------------------------------------------------------------
suppressMessages({library(readxl); library(dplyr); library(tidyr)})

meta   <- "meta"
IMEI   <- "300434065508020"   # GRIP snowmelt head

pos <- read_excel(file.path(meta, "GRIP_Position_NodeNr.xlsx")) |> as.data.frame()
names(pos) <- c("position", "node")
pos$position <- as.integer(pos$position); pos$node <- as.integer(pos$node)
pos <- pos[order(pos$position), ]

read_sm <- function(f, src) {
  d    <- read.csv(file.path(meta, f), check.names = FALSE, row.names = 1)  # rows a,b,c,d
  long <- data.frame(key = colnames(d), t(d), row.names = NULL, check.names = FALSE)
  names(long)[-1] <- rownames(d)
  long |>
    separate(key, into = c("node", "ntc"), sep = "_") |>
    mutate(node = as.integer(sub("^N", "", node)),
           ntc  = as.integer(sub("^NTC", "", ntc)),
           source = src) |>
    select(node, ntc, a, b, c, d, source)
}
coef_all <- bind_rows(read_sm("SM1_CalibrationCoefficients.csv", "SM1"),
                      read_sm("SM2_CalibrationCoefficients.csv", "SM2"))

# Preferred source per node: SM2 if available, else SM1.
pref <- coef_all |>
  mutate(prio = ifelse(source == "SM2", 2L, 1L)) |>
  group_by(node, ntc) |>
  slice_max(prio, n = 1, with_ties = FALSE) |>
  ungroup() |>
  select(-prio)

# Join onto the 24 GRIP positions × 3 NTCs (NTC1/NTC2/NTC3).
assign <- pos |>
  tidyr::crossing(ntc = 1:3) |>
  left_join(pref, by = c("node", "ntc")) |>
  arrange(position, ntc)

# --- Report -----------------------------------------------------------------
miss <- assign |> filter(if_any(c(a, b, c, d), is.na))
cat(sprintf("GRIP assignment: %d positions × 3 NTC = %d rows\n", nrow(pos), nrow(assign)))
cat("source counts:\n"); print(table(assign$source))
cat(sprintf("missing / NA coefficient rows: %d\n", nrow(miss)))
if (nrow(miss)) print(miss |> select(position, node, ntc))
cat("\nNodes taken from SM2 (rest from SM1):",
    paste(sort(unique(assign$node[assign$source == "SM2"])), collapse = " "), "\n")

# Outlier flag on coefficient 'a' (robust z > 4) just as a heads-up for later.
med <- median(assign$a, na.rm = TRUE); madv <- mad(assign$a, na.rm = TRUE)
assign$a_suspect <- abs(assign$a - med) > 4 * madv
if (any(assign$a_suspect, na.rm = TRUE)) {
  cat("\nSuspect 'a' coefficients (robust z>4):\n")
  print(assign |> filter(a_suspect) |> select(position, node, ntc, a, source))
}

# --- Write ------------------------------------------------------------------
out <- assign |> select(position, node, ntc, a, b, c, d, source, a_suspect)
outfile <- file.path(meta, "GRIP_calibration_assignment.csv")
write.csv(out, outfile, row.names = FALSE)
cat("\nSaved:", outfile, "\n")
