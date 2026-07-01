# Illustration: how to read the calibration coefficients via the LOCAL SLOPE.
#
# The 4 Steinhart-Hart coefficients (a,b,c,d) define a *nonlinear* counts -> T
# curve that spans the whole measured temperature range and is hard to summarise
# by the four numbers themselves. The interpretable summary is the *local slope*
# dT/dcounts: the tangent (linearisation) of that curve at a temperature of
# interest, e.g. -5 or -15 degC.
#
# Left  : counts -> T curve for a few sensors over a wide T range, with the
#         tangent lines drawn at -5 and -15 degC (the "local slope").
# Right : the local slope dT/dcounts as a function of the reference temperature,
#         one line per sensor, with the two reference points marked. Shows that
#         the slope depends on *where* you evaluate it, which is exactly why a
#         single number can't summarise the nonlinear curve.

suppressMessages({library(dplyr); library(ggplot2); library(patchwork)})

# --- decoder stage + 4-parameter Steinhart-Hart (same as the analysis qmd) ----
NTCcounts2R <- function(c) { H <- (-c * 1e6) / (c - 33554432); (H * 499000) / (499000 - H) }
S4_T_C      <- function(R, co) { lR <- log(R); 1 / (co[1] + co[2]*lR + co[3]*lR^2 + co[4]*lR^3) - 273.15 }

read_sm <- function(f, src) {
  m <- read.csv(f, check.names = FALSE, row.names = 1)
  do.call(rbind, lapply(colnames(m), function(cn) {
    p <- strsplit(cn, "_")[[1]]
    data.frame(source = src, node = as.integer(sub("N", "", p[1])),
               ntc = as.integer(sub("NTC", "", p[2])),
               a = m["a", cn], b = m["b", cn], c = m["c", cn], d = m["d", cn])
  }))
}
co <- rbind(read_sm("../meta/SM1_CalibrationCoefficients.csv", "SM1"),
            read_sm("../meta/SM2_CalibrationCoefficients.csv", "SM2"))
co <- co[complete.cases(co[, c("a", "b", "c", "d")]), ]

# counts <-> T helpers for a single coefficient set ----------------------------
Tc_of    <- function(cf, counts) S4_T_C(NTCcounts2R(counts), cf)
counts_at <- function(cf, T0) {                       # counts where T == T0
  f <- function(cc) Tc_of(cf, cc) - T0
  if (sign(f(4e5)) == sign(f(3.2e6))) return(NA_real_)
  uniroot(f, c(4e5, 3.2e6), tol = 1)$root
}
slope_at <- function(cf, T0) {                        # dT/dcounts at T == T0
  c0 <- counts_at(cf, T0); if (is.na(c0)) return(NA_real_)
  (Tc_of(cf, c0 + 200) - Tc_of(cf, c0 - 200)) / 400
}

# keep only physically sensible sensors (well-behaved over the range) ----------
co$valid <- mapply(function(a,b,c,d) {
  s5 <- slope_at(c(a,b,c,d), -5)
  is.finite(s5) && s5 < 0 && abs(s5) < 1e-3
}, co$a, co$b, co$c, co$d)
co <- co[co$valid, ]

T_refs   <- c(-5, -15)                                # points of interest
ntc_pal  <- c(`NTC1` = "#2980b9", `NTC2` = "#e74c3c", `NTC3` = "#27ae60")
ntc_lab  <- function(k) factor(paste0("NTC", k), names(ntc_pal))

# =============================================================================
# LEFT panel: counts -> T curve + tangents for ONE representative sensor
# =============================================================================
# representative = sensor whose -5 degC slope is the median over all sensors
co$s5 <- mapply(function(a,b,c,d) slope_at(c(a,b,c,d), -5), co$a, co$b, co$c, co$d)
rep_i <- which.min(abs(co$s5 - median(co$s5)))
cf    <- as.numeric(co[rep_i, c("a","b","c","d")])
rep_name <- sprintf("N%d_NTC%d (%s)", co$node[rep_i], co$ntc[rep_i], co$source[rep_i])

# the full nonlinear curve over a wide T range (~ -30 .. +5 degC)
cc_grid <- seq(counts_at(cf, 5), counts_at(cf, -30), length.out = 400)
curve_df <- data.frame(counts = cc_grid, T = Tc_of(cf, cc_grid))

# tangent line segments at each reference temperature
tan_df <- do.call(rbind, lapply(T_refs, function(T0) {
  c0 <- counts_at(cf, T0); m <- slope_at(cf, T0)
  cc <- c0 + c(-2.2e5, 2.2e5)                          # short window around c0
  data.frame(Tref = T0, counts = cc, T = T0 + m * (cc - c0),
             mK_per_kcount = m * 1e6)
}))
pt_df <- do.call(rbind, lapply(T_refs, function(T0) {
  data.frame(Tref = T0, counts = counts_at(cf, T0), T = T0,
             lab = sprintf("%g °C:  %.0f mK / 1000 counts",
                           T0, slope_at(cf, T0) * 1e6))
}))

p_left <- ggplot() +
  geom_line(data = curve_df, aes(counts/1000, T), colour = "grey30", linewidth = 0.9) +
  geom_line(data = tan_df, aes(counts/1000, T, group = Tref),
            colour = "#c0392b", linewidth = 1.1) +
  geom_point(data = pt_df, aes(counts/1000, T), colour = "#c0392b", size = 3) +
  geom_text(data = pt_df, aes(counts/1000, T, label = lab),
            hjust = -0.05, vjust = 1.7, size = 3.5, colour = "#c0392b") +
  labs(title = "Nichtlineare Kalibrationskurve + lokale Steigung (Tangente)",
       subtitle = sprintf("Beispielsensor %s — rote Tangente = Linearisierung", rep_name),
       x = "Rohwert (1000 counts)", y = "Temperatur (°C)") +
  theme_bw(base_size = 12)

# =============================================================================
# RIGHT panel: local slope dT/dcounts vs reference temperature, all sensors
# =============================================================================
T_eval <- seq(-25, 2, by = 1)
slope_long <- do.call(rbind, lapply(seq_len(nrow(co)), function(i) {
  cf <- as.numeric(co[i, c("a","b","c","d")])
  data.frame(id = i, ntc = co$ntc[i],
             T0 = T_eval,
             slope = sapply(T_eval, function(t) slope_at(cf, t)))
}))
slope_long <- slope_long[is.finite(slope_long$slope), ]
slope_long$mK <- slope_long$slope * 1e6

p_right <- ggplot(slope_long, aes(T0, mK, group = id, colour = ntc_lab(ntc))) +
  geom_vline(xintercept = T_refs, linetype = "dashed", colour = "grey50") +
  geom_line(alpha = 0.35, linewidth = 0.4) +
  annotate("text", x = T_refs, y = min(slope_long$mK, na.rm = TRUE),
           label = paste0(T_refs, " °C"), vjust = 1.2, size = 3.3, colour = "grey30") +
  scale_colour_manual(values = ntc_pal, name = NULL) +
  coord_cartesian(clip = "off") +
  labs(title = "Lokale Steigung dT/dcounts vs. Bezugstemperatur",
       subtitle = "jede Linie = ein Sensor — Steigung je Arbeitspunkt",
       x = "Bezugstemperatur (°C)", y = "dT/dcounts (mK / 1000 counts)") +
  theme_bw(base_size = 12) +
  theme(legend.position = "inside", legend.position.inside = c(0.84, 0.7),
        legend.background = element_rect(fill = "white", colour = NA),
        plot.margin = margin(12, 12, 6, 6))

fig <- p_left + p_right + plot_layout(widths = c(1, 1)) +
  plot_annotation(
    caption = sprintf("%d Sensoren (SM1+SM2) | 4-Parameter Steinhart-Hart", nrow(co)))

outfile <- "local_slope_illustration.png"
ggsave(outfile, fig, width = 13, height = 5.4, dpi = 130)
cat("Saved:", normalizePath(outfile), "\n")
cat("Representative sensor:", rep_name, "\n")
print(pt_df[, c("Tref", "lab")])
