# Local slope as a corruption check for "anomalous" coefficient sets.
#
# Some lab coefficient sets look anomalous (a,b,c,d far from the population) and
# were suspected to be corrupt. The local slope dT/dcounts at a working point
# reveals the truth: an entangled-but-valid parametrisation gives a perfectly
# normal slope; only a genuinely broken set flies off.
#
# Left  : counts->T curves + tangents at -5 degC for normal vs. "anomalous but
#         fine" vs. truly corrupt sensors.
# Right : coefficient anomaly (robust z of a,b,c,d) vs. local slope at -5 degC
#         for ALL sensors -> anomaly in the coefficients does NOT imply anomaly
#         in the slope, except for the one corrupt sensor.

suppressMessages({library(dplyr); library(ggplot2); library(patchwork); library(ggrepel)})

NTCcounts2R <- function(c) { H <- (-c * 1e6) / (c - 33554432); (H * 499000) / (499000 - H) }
S4_T_C      <- function(R, co) { lR <- log(R); 1 / (co[1] + co[2]*lR + co[3]*lR^2 + co[4]*lR^3) - 273.15 }

read_sm <- function(f, src) {
  m <- read.csv(f, check.names = FALSE, row.names = 1)
  do.call(rbind, lapply(colnames(m), function(cn) {
    p <- strsplit(cn, "_")[[1]]
    data.frame(source = src, node = as.integer(sub("N", "", p[1])),
               ntc = as.integer(sub("NTC", "", p[2])), name = cn,
               a = m["a", cn], b = m["b", cn], c = m["c", cn], d = m["d", cn])
  }))
}
co <- rbind(read_sm("../meta/SM1_CalibrationCoefficients.csv", "SM1"),
            read_sm("../meta/SM2_CalibrationCoefficients.csv", "SM2"))
co <- co[complete.cases(co[, c("a", "b", "c", "d")]), ]

Tc_of    <- function(cf, counts) S4_T_C(NTCcounts2R(counts), cf)
counts_at <- function(cf, T0) {
  f <- function(cc) Tc_of(cf, cc) - T0
  if (sign(f(4e5)) == sign(f(3.2e6))) return(NA_real_)
  uniroot(f, c(4e5, 3.2e6), tol = 1)$root
}
slope_at <- function(cf, T0) {
  c0 <- counts_at(cf, T0); if (is.na(c0)) return(NA_real_)
  (Tc_of(cf, c0 + 200) - Tc_of(cf, c0 - 200)) / 400
}
is_mono <- function(cf) { cc <- seq(7e5, 2.3e6, length.out = 200); all(diff(Tc_of(cf, cc)) < 0) }

# robust coefficient-anomaly score: max |z| over a,b,c,d (median/MAD) ----------
med <- sapply(c("a","b","c","d"), function(k) median(co[[k]]))
mad_ <- sapply(c("a","b","c","d"), function(k) mad(co[[k]]))
co$zmax  <- apply(co[, c("a","b","c","d")], 1, function(r) max(abs((r - med) / mad_)))
co$s5    <- mapply(function(a,b,c,d) slope_at(c(a,b,c,d), -5)  * 1e6, co$a, co$b, co$c, co$d)
co$mono  <- mapply(function(a,b,c,d) is_mono(c(a,b,c,d)),             co$a, co$b, co$c, co$d)
co$corrupt <- !co$mono | !is.finite(co$s5) | co$s5 > -10 | co$s5 < -40

# --- pick sensors for the curve panel ----------------------------------------
normal2  <- co |> filter(zmax < 2, !corrupt) |> arrange(abs(s5 + 23.7)) |> slice(1:2)
anomfine <- co |> filter(name %in% c("N77_NTC3", "N96_NTC3", "N80_NTC3"))
showco <- bind_rows(
  transform(normal2,  cls = "normal (z<2)"),
  transform(anomfine, cls = "anomale Koeffizienten (z 20–39)"))
showco$lab <- sprintf("%s (z=%.0f)", showco$name, showco$zmax)

cls_pal <- c(`normal (z<2)` = "#1f78b4", `anomale Koeffizienten (z 20–39)` = "#33a02c")
T0 <- -5

curve_df <- do.call(rbind, lapply(seq_len(nrow(showco)), function(i) {
  cf <- as.numeric(showco[i, c("a","b","c","d")])
  cc <- seq(7e5, 2.3e6, length.out = 400)
  data.frame(lab = showco$lab[i], cls = showco$cls[i], counts = cc, T = Tc_of(cf, cc))
}))
cn <- curve_df |> filter(cls == "normal (z<2)")          # blue halo (drawn first)
ca <- curve_df |> filter(cls != "normal (z<2)")          # green core on top
tan_df <- do.call(rbind, lapply(seq_len(nrow(showco)), function(i) {
  cf <- as.numeric(showco[i, c("a","b","c","d")]); c0 <- counts_at(cf, T0); m <- slope_at(cf, T0)
  cc <- c0 + c(-2e5, 2e5)
  data.frame(lab = showco$lab[i], counts = cc, T = T0 + m * (cc - c0))
}))
pt_df <- data.frame(counts = mean(sapply(seq_len(nrow(showco)),
                      function(i) counts_at(as.numeric(showco[i, c("a","b","c","d")]), T0))), T = T0)

p_left <- ggplot() +
  geom_line(data = cn, aes(counts/1000, T, group = lab, colour = cls), linewidth = 2.4) +
  geom_line(data = ca, aes(counts/1000, T, group = lab, colour = cls), linewidth = 0.8) +
  geom_line(data = tan_df, aes(counts/1000, T, group = lab), colour = "black", linewidth = 0.5) +
  geom_point(data = pt_df, aes(counts/1000, T), colour = "black", size = 2) +
  annotate("text", x = pt_df$counts/1000, y = T0,
           label = "Tangente −5 °C\n≈ −23.7 mK/kcount\n(alle gesunden)",
           hjust = -0.06, vjust = 0.9, size = 3.1) +
  scale_colour_manual(values = cls_pal, name = NULL) +
  coord_cartesian(ylim = c(-30, 12)) +
  labs(title = "5 sehr verschiedene Koeffizientensätze — eine Kurve",
       subtitle = "grün (anomale a,b,c,d) liegt exakt auf blau: gleiche Kurve, gleiche lokale Steigung",
       x = "Rohwert (1000 counts)", y = "Temperatur (°C)") +
  theme_bw(base_size = 12) +
  theme(legend.position = "inside", legend.position.inside = c(0.36, 0.16),
        legend.background = element_rect(fill = "white", colour = "grey80"))

# --- RIGHT: coefficient anomaly vs. local slope, all sensors -----------------
allc <- co |> mutate(grp = ifelse(corrupt, "korrupt", "gesund"),
                     s5_plot = pmin(pmax(s5, -40), -10))
off <- allc |> filter(corrupt)                     # off-scale slope label
p_right <- ggplot(allc, aes(zmax, s5_plot, colour = grp)) +
  annotate("rect", xmin = 0, xmax = Inf, ymin = -24.0, ymax = -23.4,
           fill = "#1f78b4", alpha = 0.12) +
  geom_point(size = 2, alpha = 0.8) +
  annotate("text", x = off$zmax, y = -11.2,
           label = sprintf("%s: Steigung %.0e\nKurve bis −1250 °C\n(korrupt, geclippt)", off$name, off$s5),
           colour = "#e31a1c", size = 3, hjust = 1.05, vjust = 1) +
  scale_x_log10() +
  scale_colour_manual(values = c(gesund = "#1f78b4", korrupt = "#e31a1c"), name = NULL) +
  coord_cartesian(ylim = c(-40, -8)) +
  labs(title = "Koeffizienten-Anomalie vs. lokale Steigung (alle Sensoren)",
       subtitle = "x: wie anomal die Koeffizienten sind (rob. z) | Band = normaler Steigungsbereich",
       x = "Koeffizienten-Anomalie  max|z|  (log)", y = "Steigung bei −5 °C (mK / 1000 counts)") +
  theme_bw(base_size = 12) +
  theme(legend.position = "inside", legend.position.inside = c(0.16, 0.22),
        legend.background = element_rect(fill = "white", colour = "grey80"))

fig <- p_left + p_right + plot_layout(widths = c(1, 1)) +
  plot_annotation(caption = sprintf(
    "%d Sensoren | %d mit anomalen Koeffizienten (z>3) sind gesund, nur %d korrupt",
    nrow(co), sum(co$zmax > 3 & !co$corrupt), sum(co$corrupt)))

ggsave("local_slope_anomalous.png", fig, width = 13.5, height = 5.6, dpi = 130)
cat("Saved:", normalizePath("local_slope_anomalous.png"), "\n")
cat(sprintf("anomalous (z>3) but healthy: %d | corrupt: %s\n",
            sum(co$zmax > 3 & !co$corrupt), paste(co$name[co$corrupt], collapse = ", ")))
