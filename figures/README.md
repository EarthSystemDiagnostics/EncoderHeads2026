# figures/ — Präsentationsgrafiken

Zwei Abbildungen für Vorträge/Direktion, mit den Skripten, die sie erzeugen.
Aufruf aus diesem Ordner: `Rscript make_fig1_kohnen.R` bzw. `Rscript make_fig2_netzwerk.R`.

## fig1_kohnen.png — „Was an Kohnen passiert, und was wir davon messen"

Ein Winter an Kohnen, gemessen von der Luft bis 62 m Tiefe. **(A)** Tagesmittel der
Lufttemperatur 2026 gegen die Klimatologie 1979–2021 (Band = ±2σ; ERA5, mit den
Stationsdaten der AWS9 quantil-korrigiert). Ende Juni erreicht ein Warmluftvorstoß
bis **+22 K über dem Mittel** — drei Tage über der 2σ-Schwelle. **(B)** Dieselbe Welle
im Firn: standardisierte Temperaturabweichung zwischen 0,2 und 10 m Tiefe; das
Sommersignal wandert sichtbar nach unten, gedämpft und verzögert. **(C)** Über die
gesamte Kette von 0,2 bis 62 m fällt die Jahresvariabilität um **vier Größenordnungen**,
von 10 K an der Oberfläche auf unter 10 mK unterhalb 30 m — dort steht das Profil für
die Temperaturgeschichte der letzten Jahrhunderte. Alle Daten aus einem autonomen
System (35 Sensoren, tägliche Satellitenübertragung); die weiße Lücke Anfang März ist
ein Übertragungsausfall.

Panel B ist bewusst je Tiefe standardisiert — nur so bleibt die Wellenausbreitung bis
10 m sichtbar; die absoluten Amplituden stehen in Panel C.

Datenquellen: `KohnenRecords_Analyse/data/decoded_head03_231709_combined.csv`,
`data/head03_depths.csv`, ERA5 (`antwarm26/experiments/era5_legacy_merged.rds`),
AWS9 (`t4m_ms26/data/processed/AWS9_daily.RData`).

## fig2_netzwerk.png — „Vom Einzelpunkt zum Netzwerk"

Kohnen ist der Machbarkeitsnachweis, die Traverse macht daraus ein Netzwerk. Blau: das
seit 2026 laufende System an Kohnen — Atmosphäre und Firn bis 62 m, unbeaufsichtigt,
mit täglicher Telemetrie. Orange: die geplante Route der Traverse **PlateauInSync**
(Saison 2028/29, ~5 800 km von Neumayer III über Kohnen und Dome C zur Terra-Nova-Bucht)
mit den vorgesehenen Standorten. Dieselbe Sensorik an jedem dieser Punkte verwandelt
Einzelmessungen in eine durchgehende Messkette über das ostantarktische Plateau — die
Region, aus der die längsten Eiskernarchive stammen und für die bisher fast keine
Firntemperaturzeitreihen existieren.

Datenquelle Route: `sharedAI/AWS_Wetterstation_Entwicklung/daten/accum_stats.csv`.

## Gestaltung

Farbpalette CVD-geprüft (Blau #2a78d6, Orange #eb6834, Rot #e34948 für die divergierende
Skala); Tiefenachsen logarithmisch, wo der Wertebereich mehrere Größenordnungen umfasst.
