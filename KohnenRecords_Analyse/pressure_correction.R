# Druckkorrektur der Temperaturen in luftgefüllten Bohrlöchern (head04/B40, head03/B50-Luftkette).
#
# Modell (b40_druckschwankungen.qmd): T'(z,t) = b(z)·F(t), F = dp/dt + Rest.
# 1. b(z) aus der Regression der hochpassgefilterten Temperatur auf dp/dt.
# 2. Rest = Residuum der Referenztiefen, je durch b geteilt und gemittelt; für jede Tiefe
#    ohne diese Tiefe selbst (leave-one-out), damit keine Tiefe sich selbst korrigiert.
# 3. b neu gegen F angepasst, korrigiert wird T − b·F.
# Ergebnis: data/<head>_pressure_corrected.csv mit denselben Spaltennamen wie die Rohdaten.

suppressMessages(library(dplyr))

tp <- function(x) as.POSIXct(x, format = "%Y-%m-%dT%H:%M:%SZ", tz = "UTC")

correct_chain <- function(t, Tl, depth, dpdt, ref_depths, span = 0.2) {
  # t: POSIXct; Tl: Liste mit Matrizen (Zeit × Knoten) für ntc1/ntc2; dpdt: hPa/Tag
  td <- (as.numeric(t) - as.numeric(t[1])) / 86400
  y  <- (Tl$ntc1 + Tl$ntc2) / 2 * 1000                     # mK, Mittel wie in der Inversion
  hpf <- function(v) { o <- is.finite(v); r <- rep(NA_real_, length(v))
    r[o] <- v[o] - predict(loess(v[o] ~ td[o], span = span)); r }
  r  <- apply(y, 2, hpf)
  b1 <- apply(r, 2, function(v) coef(lm(v ~ dpdt))[2])
  rr <- r - outer(dpdt, b1)
  ref <- which(depth %in% ref_depths)
  out <- lapply(seq_along(depth), function(j) {
    k <- setdiff(ref, j)
    F <- dpdt + rowMeans(sweep(rr[, k, drop = FALSE], 2, b1[k], "/"))
    b <- coef(lm(r[, j] ~ F))[2]
    list(corr = b * F, b = b, F = F) })
  corr <- sapply(out, `[[`, "corr")
  list(corr = corr, b1 = b1, b = sapply(out, `[[`, "b"), r = r, td = td, y = y)
}

# Kennzahlen wie in b40_inversion.qmd: linearer Trend, Fehler AR(1)-korrigiert
trend_stats <- function(x, y) {
  o <- is.finite(y) & is.finite(x); x <- x[o]; y <- y[o]
  s <- summary(lm(y ~ x)); r <- resid(lm(y ~ x)); rho <- cor(r[-1], r[-length(r)])
  n <- length(y); neff <- n * (1 - rho) / (1 + rho)
  c(rate = s$coefficients[2, 1], rse = s$coefficients[2, 2] * sqrt(n / max(neff, 2)), rho = rho)
}

K <- "data/"

## head04 (B40), Druck von B50 ------------------------------------------------
h4 <- read.csv(paste0(K, "decoded_head04_231710_combined.csv")); h4$t <- tp(h4$time_utc)
h3 <- read.csv(paste0(K, "decoded_head03_231709_combined.csv")); h3$t <- tp(h3$time_utc)
d03 <- read.csv(paste0(K, "head03_depths.csv"))
c4  <- unique(read.csv(paste0(K, "head04_calibration.csv"))[, c("node", "depth_m")])
c4  <- c4[c4$node <= 20, ]

P3  <- sapply(d03$node, function(n) h3[[sprintf("n%d.pressure_hPa", n)]])
Tm3 <- sapply(d03$node, function(n) min(h3[[sprintf("n%d.ntc1_temp_C", n)]], na.rm = TRUE))
p3all <- rowMeans(P3[, Tm3 > -45], na.rm = TRUE)
o3 <- order(h3$t); t3 <- as.numeric(h3$t[o3]); p3 <- p3all[o3]
t3 <- t3[is.finite(p3)]; p3 <- p3[is.finite(p3)]

h4 <- h4[order(h4$t), ]; tt <- as.numeric(h4$t)
h4$dpdt <- approx(t3[-1] - diff(t3)/2, diff(p3)/diff(t3) * 86400, tt)$y
ok4 <- is.finite(h4$dpdt)
sel4 <- c4$node[c4$depth_m >= 5]; dep4 <- c4$depth_m[c4$depth_m >= 5]
T4 <- lapply(c(ntc1 = "ntc1", ntc2 = "ntc2"), function(ch)
  sapply(sel4, function(n) h4[[sprintf("n%d.%s_temp_C", n, ch)]][ok4]))
k4 <- correct_chain(h4$t[ok4], T4, round(dep4), h4$dpdt[ok4], ref_depths = c(21, 26, 32, 40, 50, 62))

out4 <- h4
for (j in seq_along(sel4)) for (ch in c("ntc1", "ntc2")) {
  col <- sprintf("n%d.%s_temp_C", sel4[j], ch)
  out4[[col]][ok4] <- out4[[col]][ok4] - k4$corr[, j] / 1000 }
out4$druckkorrigiert <- ok4
write.csv(out4[, setdiff(names(out4), c("t", "dpdt"))], paste0(K, "head04_231710_pressure_corrected.csv"),
          row.names = FALSE)

## head03 (B50), 60-m-Luftkette, eigener Druck ---------------------------------
h3 <- h3[o3, ]; p3o <- p3all[o3]; t3o <- as.numeric(h3$t)
n3 <- length(p3o)
h3$dpdt <- c(NA, (p3o[3:n3] - p3o[1:(n3-2)]) / (t3o[3:n3] - t3o[1:(n3-2)]) * 86400, NA)   # zentriert, 24 h
ok3 <- is.finite(h3$dpdt)
air <- d03[grepl("Luft", d03$chain) & d03$depth_m >= 5, ]
T3 <- lapply(c(ntc1 = "ntc1", ntc2 = "ntc2"), function(ch)
  sapply(air$node, function(n) h3[[sprintf("n%d.%s_temp_C", n, ch)]][ok3]))
k3 <- correct_chain(h3$t[ok3], T3, air$depth_m, h3$dpdt[ok3], ref_depths = c(21, 26, 32, 40, 50, 62))

out3 <- h3
for (j in seq_len(nrow(air))) for (ch in c("ntc1", "ntc2")) {
  col <- sprintf("n%d.%s_temp_C", air$node[j], ch)
  out3[[col]][ok3] <- out3[[col]][ok3] - k3$corr[, j] / 1000 }
out3$druckkorrigiert <- ok3
write.csv(out3[, setdiff(names(out3), c("t", "dpdt"))], paste0(K, "head03_231709_pressure_corrected.csv"),
          row.names = FALSE)

## Kennzahlen ----------------------------------------------------------------
summ <- function(k, depth, t, head) {
  yrs <- (as.numeric(t) - as.numeric(t[1])) / 86400 / 365.25
  bind_rows(lapply(seq_along(depth), function(j) {
    y0 <- k$y[, j]; y1 <- y0 - k$corr[, j]
    s0 <- trend_stats(yrs, y0); s1 <- trend_stats(yrs, y1)
    r1 <- k$r[, j] - k$corr[, j] + mean(k$corr[, j], na.rm = TRUE)
    acf_tau <- function(v) { v <- v[is.finite(v)]; a <- acf(v, lag.max = 60, plot = FALSE)$acf[-1]
                             i <- which(a < exp(-1))[1]; if (is.na(i)) NA else i }
    data.frame(Kopf = head, z = depth[j], b = k$b[j],
               sd_vor = sd(k$r[, j], na.rm = TRUE), sd_nach = sd(r1, na.rm = TRUE),
               rate_vor = s0["rate"], rate_nach = s1["rate"],
               rse_vor = s0["rse"], rse_nach = s1["rse"],
               rho_vor = s0["rho"], rho_nach = s1["rho"],
               tau_vor = acf_tau(k$r[, j]), tau_nach = acf_tau(r1)) }))
}
stats <- bind_rows(summ(k4, dep4, h4$t[ok4], "head04 (B40)"),
                   summ(k3, air$depth_m, h3$t[ok3], "head03 (B50, Luft)"))
write.csv(stats, paste0(K, "pressure_correction_stats.csv"), row.names = FALSE)
