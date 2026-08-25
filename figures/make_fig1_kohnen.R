suppressMessages({library(dplyr);library(tidyr);library(lubridate);library(readr);library(zoo)
                  library(ggplot2);library(patchwork)})
# Aus figures/ aufrufen:  Rscript make_fig1_kohnen.R
setwd("../KohnenRecords_Analyse")
SP <- "."   # Ausgabe in figures/
BLUE <- "#2a78d6"; ORANGE <- "#eb6834"; RED <- "#e34948"; GREY <- "#52514e"; SURF <- "#fcfcfb"

## --- Daten ------------------------------------------------------------------
d3   <- read_csv("data/decoded_head03_231709_combined.csv", show_col_types=FALSE) |>
  mutate(time_utc = as_datetime(time_utc))
dep3 <- read_csv("data/head03_depths.csv", show_col_types=FALSE)
load("/Users/tlaepple/data/t4m_ms26/data/processed/AWS9_daily.RData")
aws <- daily |> transmute(date=as.Date(day), t=t2m) |> filter(is.finite(t))
era <- readRDS("/Users/tlaepple/data/antwarm26/experiments/era5_legacy_merged.rds") |>
  transmute(date=as.Date(date), t=as.vector(t2m)) |> filter(is.finite(t))
ov <- inner_join(aws|>rename(ta=t), era|>rename(te=t), by="date") |> mutate(mon=month(date))
pr <- seq(0.005,0.995,0.005)
qm <- lapply(1:12, function(m){d<-ov|>filter(mon==m); if(nrow(d)<60) return(NULL)
  list(qm=quantile(d$te,pr,na.rm=TRUE), qo=quantile(d$ta,pr,na.rm=TRUE))})
era <- era |> mutate(mon=month(date), tq={o<-rep(NA_real_,n())
  for(m in 1:12){k<-which(mon==m);q<-qm[[m]];if(length(k)&&!is.null(q))o[k]<-approx(q$qm,q$qo,xout=t[k],rule=2)$y};o},
  doy=pmin(yday(date),365))
cr <- era |> filter(year(date)>=1979, year(date)<=2021) |> group_by(doy) |>
  summarise(m=mean(tq), s=sd(tq), .groups="drop") |> arrange(doy)
np<-15; cl <- bind_rows(cr|>slice_tail(n=np)|>mutate(doy=doy-365),cr,cr|>slice_head(n=np)|>mutate(doy=doy+365)) |>
  mutate(clim_mean=as.vector(rollmean(m,31,fill=NA,align="center")),
         clim_sd=as.vector(rollmean(s,31,fill=NA,align="center"))) |> filter(doy>=1,doy<=365)|>
  select(doy,clim_mean,clim_sd)

n1 <- d3 |> mutate(date=as.Date(time_utc)) |> group_by(date) |>
  summarise(T=mean(n1.ntc1_temp_C,na.rm=TRUE), .groups="drop") |>
  mutate(doy=pmin(yday(date),365)) |> left_join(cl,by="doy") |>
  mutate(a=(T-clim_mean)/clim_sd)
e <- !is.na(n1$a)&n1$a>2; r <- rle(e); n1$hw <- e & rep(r$lengths,r$lengths)>=3
rib <- cl |> filter(doy>=min(n1$doy), doy<=max(n1$doy)) |> mutate(date=as.Date("2026-01-01")+doy-1)

## --- Panel A: Atmosphäre -----------------------------------------------------
hw <- n1 |> filter(hw)
pA <- ggplot(n1, aes(date,T)) +
  geom_ribbon(data=rib, aes(x=date,ymin=clim_mean-2*clim_sd,ymax=clim_mean+2*clim_sd),
              fill=BLUE, alpha=0.13, inherit.aes=FALSE) +
  geom_line(data=rib, aes(date,clim_mean), colour=GREY, linewidth=0.4, linetype="22", inherit.aes=FALSE) +
  geom_line(colour=BLUE, linewidth=0.6) +
  geom_line(data=hw, colour=ORANGE, linewidth=1.6, lineend="round") +
  annotate("segment", x=as.Date("2026-06-10"), xend=as.Date("2026-06-28"),
           y=-27.5, yend=-30.5, colour=ORANGE, linewidth=0.4) +
  annotate("text", x=as.Date("2026-06-09"), y=-27, hjust=1, size=3.6, colour=ORANGE, lineheight=0.95,
           label="Wärmeereignis 30.06.–02.07.\nbis +22 K über dem Mittel") +
  annotate("text", x=as.Date("2026-02-20"), y=-63, hjust=0, size=3.2, colour=GREY,
           label="Band: ±2σ der Klimatologie 1979–2021 (ERA5, an AWS9 quantil-korrigiert)") +
  scale_x_date(NULL, date_breaks="1 month", date_labels="%b", expand=c(0.01,0)) +
  scale_y_continuous("Lufttemperatur (°C)", breaks=seq(-70,-20,10)) +
  labs(title="Was an Kohnen passiert — und was wir davon messen",
       subtitle="A · Atmosphäre: Tagesmittel 2026 gegen die Klimatologie") +
  theme_minimal(base_size=12) +
  theme(panel.grid.minor=element_blank(), panel.grid.major.x=element_blank(),
        plot.title=element_text(face="bold", size=15),
        plot.subtitle=element_text(colour=GREY, margin=margin(b=6)))

## --- Panel B: Firn (standardisierte Anomalie, regelmäßiges Tiefengitter) -----
nB <- dep3 |> filter(chain=="C25.4.B (10 m, Schnee)")
firn <- lapply(seq_len(nrow(nB)), function(i){
  v <- rowMeans(cbind(d3[[sprintf("n%d.ntc1_temp_C",nB$node[i])]],
                      d3[[sprintf("n%d.ntc2_temp_C",nB$node[i])]]), na.rm=TRUE)
  tibble(date=as.Date(d3$time_utc), depth=nB$depth_m[i], T=v)}) |> bind_rows() |>
  group_by(depth,date) |> summarise(T=mean(T,na.rm=TRUE), .groups="drop") |>
  group_by(depth) |> mutate(z=(T-mean(T,na.rm=TRUE))/sd(T,na.rm=TRUE)) |> ungroup()
grid <- seq(0.2, 10, by=0.1)
fs <- split(firn |> filter(is.finite(z)), firn$date[is.finite(firn$z)])
firn_i <- bind_rows(lapply(fs, function(d) {
  if (nrow(d) < 5) return(NULL)
  d <- d[order(d$depth), ]
  tibble(date = d$date[1], depth = grid, z = approx(d$depth, d$z, xout = grid, rule = 2)$y)
}))
pB <- ggplot(firn_i, aes(date, depth, fill=z)) +
  geom_raster(interpolate=TRUE) +
  scale_fill_gradient2(name="standardisiert", low=BLUE, mid="#f0efec", high=RED,
                       midpoint=0, limits=c(-2,2), oob=scales::squish,
                       breaks=c(-2,0,2), labels=c("kalt","", "warm")) +
  scale_y_reverse("Tiefe im Firn (m)", breaks=c(0.2,2,4,6,8,10), expand=c(0,0)) +
  scale_x_date(NULL, date_breaks="1 month", date_labels="%b", expand=c(0,0)) +
  labs(subtitle="B · Firn 0,2–10 m: dieselbe Welle wandert nach unten, gedämpft und verzögert") +
  theme_minimal(base_size=12) +
  theme(panel.grid=element_blank(), plot.subtitle=element_text(colour=GREY, margin=margin(b=6)),
        legend.key.width=unit(0.45,"cm"), legend.key.height=unit(0.8,"cm"))

## --- Panel C: Variabilität gegen Tiefe (je Kette getrennt) -------------------
amp <- lapply(seq_len(nrow(dep3)), function(i){
  if (is.na(dep3$depth_m[i])) return(NULL)
  v <- rowMeans(cbind(d3[[sprintf("n%d.ntc1_temp_C",dep3$node[i])]],
                      d3[[sprintf("n%d.ntc2_temp_C",dep3$node[i])]]), na.rm=TRUE)
  tibble(depth=dep3$depth_m[i], sd=sd(v,na.rm=TRUE), chain=dep3$chain[i])}) |> bind_rows()
pC <- ggplot(amp, aes(sd, depth, group=chain)) +
  geom_path(colour=GREY, linewidth=0.3, alpha=0.45) +
  geom_point(colour=BLUE, size=2.2) +
  annotate("text", x=0.0035, y=45, hjust=0, size=3.3, colour=GREY, lineheight=0.95,
           label="unter 30 m:\nSignal < 10 mK") +
  scale_y_continuous("Tiefe (m)", trans=scales::compose_trans("log10","reverse"),
                     breaks=c(0.2,1,3,10,30,62)) +
  scale_x_log10("Jahresvariabilität (K)", breaks=c(0.001,0.01,0.1,1,10),
                labels=c("0,001","0,01","0,1","1","10")) +
  labs(subtitle="C · bis 62 m Tiefe") +
  theme_minimal(base_size=12) +
  theme(panel.grid.minor=element_blank(), plot.subtitle=element_text(colour=GREY, margin=margin(b=6)))

fig <- pA / (pB + pC + plot_layout(widths=c(2,1))) + plot_layout(heights=c(1,1.05)) &
  theme(plot.background=element_rect(fill=SURF, colour=NA))
ggsave(file.path("../figures", "fig1_kohnen.png"), fig, width=11, height=8.2, dpi=200, bg=SURF)
hw2 <- n1 |> filter(hw) |> mutate(dK = T - clim_mean)
cat(sprintf("HW: %s .. %s | T %.1f..%.1f | Klima %.1f | Anomalie %.1f..%.1f K | sigma %.2f..%.2f\n",
  format(min(hw2$date)), format(max(hw2$date)), min(hw2$T), max(hw2$T),
  mean(hw2$clim_mean), min(hw2$dK), max(hw2$dK), min(hw2$a), max(hw2$a)))
cat("ok\n")
