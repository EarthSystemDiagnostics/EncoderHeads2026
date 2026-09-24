#!/usr/bin/env Rscript
# Auswertung des Potsdamer Vorversuchs zur Einschneiterkennung über die
# Kurzzeitvarianz. Erwartet eine CSV mit 1-Hz-Aufzeichnung und den Spalten
#   time   POSIXct oder Sekunden
#   luft   NTC frei in Luft (°C)
#   sand   baugleicher NTC 4 cm tief in Sand/Schnee (°C)
#
# Aufruf:  Rscript zeitkonstante_test.R messung.csv [abstand_s] [n_pro_block]
#
# Liefert (1) die Verteilung der Reststreuung nach Trendabzug für beide
# Sensoren, (2) den Kontrast und die Überlappung der Verteilungen, (3) die
# Zeitkonstante aus dem Spektralknick.

args <- commandArgs(trailingOnly = TRUE)
f    <- args[1]
dt   <- if (length(args) >= 2) as.numeric(args[2]) else 75   # Abstand der Punkte
np   <- if (length(args) >= 3) as.numeric(args[3]) else 10   # Punkte je Block

x <- read.csv(f)
tt <- if (is.numeric(x$time)) x$time else as.numeric(as.POSIXct(x$time, tz = "UTC"))
tt <- tt - min(tt)
fs <- 1/median(diff(tt))
cat(sprintf("%d Messungen, %.1f h, Abtastrate %.2f Hz\n\n", nrow(x), max(tt)/3600, fs))

# --- (1) Reststreuung nach linearem Trendabzug ------------------------------
# Alle Startversätze auswerten: aus einer 1-Hz-Reihe entstehen so dt-mal mehr
# Blöcke als bei einem einzigen Raster, ohne dass ein Block Punkte teilt.
blocks <- function(v, dt, np, fs) {
  step <- round(dt * fs); span <- step * (np - 1)
  out  <- c()
  for (off in seq_len(step)) {
    idx <- seq(off, length(v) - span, by = span + step)
    for (i in idx) {
      j <- i + step * (0:(np - 1))
      y <- v[j]; if (anyNA(y)) next
      out <- c(out, sd(resid(lm(y ~ seq_along(y)))) * 1000)      # mK
    }
  }
  out
}
bl <- blocks(x$luft, dt, np, fs); bs <- blocks(x$sand, dt, np, fs)
q  <- c(0.10, 0.50, 0.90)
cat(sprintf("Reststreuung nach Trendabzug (%d Punkte im Abstand %.0f s), mK:\n", np, dt))
cat(sprintf("  Luft  n=%5d   q10 %6.1f   Median %6.1f   q90 %6.1f\n", length(bl), quantile(bl, q)[1], quantile(bl, q)[2], quantile(bl, q)[3]))
cat(sprintf("  Sand  n=%5d   q10 %6.1f   Median %6.1f   q90 %6.1f\n\n", length(bs), quantile(bs, q)[1], quantile(bs, q)[2], quantile(bs, q)[3]))
cat(sprintf("Kontrast der Mediane: %.1f\n", median(bl)/median(bs)))
cat(sprintf("Trennung: q10(Luft) = %.1f mK gegen q90(Sand) = %.1f mK -> %s\n",
  quantile(bl, 0.10), quantile(bs, 0.90),
  if (quantile(bl, 0.10) > quantile(bs, 0.90)) "Ein-Tages-Urteil möglich" else
    "Ein-Tages-Urteil nicht sicher, Wochenmittel prüfen"))
ov <- mean(outer(sample(bs, min(2000, length(bs))), sample(bl, min(2000, length(bl))), ">"))
cat(sprintf("Fehlklassifikationsrate bei optimaler Schwelle: %.1f %%\n\n", 100*ov))

# --- (2) Wochenmittel: schlägt der Kontrast den Schätzfehler? ---------------
kw <- function(v, k) sapply(seq_len(200), function(i) mean(sample(v, k)))
for (k in c(1, 7, 14)) cat(sprintf("  über %2d Durchläufe gemittelt: Luft %6.1f ± %4.1f   Sand %6.1f ± %4.1f mK\n",
  k, mean(kw(bl,k)), sd(kw(bl,k)), mean(kw(bs,k)), sd(kw(bs,k))))

# --- (3) Zeitkonstante aus dem Spektralknick -------------------------------
# Atmosphäre im Trägheitsbereich: P ~ f^b mit b nahe -5/3; ein Sensor erster
# Ordnung multipliziert das mit 1/(1+(2 pi f tau)^2). b bleibt frei, weil die
# Steigung dicht über der Oberfläche von -5/3 abweichen kann; tau wird
# logarithmisch parametrisiert, damit der Fit positiv bleibt.
sp <- spec.pgram(ts(x$luft, frequency = fs), spans = c(15, 15), plot = FALSE, taper = 0.1)
ok <- sp$freq > fs/2000 & sp$freq < 0.45*fs
dd <- data.frame(freq = sp$freq[ok], lp = log(sp$spec[ok]))
mod <- try(nls(lp ~ a + b*log(freq) - log(1 + (2*pi*freq*exp(lt))^2), data = dd,
  start = list(a = mean(dd$lp), b = -5/3, lt = log(2)),
  control = list(warnOnly = TRUE, maxiter = 200)), silent = TRUE)
if (!inherits(mod, "try-error") && is.finite(coef(mod)["lt"])) {
  tau <- exp(coef(mod)["lt"]); b <- coef(mod)["b"]
  cat(sprintf("\nSpektrum der Luftreihe: Steigung %.2f (erwartet -1.67 im Trägheitsbereich)\n", b))
  if (tau*2*pi < 1/(0.45*fs)) {
    cat(sprintf("  Knick liegt über der Nyquistfrequenz: tau < %.1f s, aus dieser Rate nicht bestimmbar.\n", 1/(2*pi*0.45*fs)))
  } else {
    cat(sprintf("  Zeitkonstante des NTC in Luft: tau = %.1f s (Knick bei %.3f Hz)\n", tau, 1/(2*pi*tau)))
  }
  cat("  Weicht die Steigung stark von -1.67 ab, trägt der Fit nicht — dann tau\n")
  cat("  über einen Sprungversuch bestimmen (Sensor aus der Kammer in Raumluft).\n")
} else cat("\nSpektralfit nicht konvergiert — Aufzeichnung zu kurz, zu verrauscht oder tau zu klein.\n")
