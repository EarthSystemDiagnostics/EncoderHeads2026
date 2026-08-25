# figures/ — Präsentationsgrafiken

Zwei Abbildungen für Vorträge/Direktion, mit den Skripten, die sie erzeugen.
Aufruf aus diesem Ordner: `Rscript make_fig1_kohnen.R` bzw. `Rscript make_fig2_netzwerk.R`.

## fig1_kohnen.png — „Was an Kohnen passiert, und was wir davon messen"

Ein Winter an Kohnen, gemessen von der Luft bis 62 m Tiefe. **(A)** Tagesmittel der
Lufttemperatur 2026 gegen die Klimatologie 1979–2021 (Band = ±2σ; ERA5, mit den
Stationsdaten der AWS9 quantil-korrigiert). Ende Juni erreicht ein Warmluftvorstoß
**bis +22 K über dem Mittel**. **(B)** Derselbe Vorstoß im 2-m-Schacht: die Wärme dringt
in den Schnee ein — nach zwei Tagen steht sie bei 0,8 m, nach zehn bei 1,5 m, gedämpft
von 12 K auf 2 K. **(C)** Auf der Jahresskala dasselbe Prinzip: die Sommerwärme von
Januar/Februar wandert nach unten und erreicht **im Winter 6–8 m Tiefe** (standardisiert
je Tiefe, sonst wäre die Welle unterhalb weniger Meter unsichtbar). **(D)** Über die
gesamte Kette fällt die Jahresvariabilität um **vier Größenordnungen**, von 10 K an der
Oberfläche auf unter 10 mK unterhalb 30 m.

**Warum die oberen 10–20 m zählen:** Dort entsteht das Eiskernarchiv. Die
Firntemperatur steuert die Isotopendiffusion und den Dampftransport, die das Klimasignal
nach der Ablagerung noch verändern; sie steuert die Verdichtung, von der Close-off-Tiefe,
Eis-Gas-Altersdifferenz und die Umrechnung von Satelliten-Höhenänderungen in Massenbilanz
abhängen; und sie ist die obere Randbedingung, ohne die sich aus dem tiefen Bohrlochprofil
keine Oberflächentemperatur-Geschichte invertieren lässt. Zugleich ist sie ein
tiefpassgefiltertes Integral der Oberflächenenergiebilanz — ein strengerer Modelltest als
jede Lufttemperaturmessung (die Reanalyse ERA5 liegt hier im Winter um +4,6 K daneben). An
Kohnen entsprechen 10 m rund 60 und 20 m rund 140 Jahren. Und anders als ein tiefes
Bohrloch ist dieser Tiefenbereich billig, wiederholbar und damit **netzwerkfähig**.

Alle Daten aus einem autonomen System (35 Sensoren, tägliche Satellitenübertragung); die
weiße Lücke Anfang März ist ein Übertragungsausfall.

Datenquellen: `KohnenRecords_Analyse/data/decoded_head03_231709_combined.csv`,
`data/head03_depths.csv`, ERA5 (`antwarm26/experiments/era5_legacy_merged.rds`),
AWS9 (`t4m_ms26/data/processed/AWS9_daily.RData`), Tiefen-Alter aus
`sharedAI/AWS_Wetterstation_Entwicklung/daten/accum_stats.csv`.

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
