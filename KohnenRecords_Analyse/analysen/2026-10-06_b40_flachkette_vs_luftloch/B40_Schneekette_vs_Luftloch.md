# B40 (Kohnen): flache 10-m-Kette im Schnee gegen die oberen Sensoren der 200-m-Kette im offenen Bohrloch, verglichen mit dem GRIP-Doppelketten-Experiment

Stand 06.10.2026, Thomas Laepple (AWI). Analyse: `EncoderHeads2026/KohnenRecords_Analyse/analysen/2026-10-06_b40_flachkette_vs_luftloch/`.

## Aufbau und Daten

**B40 (head04, Modem 231710).** Zwei Ketten am selben Kopf: die Bohrlochkette n1–n20 im offenen, luftgefüllten Loch (Ø 12 cm, gebohrt 2013, 1–201 m; oberste Knoten bei 1, 2, 5, 8, 10, 13, 16 m) und eine flache 10-m-Kette n21–n25 im Schnee (nominal 1 / 1,4 / 1,9 / 2,9 / 5,9 m; Tiefen aus der Kalibrierdatei, nicht eingemessen). Ein Profil pro Tag (17:38 UTC), Record 18.01.–13.08.2026, 203 Profile. Kalibrierung: Lab-S4 pro Sensor (2023).

**GRIP Doppelkette (IMEI 301434062008130).** Zwei Ketten mit identischer Tiefenbelegung (1/3/5/8/10/13/16/21/26/30 m) in zwei frisch gebohrten Löchern 10 m voneinander entfernt, eingebaut 08.07.2026: Kette 1 im offenen Luftloch, Kette 2 schneeverfüllt. Ein Profil pro Tag (15:13 UTC). Ausgewertet ab 29.07. (drei Wochen nach Einbau) bis 28.09.2026, 62 Profile. Kalibrierung: universelle Mean-S4-Kurve.

**Metrik.** Tag-zu-Tag-Streuung σ_Tag = sd(T(t+1 d) − T(t)) / √2 je Knoten. Das Instrumentenniveau gibt das Replikat-Rauschen der beiden Thermistoren desselben Knotens, sd(NTC1 − NTC2) / √2. Die Streuung einer Zeitreihe um sich selbst ist unabhängig von Kalibrieroffsets; die Mitteldifferenz zweier Knoten ist es nicht.

## B40: Tag-zu-Tag-Streuung Luft gegen Schnee

Ganzer Record, in mK:

| Tiefe | Luft (200-m-Loch) | Schnee (10-m-Kette) | Verhältnis | Replikat Luft / Schnee |
|---|---|---|---|---|
| 1 m | 84 | 69 | 1,2 | 0,8 / 3,7 |
| 2 m / 1,9 m | 63 | 41 | 1,5 | 1,0 / 1,1 |
| 2,9 m | – | 30 | – | – / 0,6 |
| 5 m / 5,9 m | 98 | 10 | 9,8 | 0,2 / 0,8 |
| 8 m | 77 | – | – | 0,2 |
| 10 m | 75 | – | – | 0,2 |
| 13 m | 61 | – | – | 0,1 |
| 16 m | 49 | – | – | 0,1 |

Winterfenster 01.05.–30.06.2026 (Polarnacht, flache Oberflächentrends): Luftkette bei 8–10 m 109–113 mK, Schneekette bei 2,9 m 9 mK und bei 5,9 m 3,4 mK. Das Replikat-Rauschen bleibt überall unter 4 mK; die Unruhe ist physikalisch.

Nach Abzug des druckgetriebenen Anteils b·dp/dt (Druck aus B50, Koeffizienten aus `b40_druckschwankungen.qmd`) sinkt σ_Tag der Luftkette bei 5–16 m auf 25–71 mK, etwa die Hälfte.

**Paare gleicher Tiefe.** Bei 1 m folgen beide Ketten derselben Oberflächenwelle: Spanne 15,5 K (Luft) gegen 15,1 K (Schnee), Kreuzkorrelation 0,999 ohne Verzug, Korrelation der Tagesdifferenzen 0,83. Bei 5 m / 5,9 m ist die Kopplung der Tagesdifferenzen weg (r = 0,16). Die Mitteldifferenz Luft − Schnee driftet vom ersten zum letzten Monat des Records von −0,41 K auf +0,26 K (5 m / 5,9 m) und von +0,35 K auf −0,11 K (2 m / 1,9 m). Ein fester Offset, wie ihn eine Kalibrierdifferenz erzeugen würde, liegt nicht vor; die Luftkette gibt oberhalb ~6 m die Firntemperatur der jeweiligen Tiefe nicht wieder.

## Vergleich mit GRIP

σ_Tag in mK, GRIP ab 29.07.2026:

| Tiefe | GRIP Luft | GRIP Schnee | Verhältnis GRIP | Verhältnis B40 |
|---|---|---|---|---|
| 1 m | 82 | 74 | 1,1 | 1,2 |
| 3 m | 241 | 20 | 12 | – |
| 5 m | 199 | 2,8 | 71 | 9,8 (5 / 5,9 m) |
| 8 m | 19 | 2,2 | 8,6 | – |
| 10 m | 6,1 | 1,4 | 4,3 | – |
| 16 m | 24 | 0,1 | 219 | – |

- Bei 1 m sind beide Experimente gleich: Luft ≈ Schnee, Verhältnis 1,1–1,2. Dort misst auch das Luftloch das Oberflächensignal.
- Unterhalb 8 m ist das Luftloch an B40 unruhiger als an GRIP: 49–77 mK gegen 6–27 mK, im Winter bis 113 mK. B40 ist 200 m tief (GRIP 30 m) und seit 2013 offen; die Luftsäule unter dem Sensor ist siebenfach länger, der Druckanteil trägt etwa die Hälfte. An GRIP fällt die Unruhe von 3–5 m (200–250 mK) zu 8–10 m auf 6–19 mK ab; an B40 bleibt sie zwischen 5 und 16 m bei 50–100 mK.
- Die Schneeketten verhalten sich gleich: GRIP 5 m 2,8 mK, B40 5,9 m 10 mK (σ_Tag); als Residuum um einen glatten Jahresgang 0,3 gegen 1,5 mK. Der Rest an B40 ist der Jahresgang bei Kohnen (Spanne 1,7 K bei 5,9 m über Januar–August), kein Rauschen.

## Folgerungen

1. Für Profil- und Jahresgangfragen an B40 sind die Knoten 1–3 der Luftkette (1–5 m) durch die Schneekette (n21–n25) zu ersetzen.
2. Ab 8 m gibt es an B40 keine Schnee-Referenz. Dort ist die Druckkorrektur die einzige Handhabe; sie lässt 25–47 mK Tagesunruhe stehen.
3. Der GRIP-Befund (Bohrlöcher für Firntemperatur-Messungen verfüllen) wird an B40 bestätigt, in der Tiefe mit größerem Faktor.
