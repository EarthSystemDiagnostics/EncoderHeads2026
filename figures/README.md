# figures/ — Präsentationsgrafiken

Zwei Abbildungen für Vorträge/Direktion, mit den Skripten, die sie erzeugen.
Aufruf aus diesem Ordner: `Rscript make_fig1_kohnen.R` bzw. `Rscript make_fig2_netzwerk.R`.

## fig1_kohnen.png — „Was an Kohnen passiert, und was wir davon messen"

Ein Winter an Kohnen, gemessen von der Luft bis in den Firn. **(A)** Tagesmittel der
Lufttemperatur 2026 gegen die Klimatologie 1979–2021 (Band = ±2σ; ERA5, mit den
Stationsdaten der AWS9 quantil-korrigiert). Ende Juni erreicht ein Warmluftvorstoß
**bis +22 K über dem Mittel**. **(B)** Derselbe Vorstoß im 2-m-Schacht: die Wärme dringt
in den Schnee ein — nach zwei Tagen steht sie bei 0,8 m, nach zehn bei 1,5 m, gedämpft
von 12 K auf 2 K. **(C)** Auf der Jahresskala dasselbe Prinzip: die Sommerwärme von
Januar/Februar wandert nach unten und erreicht **im Winter 6–8 m Tiefe** (standardisiert
je Tiefe, sonst wäre die Welle unterhalb weniger Meter unsichtbar). Dieselbe Kette misst
weiter bis 62 m, wo das Jahressignal auf unter 10 mK gedämpft ist.

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

## fig3_druck_temperatur.png — „Firntemperatur folgt dem Luftdruck"

Drei Ketten an zwei Standorten gegen eine Vorhersage ohne freien Parameter. Steigt der
Luftdruck um Δp, wird die Porenluft komprimiert; die Kompressionswärme `φ·Δp` nimmt die
Matrix mit `ρ·c` auf, woraus `b = ΔT/Δp = φ/(ρ c)` folgt. **(A)** Gemessene Kopplung gegen die
Tiefe, dazu die Vorhersage mit Herron-Langway-Dichte für beide Standorte (durchgezogen GRIP,
gestrichelt Kohnen). Gefüllte Punkte: direkt gemessen. Offene Punkte (head02): nach Abzug
eines gemeinsamen Anteils, der einen freien additiven Versatz zurücklässt — dort ist nur die
**Form** prüfbar. **(B)** 1:1-Vergleich der direkt gemessenen Knoten: **Faktor 0,953 ± 0,015
über 10 Knoten**, zwei Standorte, Tiefen von 7 bis 30 m. **(C)** Die Rohdaten, aus denen die
Steigungen in (A) und (B) stammen: Temperatur- gegen Druckabweichung im synoptischen Band,
je Tiefe eine Regressionsgerade. Links GRIP (täglich, 10/21/30 m, ±0,5 mK auf ±5 hPa), rechts
Kohnen B50 (zweimal täglich, 8/9/10 m, ±1 mK auf ±15 hPa).

Datengrundlage: Kohnen B50 (head03, Jan–Jul 2026, 2 Messungen täglich, 41 hPa Druckhub,
verfüllte 10-m-Kette), GRIP-Doppelkette (Jul–Sep 2026, täglich, 21 hPa, verfülltes Bohrloch),
Kohnen B46 (head02, 18.01.–02.02.2026, 4-stündlich, 16 hPa, beide Ketten in Schnee).
Erzeugt mit `Rscript make_fig3_druck_temperatur.R`; die Eingangstabellen liegen als
`fig3_*_b.csv` in den jeweiligen `data/`-Ordnern.

## slides_druck_temperatur.pptx — zwei englische Folien

Erzeugt mit `python3 make_slides_pressure.py` (16:9, python-pptx). Folie 1 zeigt die
Beobachtung: links die Rohdaten (Panel C aus fig3), rechts die Kopplung gegen die Tiefe mit
der parameterfreien Vorhersage (Panel A). Folie 2 skizziert, wie sich daraus offene Porosität
und Close-off ableiten ließen, mit den erreichbaren Genauigkeiten und den Anforderungen. Die
Einzelpanels liegen als `fig3a_kopplung_tiefe.png` und `fig3c_rohdaten.png` daneben.

## Beschriftungsvarianten

Jede Abbildung liegt in drei Fassungen vor, damit sie sich direkt in Vorträge übernehmen lässt:

| Datei | Beschriftung |
|---|---|
| `figX.png` | mit Panelbuchstaben, z. B. „A · Coupling vs. depth …" |
| `figX_nolabel.png` | ohne Buchstaben, beschreibender Untertitel bleibt |
| `figX_bare.png` | ohne jede Überschrift — Titel setzt der Vortragende |

Dazu die Einzelpanels ohne Überschrift: `fig1a_atmosphere_bare.png`, `fig1b_pit_bare.png`,
`fig1c_annualwave_bare.png`, `fig3a_kopplung_tiefe_bare.png`, `fig3b_elf_bare.png`,
`fig3c_rohdaten_bare.png`.

## Sprache

Die **Abbildungen** sind seit 09.09.2026 englisch beschriftet (fig1, fig2, fig3 und die
Einzelpanels), weil sie in Vorträgen und der pptx verwendet werden. Diese README und die
Bildunterschriften hier bleiben deutsch.
