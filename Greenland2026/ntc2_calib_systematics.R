# Is there a SYSTEMATIC NTC2-vs-NTC1/NTC3 difference anywhere in the calibration?
# Paired within node (removes node-to-node spread), over the whole temp range,
# NTC2-NTC1 and NTC2-NTC3 kept separate. Two physical quantities:
#   slope dT/dcounts (sensitivity)  and  counts level at fixed T (nominal R).

suppressMessages({library(dplyr); library(tidyr); library(ggplot2); library(patchwork)})

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
co <- co[complete.cases(co[, c("a","b","c","d")]), ]

Tc_of    <- function(cf, counts) S4_T_C(NTCcounts2R(counts), cf)
counts_at <- function(cf, T0) { f <- function(cc) Tc_of(cf, cc) - T0
  if (sign(f(4e5)) == sign(f(3.2e6))) return(NA_real_); uniroot(f, c(4e5, 3.2e6), tol = 1)$root }
slope_at <- function(cf, T0) { c0 <- counts_at(cf, T0); if (is.na(c0)) return(NA_real_)
  (Tc_of(cf, c0 + 200) - Tc_of(cf, c0 - 200)) / 400 }
is_mono  <- function(cf) { cc <- seq(7e5, 2.3e6, length.out = 200); all(diff(Tc_of(cf, cc)) < 0) }
co <- co[mapply(function(a,b,c,d) is_mono(c(a,b,c,d)), co$a, co$b, co$c, co$d), ]  # drop corrupt

Tgrid <- c(-25, -20, -15, -10, -5, -2)
slope <- sapply(Tgrid, function(t) mapply(function(a,b,c,d) slope_at(c(a,b,c,d), t)*1e6, co$a,co$b,co$c,co$d))
cnts  <- sapply(Tgrid, function(t) mapply(function(a,b,c,d) counts_at(c(a,b,c,d), t),     co$a,co$b,co$c,co$d))
colnames(slope) <- colnames(cnts) <- as.character(Tgrid)

# paired difference NTC2 - NTCk within node, in % of the mean magnitude --------
paired_pct <- function(M, k) {
  long <- data.frame(uid = paste(co$source, co$node), ntc = co$ntc, M, check.names = FALSE) |>
    pivot_longer(-c(uid, ntc), names_to = "T", values_to = "v") |>
    mutate(T = as.numeric(T)) |>
    pivot_wider(names_from = ntc, values_from = v, names_prefix = "n")
  base <- long |> group_by(T) |> summarise(scale = mean(abs(c(n1, n2, n3)), na.rm = TRUE), .groups = "drop")
  long |> mutate(d = 100 * (n2 - .data[[paste0("n", k)]]) / base$scale[match(T, base$T)]) |>
    filter(is.finite(d)) |>
    group_by(T) |>
    summarise(mean = mean(d), se = sd(d)/sqrt(n()), p = t.test(d)$p.value, .groups = "drop") |>
    mutate(contrast = sprintf("NTC2 − NTC%d", k))
}
df_slope <- bind_rows(paired_pct(slope, 1), paired_pct(slope, 3))
df_cnts  <- bind_rows(paired_pct(cnts,  1), paired_pct(cnts,  3))

stars <- function(p) ifelse(p<.001,"***",ifelse(p<.01,"**",ifelse(p<.05,"*","")))
df_slope$lab <- stars(df_slope$p); df_cnts$lab <- stars(df_cnts$p)
con_pal <- c(`NTC2 − NTC1` = "#1f78b4", `NTC2 − NTC3` = "#33a02c")

mkpanel <- function(d, ttl, ylab) {
  ggplot(d, aes(T, mean, colour = contrast, fill = contrast)) +
    geom_hline(yintercept = 0, colour = "grey50") +
    geom_ribbon(aes(ymin = mean - 1.96*se, ymax = mean + 1.96*se), alpha = 0.18, colour = NA) +
    geom_line(linewidth = 0.8) + geom_point(size = 2) +
    geom_text(aes(label = lab), vjust = -0.6, size = 4, show.legend = FALSE) +
    scale_colour_manual(values = con_pal, name = NULL, aesthetics = c("colour","fill")) +
    labs(title = ttl, x = "Bezugstemperatur (°C)", y = ylab) +
    theme_bw(base_size = 12) +
    theme(legend.position = "inside", legend.position.inside = c(0.80, 0.16),
          legend.background = element_rect(fill = "white", colour = "grey80"))
}

p1 <- mkpanel(df_slope, "Empfindlichkeit dT/dcounts — gepaart je Node",
              "NTC2 − NTCk  (% der Steigung)") +
  annotate("text", x = -25, y = Inf, vjust = 1.4, hjust = 0, size = 3, colour = "grey30",
           label = "Feld-Amplitudeneffekt NTC2: +2.4 %  (≈ 20× größer)")
p2 <- mkpanel(df_cnts, "Counts-Niveau bei fester Temperatur — gepaart je Node",
              "NTC2 − NTCk  (% der Counts)")

fig <- p1 + p2 + plot_layout(widths = c(1,1)) +
  plot_annotation(
    title = "Systematischer NTC2-Unterschied in der Kalibration? — gepaart, ganzer Temperaturbereich",
    subtitle = "NTC2 ≈ NTC1 überall (blau ~ 0). Einzige signifikante, aber winzige (≤0.15 %) Abweichung: NTC2 vs NTC3 bei Kälte.",
    caption = sprintf("%d Sensoren, 48 vollständige Nodes | Stern = p<0.05/0.01/0.001 (gepaarter t-Test)", nrow(co)))

ggsave("ntc2_calib_systematics.png", fig, width = 13.5, height = 5.4, dpi = 130)
cat("Saved ntc2_calib_systematics.png\n")
print(df_slope, digits = 3); print(df_cnts, digits = 3)
