# Prüfauftrag SnowMelt-Vollantrag (InnoFond), Problemstellung (iii) und AP 4:
# tragen die GRIP- und Dye-3-Daten die Antragszahlen?
#   1  Rauschen der Profilkrümmung, gemessen und mit 1/16-K-Rundung
#   2  Tagesgang im Schnee: Dämpfungstiefe aus Amplitude und Phase, A(50 cm)
#   3  κ je 4-cm-Schicht aus drei Nachbarsensoren, Dichteindex (Sturm 1997)
#   4  Residuum der Wärmeleitungsgleichung, Nachweisgrenze, Ereignisse
#   5  Faktor d_phi/d_A gegen Wind und Einstrahlung (AWS Summit, NASA-SE)
#
# Eingaben: grip_objekte.rds, dye3_objekte.rds (extrahiere.R)
# Aufruf aus diesem Ordner: Rscript waermebilanz.R

suppressMessages({ library(dplyr); library(tidyr); library(ggplot2) })
setwd("/Users/tlaepple/data/EncoderHeads2026/Greenland2026/analysen/2026-11-11_waermebilanz")
om  <- 2*pi/86400
DZ  <- 0.04                      # m
out <- character(0)
say <- function(...) { s <- sprintf(...); out <<- c(out, s); cat(s, "\n") }

# ---------------------------------------------------------------- Daten ------
g <- readRDS("grip_objekte.rds")
d <- readRDS("dye3_objekte.rds")

# GRIP: Oberflächenlage = Verzugs-Schätzer (geglättet) aus dem Report; ab 10.08.
grip <- g$ser_dat |> select(time, ts, hoehe_cm, temp_C, counts) |>
  mutate(day = as.Date(time)) |>
  inner_join(g$surf, by = "day") |>
  filter(day >= as.Date("2026-08-10"))

# Dye-3: Oberfläche aus dem Übergang überhöht -> gedämpft (Tagesverhältnis aus
# dem Report), laufender Median über 5 Tage; eingeschneit ab 31.10.2026.
hu <- function(h, r, hm) { ue <- h[r > 1.05 & h < hm]; if (!length(ue)) return(NA_real_)
  hue <- min(ue); gd <- h[r < 0.95 & h < hue]; if (!length(gd)) return(NA_real_)
  (max(gd) + hue)/2 }
ds <- d$ratio_d |> group_by(day) |> summarise(hs = hu(hoehe_cm, ratio, d$h_ref), .groups = "drop") |>
  filter(day >= as.Date("2026-10-31"), is.finite(hs), hs < 40)
dye_sfc <- tibble(day = seq(as.Date("2026-10-31"), as.Date(max(d$series_long$time)), by = "1 day")) |>
  mutate(h_surf = approx(as.numeric(ds$day), ds$hs, as.numeric(day), rule = 2)$y,
         h_surf = runmed(h_surf, 5, endrule = "median"))
dye <- d$series_long |>
  mutate(hoehe_cm = (node - 1L) * 3L * d$s + d$rank_map[sensor] * d$s,
         ts = as.numeric(time), day = as.Date(time)) |>
  select(time, ts, hoehe_cm, temp_C, counts, day) |>
  inner_join(dye_sfc, by = "day")

prep <- function(x) x |> mutate(z_cm = h_surf - hoehe_cm) |> filter(is.finite(temp_C))
grip <- prep(grip); dye <- prep(dye)
say("Datenstand: GRIP %s – %s, Oberfläche %.1f cm Kettenhöhe am Ende; Dye-3 eingeschneit ab 31.10., Oberfläche %.1f cm am Ende",
    format(min(grip$time), "%d.%m."), format(max(grip$time), "%d.%m.%Y"), tail(g$surf$h_surf, 1), tail(dye_sfc$h_surf, 1))
say("Eingeschneite Sensoren (z >= 2 cm) am Ende: GRIP %s cm; Dye-3 %s cm Kettenhöhe",
    paste(sort(unique(grip$hoehe_cm[grip$day == max(grip$day) & grip$z_cm >= 2])), collapse = ","),
    paste(sort(unique(dye$hoehe_cm[dye$day == max(dye$day) & dye$z_cm >= 2])), collapse = ","))

# Krümmung aus drei Nachbarn (auch ungleiche Abstände: Dye-3 hat bei 8 cm keinen Sensor)
curv3 <- function(T1, T2, T3, h1, h2) 2*((T3 - T2)/h2 - (T2 - T1)/h1)/(h1 + h2)

triplets <- function(x, zmin = 2) {
  # x: ein Standort, breit nach Höhe; Tripel (unten, mitte, oben) mit allen drei z >= zmin
  hs <- sort(unique(x$hoehe_cm))
  tr <- tibble(hl = head(hs, -2), hm = hs[-c(1, length(hs))], hh = tail(hs, -2)) |>
    filter(hh - hl <= 12)
  w <- x |> select(time, ts, day, hoehe_cm, temp_C, h_surf) |>
    pivot_wider(names_from = hoehe_cm, values_from = temp_C)
  bind_rows(lapply(seq_len(nrow(tr)), function(k) {
    r <- tr[k, ]; a <- w[[as.character(r$hl)]]; b <- w[[as.character(r$hm)]]; c3 <- w[[as.character(r$hh)]]
    # Tiefe nach unten positiv: oberer Sensor = hh
    tibble(time = w$time, ts = w$ts, day = w$day, hm = r$hm,
           z_top = w$h_surf - r$hh, z_mid = w$h_surf - r$hm,
           Tl = a, Tm = b, Th = c3,
           curv = curv3(a, b, c3, (r$hm - r$hl)/100, (r$hh - r$hm)/100))
  })) |> filter(is.finite(curv), z_top >= zmin)
}
trG <- triplets(grip); trD <- triplets(dye)

# ----------------------------------------------------------- 1 Rauschen ------
# Rauschen der Einzeltemperatur: zweite zeitliche Differenz bei 4-h-Abstand in
# den ruhigsten Fenstern ist eine OBERGRENZE (enthält Restsignal). Daneben die
# Quantisierung aus den Rohcounts und der direkte Rundungstest.
say("\n== 1  Rauschen der Profilkrümmung (Δz = 4 cm) ==")
say("Erwartung bei unabhängigem Rauschen σ_T: σ_c = √6·σ_T/Δz²; 1 mK -> %.2f K/m², Gleichverteilung 1/16 K (σ = %.1f mK) -> %.1f K/m²",
    sqrt(6)*0.001/DZ^2, 1000*0.0625/sqrt(12), sqrt(6)*0.0625/sqrt(12)/DZ^2)

# Quantisierung: Temperaturschritt je Count (aus benachbarten Messungen gleicher Sensoren)
qstep <- function(x) x |> group_by(hoehe_cm) |> arrange(ts, .by_group = TRUE) |>
  mutate(dT = diff(c(NA, temp_C)), dC = diff(c(NA, counts))) |> ungroup() |>
  filter(is.finite(dC), dC != 0, abs(dC) < 2000) |> summarise(step = median(abs(dT/dC)))
qG <- qstep(grip |> filter(z_cm >= 2))$step
say("Quantisierungsschritt im Schnee (GRIP, Median): %.4f mK/Count -> σ_q = %.4f mK -> Krümmung %.3f K/m²",
    1000*qG, 1000*qG/sqrt(12), sqrt(6)*qG/sqrt(12)/DZ^2)

# zweite zeitliche Differenz auf regelmäßigen 4-h-Folgen
d2 <- function(t, y) { n <- length(y); if (n < 3) return(rep(NA_real_, n))
  ok <- c(NA, abs(diff(t, lag = 2) - 28800) < 600, NA)
  v <- c(NA, y[3:n] - 2*y[2:(n-1)] + y[1:(n-2)], NA); v[!ok] <- NA; v }
nz <- trG |> arrange(hm, ts) |> group_by(hm) |>
  mutate(d2c = d2(ts, curv), d2T = d2(ts, Tm), wk = format(time, "%G-%V")) |> ungroup()
# ruhigste Woche je Tripel (kleinste robuste Streuung)
q <- nz |> filter(is.finite(d2c)) |> group_by(hm, wk) |>
  summarise(n = n(), sc = mad(d2c)/sqrt(6), sT = mad(d2T)/sqrt(6), zm = mean(z_mid), .groups = "drop") |>
  filter(n >= 20)
qq <- q |> group_by(hm) |> slice_min(sc, n = 1) |> ungroup()
say("GRIP, ruhigste Woche je Tripel (Obergrenze, MAD der 2. Zeitdifferenz/√6):")
for (i in seq_len(nrow(qq))) say("  Mitte %2d cm Kettenhöhe, z = %4.1f cm, Woche %s: σ_c ≤ %.1f K/m², σ_T ≤ %.1f mK",
  qq$hm[i], qq$zm[i], qq$wk[i], qq$sc[i], 1000*qq$sT[i])
say("  Median über Tripel: σ_c ≤ %.1f K/m²; tiefstes Tripel: %.1f K/m²", median(qq$sc), qq$sc[which.max(qq$zm)])

# Rundungstest: dieselben Daten auf 1/16 K gerundet
rnd <- function(v) round(v*16)/16
rt <- trG |> mutate(cr = curv3(rnd(Tl), rnd(Tm), rnd(Th), 0.04, 0.04) - curv)
say("Rundung auf 1/16 K: Krümmungsfehler sd = %.1f K/m² (n = %d), Median |Fehler| %.1f K/m²; Antrag: 28 K/m²",
    sd(rt$cr), nrow(rt), median(abs(rt$cr)))
nzr <- trG |> mutate(curv = curv3(rnd(Tl), rnd(Tm), rnd(Th), 0.04, 0.04)) |> arrange(hm, ts) |>
  group_by(hm) |> mutate(d2c = d2(ts, curv), wk = format(time, "%G-%V")) |> ungroup() |>
  semi_join(qq, by = c("hm", "wk")) |> group_by(hm) |> summarise(sc = sd(d2c, na.rm = TRUE)/sqrt(6))
say("  dieselben ruhigsten Wochen, gerundet: σ_c (sd der 2. Zeitdifferenz/√6) Median %.1f K/m²", median(nzr$sc))

# Systematischer Anteil: zeitlich mittlere Krümmung je Tripel (Kalibrierversatz + echtes Profil)
mc <- trG |> filter(day >= as.Date("2026-10-15")) |> group_by(hm) |>
  summarise(c_mean = mean(curv), z = mean(z_mid), .groups = "drop")
say("Mittlere Krümmung je Tripel 15.10.–Ende (enthält Kalibrierversatz): %s K/m²; sd zwischen Tripeln %.0f K/m²",
    paste(sprintf("%.0f", mc$c_mean), collapse = ", "), sd(mc$c_mean))
say("  entspricht bei unabhängigen Versätzen σ_cal ≈ %.0f mK je Sensor", 1000*sd(mc$c_mean)*DZ^2/sqrt(6))

# ------------------------------------------------------------ 2 Tagesgang ----
say("\n== 2  Tagesgang im Schnee ==")
harm <- function(x) { # x: ein Sensor in einem Fenster
  X <- cbind(1, sin(om*x$ts), cos(om*x$ts)); cf <- lm.fit(X, x$temp_C)$coefficients
  tibble(A = sqrt(cf[2]^2 + cf[3]^2), phi = atan2(cf[3], cf[2]), Tm = cf[1], z = mean(x$z_cm), n = nrow(x)) }
wrap <- function(p) ((p + pi) %% (2*pi)) - pi

fenster <- function(x, t0, half, href) {
  w <- x |> filter(abs(ts - t0) <= half)
  if (n_distinct(w$ts) < 0.6*(2*half/14400)) return(NULL)
  fa <- w |> group_by(hoehe_cm) |> group_modify(~ harm(.x)) |> ungroup()
  air <- fa |> filter(hoehe_cm >= href)
  fa |> mutate(A_air = median(air$A), phi_air = median(air$phi),
               lag_h = wrap(phi_air - phi)/om/3600)
}
prof_fit <- function(fa, Amin = 0.03) {
  s <- fa |> filter(z >= 2, A > Amin)
  if (nrow(s) < 3) return(NULL)
  la <- lm(log(A) ~ z, data = s)
  ph <- s |> arrange(z) |> mutate(p = phi[1] + cumsum(c(0, wrap(diff(phi)))))
  lp <- lm(p ~ z, data = ph)
  bA <- coef(la)[2]; bp <- coef(lp)[2]
  tibble(n = nrow(s), zmax = max(s$z), d_A = -1/bA, d_A_se = summary(la)$coef[2, 2]/bA^2,
         d_P = -1/bp, d_P_se = summary(lp)$coef[2, 2]/bp^2,
         lnA0 = coef(la)[1], A_air = fa$A_air[1], T_snow = mean(s$Tm))
}

run_win <- function(x, days, half, href)
  bind_rows(lapply(days, function(dy) {
    t0 <- as.numeric(as.POSIXct(paste(dy, "12:00"), tz = "UTC"))
    fa <- fenster(x, t0, half, href); if (is.null(fa)) return(NULL)
    pf <- prof_fit(fa); if (is.null(pf)) return(NULL)
    pf |> mutate(day = dy) }))

# 7-Tage-Fenster, wöchentlich, nur Tage mit Luftamplitude >= 2 K
wG <- run_win(grip, seq(as.Date("2026-08-14"), max(grip$day) - 3, by = "7 days"), 3.5*86400, 64) |>
  mutate(site = "GRIP")
wD <- run_win(dye, seq(as.Date("2026-11-03"), max(dye$day) - 3, by = "3 days"), 3.5*86400, 40) |>
  mutate(site = "Dye-3")
W7 <- bind_rows(wG, wD) |> filter(A_air >= 2, d_A > 0, d_P > 0)
for (st in unique(W7$site)) {
  x <- W7 |> filter(site == st)
  say("%s: %d Wochenfenster, max. Tiefe im Schnee %.0f cm", st, nrow(x), max(x$zmax))
  say("  d_A = %.1f cm (Median; Spanne %.1f–%.1f), d_φ = %.1f cm (%.1f–%.1f), d_φ/d_A Median %.2f (Spanne %.2f–%.2f)",
      median(x$d_A), min(x$d_A), max(x$d_A), median(x$d_P), min(x$d_P), max(x$d_P),
      median(x$d_P/x$d_A), min(x$d_P/x$d_A), max(x$d_P/x$d_A))
  # Amplitude an der Oberfläche aus der Regression (z = 0), Extrapolation nach 50 cm
  A0 <- exp(x$lnA0)
  A50 <- A0*exp(-50/x$d_A)
  say("  A(z=0) aus Fit Median %.2f K (Luft %.2f K); extrapoliert A(50 cm) Median %.2g mK (Spanne %.2g–%.2g mK) — außerhalb der Messtiefe",
      median(A0), median(x$A_air), 1000*median(A50), 1000*min(A50), 1000*max(A50))
  z625 <- x$d_A*log(A0/0.0625)
  say("  Tiefe mit A < 62,5 mK: Median %.0f cm (Spanne %.0f–%.0f cm)", median(z625), min(z625), max(z625))
}
say("Antrag: Dämpfungstiefe 7–11 cm; A(50 cm) ~20 mK")
say("  Mit A0 = 5 K: d = 7 cm -> %.1f mK, d = 11 cm -> %.0f mK; 20 mK in 50 cm verlangt d = %.1f cm",
    5000*exp(-50/7), 5000*exp(-50/11), 50/log(5/0.02))

# Gemessene Amplituden direkt (tiefstes Tripel), GRIP September/Oktober
deep <- bind_rows(lapply(seq(as.Date("2026-09-01"), max(grip$day) - 3, by = "7 days"), function(dy) {
  t0 <- as.numeric(as.POSIXct(paste(dy, "12:00"), tz = "UTC"))
  fa <- fenster(grip, t0, 3.5*86400, 64); if (is.null(fa)) return(NULL)
  fa |> filter(z >= 2) |> mutate(day = dy) }))
dmax <- deep |> group_by(day) |> slice_max(z, n = 1) |> ungroup()
say("GRIP tiefster Sensor je Woche: z %.0f–%.0f cm, A %.0f–%.0f mK, Luft %.1f–%.1f K",
    min(dmax$z), max(dmax$z), 1000*min(dmax$A), 1000*max(dmax$A), min(dmax$A_air), max(dmax$A_air))

p2 <- deep |> filter(A_air >= 2) |> ggplot(aes(z, A*1000, colour = reorder(format(day, "%d.%m."), as.numeric(day)))) +
  geom_hline(yintercept = c(62.5, 20), linetype = c("dashed", "dotted"), colour = "grey40") +
  geom_point() + geom_line() + scale_y_log10() +
  annotate("text", x = 1, y = c(70, 22), label = c("62,5 mK", "20 mK"), hjust = 0, size = 3) +
  labs(x = "Tiefe unter der Oberfläche (cm)", y = "Tagesamplitude (mK)", colour = "Woche ab",
       title = "SnowMelt GRIP: Tagesamplitude im Schnee, 7-Tage-Fenster") +
  theme_bw(11)
ggsave("abb2_tagesgang_amplitude.png", p2, width = 8, height = 4.8, dpi = 150)

# -------------------------------------------------------------- 3 κ ---------
say("\n== 3  Temperaturleitfähigkeit je 4-cm-Schicht ==")
kap <- function(x, days, half, href) bind_rows(lapply(days, function(dy) {
  t0 <- as.numeric(as.POSIXct(paste(dy, "12:00"), tz = "UTC"))
  fa <- fenster(x, t0, half, href); if (is.null(fa)) return(NULL)
  fa <- fa |> arrange(hoehe_cm)
  if (fa$A_air[1] < 2) return(NULL)
  Tc <- fa$A*exp(1i*fa$phi)  # komplexe Amplitude, Phase relativ zu sin
  bind_rows(lapply(2:(nrow(fa) - 1), function(i) {
    if (fa$z[i + 1] < 2) return(NULL)                    # oberer Nachbar im Schnee
    h1 <- (fa$hoehe_cm[i] - fa$hoehe_cm[i - 1])/100; h2 <- (fa$hoehe_cm[i + 1] - fa$hoehe_cm[i])/100
    if (h1 + h2 > 0.121 || fa$A[i - 1] < 0.03) return(NULL)
    dzz <- h1 + h2
    dA <- dzz/log(fa$A[i + 1]/fa$A[i - 1])               # oben/unten
    dP <- dzz/wrap(fa$phi[i + 1] - fa$phi[i - 1])
    cc <- 2*((Tc[i + 1] - Tc[i])/h2 - (Tc[i] - Tc[i - 1])/h1)/(h1 + h2)
    kc <- 1i*om*Tc[i]/cc                                  # iωT = κ T''
    tibble(day = dy, hm = fa$hoehe_cm[i], z = fa$z[i], T = fa$Tm[i], A = fa$A[i],
           kA = om*dA^2/2, kP = om*dP^2/2, kC = Mod(kc), argC = Arg(kc)*180/pi)
  })) }))
kG <- kap(grip, seq(as.Date("2026-08-14"), max(grip$day) - 3, by = "7 days"), 3.5*86400, 64) |> mutate(site = "GRIP")
kD <- kap(dye,  seq(as.Date("2026-11-03"), max(dye$day) - 3, by = "3 days"), 3.5*86400, 40) |> mutate(site = "Dye-3")
K <- bind_rows(kG, kD) |> filter(is.finite(kA), is.finite(kP))

# Sturm et al. (1997): k(ρ), ρ in g/cm³; c_Eis(T) = 2115 + 7.79·T (J/kg/K)
k_sturm <- function(r) ifelse(r < 0.156, 0.023 + 0.234*r, 0.138 - 1.01*r + 3.233*r^2)
kap_rho <- function(r, T) k_sturm(r)/(r*1000*(2115 + 7.79*T))
rr <- seq(0.10, 0.60, 0.001)
rmin <- rr[which.min(kap_rho(rr, -25))]
dens <- function(kv, T) sapply(seq_along(kv), function(j) {
  f <- kap_rho(rr, T[j]); f[rr < rmin] <- NA
  if (!is.finite(kv[j]) || kv[j] < min(f, na.rm = TRUE) || kv[j] > max(f, na.rm = TRUE)) return(NA_real_)
  1000*approx(f[rr >= rmin], rr[rr >= rmin], kv[j])$y })
K <- K |> mutate(rho_A = dens(kA, T), rho_P = dens(kP, T), rho_C = dens(kC, T))
say("Sturm-Beziehung: κ(ρ) hat bei -25 °C ein Minimum %.2e m²/s bei ρ = %.0f kg/m³; Inversion nur auf dem Ast ρ > %.0f",
    kap_rho(rmin, -25), 1000*rmin, 1000*rmin)
say("Referenz: Fausto et al. (2018), Grönland-weit 0–0,1 m: 315 ± 44 kg/m³ (Frühjahr/Sommer) -> κ_Sturm(−25 °C) = %.2e m²/s, d = %.1f cm",
    kap_rho(0.315, -25), 100*sqrt(2*kap_rho(0.315, -25)/om))
for (st in unique(K$site)) {
  x <- K |> filter(site == st)
  say("%s: %d Schicht-Wochen, %d Schichten, %d Fenster", st, nrow(x), n_distinct(x$hm), n_distinct(x$day))
  say("  κ_A Median %.2e (IQR %.2e–%.2e), κ_φ Median %.2e (IQR %.2e–%.2e), |κ_komplex| Median %.2e m²/s; arg Median %.0f°",
      median(x$kA), quantile(x$kA, .25), quantile(x$kA, .75), median(x$kP), quantile(x$kP, .25),
      quantile(x$kP, .75), median(x$kC), median(x$argC))
  say("  κ_φ/κ_A Median %.1f", median(x$kP/x$kA))
  say("  Dichteindex: ρ_A Median %.0f kg/m³ (%d von %d invertierbar), ρ_φ Median %.0f (%d von %d)",
      median(x$rho_A, na.rm = TRUE), sum(is.finite(x$rho_A)), nrow(x),
      median(x$rho_P, na.rm = TRUE), sum(is.finite(x$rho_P)), nrow(x))
  sl <- x |> group_by(hm) |> filter(n() >= 3) |>
    summarise(n = n(), z = mean(z), cvA = sd(kA)/mean(kA), cvP = sd(kP)/mean(kP), .groups = "drop")
  if (nrow(sl)) say("  Streuung je Schicht über Wochen (Variationskoeffizient): κ_A Median %.0f %%, κ_φ Median %.0f %% (Schichten mit ≥ 3 Wochen: %d)",
                    100*median(sl$cvA), 100*median(sl$cvP), nrow(sl))
  sw <- x |> group_by(day) |> filter(n() >= 3) |>
    summarise(cvA = sd(kA)/mean(kA), cvP = sd(kP)/mean(kP), .groups = "drop")
  if (nrow(sw)) say("  Streuung zwischen Schichten je Woche: κ_A Median %.0f %%, κ_φ Median %.0f %%",
                    100*median(sw$cvA), 100*median(sw$cvP))
}
write.csv(K, "kappa_schichten.csv", row.names = FALSE)

p3 <- K |> filter(site == "GRIP") |> select(day, z, hm, `aus Amplitude` = kA, `aus Phase` = kP) |>
  pivot_longer(c(`aus Amplitude`, `aus Phase`), names_to = "Weg", values_to = "kappa") |>
  ggplot(aes(day, kappa*1e7, colour = z, group = hm)) +
  geom_hline(yintercept = 1e7*kap_rho(0.315, -25), linetype = "dashed") +
  geom_line(alpha = 0.6) + geom_point(size = 1.4) + facet_wrap(~Weg) +
  scale_y_log10() + scale_colour_viridis_c("Tiefe (cm)", direction = -1) +
  labs(x = NULL, y = expression(kappa~(10^{-7}~m^2/s)),
       title = "SnowMelt GRIP: κ je 4-cm-Schicht aus drei Nachbarsensoren (7-Tage-Fenster)",
       subtitle = "gestrichelt: Sturm et al. (1997) bei 315 kg/m³ (Fausto et al. 2018), −25 °C") +
  theme_bw(11)
ggsave("abb3_kappa_schichten.png", p3, width = 9, height = 4.8, dpi = 150)

# ---------------------------------------------------------- 4 Residuum ------
say("\n== 4  Residuum der Wärmeleitungsgleichung ==")
# R = ρc(∂T/∂t − κ ∂²T/∂z²) − a ; κ und a je Schicht aus der Regression
# ∂T/∂t = a + κ·T'' (a nimmt den Kalibrierversatz der Krümmung auf). ρc mit
# ρ = 315 kg/m³, c = c_Eis(T). Nachweisgrenze = 3·MAD-σ des Residuums.
resid_layer <- function(tr, agg) {
  x <- if (agg == "4h") tr else
    tr |> group_by(hm, day) |> filter(n() >= 5) |>
      summarise(ts = mean(ts), time = min(time), Tm = mean(Tm), curv = mean(curv), z_mid = mean(z_mid), .groups = "drop")
  dtnom <- if (agg == "4h") 14400 else 86400
  x |> arrange(hm, ts) |> group_by(hm) |>
    mutate(dTdt = (lead(Tm) - lag(Tm))/(lead(ts) - lag(ts)),
           ok = abs((lead(ts) - lag(ts)) - 2*dtnom) < 0.25*dtnom) |>
    filter(ok, is.finite(dTdt)) |>
    group_modify(function(s, k) {
      if (nrow(s) < 15) return(tibble())
      m <- lm(dTdt ~ curv, data = s)
      rc <- 315*(2115 + 7.79*s$Tm)
      s |> mutate(kfit = coef(m)[2], R = rc*resid(m), q_cal = rc*coef(m)[1]) }) |> ungroup()
}
for (st in c("GRIP", "Dye-3")) for (agg in c("4h", "Tag")) {
  tr <- if (st == "GRIP") trG else trD
  r <- resid_layer(tr, agg); if (!nrow(r)) { say("%s %s: zu wenige Werte", st, agg); next }
  lim <- r |> group_by(hm) |> summarise(z = mean(z_mid), n = n(), kfit = kfit[1], q_cal = q_cal[1],
                                        sR = 1.4826*mad(R), .groups = "drop")
  say("%s, %s-Werte: Nachweisgrenze 3σ je Schicht %s W/m³ (Median %.1f); κ_fit Median %.1e m²/s; Versatzterm Median %.1f W/m³",
      st, agg, paste(sprintf("%.1f", 3*lim$sR), collapse = "/"), 3*median(lim$sR), median(lim$kfit), median(lim$q_cal))
  r2 <- r |> left_join(lim |> select(hm, sR), by = "hm") |> filter(abs(R) > 3*sR)
  ev <- r2 |> filter(abs(R) > 97/4)   # über einem Viertel des 1-mm/Tag-Bezugs
  say("  Werte > 3σ: %d von %d (%.1f %%); davon |R| > 24 W/m³ (¼ des 97-W/m³-Bezugs): %d; max |R| %.0f W/m³; T_max in diesen Schichten %.1f °C",
      nrow(r2), nrow(r), 100*nrow(r2)/nrow(r), nrow(ev), max(abs(r$R)), max(r$Tm))
  if (nrow(ev)) for (i in seq_len(min(nrow(ev), 12)))
    say("    %s  Mitte %d cm (z %.0f cm)  R = %+.0f W/m³  T = %.1f °C", format(ev$time[i], "%d.%m. %H:%M"),
        ev$hm[i], ev$z_mid[i], ev$R[i], ev$Tm[i])
  if (st == "GRIP" && agg == "Tag") lastR <- r
}
say("Bezug: 1 mm Wasser/Tag in 4 cm: 1 kg/m² · 334 kJ/kg / 86400 s / 0,04 m = %.0f W/m³", 334000/86400/0.04)

# ---------------------------------------------------------- 5 Faktor/Wind ---
say("\n== 5  Faktor d_φ/d_A gegen Wind und Einstrahlung ==")
nse <- tryCatch({ options(timeout = 60)
  read.csv("https://thredds.geus.dk/thredds/fileServer/aws/l3sites/csv/day/NSE_day.csv") |>
    mutate(time = as.POSIXct(time, tz = "UTC")) }, error = function(e) NULL)
awsday <- function(a) a |> mutate(day = as.Date(time)) |> group_by(day) |>
  summarise(wind = mean(wspd_u, na.rm = TRUE), dsr = mean(dsr, na.rm = TRUE), .groups = "drop")
# nicht überlappende 3-Tage-Blöcke
w3 <- function(x, from, href) run_win(x, seq(from, max(x$day) - 2, by = "3 days"), 1.5*86400, href)
b3 <- bind_rows(w3(grip, as.Date("2026-08-14"), 64) |> mutate(site = "GRIP"),
                w3(dye, as.Date("2026-11-01"), 40) |> mutate(site = "Dye-3")) |>
  filter(A_air >= 2, d_A > 0, d_P > 0, d_A < 40, d_P < 60) |> mutate(f = d_P/d_A)
met <- bind_rows(awsday(g$aws_raw) |> mutate(site = "GRIP"),
                 if (!is.null(nse)) awsday(nse) |> mutate(site = "Dye-3"))
b3 <- b3 |> rowwise() |> mutate(
  wind = mean(met$wind[met$site == site & abs(as.numeric(met$day - day)) <= 1], na.rm = TRUE),
  dsr  = mean(met$dsr[met$site == site & abs(as.numeric(met$day - day)) <= 1], na.rm = TRUE)) |> ungroup()
write.csv(b3, "faktor_wind_bloecke.csv", row.names = FALSE)
for (st in unique(b3$site)) {
  x <- b3 |> filter(site == st, is.finite(wind))
  say("%s: %d Blöcke à 3 Tage; d_φ/d_A Median %.2f (Spanne %.2f–%.2f)", st, nrow(x), median(x$f), min(x$f), max(x$f))
  if (nrow(x) >= 6) {
    m <- lm(f ~ wind + dsr, data = x); sm <- summary(m)$coef
    ct <- cor.test(x$f, x$wind, method = "spearman", exact = FALSE)
    cs <- cor.test(x$f, x$dsr, method = "spearman", exact = FALSE)
    say("  f = a + b·Wind + c·Einstrahlung: b = %+.3f ± %.3f pro m/s (p = %.2f), c = %+.4f ± %.4f pro W/m² (p = %.2f)",
        sm[2, 1], sm[2, 2], sm[2, 4], sm[3, 1], sm[3, 2], sm[3, 4])
    say("  Spearman ρ(f, Wind) = %.2f (p = %.2f), ρ(f, Einstrahlung) = %.2f (p = %.2f); Wind %.1f–%.1f m/s",
        ct$estimate, ct$p.value, cs$estimate, cs$p.value, min(x$wind), max(x$wind))
    say("  Zeitkorrelation: ρ(f, Tag) = %.2f; ρ(Wind, Tag) = %.2f", cor(x$f, as.numeric(x$day), method = "spearman"),
        cor(x$wind, as.numeric(x$day), method = "spearman"))
  } else say("  zu wenige Blöcke für eine Regression")
}

writeLines(out, "ergebnis.txt")
