suppressPackageStartupMessages({library(dplyr); library(readr); library(tidyr)})
setwd("/Users/tlaepple/data/EncoderHeads2026"); options(width=220)
h4 <- read_csv("KohnenRecords_Analyse/data/decoded_head04_231710_combined.csv", show_col_types=FALSE) |> mutate(time_utc=as.POSIXct(time_utc,tz="UTC"))
T <- function(n) (h4[[sprintf("n%d.ntc1_temp_C",n)]]+h4[[sprintf("n%d.ntc2_temp_C",n)]])/2
d <- tibble(M=format(h4$time_utc,"%m"), S1_S14=T(21)-T(22), S14_S19=T(22)-T(23), S29_S59=T(24)-T(25), L1_S1=T(1)-T(21), L5_S59=T(3)-T(25))
cat("B40 Monatsmittel (K): Gradientenpaare der Schneekette und Luft-Schnee-Differenzen\n")
print(as.data.frame(d |> group_by(M) |> summarise(across(everything(), ~round(mean(.),2)))), row.names=FALSE)
g <- read_csv("Greenland2026/data/chain_series_imei301434062008130_20260928_151317.csv", show_col_types=FALSE) |>
  mutate(time_utc=as.POSIXct(time,tz="UTC")) |> filter(time_utc>=as.POSIXct("2026-07-29",tz="UTC"), is.finite(ntc_C)) |>
  select(time_utc, chain, depth_m, ntc_C) |> pivot_wider(names_from=chain, values_from=ntc_C) |>
  mutate(d=`Kette 1`-`Kette 2`, M=format(time_utc,"%m"))
cat("\nGRIP Luft - Schnee gleiche Tiefe (K), Monatsmittel ab 29.07. und sd der Tagesdifferenz:\n")
print(as.data.frame(g |> group_by(depth_m, M) |> summarise(d=round(mean(d),3), .groups="drop") |> pivot_wider(names_from=M, values_from=d) |>
  left_join(g |> group_by(depth_m) |> summarise(sd=round(sd(d),3), gesamt=round(mean(d),3)), by="depth_m")), row.names=FALSE)
