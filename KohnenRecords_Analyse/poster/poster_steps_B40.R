# Poster: Schritt für Schritt von den Rohdaten zu T ~ dp/dt (B40, head04, Tagesprofile).
# Aufruf aus KohnenRecords_Analyse/:  Rscript poster/poster_steps_B40.R
suppressMessages({library(dplyr); library(tidyr); library(ggplot2); library(patchwork)})
BLUE <- "#2a78d6"; ORANGE <- "#eb6834"; GREY <- "grey55"
th <- theme_bw(base_size = 10) + theme(panel.grid.minor = element_blank())
source("pressure_correction.R", local = TRUE)

t4 <- h4$t[ok4]; td <- (as.numeric(t4) - as.numeric(t4[1])) / 86400
p4 <- approx(t3, p3, as.numeric(t4))$y; dp <- h4$dpdt[ok4]
rp <- p4 - predict(loess(p4 ~ td, span = 0.2))
col <- function(z) which(round(dep4) == z)
Z <- c(26, 134)

# a: Druck roh
ga <- ggplot(data.frame(t = t4, p = p4), aes(t, p)) + geom_line(colour = GREY, linewidth = 0.4) +
  labs(x = NULL, y = "p (hPa)", title = "1  Raw data: surface pressure (B50) ...") + th
# b: Temperatur roh bei 26 m mit Trend
y26 <- k4$y[, col(26)]
gb <- ggplot(data.frame(t = t4, T = y26 / 1000, tr = (y26 - k4$r[, col(26)]) / 1000), aes(t)) +
  geom_line(aes(y = T), linewidth = 0.4) + geom_line(aes(y = tr), colour = ORANGE, linewidth = 0.6) +
  labs(x = NULL, y = "T at 26 m (°C)", title = "... and temperature in the open hole, B40 (orange: trend)") + th

# c: Ausschnitt, gefiltert, beide Erklärungen in mK
win <- t4 >= as.POSIXct("2026-05-25", tz = "UTC") & t4 < as.POSIXct("2026-07-20", tz = "UTC")
r26 <- k4$r[, col(26)]
fp <- fitted(lm(r26 ~ rp)); fd <- fitted(lm(r26 ~ dp))
cd <- data.frame(t = t4, measured = r26, `fit from p` = fp, `fit from dp/dt` = fd, check.names = FALSE)[win, ] |>
  pivot_longer(-t) |> mutate(name = factor(name, c("measured", "fit from p", "fit from dp/dt")))
gc <- ggplot(cd, aes(t, value, colour = name, linewidth = name)) + geom_line() +
  scale_colour_manual(values = c(measured = "black", `fit from p` = GREY, `fit from dp/dt` = BLUE), name = NULL) +
  scale_linewidth_manual(values = c(0.5, 0.6, 0.6), guide = "none") +
  labs(x = NULL, y = "T − trend (mK)", title = "2  Detrended, 26 m: temperature follows dp/dt, not p") +
  th + theme(legend.position = "top", legend.margin = margin(0, 0, -6, 0))

# d: Streudiagramme
sc <- bind_rows(lapply(Z, function(z) { r <- k4$r[, col(z)]
  bind_rows(data.frame(z = z, x = rp, y = r, reg = "against p (hPa)"),
            data.frame(z = z, x = dp, y = r, reg = "against dp/dt (hPa/day)")) })) |>
  mutate(zl = factor(sprintf("%d m", z), sprintf("%d m", Z)),
         reg = factor(reg, c("against p (hPa)", "against dp/dt (hPa/day)")))
r2 <- sc |> group_by(zl, reg) |> summarise(r2 = summary(lm(y ~ x))$r.squared, .groups = "drop") |>
  mutate(lab = sprintf("R² = %.2f", r2))
gd <- ggplot(sc, aes(x, y)) + geom_point(size = 0.6, alpha = 0.6) +
  geom_smooth(method = "lm", se = FALSE, colour = BLUE, linewidth = 0.6) +
  geom_text(data = r2, aes(x = -Inf, y = Inf, label = lab), hjust = -0.1, vjust = 1.4, size = 3) +
  facet_grid(zl ~ reg, scales = "free") +
  labs(x = NULL, y = "T − trend (mK)", title = "3  All 180 days, 26 m and 134 m") + th

fig <- (ga / gb / gc + plot_layout(heights = c(1, 1, 1.4))) | gd
fig <- fig + plot_layout(widths = c(1.35, 1))
ggsave("poster/fig_poster_steps_B40.pdf", fig, width = 24, height = 13, units = "cm", device = cairo_pdf)
ggsave("poster/fig_poster_steps_B40.png", fig, width = 24, height = 13, units = "cm", dpi = 300)
print(r2)
