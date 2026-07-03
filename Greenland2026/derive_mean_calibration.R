# Derive the universal MEAN lab-S4 calibration coefficient set --------------------
#
# Purpose: a single 4-param Steinhart-Hart coefficient set (a,b,c,d) to use as the
# universal fallback in the decoder when a sensor / head has NO per-sensor lab
# calibration. It replaces the old fixed Beta curve, which reads systematically
# too warm (−0.7 °C at 0 °C, growing to −3.2 °C at −40 °C).
#
# Method: average a,b,c,d over the healthy GRIP sensors (drop the a_suspect fits).
# Because the S4 model 1/T = a + b·lnR + c·lnR^2 + d·lnR^3 is LINEAR in (a,b,c,d),
# the mean coefficients reproduce the mean 1/T curve EXACTLY — no refit needed.
# The mean curve represents every healthy sensor to ±0.03–0.05 °C (SD) over −40…0 °C.
#
# Output: meta/mean_calibration_coefficients.csv (one row, columns a,b,c,d,n_sensors).
# The same numbers are hard-coded as NTC_MEAN_COEF in Greenland2026/decode_field.qmd.
#
# Run from the repo root:  Rscript Greenland2026/derive_mean_calibration.R

assign_path <- "meta/GRIP_calibration_assignment.csv"
out_path    <- "meta/mean_calibration_coefficients.csv"

ca <- read.csv(assign_path)

# Healthy set: drop the flagged (a_suspect) and any non-finite fits.
healthy <- ca[!ca$a_suspect & is.finite(ca$a) & is.finite(ca$b) &
                is.finite(ca$c) & is.finite(ca$d), ]

mean_coef <- colMeans(healthy[, c("a", "b", "c", "d")])

out <- data.frame(
  a = mean_coef["a"], b = mean_coef["b"],
  c = mean_coef["c"], d = mean_coef["d"],
  n_sensors = nrow(healthy),
  source    = "mean of healthy GRIP sensors (a_suspect dropped) in GRIP_calibration_assignment.csv",
  model     = "1/T[K] = a + b*lnR + c*lnR^2 + d*lnR^3 ; T_C = 1/(1/T)-273.15",
  row.names = NULL
)

write.csv(out, out_path, row.names = FALSE)

cat(sprintf("Healthy sensors: %d of %d (per NTC: %s)\n",
            nrow(healthy), nrow(ca), paste(table(healthy$ntc), collapse = "/")))
cat(sprintf("Mean coefficients: a=%.10e b=%.10e c=%.10e d=%.10e\n",
            mean_coef[1], mean_coef[2], mean_coef[3], mean_coef[4]))
cat(sprintf("Written to %s\n", out_path))
