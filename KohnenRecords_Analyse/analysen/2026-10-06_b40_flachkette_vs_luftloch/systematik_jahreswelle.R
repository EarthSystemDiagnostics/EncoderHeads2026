suppressPackageStartupMessages({library(dplyr); library(readr); library(tidyr)})
setwd("/Users/tlaepple/data/EncoderHeads2026"); options(width=220)
h4 <- read_csv("KohnenRecords_Analyse/data/decoded_head04_231710_combined.csv", show_col_types=FALSE) |>
  mutate(time_utc=as.POSIXct(time_utc,tz="UTC")) |> arrange(time_utc)
dm <- bind_rows(tibble(node=1:8, depth=c(1,2,5,8,10,13,16,21), chain="Luft"),
                tibble(node=21:25, depth=c(1,1.4,1.9,2.9,5.9), chain="Schnee"))
L <- h4 |> select(time_utc, matches("^n\\d+\\.ntc[12]_temp_C$")) |>
  pivot_longer(-time_utc, names_to=c("node","ch"), names_pattern="n(\\d+)\\.(ntc[12])_temp_C") |>
  mutate(node=as.integer(node)) |> pivot_wider(names_from=ch, values_from=value) |>
  inner_join(dm, by="node") |> mutate(T=(ntc1+ntc2)/2, doy=as.numeric(format(time_utc,"%j")) + as.numeric(format(time_utc,"%H"))/24)

## 1) Monatsmittel der Differenz Luft - Schnee fuer die Tiefenpaare
pairs <- tribble(~a,~s,~lab, 1L,21L,"1 m / 1 m", 2L,23L,"2 m / 1,9 m", 3L,25L,"5 m / 5,9 m")
cat("Monatsmittel Luft - Schnee (K):\n")
mm <- bind_rows(lapply(seq_len(nrow(pairs)), function(i) {
  inner_join(L |> filter(node==pairs$a[i]) |> select(time_utc, Ta=T), L |> filter(node==pairs$s[i]) |> select(time_utc, Ts=T), by="time_utc") |>
    mutate(Monat=format(time_utc,"%m")) |> group_by(Monat) |> summarise(d=round(mean(Ta-Ts),2), .groups="drop") |> mutate(Paar=pairs$lab[i]) }))
print(as.data.frame(mm |> pivot_wider(names_from=Monat, values_from=d)), row.names=FALSE)

## 2) Jahreswelle: T = m + A cos(w t) + B sin(w t), Periode 365.25 d  -> Amplitude, Tag des Maximums
w <- 2*pi/365.25
fit <- L |> filter(depth<=16) |> group_by(chain, node, depth) |> group_modify(function(d, k) {
  t <- as.numeric(difftime(d$time_utc, as.POSIXct("2026-01-01",tz="UTC"), units="days"))
  m <- lm(T ~ cos(w*t) + sin(w*t), data=d)
  cf <- coef(m); A <- sqrt(cf[2]^2+cf[3]^2); ph <- atan2(cf[3], cf[2])  # max bei w t = ph
  dmax <- (ph/w) %% 365.25
  V <- vcov(m); g <- c(0, cf[2]/A, cf[3]/A); seA <- sqrt(t(g)%*%V%*%g)
  tibble(mean=cf[1], A=A, seA=as.numeric(seA), tmax=dmax, resid=sd(resid(m))*1000, range=diff(range(d$T)))
}) |> ungroup() |> mutate(tmax = ifelse(tmax > 330 & depth < 1.5, tmax - 365.25, tmax))
cat("\nJahreswellen-Fit (Periode 365,25 d, Record 18.01.-13.08.): Mittel, Amplitude A (K) +- se, Tag des Maximums (DOY), Residuum (mK):\n")
print(as.data.frame(fit |> mutate(across(c(mean,A,seA,range), ~round(.,3)), tmax=round(tmax), resid=round(resid)) |> arrange(depth, chain)), row.names=FALSE)

## 3) Leitungsgerade: ln A gegen Phase (Tag des Maximums). Steigung in reiner Leitung: d lnA / d tmax = -w (= -0.0172 /Tag)
sn <- fit |> filter(chain=="Schnee")
lf <- lm(log(A) ~ tmax, data=sn)
cat(sprintf("\nSchneekette: Steigung ln A gegen tmax = %.4f /Tag (Leitung: %.4f); R2 = %.3f\n", coef(lf)[2], -w, summary(lf)$r.squared))
## Daempfungstiefe aus Schneekette ueber Tiefe
la <- lm(log(A) ~ depth, data=sn); lp <- lm(tmax ~ depth, data=sn)
cat(sprintf("Schneekette: Daempfungstiefe aus Amplitude %.2f m, aus Phase %.2f m (Phase: %.1f Tage/m)\n", -1/coef(la)[2], 1/(w*coef(lp)[2]), coef(lp)[2]))
## Jeden Luftknoten auf die Schnee-Gerade projizieren: aus tmax -> erwartetes ln A ; aus A -> erwartete tmax
fit <- fit |> mutate(A_erw_aus_phase = exp(predict(lf, newdata=data.frame(tmax=tmax))),
                     tmax_erw_aus_A  = (log(A)-coef(lf)[1])/coef(lf)[2],
                     tiefe_aus_A     = (log(A)-coef(la)[1])/coef(la)[2],
                     tiefe_aus_phase = (tmax-coef(lp)[1])/coef(lp)[2])
cat("\nLage relativ zur Schnee-Leitungsgeraden: A/A_erw (1 = auf der Geraden), Phasenabweichung (Tage; negativ = frueher als Leitung), scheinbare Tiefe aus A bzw. Phase (m):\n")
print(as.data.frame(fit |> transmute(chain, depth, A=round(A,3), `A/A_erw`=round(A/A_erw_aus_phase,2), dPhase_d=round(tmax-tmax_erw_aus_A), z_aus_A=round(tiefe_aus_A,1), z_aus_Phase=round(tiefe_aus_phase,1), mean=round(mean,3)) |> arrange(depth, chain)), row.names=FALSE)
