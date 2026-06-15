library(readr)
library(dplyr)
library(tidyr)
library(ggplot2)
library(patchwork)
library(lubridate)

d03 <- read_csv("./data/decoded_head03_231709.csv", show_col_types = FALSE)
d10 <- read_csv("./data/decoded_head04_231710.csv", show_col_types = FALSE)

# head03 NTC1 temps long format
ntc_long <- d03 %>%
  select(time_utc, matches("^n[0-9]+\\.ntc1_temp_C$")) %>%
  pivot_longer(-time_utc, names_to = "sensor", values_to = "temp_C") %>%
  mutate(node = as.integer(sub("n(\\d+)\\..*", "\\1", sensor)))

p1 <- ggplot(ntc_long, aes(time_utc, temp_C, colour = factor(node), group = node)) +
  geom_line(alpha = 0.8) +
  labs(title = "head03 (231709): NTC1 Temperaturen n1–n15",
       x = "Zeit (UTC)", y = "°C", colour = "Node") +
  theme_minimal()

# head03 pressure
pres_long <- d03 %>%
  select(time_utc, matches("\\.pressure_hPa$")) %>%
  pivot_longer(-time_utc, names_to = "sensor", values_to = "pressure_hPa") %>%
  mutate(node = as.integer(sub("n(\\d+)\\..*", "\\1", sensor)))

p2 <- ggplot(pres_long, aes(time_utc, pressure_hPa, colour = factor(node), group = node)) +
  geom_line(alpha = 0.7) +
  labs(title = "head03: Druck alle Sensoren",
       x = "Zeit (UTC)", y = "hPa", colour = "Node") +
  theme_minimal()

# head03 ADC logger temperature
p3 <- ggplot(d03, aes(time_utc, adc_temp_C)) +
  geom_line(colour = "steelblue") +
  labs(title = "head03: ADC Temperatur (Logger)",
       x = "Zeit (UTC)", y = "°C") +
  theme_minimal()

# head04 NTC1 temps
ntc_long10 <- d10 %>%
  select(time_utc, matches("^n[0-9]+\\.ntc1_temp_C$")) %>%
  pivot_longer(-time_utc, names_to = "sensor", values_to = "temp_C") %>%
  mutate(node = as.integer(sub("n(\\d+)\\..*", "\\1", sensor)))

p4 <- ggplot(ntc_long10, aes(time_utc, temp_C, colour = factor(node), group = node)) +
  geom_line(alpha = 0.8) +
  labs(title = "head04 (231710): NTC1 Temperaturen n1–n11",
       x = "Zeit (UTC)", y = "°C", colour = "Node") +
  theme_minimal()

combined <- (p1 / p2) | (p3 / p4)
ggsave("./data/plots_results3.png", combined, width = 16, height = 10, dpi = 150)
cat("Plot gespeichert: data/plots_results3.png\n")
