#!/usr/bin/env Rscript
# ---------------------------------------------------------------------------
# Lufttemperatur fuer die Ultraschall-Schneehoehe: Inversionsstatistik,
# Wegmittelfehler und Strahlungsschutz. Siehe README.md.
#
# Aufruf aus Greenland2026/:  Rscript ../meta/ultraschall_lufttemperatur/lufttemperatur_test.R
# ---------------------------------------------------------------------------
suppressMessages({library(dplyr); library(tidyr)})
source("decode_core.R")

H_SURF <- 26          # cm, aktuelle Oberflaeche auf der Kettenachse (Uebergangsschaetzer)
L_WEG  <- 1.5         # m, typischer Ultraschallweg
bf <- Sys.glob("../testdata/300434065508020-*.bin")
fields <- c("ntc1","ntc2","testSB"); n_nodes <- 24L; s <- 4L
lab <- load_lab_cal("../meta/GRIP_calibration_assignment.csv", n_nodes)
rank_map <- c(ntc1=1, ntc2=2, testSB=3)
alld <- lapply(bf, function(f) tryCatch(read_snowchain_bin(f, fields, n_nodes),
                                        error=function(e) NULL))
alld <- alld[!sapply(alld, is.null)]
d <- bind_rows(lapply(alld, function(b) { nd <- bin_to_nodes(b, fields, lab)
  pivot_longer(nd, ends_with("_C"), names_to="sensor", values_to="temp_C") |>
    mutate(sensor=sub("_C$","",sensor), time=unix2utc(b$time_unix)) })) |>
  filter(!is.na(temp_C)) |>
  mutate(hoehe_cm=(node-1L)*3L*s + rank_map[sensor]*s, ts=as.numeric(time))
aws <- tryCatch(suppressWarnings(readr::read_csv(
  "https://thredds.geus.dk/thredds/fileServer/aws/l3sites/csv/hour/SUM_hour.csv",
  show_col_types=FALSE)), error=function(e) NULL)
a <- if (is.null(aws)) NULL else
  aws |> transmute(time=as.POSIXct(time, tz="UTC"), Taws=t_u, dsr, u=wspd_u) |>
    filter(is.finite(dsr))

# --- A) Inversionsstatistik und Wegmittelfehler ----------------------------
cat("== A) Luftprofil ueber der Oberflaeche ==\n")
w <- d |> filter(time > max(time) - 21*86400) |>
  mutate(z = (hoehe_cm - H_SURF)/100) |> filter(z > 0.1, z < 2.7)
g <- w |> group_by(time) |> filter(n() >= 10) |> summarise(
  T2 = approx(z, temp_C, 2.0, rule=2)$y, T03 = approx(z, temp_C, 0.3, rule=2)$y,
  Tweg = mean(temp_C[z <= 2.0]), G = coef(lm(temp_C ~ z))[2], .groups="drop")
cat(sprintf("n = %d Profile, %d Hoehen %.2f-%.2f m\n", nrow(g), n_distinct(w$z),
            min(w$z), max(w$z)))
cat("Luftgradient (K/m, + = Inversion): ")
cat(sprintf("%s\n", paste(sprintf("%s=%.2f", c("5%","25%","50%","75%","95%"),
  quantile(g$G, c(.05,.25,.5,.75,.95))), collapse="  ")))
cat(sprintf("T(2m)-T(0.3m): Median %+.2f K, 95%% %+.2f K, max %+.2f K\n",
  median(g$T2-g$T03), quantile(g$T2-g$T03,.95), max(g$T2-g$T03)))
mm <- function(dT, Tm = -50) 1000*L_WEG*0.5*dT/(273.15+Tm)
g <- g |> mutate(e1 = mm(T2 - Tweg, Tweg), e2 = mm((T2+T03)/2 - Tweg, Tweg))
cat(sprintf("Hoehenfehler, ein Sensor bei 2 m : Median %+.1f mm, 95%% %+.1f mm, max %+.1f mm\n",
  median(g$e1), quantile(g$e1,.95), max(g$e1)))
cat(sprintf("Hoehenfehler, zwei Sensoren      : Median %+.1f mm, 95%% %+.1f mm\n\n",
  median(g$e2), quantile(abs(g$e2),.95)))

# --- B) Strahlungsschutz: Theoriewerte ------------------------------------
cat("== B) Strahlungsschutz ==\n")
sig <- 5.67e-8; Tl <- 213.15
cat("Polarwinter, langwellige Unterkuehlung (halb Himmel, halb Flaeche):\n")
for (LW in c(80, 100, 120)) { Tsky <- (LW/sig)^0.25
  net <- sig*(Tl^4 - 0.5*Tsky^4 - 0.5*(Tl-2)^4)
  cat(sprintf("  LW=%3d -> T_Himmel %3.0f K, Verlust %5.1f W/m2, dT = %.2f/%.2f/%.2f K (h=4/8/15)\n",
    LW, Tsky, net, net/4, net/8, net/15)) }
cat("Sommer ohne Schutz, Zylinder dT = alpha*S/(pi*h), S = 800 W/m2:\n")
for (al in c(0.1, 0.9)) cat(sprintf("  alpha=%.1f: %.1f K (h=4), %.1f K (h=8)\n",
  al, al*800/(pi*4), al*800/(pi*8)))
cat("Mehrplattenschutz laut Literatur 0.5-2 K (<1 m/s), <0.4 K (>3 m/s)\n")
cat(sprintf("  0.4 K entspricht %.1f mm auf %.1f m Weg\n\n", mm(0.4, -50), L_WEG))

# --- C) Gegenprobe gegen die AWS (traegt NICHT, siehe README) -------------
if (!is.null(a)) {
  cat("== C) Ungeschirmte Kettensensoren gegen Summit-AWS (30 km) ==\n")
  cc <- d |> filter(time > max(time) - 40*86400,
                    hoehe_cm >= H_SURF+180, hoehe_cm <= H_SURF+220) |>
    group_by(time) |> summarise(Tc = mean(temp_C), .groups="drop") |>
    mutate(Taws = approx(as.numeric(a$time), a$Taws, as.numeric(time), rule=2)$y,
           dsr  = approx(as.numeric(a$time), a$dsr,  as.numeric(time), rule=2)$y) |>
    filter(is.finite(Taws), is.finite(dsr)) |> mutate(dT = Tc - Taws)
  f <- lm(dT ~ dsr, cc)
  cat(sprintf("n = %d, Median %+.2f K, sd %.2f K\n", nrow(cc), median(cc$dT), sd(cc$dT)))
  cat(sprintf("Steigung %+.3f mK je W/m2 (t=%.1f, R2=%.3f) -> %+.2f K bei 800 W/m2\n",
    1000*coef(f)[2], summary(f)$coefficients[2,3], summary(f)$r.squared, 800*coef(f)[2]))
  cat("Vorzeichen falsch, R2 vernachlaessigbar: die Standortdifferenz (sd 3.5 K)\n")
  cat("ueberdeckt den Effekt. Braucht ein Paar am selben Mast.\n")
}

# --- D) Rekonstruktion des Pfadmittels aus 1, 2 oder 3 Hoehen --------------
# An den gemessenen Profilen, ohne Profilannahme. Der Fehler wird gegen die
# Inversionsstaerke regressiert, damit er auf Winterwerte extrapolierbar ist.
cat("== D) Rekonstruktion aus 1/2/3 Sensorhoehen ==\n")
wd <- d |> filter(time > max(time) - 25*86400) |>
  mutate(z = (hoehe_cm - H_SURF)/100) |> filter(z > 0.04, z < 2.05)
rk <- wd |> group_by(time) |> filter(n() >= 20) |> group_modify(function(x, k) {
  x <- x |> arrange(z); zg <- seq(max(0.05, min(x$z)), 2.0, length.out = 400)
  wahr <- mean(approx(x$z, x$temp_C, zg, rule = 2)$y)
  gv <- function(zz) approx(x$z, x$temp_C, zz, rule = 2)$y
  s2 <- c(0.3, 2.0); s3 <- c(0.45, 0.9, 1.9); T2 <- gv(s2); T3 <- gv(s3)
  tibble(inv = gv(2.0) - gv(0.3),
         e_1s  = gv(2.0) - wahr,
         e_lin = mean(approx(s2, T2, zg, rule = 2)$y) - wahr,
         e_lg2 = { b <- diff(T2)/diff(log(s2))
                   mean(T2[1] + b*(log(zg) - log(s2[1]))) - wahr },
         e_lg3 = { m <- lm(T3 ~ log(s3))
                   mean(coef(m)[1] + coef(m)[2]*log(zg)) - wahr })
}) |> ungroup() |> filter(is.finite(inv))
cat(sprintf("n = %d Profile, Inversion Median %+.2f K, 95%% %+.2f K\n",
            nrow(rk), median(rk$inv), quantile(rk$inv, .95)))
for (v in c("e_1s","e_lin","e_lg2","e_lg3")) {
  lab <- c(e_1s = "1 Sensor bei 2 m", e_lin = "linear aus 2",
           e_lg2 = "log-Fit aus 2", e_lg3 = "log-Fit aus 3")[v]
  f <- lm(rk[[v]] ~ rk$inv + 0)
  cat(sprintf("  %-20s %+.3f K je K Inversion -> %+5.1f mm bei 11 K\n",
              lab, coef(f)[1], mm(11*coef(f)[1]))) }

# --- E) Schirmfehler und Windfilter an den IMAU-Stationen -----------------
# Laedt bei Bedarf von PANGAEA; braucht Netz. AWS09 Kohnen 1997-2022,
# AWS12 Hochplateau 3620 m 2007-2016.
cat("\n== E) IMAU-Stationen (optional, braucht Netz) ==\n")
imau <- function(doi, nm, lab) {
  f <- file.path(tempdir(), paste0(nm, ".txt"))
  if (!file.exists(f)) try(download.file(
    sprintf("https://doi.pangaea.de/10.1594/PANGAEA.%s?format=textfile", doi),
    f, quiet = TRUE), silent = TRUE)
  if (!file.exists(f)) { cat("  ", lab, ": nicht erreichbar\n"); return(invisible()) }
  hdr <- grep("^\\*/", readLines(f, n = 60))[1]
  x <- readr::read_tsv(f, skip = hdr, show_col_types = FALSE, progress = FALSE)
  nmv <- c("time","T"); ff <- grep("^ff \\[", names(x))[1]
  se <- grep("cum. change", names(x))[1]
  x <- tibble(time = as.POSIXct(x[[1]], tz = "UTC"), ff = x[[ff]], selev = x[[se]]) |>
    filter(is.finite(ff), is.finite(selev)) |> mutate(mon = format(time, "%Y-%m"))
  m <- x |> group_by(mon) |> summarise(a = median(selev), b = median(selev[ff > 3]),
                                       n3 = sum(ff > 3), .groups = "drop") |> filter(n3 >= 50)
  cat(sprintf("  %-22s n=%6d, Wind-Median %.1f m/s, unter 3 m/s %.0f %%, Filterversatz %+.1f +- %.1f mm\n",
    lab, nrow(x), median(x$ff), 100*mean(x$ff < 3), 1000*median(m$b - m$a), 1000*sd(m$b - m$a))) }
imau("974118", "aws09", "AWS09 Kohnen 2892 m")
imau("974121", "aws12", "AWS12 Plateau 3620 m")
