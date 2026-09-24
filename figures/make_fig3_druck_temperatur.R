# Aufruf aus figures/:  Rscript make_fig3_druck_temperatur.R
suppressMessages({library(dplyr); library(tidyr); library(readr); library(ggplot2); library(patchwork)})
BLUE <- "#2a78d6"; ORANGE <- "#eb6834"; AQUA <- "#1baf7a"; GREY <- "#52514e"

## ---- Theorie: b = phi / (rho * c) mit Herron-Langway-Dichte -----------------
hl <- function(T_site, acc, rho0 = 0.34) {
  k0 <- 11 * exp(-10160/(8.314*T_site)); k1 <- 575 * exp(-21400/(8.314*T_site))
  z55 <- (log(.55/(.917-.55)) - log(rho0/(.917-rho0)))/(.917*k0)
  function(z) vapply(z, function(q) {
    Z <- if (q <= z55) exp(.917*k0*q + log(rho0/(.917-rho0)))
         else exp(.917*k1*(q - z55)/sqrt(acc) + log(.55/(.917-.55)))
    .917*Z/(1+Z) }, 0) }
# Waermekapazitaet von Eis, temperaturabhaengig (Alexiades & Solomon): c = 152.5 + 7.122 T[K]
cp_ice <- function(TK) 152.5 + 7.122*TK
b_of <- function(dens, c_ice) function(z) { r <- dens(z)*1000; (1 - r/917)/(r*c_ice)*1e5 }
b_grip   <- b_of(hl(242.0, 0.230), cp_ice(242.0))    # Summit/GRIP, -31 C
b_kohnen <- b_of(hl(228.6, 0.064), cp_ice(228.6))    # Kohnen, -44,5 C

## ---- 1) Grönland-Doppelkette, verfülltes Loch ------------------------------
gr <- read_csv("../Greenland2026/data/fig3_greenland_b.csv", show_col_types = FALSE)

## ---- 2) head02 (B46), nach Abzug des gemeinsamen Anteils -------------------
h02 <- read_csv("../KohnenRecords_Analyse/data/fig3_head02_b.csv", show_col_types = FALSE)

## ---- 3) head03 (B50), verfüllte 10-m-Kette --------------------------------
h03 <- read_csv("../KohnenRecords_Analyse/data/fig3_head03_b.csv", show_col_types = FALSE)

dat <- bind_rows(
  gr  |> transmute(head = "GRIP, double chain (2 months)", z = depth_m, b, se, theorie = b_grip(depth_m)),
  h03 |> transmute(head = "Kohnen B50, head03 (6 months)", z = depth_m, b, se, theorie = b_kohnen(depth_m)),
  h02 |> transmute(head = "Kohnen B46, head02 (2 weeks)", z = depth_m, b, se, theorie = b_kohnen(depth_m))) |>
  filter(abs(b)/se > 2 | grepl("B46", head))          # nur aufgelöste Knoten
dat$head <- factor(dat$head, levels = c("Kohnen B50, head03 (6 months)",
                                        "GRIP, double chain (2 months)",
                                        "Kohnen B46, head02 (2 weeks)"))
cols <- setNames(c(BLUE, AQUA, ORANGE), levels(dat$head))

## head02 trägt einen freien additiven Versatz (Common-Mode-Abzug) -> anpassen
h2d <- dat |> filter(grepl("B46", head))
off <- weighted.mean(h2d$b - h2d$theorie, 1/h2d$se^2)
dat <- dat |> mutate(b_adj = ifelse(grepl("B46", head), b - off, b),
                     frei = grepl("B46", head))

## ---- Panel A: b gegen Tiefe, mit den beiden Theoriekurven ------------------
curve <- bind_rows(
  data.frame(z = seq(1, 65, 0.5)) |> mutate(b = b_kohnen(z), site = "Kohnen (−44.5 °C, 64 kg/m²/a)"),
  data.frame(z = seq(1, 65, 0.5)) |> mutate(b = b_grip(z),   site = "GRIP (−31 °C, 230 kg/m²/a)"))

pA <- ggplot(curve, aes(z, b, linetype = site)) +
  geom_line(colour = GREY, linewidth = 0.6) +
  geom_errorbar(data = dat, aes(z, ymin = b_adj - se, ymax = b_adj + se, colour = head),
                width = 0, linewidth = 0.5, inherit.aes = FALSE) +
  geom_point(data = dat, aes(z, b_adj, colour = head, shape = frei), size = 2.4, inherit.aes = FALSE) +
  scale_shape_manual(values = c(16, 1), guide = "none") +
  scale_colour_manual(values = cols, name = NULL) +
  scale_linetype_manual(values = c("solid", "22"), name = "prediction φ/(ρ c)") +
  scale_x_log10(breaks = c(1, 2, 5, 10, 20, 50)) +
  labs(x = "Depth (m)", y = expression(b~"= "*Delta*T/Delta*p~~"(mK/hPa)"),
       subtitle = "A · Coupling vs. depth, against the parameter-free prediction") +
  theme_bw(base_size = 12) + theme(legend.position = "bottom", legend.box = "vertical",
                                   legend.margin = margin(0,0,0,0), legend.spacing.y = unit(1,"pt"))

## ---- Panel B: gemessen gegen vorhergesagt (1:1) ----------------------------
lim <- range(c(dat$b_adj[!dat$frei], dat$theorie[!dat$frei])) + c(-0.005, 0.005)
pB <- ggplot(dat |> filter(!frei), aes(theorie, b_adj, colour = head)) +
  geom_abline(slope = 1, intercept = 0, colour = GREY, linewidth = 0.6) +
  geom_errorbar(aes(ymin = b_adj - se, ymax = b_adj + se), width = 0, linewidth = 0.5) +
  geom_point(size = 2.4) +
  scale_colour_manual(values = cols, name = NULL, guide = "none") +
  coord_equal(xlim = lim, ylim = lim) +
  labs(x = "prediction φ/(ρ c)  (mK/hPa)", y = "measured  (mK/hPa)",
       subtitle = "B · 1:1 comparison (without head02, which gives the shape only)") +
  theme_bw(base_size = 12)

sol <- dat |> filter(!frei)
fit <- lm(b_adj ~ 0 + theorie, data = sol, weights = 1/sol$se^2)
cat(sprintf("Faktor gegen die Vorhersage (ohne head02): %.3f +- %.3f (n = %d Knoten)\n",
            coef(fit)[1], summary(fit)$coefficients[1,2], nrow(sol)))
cat(sprintf("head02 nur als Form, freier Versatz %.4f mK/hPa\n", off))

## ---- Panel C: die Rohdaten, aus denen b kommt -----------------------------
sc <- read_csv("../KohnenRecords_Analyse/data/fig3_scatter.csv", show_col_types = FALSE) |>
  mutate(site = recode(site, "GRIP-Doppelkette (täglich)" = "GRIP double chain (daily)",
                             "Kohnen B50 (2×täglich)"     = "Kohnen B50 (2× daily)"),
         tiefe = factor(sprintf("%g m", depth_m), levels = sprintf("%g m", sort(unique(depth_m)))))

pC <- ggplot(sc, aes(rP, rT, colour = tiefe)) +
  geom_hline(yintercept = 0, colour = "grey85") + geom_vline(xintercept = 0, colour = "grey85") +
  geom_point(size = 0.7, alpha = 0.55) +
  geom_smooth(method = "lm", se = FALSE, linewidth = 0.6) +
  scale_colour_viridis_d(name = "depth", option = "D", end = 0.88) +
  facet_wrap(~ site, scales = "free") +
  labs(x = "air pressure, deviation from trend (hPa)", y = "temperature, deviation from trend (mK)",
       subtitle = "C · The raw data behind b: temperature vs. air pressure in the synoptic band") +
  theme_bw(base_size = 12) + theme(legend.position = "bottom")


## --- Beschriftungsvarianten ------------------------------------------------
## voll      : "A · Text"      (Standard)
## nolabel   : "Text"          (ohne Panelbuchstaben)
## bare      : ohne Untertitel (Titel setzt der Vortragende)
strip_letter <- function(p) { st <- p$labels$subtitle
  if (!is.null(st)) p$labels$subtitle <- sub("^[A-D] . ", "", st); p }
drop_sub <- function(p) { p$labels$subtitle <- NULL; p }

build3 <- function(f) (f(pA) + f(pB) + plot_layout(widths = c(1.25, 1))) / f(pC) +
  plot_layout(heights = c(1, 0.9))

ggsave("fig3_druck_temperatur.png",         build3(identity),     width = 12, height = 10, dpi = 200, bg = "white")
ggsave("fig3_druck_temperatur_nolabel.png", build3(strip_letter), width = 12, height = 10, dpi = 200, bg = "white")
ggsave("fig3_druck_temperatur_bare.png",    build3(drop_sub),     width = 12, height = 9.4, dpi = 200, bg = "white")

## Einzelpanels für Folien — mit und ohne Untertitel
ggsave("fig3a_kopplung_tiefe.png",      strip_letter(pA), width = 7.2, height = 5.4, dpi = 200, bg = "white")
ggsave("fig3c_rohdaten.png",            strip_letter(pC), width = 9.0, height = 4.4, dpi = 200, bg = "white")
ggsave("fig3a_kopplung_tiefe_bare.png", drop_sub(pA),     width = 7.2, height = 5.1, dpi = 200, bg = "white")
ggsave("fig3b_elf_bare.png",            drop_sub(pB),     width = 5.4, height = 5.1, dpi = 200, bg = "white")
ggsave("fig3c_rohdaten_bare.png",       drop_sub(pC),     width = 9.0, height = 4.1, dpi = 200, bg = "white")
cat("fig3_druck_temperatur.png geschrieben\n")
