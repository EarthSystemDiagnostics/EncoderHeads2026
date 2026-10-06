suppressPackageStartupMessages({library(dplyr); library(readr); library(tidyr)})
setwd("/Users/tlaepple/data/EncoderHeads2026")
options(width = 200)

## ---------- B40 / head04 ----------
h4  <- read_csv("KohnenRecords_Analyse/data/decoded_head04_231710_combined.csv", show_col_types = FALSE) |>
  mutate(time_utc = as.POSIXct(time_utc, tz = "UTC")) |> arrange(time_utc)
h4c <- read_csv("KohnenRecords_Analyse/data/head04_231710_pressure_corrected.csv", show_col_types = FALSE) |>
  mutate(time_utc = as.POSIXct(time_utc, tz = "UTC")) |> arrange(time_utc)
cat("head04:", nrow(h4), "Profile", format(min(h4$time_utc)), "bis", format(max(h4$time_utc)), "\n")
dm <- bind_rows(
  tibble(node = 1:7,   depth_m = c(1,2,5,8,10,13,16), chain = "Luft (200-m-Loch)"),
  tibble(node = 21:25, depth_m = c(1,1.4,1.9,2.9,5.9), chain = "Schnee (10-m-Kette)"))

long <- function(x) x |> select(time_utc, matches("^n\\d+\\.ntc[12]_temp_C$")) |>
  pivot_longer(-time_utc, names_to = c("node","ch"), names_pattern = "n(\\d+)\\.(ntc[12])_temp_C") |>
  mutate(node = as.integer(node)) |> pivot_wider(names_from = ch, values_from = value) |>
  inner_join(dm, by = "node") |> mutate(T = (ntc1 + ntc2)/2) |> filter(is.finite(T))

stats <- function(L, label) {
  L |> arrange(chain, node, time_utc) |> group_by(chain, node, depth_m) |>
    mutate(dt = as.numeric(difftime(time_utc, lag(time_utc), units = "days")), dT = T - lag(T),
           td = as.numeric(difftime(time_utc, min(time_utc), units = "days")),
           res = if (n() > 30) resid(loess(T ~ td, span = 0.2)) else NA_real_) |>
    summarise(n = n(), Tmin = min(T), Tmax = max(T), Tmean = mean(T),
              sd_Tag = sd(dT[is.finite(dT) & dt > 0.5 & dt < 1.5]) / sqrt(2) * 1000,
              sd_loess = sd(res, na.rm = TRUE) * 1000,
              sd_repl = sd(ntc1 - ntc2, na.rm = TRUE) / sqrt(2) * 1000, .groups = "drop") |>
    mutate(satz = label)
}
L4  <- long(h4);  L4c <- long(h4c)
s4_all <- stats(L4, "ganzer Record")
s4_cor <- stats(L4c, "druckkorrigiert")
cat("\n== B40 ganzer Record (18.01.-13.08.2026): σ_Tag = sd(ΔT_1d)/√2, σ_loess = Residuum um loess(span .2), Replikat NTC1-NTC2 ==\n")
print(as.data.frame(s4_all |> select(chain, node, depth_m, n, Tmean, Tmin, Tmax, sd_Tag, sd_loess, sd_repl) |>
  mutate(across(c(Tmean,Tmin,Tmax), ~round(.,2)), across(c(sd_Tag,sd_loess,sd_repl), ~round(.,1)))), row.names = FALSE)
cat("\n== B40 druckkorrigiert (b·dp/dt aus B50 abgezogen) ==\n")
print(as.data.frame(s4_cor |> select(chain, node, depth_m, sd_Tag, sd_loess) |> mutate(across(c(sd_Tag,sd_loess), ~round(.,1)))), row.names = FALSE)

## Winterfenster (Polarnacht, kleine Oberflächen-Trends): 01.05.-30.06.
win <- function(L, a, b) L |> filter(time_utc >= as.POSIXct(a, tz="UTC"), time_utc < as.POSIXct(b, tz="UTC"))
s4_win <- stats(win(L4, "2026-05-01", "2026-07-01"), "Mai-Jun")
cat("\n== B40 Fenster 01.05.-30.06.2026 ==\n")
print(as.data.frame(s4_win |> select(chain, node, depth_m, n, Tmean, sd_Tag, sd_loess, sd_repl) |>
  mutate(Tmean = round(Tmean,2), across(c(sd_Tag,sd_loess,sd_repl), ~round(.,1)))), row.names = FALSE)

## Tiefenpaare Luft vs Schnee
pairs <- tribble(~air, ~snow, ~lab, 1L, 21L, "1 m / 1 m", 2L, 23L, "2 m / 1,9 m", 3L, 25L, "5 m / 5,9 m")
cat("\n== B40 Paare Luft/Schnee gleicher Tiefe: Verhältnis σ_Tag, Differenz Luft-Schnee (Mittel, sd), Korrelation der Tagesdifferenzen, Lag (Tage) der max. Kreuzkorrelation der loess-Residuen ==\n")
for (i in seq_len(nrow(pairs))) {
  a <- L4 |> filter(node == pairs$air[i]) |> select(time_utc, Ta = T)
  s <- L4 |> filter(node == pairs$snow[i]) |> select(time_utc, Ts = T)
  j <- inner_join(a, s, by = "time_utc") |> arrange(time_utc) |>
    mutate(td = as.numeric(difftime(time_utc, min(time_utc), units="days")),
           dTa = Ta - lag(Ta), dTs = Ts - lag(Ts))
  sa <- s4_all$sd_Tag[s4_all$node == pairs$air[i]]; ss <- s4_all$sd_Tag[s4_all$node == pairs$snow[i]]
  # Jahresgang-Spanne
  cat(sprintf("%-12s σ_Tag Luft/Schnee %.0f/%.0f mK (Verh. %.1f) | Spanne Luft %.2f K, Schnee %.2f K | Luft−Schnee: Mittel %+.2f K, sd %.2f K | r(ΔT_Tag) = %.2f\n",
      pairs$lab[i], sa, ss, sa/ss, diff(range(j$Ta)), diff(range(j$Ts)), mean(j$Ta - j$Ts), sd(j$Ta - j$Ts),
      cor(j$dTa, j$dTs, use = "complete.obs")))
  # Lag via Kreuzkorrelation der Zeitreihen (nur bei täglicher Lücke < 1,5 d; einfache Näherung)
  cc <- ccf(j$Ta, j$Ts, lag.max = 15, plot = FALSE)
  cat(sprintf("             Kreuzkorr. max r=%.3f bei Lag %d Tage (positiv = Luft eilt voraus); Schnee−Luft über die Zeit: erstes Monat %+.2f K, letztes Monat %+.2f K\n",
      max(cc$acf), cc$lag[which.max(cc$acf)],
      -mean((j$Ta - j$Ts)[j$td <= 30]), -mean((j$Ta - j$Ts)[j$td >= max(j$td) - 30])))
}

## ---------- GRIP Doppelkette ----------
g <- read_csv("Greenland2026/data/chain_series_imei301434062008130_20260928_151317.csv", show_col_types = FALSE) |>
  mutate(time_utc = as.POSIXct(time, tz = "UTC"), T = ntc_C, ntc1 = ntc1_C, ntc2 = ntc2_C) |> filter(is.finite(T)) |>
  mutate(chain = ifelse(chain == "Kette 1", "Luft (GRIP K1)", "Schnee (GRIP K2)"), node = node_nr)
cat("\nGRIP Doppelkette:", length(unique(g$time_utc)), "Profile", format(min(g$time_utc)), "bis", format(max(g$time_utc)), "\n")
sg_30 <- stats(g |> filter(time_utc >= max(time_utc) - 30*86400), "letzte 30 d")
sg_eq <- stats(g |> filter(time_utc >= as.POSIXct("2026-07-29", tz="UTC")), "ab 29.07.")
cat("\n== GRIP letzte 30 Tage ==\n")
print(as.data.frame(sg_30 |> filter(depth_m <= 16) |> select(chain, depth_m, n, Tmean, sd_Tag, sd_loess, sd_repl) |>
  mutate(Tmean = round(Tmean,2), across(c(sd_Tag,sd_loess,sd_repl), ~round(.,1))) |> arrange(depth_m, chain)), row.names = FALSE)
cat("\n== GRIP ab 29.07. (3 Wochen nach Einbau) bis 28.09. ==\n")
print(as.data.frame(sg_eq |> filter(depth_m <= 16) |> select(chain, depth_m, n, Tmean, Tmin, Tmax, sd_Tag, sd_loess) |>
  mutate(across(c(Tmean,Tmin,Tmax), ~round(.,2)), across(c(sd_Tag,sd_loess), ~round(.,1))) |> arrange(depth_m, chain)), row.names = FALSE)

## Verhältnis-Tabelle
rat <- function(s, lab) s |> filter(depth_m <= 16) |> mutate(typ = ifelse(grepl("Luft", chain), "Luft", "Schnee")) |>
  select(depth_m, typ, sd_Tag) |> pivot_wider(names_from = typ, values_from = sd_Tag) |>
  mutate(Verh = Luft/Schnee, satz = lab)
cat("\n== Verhältnis σ_Tag Luft/Schnee ==\n")
print(as.data.frame(bind_rows(rat(sg_30, "GRIP 30 d"), rat(sg_eq, "GRIP ab 29.07.")) |> mutate(across(c(Luft,Schnee,Verh), ~round(.,1)))), row.names = FALSE)
