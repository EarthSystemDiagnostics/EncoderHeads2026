# Illustration: DIFFERENT coefficient sets -> SIMILAR local slope at a point.
#
# We take 5 sensors with visibly different counts->T curves (different a,b,c,d)
# and draw the tangent (local slope dT/dcounts) at one working point (-5 degC).
# Left  : the 5 full curves over a wide T range + their tangents at -5 degC.
# Right : zoom around -5 degC -> the tangents are near-parallel (similar slope)
#         although the underlying coefficients differ.

suppressMessages({library(dplyr); library(ggplot2); library(patchwork)})

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

# keep only well-behaved sensors over the range
co$s5    <- mapply(function(a,b,c,d) slope_at(c(a,b,c,d), -5), co$a, co$b, co$c, co$d)
co$cnt5  <- mapply(function(a,b,c,d) counts_at(c(a,b,c,d), -5), co$a, co$b, co$c, co$d)
co <- co[is.finite(co$s5) & co$s5 < 0 & abs(co$s5) < 1e-3 &
         is.finite(co$cnt5) & co$cnt5 > 7e5 & co$cnt5 < 1.6e6, ]

# Pick 5 sensors with DIFFERENT coefficients: spread across counts@-5C (= curve
# is horizontally shifted -> genuinely different a,b,c,d), evenly in quantiles.
ord  <- order(co$cnt5)
sel  <- ord[round(seq(1, length(ord), length.out = 5))]
co5  <- co[sel, ]
co5$name <- sprintf("N%d_NTC%d (%s)", co5$node, co5$ntc, co5$source)
co5$name <- factor(co5$name, levels = co5$name)
pal  <- setNames(c("#1f78b4", "#e31a1c", "#33a02c", "#ff7f00", "#6a3d9a"), levels(co5$name))

T0 <- -5                                        # working point of interest

# full curves -----------------------------------------------------------------
curve_df <- do.call(rbind, lapply(seq_len(nrow(co5)), function(i) {
  cf <- as.numeric(co5[i, c("a","b","c","d")])
  cc <- seq(counts_at(cf, 5), counts_at(cf, -28), length.out = 300)
  data.frame(name = co5$name[i], counts = cc, T = Tc_of(cf, cc))
}))
# tangents + points at T0 ------------------------------------------------------
tan_df <- do.call(rbind, lapply(seq_len(nrow(co5)), function(i) {
  cf <- as.numeric(co5[i, c("a","b","c","d")]); c0 <- counts_at(cf, T0); m <- slope_at(cf, T0)
  cc <- c0 + c(-2.0e5, 2.0e5)
  data.frame(name = co5$name[i], counts = cc, T = T0 + m * (cc - c0))
}))
pt_df <- do.call(rbind, lapply(seq_len(nrow(co5)), function(i) {
  cf <- as.numeric(co5[i, c("a","b","c","d")])
  data.frame(name = co5$name[i], counts = counts_at(cf, T0), T = T0,
             slope = slope_at(cf, T0))
}))
pt_df$mK <- pt_df$slope * 1e6

# coefficient + slope table to console
tab <- transform(co5[, c("name","a","b","c","d")],
                 `mK_per_kcount@-5C` = round(co5$s5 * 1e6, 1))
print(tab, row.names = FALSE)
cat(sprintf("\nslope@-5C: mean %.1f, range [%.1f, %.1f] mK/1000counts (spread %.1f)\n",
            mean(pt_df$mK), min(pt_df$mK), max(pt_df$mK), diff(range(pt_df$mK))))

# LEFT: full curves + tangents ------------------------------------------------
p_left <- ggplot() +
  geom_line(data = curve_df, aes(counts/1000, T, colour = name), linewidth = 0.7) +
  geom_line(data = tan_df, aes(counts/1000, T, group = name), colour = "black",
            linewidth = 0.9, linetype = "solid") +
  geom_point(data = pt_df, aes(counts/1000, T), colour = "black", size = 2) +
  annotate("text", x = Inf, y = Inf, label = sprintf("Tangente bei %g °C", T0),
           hjust = 1.05, vjust = 1.6, size = 3.6) +
  scale_colour_manual(values = pal, name = "Sensor (a,b,c,d)") +
  labs(title = "5 Kalibrationen — volle Kurve + lokale Steigung",
       subtitle = "unterschiedliche Koeffizienten → unterschiedlich verschobene Kurven",
       x = "Rohwert (1000 counts)", y = "Temperatur (°C)") +
  theme_bw(base_size = 12) +
  theme(legend.position = "inside", legend.position.inside = c(0.72, 0.82),
        legend.background = element_rect(fill = "white", colour = "grey80"),
        legend.text = element_text(size = 8), legend.title = element_text(size = 9),
        legend.key.height = unit(10, "pt"))

# RIGHT: zoom around T0 — overlay each curve on its own working point ----------
# Shift every curve so its -5 degC point sits at counts = 0: then the near-equal
# slopes show up as near-parallel/overlapping lines around the common origin.
zoom_w <- 1.5e5
zoom_df <- do.call(rbind, lapply(seq_len(nrow(co5)), function(i) {
  cf <- as.numeric(co5[i, c("a","b","c","d")]); c0 <- counts_at(cf, T0)
  cc <- seq(c0 - zoom_w, c0 + zoom_w, length.out = 120)
  data.frame(name = co5$name[i], dcounts = cc - c0, T = Tc_of(cf, cc))
}))
zlab <- pt_df |> mutate(lab = sprintf("%.0f mK/kcount", mK))

p_right <- ggplot(zoom_df, aes(dcounts/1000, T, colour = name)) +
  geom_vline(xintercept = 0, linetype = "dotted", colour = "grey60") +
  geom_hline(yintercept = T0, linetype = "dotted", colour = "grey60") +
  geom_line(linewidth = 0.9) +
  geom_point(data = data.frame(dcounts = 0, T = T0), aes(dcounts, T),
             inherit.aes = FALSE, size = 2) +
  scale_colour_manual(values = pal, guide = "none") +
  labs(title = sprintf("Zoom um %g °C — gemeinsamer Arbeitspunkt", T0),
       subtitle = sprintf("Steigungen %.0f … %.0f mK/1000 counts (≈ parallel)",
                          min(pt_df$mK), max(pt_df$mK)),
       x = "Rohwert − Arbeitspunkt (1000 counts)", y = "Temperatur (°C)") +
  theme_bw(base_size = 12)

fig <- p_left + p_right + plot_layout(widths = c(1.05, 1)) +
  plot_annotation(caption = "4-Parameter Steinhart-Hart | schwarze Linie/Punkt = lokale Linearisierung")

ggsave("local_slope_multi.png", fig, width = 13, height = 5.4, dpi = 130)
cat("\nSaved:", normalizePath("local_slope_multi.png"), "\n")
