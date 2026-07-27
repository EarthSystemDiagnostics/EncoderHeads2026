library(readr)
library(dplyr)
library(tidyr)
library(ggplot2)
library(lubridate)
library(patchwork)

d <- read_csv("./data/decoded_head04_231710_combined.csv", show_col_types = FALSE) |>
  mutate(time_utc = as_datetime(time_utc))

# ---- Node metadata (adjust depths once known) ----
n_nodes <- 11
# Placeholder: evenly spaced 5–200m across 25 total nodes → step ~8.1m
# Only nodes 1–11 decoded due to CSV truncation
depth_step <- (200 - 5) / (25 - 1)
node_depths <- tibble(
  node  = 1:n_nodes,
  depth = round(5 + (1:n_nodes - 1) * depth_step, 1)
)
cat("Assumed depths (placeholder — adjust if known):\n")
print(node_depths)

# ---- Long format NTC1 ----
ntc_long <- d |>
  select(time_utc, matches("^n[0-9]+\\.ntc1_temp_C$")) |>
  pivot_longer(-time_utc, names_to = "sensor", values_to = "temp_C") |>
  mutate(node = as.integer(sub("n(\\d+)\\..*", "\\1", sensor))) |>
  left_join(node_depths, by = "node")

# ---- Plot 1: Time series coloured by depth ----
p1 <- ggplot(ntc_long, aes(time_utc, temp_C,
                            colour = depth, group = node)) +
  geom_line(linewidth = 0.8) +
  scale_colour_viridis_c(option = "plasma", direction = -1,
                         name = "Tiefe (m)\n[Platzhalter]") +
  scale_x_datetime(date_breaks = "2 weeks", date_labels = "%d %b") +
  labs(title = "head04 (231710): NTC1 Temperaturen nach Tiefe",
       subtitle = "Oberflaechennah (n1, n2): saisonales Signal | Tief (n9-n11): quasi konstant",
       x = NULL, y = "Temperatur (°C)") +
  theme_minimal(base_size = 13)

# ---- Plot 2: Depth profiles at selected dates ----
profile_dates <- d |>
  pull(time_utc) |>
  as.Date() |>
  unique() |>
  (\(x) x[seq(1, length(x), length.out = 6)])() |>
  as.character()

profiles <- ntc_long |>
  mutate(date = as.character(as.Date(time_utc))) |>
  filter(date %in% profile_dates)

p2 <- ggplot(profiles, aes(temp_C, depth,
                            colour = date, group = date)) +
  geom_path(linewidth = 1, alpha = 0.9) +
  geom_point(size = 2) +
  scale_y_reverse(name = "Tiefe (m) [Platzhalter]") +
  scale_colour_viridis_d(option = "turbo", name = "Datum") +
  labs(title = "Temperaturprofile zu verschiedenen Zeitpunkten",
       subtitle = "Obere Nodes zeigen saisonale Abkuehlung, tiefe Nodes stabil",
       x = "Temperatur (°C)", y = "Tiefe (m) [Platzhalter]") +
  theme_minimal(base_size = 13)

# ---- Plot 3: Variability vs depth ----
node_stats <- ntc_long |>
  group_by(node, depth) |>
  summarise(mean_T = mean(temp_C, na.rm = TRUE),
            sd_T   = sd(temp_C,   na.rm = TRUE),
            range_T = max(temp_C, na.rm=TRUE) - min(temp_C, na.rm=TRUE),
            .groups = "drop")

p3 <- ggplot(node_stats, aes(sd_T, depth)) +
  geom_path(colour = "grey60", linewidth = 0.6) +
  geom_point(aes(colour = sd_T), size = 4) +
  geom_text(aes(label = paste0("n", node)), hjust = -0.3, size = 3.2) +
  scale_colour_viridis_c(option = "plasma", direction = -1, guide = "none") +
  scale_y_reverse(name = "Tiefe (m) [Platzhalter]") +
  scale_x_log10() +
  labs(title = "Temperaturvariabilitaet vs. Tiefe",
       subtitle = "Log-Skala: Daempfung des Oberflaechensignals mit der Tiefe",
       x = "Standardabweichung (°C, log-Skala)") +
  theme_minimal(base_size = 13)

# ---- testSB: reference channel check ----
sb_long <- d |>
  select(time_utc, matches("testSB")) |>
  pivot_longer(-time_utc, names_to = "sensor", values_to = "value") |>
  mutate(node = as.integer(sub("n(\\d+)\\..*", "\\1", sensor)))

p4 <- ggplot(sb_long, aes(time_utc, value, colour = factor(node), group = node)) +
  geom_line(linewidth = 0.6, alpha = 0.8) +
  scale_x_datetime(date_breaks = "2 weeks", date_labels = "%d %b") +
  labs(title = "testSB Kanal (Referenzmessung)",
       subtitle = "Quasi-konstant pro Node = Kalibrierungsreferenz, kein physikalisches Signal",
       x = NULL, y = "Wert (counts/1000)", colour = "Node") +
  theme_minimal(base_size = 13)

# Save
(p1 | p3) / (p2 | p4)
ggsave("./data/plot_head04.png", width = 16, height = 11, dpi = 150)
cat("Gespeichert: data/plot_head04.png\n")
