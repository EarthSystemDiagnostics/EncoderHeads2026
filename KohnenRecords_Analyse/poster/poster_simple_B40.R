# Poster: einfachste Darstellung — T′ bei 26 m im offenen Loch B40 gegen dp/dt (eine Zahl gefittet).
# Aufruf aus KohnenRecords_Analyse/:  Rscript poster/poster_simple_B40.R
suppressMessages({library(dplyr); library(tidyr); library(ggplot2); library(patchwork)})
BLUE <- "#2a78d6"; GREY <- "grey55"
th <- theme_bw(base_size = 10) + theme(panel.grid.minor = element_blank(), plot.title = element_text(size = 10))
source("pressure_correction.R", local = TRUE)

t4 <- h4$t[ok4]; dp <- h4$dpdt[ok4]
col <- function(z) which(round(dep4) == z)
Z <- 26; r <- k4$r[, col(Z)]                     # T − Trend (mK), 26 m
f <- lm(r ~ dp); b <- coef(f)[2]; R2 <- summary(f)$r.squared
cat(sprintf("%d m: b = %.2f mK per hPa/day, R2 = %.2f, sd(T') = %.1f mK, sd(residual) = %.1f mK, n = %d\n",
            Z, b, R2, sd(r), sd(resid(f)), length(r)))

win <- t4 >= as.POSIXct("2026-05-25", tz = "UTC") & t4 < as.POSIXct("2026-07-20", tz = "UTC")
g1 <- ggplot(data.frame(t = t4, dp = dp)[win, ], aes(t, dp)) + geom_hline(yintercept = 0, colour = "grey80") +
  geom_line(colour = GREY, linewidth = 0.5) +
  scale_y_continuous(breaks = c(-10, 0, 10)) +
  labs(x = NULL, y = "dp/dt (hPa/day)", title = "Surface pressure change, B50 (a site 1 km from B40)") + th + theme(axis.text.x = element_blank())
d2 <- data.frame(t = t4, measured = r, model = b * dp)[win, ] |> pivot_longer(-t)
g2 <- ggplot(d2, aes(t, value, colour = name)) + geom_hline(yintercept = 0, colour = "grey80") +
  geom_line(linewidth = 0.55) +
  scale_colour_manual(values = c(measured = "black", model = BLUE), name = NULL,
                      labels = c(measured = sprintf("measured, %d m (detrended)", Z), model = "b · dp/dt")) +
  scale_x_datetime(date_labels = "%d %b") +
  labs(x = "2026", y = "T′ (mK)", title = "Temperature in the open hole, B40") +
  th + theme(legend.position = "bottom", legend.margin = margin(-4, 0, 0, 0))
g3 <- ggplot(data.frame(dp = dp, r = r), aes(dp, r)) + geom_point(size = 0.8, alpha = 0.6) +
  geom_abline(intercept = coef(f)[1], slope = b, colour = BLUE, linewidth = 0.8) +
  annotate("text", x = Inf, y = -Inf, hjust = 1.05, vjust = -0.5, size = 3.2,
           label = sprintf("b = %.1f mK per hPa/day\nR² = %.2f, %d days", b, R2, length(r))) +
  labs(x = "dp/dt (hPa/day)", y = "T′ at 26 m (mK)", title = "All days, Jan–Jul 2026") + th
fig <- (g1 / g2 + plot_layout(heights = c(1.15, 2.2))) | g3
fig <- fig + plot_layout(widths = c(1.6, 1)) + plot_annotation(tag_levels = list(c("a", "", "b")))
ggsave("poster/fig_poster_simple_B40.pdf", fig, width = 17, height = 7.5, units = "cm", device = cairo_pdf)
ggsave("poster/fig_poster_simple_B40.png", fig, width = 17, height = 7.5, units = "cm", dpi = 300)
# Nur die linke Seite (Zeitreihen) als eigene Datei
figL <- g1 / g2 + plot_layout(heights = c(1.15, 2.2))
ggsave("poster/fig_poster_simple_B40_left.pdf", figL, width = 11, height = 7.5, units = "cm", device = cairo_pdf)
ggsave("poster/fig_poster_simple_B40_left.png", figL, width = 11, height = 7.5, units = "cm", dpi = 300)
