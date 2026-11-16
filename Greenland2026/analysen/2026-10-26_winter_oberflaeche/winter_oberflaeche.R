# Schneeoberfläche ohne Tagesgang: zwei Breitband-Schätzer für den Winter,
# geprüft gegen den Übergangsschätzer (Tagesharmonische) August–Oktober 2026.
#
# Signal: Abweichung jedes Sensors vom zentrierten 24-h-Mittel (Wetter auf
# Zeitskalen von Stunden bis ~2 Tagen, unabhängig von einer festen Periode).
#   V  Streuung: ln sd(h) ist über der Fläche flach und fällt darunter linear
#      (exponentielle Dämpfung). Knickpunkt-Fit, Knick = Oberfläche.
#   L  Verzug: Kreuzkorrelation gegen die freie Luft; Verzug 0 über der Fläche,
#      linear wachsend darunter. Knickpunkt-Fit, Knick = Oberfläche.
# Fenster: 10 Tage gleitend (zentriert), Schritt 1 Tag.
#
# Eingaben: ser_dat.rds und uebergang_tageswerte.csv (aus dem Report-Code von
# decode_snowmelt_newgrip.qmd exportiert; ser_dat.rds nicht abgelegt, 0,5 MB).
# Prototyp. Die laufende Fassung steht in decode_snowmelt_newgrip.qmd,
# Abschnitt „Oberfläche ohne Tagesgang (Winter-Schätzer)“.

suppressMessages({ library(dplyr); library(tidyr); library(ggplot2) })
setwd("/Users/tlaepple/data/EncoderHeads2026/Greenland2026/analysen/2026-10-26_winter_oberflaeche")

x     <- readRDS("ser_dat.rds")
ser   <- x$ser_dat |> filter(hoehe_cm <= 96)
ueb   <- read.csv("uebergang_tageswerte.csv") |>
  mutate(day = as.Date(day), h_ueb = x$h_bot + z_ueb)
H_AIR <- 96        # Luftreferenz: Sensoren 64–96 cm (bis Ende Oktober sicher frei)

# Hochpass: Abweichung vom zentrierten 24-h-Mittel
an <- ser |> group_by(hoehe_cm) |> arrange(ts, .by_group = TRUE) |>
  mutate(an = temp_C - sapply(ts, function(t0) mean(temp_C[abs(ts - t0) <= 43200]))) |>
  ungroup()

# Knickpunkt-Fit: y = c + b_luft·(h−hs)_+ − (hs−h)_+ / d ; hs auf 0,5-cm-Gitter
knick <- function(h, y, w = rep(1, length(h)), hs_grid = seq(2, 70, 0.5)) {
  rss <- sapply(hs_grid, function(hs) {
    m <- lm(y ~ pmax(h - hs, 0) + pmax(hs - h, 0), weights = w)
    sum(w * resid(m)^2) })
  hs <- hs_grid[which.min(rss)]
  m  <- lm(y ~ pmax(h - hs, 0) + pmax(hs - h, 0), weights = w)
  list(hs = hs, slope_unten = unname(coef(m)[3]), rss = min(rss))
}

# Verzug je Höhe: Kreuzkorrelation auf 1-h-Gitter, Maximum parabolisch verfeinert
verzug <- function(w) {
  g   <- seq(min(w$ts), max(w$ts), 3600)
  ref <- w |> filter(hoehe_cm >= 64) |> group_by(hoehe_cm) |>
    group_modify(~ tibble(ts = g, a = approx(.x$ts, .x$an, g)$y)) |>
    group_by(ts) |> summarise(a = mean(a), .groups = "drop") |> pull(a)
  L <- -3:24
  w |> group_by(hoehe_cm) |> group_modify(function(s, k) {
    y  <- approx(s$ts, s$an, g)$y
    cc <- sapply(L, function(l) {
      i <- seq(max(1, 1 - l), min(length(g), length(g) - l))
      cor(ref[i], y[i + l], use = "complete.obs") })
    j <- which.max(cc); lag <- L[j]
    if (j > 1 && j < length(L)) {                 # Parabel durch drei Punkte
      den <- cc[j-1] - 2*cc[j] + cc[j+1]
      if (den < 0) lag <- lag + 0.5*(cc[j-1] - cc[j+1])/den }
    tibble(lag_h = lag, r = max(cc)) }) |> ungroup()
}

tage <- seq(as.Date("2026-07-20"), as.Date(max(ser$time)) - 1, by = "1 day")
est <- bind_rows(lapply(tage, function(dy) {
  t0 <- as.numeric(as.POSIXct(paste(dy, "12:00"), tz = "UTC"))
  w  <- an |> filter(abs(ts - t0) <= 5*86400)
  if (n_distinct(w$ts) < 40) return(NULL)
  s  <- w |> group_by(hoehe_cm) |> summarise(sd = sd(an), .groups = "drop")
  kv <- knick(s$hoehe_cm, log(s$sd))
  lz <- verzug(w)
  kl <- knick(lz$hoehe_cm, lz$lag_h, w = pmax(lz$r, 0.1)^2)
  tibble(day = dy, h_V = kv$hs, d_V = -1/kv$slope_unten, h_L = kl$hs,
         v_L = kl$slope_unten, sd_luft = median(s$sd[s$hoehe_cm >= 64]))
}))
# d_V: Abklinglänge der Streuung (cm); v_L: Verzug je cm unter der Fläche (h/cm)

saveRDS(est, "schaetzer_tageswerte.rds")
cmp <- est |> left_join(ueb |> select(day, h_ueb, A_air), by = "day")
write.csv(cmp, "schaetzer_tageswerte.csv", row.names = FALSE)

# Vergleich im Zeitraum mit verlässlichem Übergangsschätzer (Fläche ≥ 14 cm, ab 20.08.)
ok <- cmp |> filter(day >= as.Date("2026-08-20"), day <= as.Date("2026-10-07"),
                    is.finite(h_ueb))
sink("ergebnis.txt")
cat("Vergleich gegen Übergangsschätzer, 20.08.–07.10.2026, n =", nrow(ok), "Tage\n")
for (v in c("h_V", "h_L")) {
  dlt <- ok[[v]] - ok$h_ueb
  cat(sprintf("%s: mittlere Differenz %+.1f cm, Median |Diff| %.1f cm, sd %.1f cm\n",
              v, mean(dlt), median(abs(dlt)), sd(dlt)))
}
cat("\nLetzte 14 Tage:\n"); print(as.data.frame(tail(cmp, 14)), row.names = FALSE)
sink()
cat(readLines("ergebnis.txt"), sep = "\n")

p <- cmp |> select(day, `Streuung (Knick)` = h_V, `Verzug (Knick)` = h_L,
                   `Übergang Tagesgang` = h_ueb) |>
  pivot_longer(-day, names_to = "Schätzer", values_to = "h") |>
  ggplot(aes(day, h, colour = Schätzer)) + geom_line(na.rm = TRUE) +
  geom_point(size = 0.9, na.rm = TRUE) +
  scale_colour_manual(values = c("#b2182b", "#2166ac", "#e08214")) +
  coord_cartesian(ylim = c(0, 50)) +
  labs(x = NULL, y = "Oberfläche, Kettenhöhe (cm)",
       title = "Snowmelt NEWGRIP: Oberflächenlage aus Wetter-Anomalien (10-Tage-Fenster)") +
  theme_bw(base_size = 11) + theme(legend.position = "bottom")
ggsave("vergleich_schaetzer.png", p, width = 9, height = 4.5, dpi = 150)
