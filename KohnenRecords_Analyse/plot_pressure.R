library(readr)
library(dplyr)
library(tidyr)
library(ggplot2)
library(lubridate)

d <- read_csv("./data/decoded_head03_231709.csv", show_col_types = FALSE) |>
  mutate(time_utc = as_datetime(time_utc))

# Only plausible sensors (n1-n11, values 620-740 hPa)
pres_long <- d |>
  select(time_utc, matches("^n([1-9]|1[01])\\.pressure_hPa$")) |>
  pivot_longer(-time_utc, names_to = "sensor", values_to = "pressure_hPa") |>
  mutate(
    node = as.integer(sub("n(\\d+)\\..*", "\\1", sensor)),
    sensor = paste0("n", node)
  ) |>
  filter(pressure_hPa >= 620, pressure_hPa <= 750)

p <- ggplot(pres_long, aes(time_utc, pressure_hPa,
                            colour = factor(node), group = node)) +
  geom_line(linewidth = 0.7, alpha = 0.85) +
  scale_colour_viridis_d(option = "turbo", name = "Node") +
  scale_x_datetime(date_breaks = "2 weeks", date_labels = "%d %b") +
  labs(
    title    = "Luftdruck — head03 (Modem 231709), Nodes n1–n11",
    subtitle = "Kohnen 2026  |  Nodes n12–n15 ausgeblendet (Sensorfehler)",
    x        = "Zeit (UTC)",
    y        = "Druck (hPa)"
  ) +
  theme_minimal(base_size = 13) +
  theme(legend.position = "right")

ggsave("./data/plot_pressure.png", p, width = 12, height = 6, dpi = 150)
cat("Gespeichert: data/plot_pressure.png\n")
