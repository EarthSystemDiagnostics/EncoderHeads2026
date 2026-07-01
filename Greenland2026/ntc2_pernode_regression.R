# Per-node regression: NTC2 vs. mean(NTC1, NTC3) over the 10-message time series.
#   calibrated:   ntc2_temp    ~ mean(ntc1_temp,   ntc3_temp)
#   uncalibrated: ntc2_counts  ~ mean(ntc1_counts, ntc3_counts)
# Slope > 1  =>  NTC2 swings more than its neighbours (the ~2% amplitude excess).
# 24 nodes -> 24 slopes; we look at how robust/consistent they are.

suppressMessages({library(dplyr); library(tidyr); library(ggplot2); library(patchwork)})

f <- sort(Sys.glob("data/series_imei300434065508020_*.csv"))
s <- read.csv(f[length(f)])
s$sensor <- sub("_C$", "", s$sensor)          # ntc1, ntc2, testSB
n_msg <- length(unique(s$time))

# wide per (node, time): one column per sensor, for temp and for counts
wide <- s |>
  pivot_wider(id_cols = c(node, time), names_from = sensor,
              values_from = c(temp_C, counts))

fit_node <- function(d, yv, x1, x2) {
  x <- (d[[x1]] + d[[x2]]) / 2; y <- d[[yv]]
  ok <- is.finite(x) & is.finite(y)
  if (sum(ok) < 3L) return(NULL)
  m <- lm(y[ok] ~ x[ok]); cf <- summary(m)$coefficients
  data.frame(n = sum(ok), intercept = cf[1,1], slope = cf[2,1],
             slope_se = cf[2,2], r2 = summary(m)$r.squared)
}
regress <- function(yv, x1, x2, space) {
  do.call(rbind, lapply(sort(unique(wide$node)), function(nd) {
    r <- fit_node(filter(wide, node == nd), yv, x1, x2)
    if (is.null(r)) NULL else cbind(node = nd, space = space, r)
  }))
}
reg_T <- regress("temp_C_ntc2", "temp_C_ntc1", "temp_C_testSB", "kalibriert (T~T)")
reg_C <- regress("counts_ntc2", "counts_ntc1", "counts_testSB", "roh (counts~counts)")
reg   <- rbind(reg_T, reg_C)

# --- summary -----------------------------------------------------------------
summ <- reg |> group_by(space) |>
  summarise(nodes = n(),
            `slope mean` = mean(slope), `slope sd` = sd(slope),
            `slope median` = median(slope),
            `n>1` = sum(slope > 1), `mean SE` = mean(slope_se),
            `mean R2` = mean(r2),
            `p(slope=1)` = t.test(slope, mu = 1)$p.value, .groups = "drop")
cat(sprintf("Time series: %d messages\n\n", n_msg)); print(as.data.frame(summ), digits = 4)
cat(sprintf("\nCorrelation slope(T) vs slope(counts) across nodes: %.3f\n",
            cor(reg_T$slope[order(reg_T$node)], reg_C$slope[order(reg_C$node)],
                use = "complete.obs")))

sp_pal <- c(`kalibriert (T~T)` = "#c0392b", `roh (counts~counts)` = "#2980b9")

# --- panel A: per-node slope with 95% CI -------------------------------------
pA <- ggplot(reg, aes(node, slope, colour = space)) +
  geom_hline(yintercept = 1, colour = "grey40") +
  geom_errorbar(aes(ymin = slope - 1.96*slope_se, ymax = slope + 1.96*slope_se),
                width = 0, position = position_dodge(0.5), alpha = 0.6) +
  geom_point(size = 1.8, position = position_dodge(0.5)) +
  scale_colour_manual(values = sp_pal, name = NULL) +
  labs(title = "Per-Node-Steigung NTC2 ~ Mittel(NTC1,NTC3)",
       subtitle = sprintf("24 Regressionen je Raum, %d Punkte je Node | Linie = 1 (kein Mehr-Gang)", n_msg),
       x = "Node", y = "Steigung (NTC2 pro Einheit Nachbarmittel)") +
  theme_bw(base_size = 12) +
  theme(legend.position = "inside", legend.position.inside = c(0.5, 0.12),
        legend.direction = "horizontal",
        legend.background = element_rect(fill = "white", colour = "grey80"))

# --- panel B: distribution of the 24 slopes ----------------------------------
pB <- ggplot(reg, aes(space, slope, colour = space, fill = space)) +
  geom_hline(yintercept = 1, colour = "grey40") +
  geom_boxplot(width = 0.4, alpha = 0.18, outlier.shape = NA) +
  geom_jitter(width = 0.08, size = 1.6, alpha = 0.7) +
  stat_summary(fun = mean, geom = "point", shape = 23, size = 3, fill = "white") +
  scale_colour_manual(values = sp_pal, guide = "none", aesthetics = c("colour","fill")) +
  labs(title = "Verteilung der 24 Steigungen",
       subtitle = "weiße Raute = Mittel | Boxplot + einzelne Nodes",
       x = NULL, y = "Steigung") +
  theme_bw(base_size = 12)

fig <- pA + pB + plot_layout(widths = c(1.6, 1)) +
  plot_annotation(caption = sprintf(
    "Steigung > 1 => NTC2 reagiert stärker als das Mittel der Nachbarn. Mittel: T %.4f, counts %.4f.",
    summ$`slope mean`[summ$space=="kalibriert (T~T)"], summ$`slope mean`[grepl("roh", summ$space)]))
ggsave("ntc2_pernode_regression.png", fig, width = 13, height = 5.4, dpi = 130)
cat("\nSaved ntc2_pernode_regression.png\n")

# per-node table
reg |> transmute(node, space, slope = round(slope, 4), `±95%` = round(1.96*slope_se, 4),
                 intercept = round(intercept, 3), R2 = round(r2, 5)) |>
  arrange(space, node) |> write.csv("data/ntc2_pernode_regression.csv", row.names = FALSE)
