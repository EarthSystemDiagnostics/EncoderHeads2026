library(readr)
library(dplyr)
library(tidyr)
library(ggplot2)
library(lubridate)

d <- read_csv("./data/decoded_head03_231709.csv", show_col_types = FALSE) |>
  mutate(time_utc = as_datetime(time_utc))

# Check ranges
ntc_cols <- grep("^n[0-9]+\\.ntc1_temp_C", names(d), value = TRUE)
for (col in ntc_cols) {
  cat(col, ": min=", round(min(d[[col]], na.rm=TRUE), 1),
      " max=", round(max(d[[col]], na.rm=TRUE), 1),
      " NA=", sum(is.na(d[[col]])), "\n")
}

# Long format: separate atmospheric (n1) from subsurface (n2-n11)
ntc_long <- d |>
  select(time_utc, all_of(ntc_cols)) |>
  pivot_longer(-time_utc, names_to = "sensor", values_to = "temp_C") |>
  mutate(node = as.integer(sub("n(\\d+)\\..*", "\\1", sensor))) |>
  filter(node <= 11)   # n12+ are decoding artifacts from truncated CSV

p <- ggplot() +
  # Subsurface nodes n2-n11 in grey/blue
  geom_line(
    data = filter(ntc_long, node > 1),
    aes(time_utc, temp_C, group = factor(node), colour = factor(node)),
    linewidth = 0.6, alpha = 0.7
  ) +
  # Atmospheric n1 on top, bold red
  geom_line(
    data = filter(ntc_long, node == 1),
    aes(time_utc, temp_C),
    colour = "red", linewidth = 1.1, alpha = 0.9
  ) +
  annotate("text", x = max(d$time_utc), y = filter(ntc_long, node==1) |>
             slice_tail(n=1) |> pull(temp_C),
           label = "Atmosphäre (n1)", colour = "red",
           hjust = 1.05, vjust = -0.5, size = 3.5) +
  scale_colour_viridis_d(option = "viridis", name = "Node (Firn)",
                          labels = paste0("n", 2:11)) +
  scale_x_datetime(date_breaks = "2 weeks", date_labels = "%d %b") +
  labs(
    title    = "Temperaturen — head03 (Modem 231709)",
    subtitle = "Rot: Atmosphäre (n1)  |  Blau: Firn-Nodes n2–n11",
    x        = "Zeit (UTC)",
    y        = "Temperatur (°C)"
  ) +
  theme_minimal(base_size = 13) +
  theme(legend.position = "right")

ggsave("./data/plot_temperatures.png", p, width = 13, height = 6, dpi = 150)
cat("Gespeichert: data/plot_temperatures.png\n")
