# Poster-Box „Temperaturschwankungen in offenen Bohrlöchern“: zwei Abbildungen.
# Aufruf aus KohnenRecords_Analyse/:  Rscript poster/poster_box_figures.R
suppressMessages({library(dplyr); library(tidyr); library(ggplot2); library(patchwork)})
BLUE <- "#2a78d6"; ORANGE <- "#eb6834"; GREY <- "grey55"
th <- theme_bw(base_size = 11) + theme(panel.grid.minor = element_blank(), legend.position = "top",
                                       legend.margin = margin(0, 0, -4, 0))

## Fig. 1: B46, 95-s-Daten, offenes 60-m-Loch ---------------------------------
d46 <- read.csv("/Users/tlaepple/Nextcloud/KohnenRecords2526/2026_01_05/260105_B46/calibrated/CalibratedData_B46_2chains_260105.csv")
d46$t <- as.POSIXct(d46$DateTime, tz = "UTC"); ts <- as.numeric(d46$t - d46$t[1], units = "secs")
hp <- function(x, tau) { y <- numeric(length(x)); lp <- x[1]
  for (i in seq_along(x)) { if (i > 1) lp <- lp + (1 - exp(-(ts[i] - ts[i-1]) / tau)) * (x[i] - lp); y[i] <- x[i] - lp }; y }
dm <- read.csv("data/head02_depths.csv"); dm60 <- dm[dm$chain == "60m-Kette", ]
tr <- poly(ts, 3); TAU <- 780
fitz <- function(z) { n <- dm60$node[dm60$depth_m == z]
  T <- d46[[paste0(n, "_NTC1")]] * 1000; p <- d46[[paste0(n, "_Pressure")]] / 1000; h <- hp(p, TAU)
  f <- lm(T ~ tr + h); list(obs = T - (fitted(f) - coef(f)["h"] * h), mod = coef(f)["h"] * h, p = p, G = coef(f)["h"]) }
f21 <- fitz(21)
win <- d46$t >= as.POSIXct("2026-01-03 12:00", tz = "UTC") & d46$t < as.POSIXct("2026-01-04 06:00", tz = "UTC")
za <- data.frame(t = d46$t, measured = f21$obs, model = f21$mod)[win, ] |> pivot_longer(-t)
pa <- data.frame(t = d46$t, p = (f21$p - mean(f21$p[win])) * 100)[win, ]
g_a1 <- ggplot(pa, aes(t, p)) + geom_line(colour = GREY, linewidth = 0.5) +
  scale_y_continuous(breaks = c(-100, 0)) + labs(x = NULL, y = "p (Pa)") + th + theme(axis.text.x = element_blank())
g_a2 <- ggplot(za, aes(t, value, colour = name)) + geom_line(linewidth = 0.5) +
  scale_colour_manual(values = c(measured = "black", model = BLUE),
                      labels = c(measured = "T at 21 m, open hole", model = "model G·(p − p̄), τ = 13 min"), name = NULL) +
  scale_x_datetime(date_labels = "%H:%M") +
  labs(x = "3–4 Jan 2026 (UTC)", y = "T (mK)") + th + theme(legend.position = "bottom", legend.margin = margin(-4, 0, 0, 0))
# Übertragungsfunktion
dtg <- 95; tg <- seq(0, max(ts), by = dtg); ip <- function(y) approx(ts, y, tg)$y
edges <- exp(seq(log(0.3), log(12), length.out = 10))   # bis 12 h: 3 Tage Daten
sp <- bind_rows(lapply(which(dm60$depth_m >= 16), function(i) { n <- dm60$node[i]
  X <- cbind(ip(d46[[paste0(n, "_Pressure")]] / 1000), ip(d46[[paste0(n, "_NTC1")]] * 1000))
  X <- apply(X, 2, function(x) resid(lm(x ~ poly(tg, 3))))
  s <- spec.pgram(ts(X, deltat = dtg / 3600), taper = 0.1, plot = FALSE)
  bind_rows(lapply(seq_len(length(edges) - 1), function(k) {
    j <- which(1 / s$freq > edges[k] & 1 / s$freq <= edges[k + 1]); if (length(j) < 2) return(NULL)
    Sxy <- sum(sqrt(s$coh[j] * s$spec[j, 1] * s$spec[j, 2]) * exp(1i * s$phase[j]))
    data.frame(z = dm60$depth_m[i], per = sqrt(edges[k] * edges[k + 1]),
               coh = Mod(Sxy)^2 / (sum(s$spec[j, 1]) * sum(s$spec[j, 2])), phase = Arg(Conj(Sxy)) * 180 / pi) })) })) |>
  filter(coh > 0.5)
pm <- data.frame(per = exp(seq(log(0.3), log(12), length.out = 200))) |>
  mutate(phase = atan(1 / (2 * pi / (per * 60) * 13)) * 180 / pi)
g_b <- ggplot(sp, aes(per, phase)) + geom_line(data = pm, colour = BLUE, linewidth = 0.8) +
  geom_point(aes(fill = z), shape = 21, size = 2.2, colour = "white", stroke = 0.3) +
  annotate("text", x = 11, y = 99, label = "T ~ dp/dt", hjust = 1, size = 3.4) +
  annotate("text", x = 0.5, y = 2, label = "T ~ p", hjust = 0, size = 3.4) +
  scale_x_log10(breaks = c(0.5, 2, 8), labels = c("30 min", "2 h", "8 h")) +
  scale_y_continuous(breaks = c(0, 45, 90), limits = c(-8, 100)) +
  scale_fill_viridis_c(name = "depth (m)", end = 0.9) +
  labs(x = "period", y = "phase T vs. p (°)") + th + theme(legend.position = "right")
fig1 <- (g_a1 / g_a2 + plot_layout(heights = c(1, 2.6))) | g_b
fig1 <- fig1 + plot_layout(widths = c(1.5, 1)) + plot_annotation(tag_levels = list(c("a", "", "b")))
ggsave("poster/fig_poster_fast_B46.pdf", fig1, width = 17, height = 7.5, units = "cm", device = cairo_pdf)
ggsave("poster/fig_poster_fast_B46.png", fig1, width = 17, height = 7.5, units = "cm", dpi = 300)

## Fig. 2: B40, Tagesdaten, offenes 200-m-Loch --------------------------------
source("pressure_correction.R", local = TRUE)
pr4 <- colMeans(k4$y - k4$corr, na.rm = TRUE) / 1000; g4 <- splinefun(dep4, pr4, method = "natural")
st <- read.csv("data/pressure_correction_stats.csv") |> filter(grepl("head04", Kopf), z >= 20)
bz <- data.frame(z = dep4, b = k4$b, G = g4(dep4, 1) * 1000) |> filter(z >= 20) |>
  mutate(regime = ifelse(z < 80, "advection (dT/dz < 0)", "compression heat (dT/dz > 0)"))
Tk <- 228.65; pp <- 688; kap <- 0.0206 / (pp * 100 / (287.05 * Tk) * 1004)
b_ax <- 0.2857 * Tk / pp * 0.06^2 / (4 * kap) / 86400 * 1000; b_mn <- b_ax / 2
g_c <- ggplot(bz, aes(b, z)) +
  annotate("rect", ymin = 75, ymax = 92, xmin = 0, xmax = Inf, fill = "grey90") +
  annotate("rect", xmin = b_mn, xmax = b_ax, ymin = 92, ymax = 205, fill = ORANGE, alpha = 0.3) +
  annotate("text", x = b_ax * 1.2, y = 165, label = "adiabatic heating\nof hole air,\nno free parameter",
           hjust = 0, size = 3.1, colour = ORANGE, lineheight = 0.9) +
  annotate("text", x = 1.5, y = 83.5, label = "close-off", size = 3.1, colour = GREY) +
  geom_path(colour = "grey40") + geom_point(aes(shape = regime), size = 2.2) +
  scale_shape_manual(values = c(16, 17), name = NULL) +
  scale_x_log10(breaks = c(0.01, 0.1, 1, 10), labels = c("0.01", "0.1", "1", "10")) + scale_y_reverse() +
  labs(x = "b (mK per hPa/day)", y = "depth (m)") + th + theme(legend.position = "bottom", legend.direction = "vertical")
sd_df <- st |> transmute(z, raw = sd_vor, corrected = sd_nach) |> pivot_longer(-z) |>
  mutate(name = factor(name, c("raw", "corrected")))
g_d <- ggplot(sd_df, aes(value, z, colour = name)) +
  annotate("rect", ymin = 75, ymax = 92, xmin = 0, xmax = Inf, fill = "grey90") +
  geom_vline(xintercept = 2.8, linetype = "dotted", colour = "grey40") +
  annotate("text", x = 2.9, y = 130, label = "2.8 mK\ncalibration", hjust = 0, size = 3, lineheight = 0.9) +
  geom_path(linewidth = 0.6) + geom_point(size = 2) +
  scale_colour_manual(values = c(raw = GREY, corrected = BLUE), name = NULL,
                      labels = c(raw = "raw", corrected = "corrected  T − b(z)·F(t)")) +
  scale_x_log10(breaks = c(0.01, 0.1, 1, 10), labels = c("0.01", "0.1", "1", "10")) + scale_y_reverse() +
  labs(x = "day-to-day scatter (mK)", y = NULL) + th + theme(legend.position = "bottom", legend.direction = "vertical")
fig2 <- (g_c | g_d) + plot_annotation(tag_levels = list(c("c", "d")))
ggsave("poster/fig_poster_B40.pdf", fig2, width = 17, height = 9.5, units = "cm", device = cairo_pdf)
ggsave("poster/fig_poster_B40.png", fig2, width = 17, height = 9.5, units = "cm", dpi = 300)
