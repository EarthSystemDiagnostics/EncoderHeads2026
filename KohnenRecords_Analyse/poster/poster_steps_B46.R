# Poster: Schritt für Schritt von den Rohdaten zum Hochpassmodell (B46, offenes 60-m-Loch, 95 s).
# Aufruf aus KohnenRecords_Analyse/:  Rscript poster/poster_steps_B46.R
suppressMessages({library(dplyr); library(tidyr); library(ggplot2); library(patchwork)})
BLUE <- "#2a78d6"; ORANGE <- "#eb6834"; GREY <- "grey55"
th <- theme_bw(base_size = 10) + theme(panel.grid.minor = element_blank())

d46 <- read.csv("/Users/tlaepple/Nextcloud/KohnenRecords2526/2026_01_05/260105_B46/calibrated/CalibratedData_B46_2chains_260105.csv")
d46$t <- as.POSIXct(d46$DateTime, tz = "UTC"); ts <- as.numeric(d46$t - d46$t[1], units = "secs")
dm <- read.csv("data/head02_depths.csv"); dm60 <- dm[dm$chain == "60m-Kette", ]
hp <- function(x, tau) { y <- numeric(length(x)); lp <- x[1]
  for (i in seq_along(x)) { if (i > 1) lp <- lp + (1 - exp(-(ts[i] - ts[i-1]) / tau)) * (x[i] - lp); y[i] <- x[i] - lp }; y }
tr <- poly(ts, 3); detr <- function(v) resid(lm(v ~ tr))
node <- function(z) dm60$node[dm60$depth_m == z]
get <- function(z) { n <- node(z); p <- d46[[paste0(n, "_Pressure")]] / 1000
  ps <- as.numeric(stats::filter(p, rep(1/7, 7), sides = 2)); ps[is.na(ps)] <- p[is.na(ps)]
  list(T = d46[[paste0(n, "_NTC1")]] * 1000, p = p,
       dpdt = c(0, diff(ps) / diff(ts)) * 86400, h = hp(p, 780)) }
Z <- c(21, 62); D <- setNames(lapply(Z, get), Z)

# 1: Rohdaten
x <- D[["21"]]
ga <- ggplot(data.frame(t = d46$t, p = x$p), aes(t, p)) + geom_line(colour = GREY, linewidth = 0.4) +
  labs(x = NULL, y = "p (hPa)", title = "1  Raw data, 95-s sampling: pressure at 21 m ...") + th
gb <- ggplot(data.frame(t = d46$t, T = x$T / 1000, tr = (x$T - detr(x$T)) / 1000), aes(t)) +
  geom_line(aes(y = T), linewidth = 0.3) + geom_line(aes(y = tr), colour = ORANGE, linewidth = 0.6) +
  labs(x = NULL, y = "T at 21 m (°C)", title = "... and temperature in the open hole, B46 (orange: trend)") + th

# 2: Ausschnitt, drei Erklärungen in mK
rT <- detr(x$T); rp <- detr(x$p); rd <- detr(x$dpdt); rh <- detr(x$h)
win <- d46$t >= as.POSIXct("2026-01-03 14:00", tz = "UTC") & d46$t < as.POSIXct("2026-01-04 02:00", tz = "UTC")
cd <- data.frame(t = d46$t, measured = rT, `fit from p` = fitted(lm(rT ~ rp)),
                 `fit from dp/dt` = fitted(lm(rT ~ rd)), `fit from p − p̄ (τ = 13 min)` = fitted(lm(rT ~ rh)),
                 check.names = FALSE)[win, ] |>
  pivot_longer(-t) |> mutate(name = factor(name, c("measured", "fit from p", "fit from dp/dt", "fit from p − p̄ (τ = 13 min)")))
gc <- ggplot(cd, aes(t, value, colour = name)) + geom_line(linewidth = 0.45) +
  scale_colour_manual(values = c("black", GREY, ORANGE, BLUE), name = NULL) +
  scale_x_datetime(date_labels = "%H:%M") +
  labs(x = "3–4 Jan 2026 (UTC)", y = "T − trend (mK)", title = "2  Detrended, 21 m, 12 h") +
  th + theme(legend.position = "top", legend.margin = margin(0, 0, -6, 0)) + guides(colour = guide_legend(nrow = 2, byrow = TRUE))

# 3: Streudiagramme, alle 3 Tage
sc <- bind_rows(lapply(as.character(Z), function(z) { x <- D[[z]]; r <- detr(x$T)
  bind_rows(data.frame(z = z, x = detr(x$p), y = r, reg = "p (hPa)"),
            data.frame(z = z, x = detr(x$dpdt), y = r, reg = "dp/dt (hPa/day)"),
            data.frame(z = z, x = detr(x$h), y = r, reg = "p − p̄, τ = 13 min (hPa)")) })) |>
  mutate(zl = factor(paste(z, "m"), paste(Z, "m")),
         reg = factor(reg, c("p (hPa)", "dp/dt (hPa/day)", "p − p̄, τ = 13 min (hPa)")))
r2 <- sc |> group_by(zl, reg) |> summarise(r2 = cor(x, y)^2, .groups = "drop") |> mutate(lab = sprintf("R² = %.2f", r2))
gd <- ggplot(sc, aes(x, y)) + geom_point(size = 0.25, alpha = 0.3) +
  geom_smooth(method = "lm", se = FALSE, colour = BLUE, linewidth = 0.6) +
  geom_text(data = r2, aes(x = -Inf, y = Inf, label = lab), hjust = -0.1, vjust = 1.4, size = 3) +
  facet_grid(zl ~ reg, scales = "free") +
  labs(x = NULL, y = "T − trend (mK)", title = "3  All 2759 profiles, 21 m and 62 m") + th

fig <- (ga / gb / gc + plot_layout(heights = c(1, 1, 1.5))) | gd
fig <- fig + plot_layout(widths = c(1.15, 1.25))
ggsave("poster/fig_poster_steps_B46.pdf", fig, width = 26, height = 13, units = "cm", device = cairo_pdf)
ggsave("poster/fig_poster_steps_B46.png", fig, width = 26, height = 13, units = "cm", dpi = 300)
print(r2)
