## Abbildungen für B40_Schneekette_vs_Luftloch.md
suppressPackageStartupMessages({library(dplyr); library(readr); library(tidyr); library(ggplot2)})
setwd("/Users/tlaepple/data/EncoderHeads2026")
OUT <- "KohnenRecords_Analyse/analysen/2026-10-06_b40_flachkette_vs_luftloch"
col <- c(Luft = "#B2182B", Schnee = "#2166AC")
th  <- theme_bw(base_size = 12) + theme(legend.position = "bottom", panel.grid.minor = element_blank())

## ---- Daten B40 ----
h4 <- read_csv("KohnenRecords_Analyse/data/decoded_head04_231710_combined.csv", show_col_types = FALSE) |>
  mutate(time_utc = as.POSIXct(time_utc, tz = "UTC")) |> arrange(time_utc)
dm <- bind_rows(tibble(node = 1:7,   depth = c(1,2,5,8,10,13,16), chain = "Luft"),
                tibble(node = 21:25, depth = c(1,1.4,1.9,2.9,5.9), chain = "Schnee"))
L4 <- h4 |> select(time_utc, matches("^n\\d+\\.ntc[12]_temp_C$")) |>
  pivot_longer(-time_utc, names_to = c("node","ch"), names_pattern = "n(\\d+)\\.(ntc[12])_temp_C") |>
  mutate(node = as.integer(node)) |> pivot_wider(names_from = ch, values_from = value) |>
  inner_join(dm, by = "node") |> mutate(T = (ntc1 + ntc2)/2) |> filter(is.finite(T))

## ---- Daten GRIP ----
g <- read_csv("Greenland2026/data/chain_series_imei301434062008130_20260928_151317.csv", show_col_types = FALSE) |>
  mutate(time_utc = as.POSIXct(time, tz = "UTC"), T = ntc_C, depth = depth_m,
         chain = ifelse(chain == "Kette 1", "Luft", "Schnee"), node = node_nr) |>
  filter(is.finite(T), time_utc >= as.POSIXct("2026-07-29", tz = "UTC"))

stats <- function(L) L |> arrange(chain, node, time_utc) |> group_by(chain, node, depth) |>
  mutate(dt = as.numeric(difftime(time_utc, lag(time_utc), units = "days")), dT = T - lag(T),
         td = as.numeric(difftime(time_utc, min(time_utc), units = "days")),
         res = resid(loess(T ~ td, span = 0.2))) |>
  summarise(sd_Tag = sd(dT[is.finite(dT) & dt > 0.5 & dt < 1.5]) / sqrt(2) * 1000,
            sd_loess = sd(res) * 1000, .groups = "drop")

## ---- Abb. 1: Unruhe gegen Tiefe ----
u <- bind_rows(stats(L4) |> mutate(Ort = "B40 Kohnen, 18.01.–13.08.2026"),
               stats(g)  |> mutate(Ort = "GRIP Doppelkette, 29.07.–28.09.2026")) |>
  pivot_longer(c(sd_Tag, sd_loess), names_to = "Metrik", values_to = "mK") |>
  mutate(Metrik = factor(Metrik, c("sd_Tag","sd_loess"), c("σ_Tag", "σ_loess")))
p1 <- ggplot(u, aes(mK, depth, colour = chain, linetype = Metrik, shape = Metrik)) +
  geom_path(linewidth = 0.5) + geom_point(size = 2) +
  facet_wrap(~Ort) + scale_x_log10(breaks = c(0.1, 1, 10, 100), labels = c("0,1", "1", "10", "100")) +
  scale_y_reverse(breaks = c(1, 2, 3, 5, 8, 10, 13, 16, 21, 26, 30)) +
  scale_colour_manual(values = col, name = NULL) +
  scale_linetype_manual(values = c("solid", "dashed"), name = NULL) +
  scale_shape_manual(values = c(16, 1), name = NULL) +
  labs(x = "Streuung (mK, log)", y = "Tiefe (m)") + th
ggsave(file.path(OUT, "abb1_unruhe_tiefe.png"), p1, width = 8, height = 4.8, dpi = 150)

## ---- Abb. 2: Amplitude gegen Phase der Jahreswelle, B40 ----
w <- 2*pi/365.25
fit <- L4 |> group_by(chain, node, depth) |> group_modify(function(d, k) {
  t <- as.numeric(difftime(d$time_utc, as.POSIXct("2026-01-01", tz = "UTC"), units = "days"))
  m <- lm(T ~ cos(w*t) + sin(w*t), data = d); cf <- coef(m)
  tibble(A = sqrt(cf[2]^2 + cf[3]^2), tmax = (atan2(cf[3], cf[2])/w) %% 365.25)
}) |> ungroup() |> mutate(tmax = ifelse(tmax > 330 & depth < 1.5, tmax - 365.25, tmax))
lf <- lm(log(A) ~ tmax, data = fit |> filter(chain == "Schnee"))
line <- tibble(tmax = seq(-10, 330, 5)) |> mutate(A = exp(predict(lf, newdata = tibble(tmax))))
p2 <- ggplot(fit, aes(tmax, A)) +
  geom_line(data = line, colour = "grey50", linewidth = 0.5) +
  geom_point(aes(colour = chain, shape = chain), size = 2.6) +
  geom_text(aes(label = sub("\\.", ",", paste0(depth, " m")), vjust = ifelse(chain == "Schnee", -0.8, 1.7)), size = 3.2) +
  scale_y_log10(breaks = c(0.03, 0.1, 0.3, 1, 3, 10), labels = c("0,03", "0,1", "0,3", "1", "3", "10")) +
  scale_colour_manual(values = col, name = NULL) + scale_shape_manual(values = c(16, 17), name = NULL) +
  labs(x = "Tag des Maximums der Jahreswelle (Tag im Jahr)", y = "Amplitude (K, log)") + th
ggsave(file.path(OUT, "abb2_amplitude_phase.png"), p2, width = 7.5, height = 5, dpi = 150)

## ---- Abb. 3: Differenz Luft − Schnee ----
pairs <- tribble(~a, ~s, ~lab, 1L, 21L, "B40  1 m / 1 m", 2L, 23L, "B40  2 m / 1,9 m", 3L, 25L, "B40  5 m / 5,9 m")
d4 <- bind_rows(lapply(seq_len(nrow(pairs)), function(i)
  inner_join(L4 |> filter(node == pairs$a[i]) |> select(time_utc, Ta = T),
             L4 |> filter(node == pairs$s[i]) |> select(time_utc, Ts = T), by = "time_utc") |>
    transmute(time_utc, d = Ta - Ts, Paar = pairs$lab[i])))
dg <- g |> select(time_utc, chain, depth, T) |> pivot_wider(names_from = chain, values_from = T) |>
  filter(depth %in% c(1, 3, 5, 8, 16)) |> transmute(time_utc, d = Luft - Schnee, Paar = sprintf("GRIP  %g m / %g m", depth, depth))
dd <- bind_rows(d4, dg) |> mutate(Ort = ifelse(grepl("B40", Paar), "B40 Kohnen", "GRIP"))
p3 <- ggplot(dd, aes(time_utc, d, colour = Paar)) + geom_hline(yintercept = 0, colour = "grey60") +
  geom_line(linewidth = 0.5) + facet_wrap(~Ort, scales = "free_x") +
  scale_x_datetime(labels = function(x) { m <- c("Jan","Feb","Mär","Apr","Mai","Jun","Jul","Aug","Sep","Okt","Nov","Dez"); paste0(format(x, "%d. "), m[as.integer(format(x, "%m"))]) }) +
  scale_colour_brewer(palette = "Dark2", name = NULL) +
  labs(x = NULL, y = "Luft − Schnee (K)") + th + guides(colour = guide_legend(nrow = 3))
ggsave(file.path(OUT, "abb3_differenz_luft_schnee.png"), p3, width = 9, height = 4.8, dpi = 150)
cat("ok\n")
