# Aufruf aus figures/:  Rscript make_fig4_slope_density.R
suppressMessages({library(dplyr); library(readr); library(ggplot2)})
BLUE <- "#2a78d6"; ORANGE <- "#eb6834"; AQUA <- "#1baf7a"; GREY <- "#52514e"

cp_ice <- function(TK) 152.5 + 7.122*TK
hl <- function(T_site, acc, rho0 = 0.34) {
  k0 <- 11*exp(-10160/(8.314*T_site)); k1 <- 575*exp(-21400/(8.314*T_site))
  z55 <- (log(.55/(.917-.55)) - log(rho0/(.917-rho0)))/(.917*k0)
  function(z) vapply(z, function(q) {
    Z <- if (q <= z55) exp(.917*k0*q + log(rho0/(.917-rho0)))
         else exp(.917*k1*(q - z55)/sqrt(acc) + log(.55/(.917-.55)))
    .917*Z/(1+Z) }, 0) }
dG <- hl(242.0, 0.230); dK <- hl(228.6, 0.064)
cG <- cp_ice(242.0);    cK <- cp_ice(228.6)

gr  <- read_csv("../Greenland2026/data/fig3_greenland_b.csv", show_col_types = FALSE)
h03 <- read_csv("../KohnenRecords_Analyse/data/fig3_head03_b.csv", show_col_types = FALSE)
h02 <- read_csv("../KohnenRecords_Analyse/data/fig3_head02_b.csv", show_col_types = FALSE)

dat <- bind_rows(
  gr  |> transmute(head = "GRIP, double chain", rho = dG(depth_m)*1000, b, se, depth_m),
  h03 |> transmute(head = "Kohnen B50, head03", rho = dK(depth_m)*1000, b, se, depth_m),
  h02 |> transmute(head = "Kohnen B46, head02", rho = dK(depth_m)*1000, b, se, depth_m)) |>
  filter(abs(b)/se > 2 | grepl("B46", head))
dat$head <- factor(dat$head, c("Kohnen B50, head03", "GRIP, double chain", "Kohnen B46, head02"))
cols <- setNames(c(BLUE, AQUA, ORANGE), levels(dat$head))

th <- function(r, c) (1 - r/917)/(r*c)*1e5
h2 <- dat |> filter(grepl("B46", head))
off <- weighted.mean(h2$b - th(h2$rho, cK), 1/h2$se^2)
dat <- dat |> mutate(frei = grepl("B46", head), b_adj = ifelse(frei, b - off, b))

curve <- data.frame(rho = seq(300, 830, 2)) |>
  mutate(Kohnen = th(rho, cK), GRIP = th(rho, cG)) |>
  tidyr::pivot_longer(c(Kohnen, GRIP), names_to = "site", values_to = "b")

pd <- ggplot(dat, aes(rho, b_adj, colour = head)) +
  geom_line(data = curve, aes(rho, b, linetype = site), colour = GREY,
            linewidth = 0.5, inherit.aes = FALSE) +
  geom_errorbar(aes(ymin = b_adj - se, ymax = b_adj + se), width = 0, linewidth = 0.5) +
  geom_point(aes(shape = frei), size = 2.6) +
  scale_shape_manual(values = c(16, 1), guide = "none") +
  scale_colour_manual(values = cols, name = NULL) +
  scale_linetype_manual(values = c("22", "solid"), name = "φ/(ρ c)") +
  scale_x_continuous("Firn density (kg/m³)", breaks = seq(300, 800, 100)) +
  scale_y_continuous("slope  ΔT/Δp  (mK/hPa)") +
  theme_bw(base_size = 13) + theme(legend.position = "bottom", legend.box = "vertical",
                                   legend.margin = margin(0,0,0,0))

ggsave("fig4_slope_density_bare.png", pd, width = 7.4, height = 5.6, dpi = 200, bg = "white")
ggsave("fig4_slope_density.png",
       pd + labs(subtitle = "The slope falls as the firn gets denser"),
       width = 7.4, height = 5.8, dpi = 200, bg = "white")
## Variante ganz ohne Modellkurve — nur die Beobachtung
ggsave("fig4_slope_density_dataonly.png",
       ggplot(dat, aes(rho, b_adj, colour = head)) +
         geom_errorbar(aes(ymin = b_adj - se, ymax = b_adj + se), width = 0, linewidth = 0.5) +
         geom_point(aes(shape = frei), size = 2.6) +
         scale_shape_manual(values = c(16, 1), guide = "none") +
         scale_colour_manual(values = cols, name = NULL) +
         scale_x_continuous("Firn density (kg/m³)", breaks = seq(300, 800, 100)) +
         scale_y_continuous("slope  ΔT/Δp  (mK/hPa)") +
         theme_bw(base_size = 13) + theme(legend.position = "bottom"),
       width = 7.4, height = 5.4, dpi = 200, bg = "white")
cat(sprintf("Dichtebereich der Punkte: %.0f bis %.0f kg/m3; head02-Versatz %.4f mK/hPa\n",
            min(dat$rho), max(dat$rho), off))
