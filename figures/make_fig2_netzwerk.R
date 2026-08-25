# Aus figures/ aufrufen:  Rscript make_fig2_netzwerk.R
suppressMessages({library(dplyr);library(readr);library(ggplot2);library(sf)
                  library(rnaturalearth)})
SP <- "."   # Ausgabe in figures/
BLUE <- "#2a78d6"; ORANGE <- "#eb6834"; GREY <- "#52514e"; SURF <- "#fcfcfb"
PS <- "+proj=stere +lat_0=-90 +lat_ts=-71 +lon_0=0 +datum=WGS84 +units=m"

ant <- ne_countries(scale="medium", continent="Antarctica", returnclass="sf") |> st_transform(PS)
wp <- read_csv("/Users/tlaepple/sharedAI/AWS_Wetterstation_Entwicklung/daten/accum_stats.csv",
               show_col_types=FALSE) |> select(Name, lat=Latitude, lon=Longitude)
wp_sf <- st_as_sf(wp, coords=c("lon","lat"), crs=4326) |> st_transform(PS)
route <- st_sf(geometry=st_sfc(st_linestring(st_coordinates(wp_sf)), crs=PS))
key <- wp_sf |> filter(Name %in% c("NMIII","Kohnen","FD83","Dome-C","MZS/Jang-Bogo")) |>
  mutate(lab=recode(Name, NMIII="Neumayer III", `MZS/Jang-Bogo`="Mario Zucchelli /\nJang Bogo",
                    `Dome-C`="Dome C", FD83="FD83"))
kohnen <- key |> filter(Name=="Kohnen")
xy <- function(s) as.data.frame(st_coordinates(s))
kco <- xy(key); kco$lab <- key$lab
kco$hj <- c(1.12, 0.5, -0.15, -0.15, -0.12)   # NMIII, Kohnen, FD83, DomeC, MZS
kco$vj <- c(0.5, -1.6, 1.6, -0.6, 0.5)

# Sites, an denen bereits gemessen wird (Kohnen) und geplante Netzpunkte (Route)
sites <- wp_sf |> filter(!grepl("^km-", Name))

p <- ggplot() +
  geom_sf(data=ant, fill="#eceae4", colour="#d2cec4", linewidth=0.25) +
  geom_sf(data=route, colour=ORANGE, linewidth=0.9, alpha=0.9) +
  geom_sf(data=sites, colour=ORANGE, fill="white", shape=21, size=2.1, stroke=0.9) +
  geom_sf(data=kohnen, colour=BLUE, size=5.2) +
  geom_sf(data=kohnen, colour="white", size=1.9) +
  geom_text(data=kco, aes(X, Y, label=lab, hjust=hj, vjust=vj), size=3.5, colour=GREY,
            lineheight=0.95) +
  annotate("text", x=-2.35e6, y=1.55e6, hjust=0, size=4.2, colour=BLUE, fontface="bold",
           label="Kohnen: läuft seit 2026") +
  annotate("text", x=-2.35e6, y=1.33e6, hjust=0, size=3.5, colour=GREY, lineheight=1,
           label="35 Sensoren, Luft bis 62 m Tiefe,\nTelemetrie täglich") +
  annotate("text", x=-2.35e6, y=-1.55e6, hjust=0, size=4.2, colour=ORANGE, fontface="bold",
           label="PlateauInSync 2028/29") +
  annotate("text", x=-2.35e6, y=-1.78e6, hjust=0, size=3.5, colour=GREY, lineheight=1,
           label="5 800 km Traverse, ~15 Standorte —\ndasselbe System als Netzwerk") +
  coord_sf(xlim=c(-2.5e6, 2.9e6), ylim=c(-2.3e6, 2.3e6), expand=FALSE) +
  labs(title="Vom Einzelpunkt zum Netzwerk",
       subtitle="Kohnen zeigt, dass es funktioniert — die Traverse macht daraus eine Messkette über den Kontinent") +
  theme_void(base_size=12) +
  theme(plot.title=element_text(face="bold", size=15, margin=margin(b=2)),
        plot.subtitle=element_text(colour=GREY, margin=margin(b=8)),
        plot.background=element_rect(fill=SURF, colour=NA),
        plot.margin=margin(12,12,10,12))
ggsave(file.path(SP, "fig2_netzwerk.png"), p, width=10, height=7.4, dpi=200, bg=SURF)
cat("ok\n")
