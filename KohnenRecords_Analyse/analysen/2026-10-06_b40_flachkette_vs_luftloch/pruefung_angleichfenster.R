suppressPackageStartupMessages({library(dplyr); library(readr); library(tidyr)})
setwd("/Users/tlaepple/data/EncoderHeads2026"); options(width=200)
h4 <- read_csv("KohnenRecords_Analyse/data/decoded_head04_231710_combined.csv", show_col_types=FALSE) |>
  mutate(time_utc=as.POSIXct(time_utc,tz="UTC")) |> arrange(time_utc)
T <- function(n) (h4[[sprintf("n%d.ntc1_temp_C",n)]]+h4[[sprintf("n%d.ntc2_temp_C",n)]])/2
d <- tibble(t=h4$time_utc, td=as.numeric(difftime(h4$time_utc,min(h4$time_utc),units="days")),
  L1=T(1),L2=T(2),L5=T(3),L8=T(4),L10=T(5),L13=T(6),L16=T(7),S1=T(21),S14=T(22),S19=T(23),S29=T(24),S59=T(25))
sdt <- function(x, td) { dt <- diff(td); dx <- diff(x); ok <- dt>0.5 & dt<1.5; sd(dx[ok])/sqrt(2)*1000 }
tab <- function(dd, lab) dd |> summarise(across(c(L1,L2,L5,L8,L10,L13,L16,S1,S14,S19,S29,S59), ~round(sdt(.x, td),1))) |> mutate(Satz=lab, .before=1)
cat("sigma_Tag (mK), Tagesdifferenzen nur bei 1-Tages-Abstand:\n")
print(as.data.frame(bind_rows(tab(d,"ganzer Record"), tab(d |> filter(td>=30),"ab Tag 30 (17.02.)"), tab(d |> filter(td>=60),"ab Tag 60 (19.03.)"), tab(d |> filter(td<30),"nur Tage 0-29"))), row.names=FALSE)
cat("\nGroesste Tagesspruenge S59 (mK) mit Datum:\n")
x <- d |> mutate(dS59=(S59-lag(S59))*1000, dt=td-lag(td)) |> filter(dt<1.5) |> arrange(-abs(dS59)) |> slice(1:8) |> select(t,dS59,S59)
print(as.data.frame(x |> mutate(dS59=round(dS59,1), S59=round(S59,3))), row.names=FALSE)
cat("\nS59 Tag-fuer-Tag 17.02.-10.03.:\n")
print(as.data.frame(d |> filter(t>=as.POSIXct("2026-02-17",tz="UTC"), t<=as.POSIXct("2026-03-10",tz="UTC")) |> transmute(t=format(t,"%d.%m"), S59=round(S59,3), S29=round(S29,3), S19=round(S19,2), n25_ntc1=round(h4$n25.ntc1_temp_C[match(t, format(h4$time_utc,"%d.%m"))],3))), row.names=FALSE)
