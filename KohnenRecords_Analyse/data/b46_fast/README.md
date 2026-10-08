# B46, schnelle Logger-Daten (95 s), 02.–05.01.2026

Zwei Ketten im damals noch offenen 60-m-Loch und im 10-m-Loch an B46 (head02-Standort), vor der
Verfüllung. Ein Logger vor Ort, kein Iridium. Abtastung 95 s, 2758 Zeitpunkte, 02.01. 10:47 bis
05.01. 11:45 UTC. Kalibriert von Nora Hirsch (Kampagne 2025/26). Original in Nextcloud
`KohnenRecords2526/2026_01_05/260105_B46/calibrated/`.

| Datei | Inhalt |
|---|---|
| `CalibratedData_B46_2chains_260105.csv` | je Knoten `<N>_NTC1`, `<N>_NTC2` (°C), `<N>_GND`, `<N>_Pressure` (Pa·1000 → /1000 = hPa) |
| `CalibratedTemperatures_B46_2chains_260105.csv` | nur Temperaturen |
| `PressureData_B46_2chains_260105.csv` | nur Druck je Knoten |
| `pressure_fluctuation.ipynb` | Noras Notebook zur Druck-Temperatur-Kopplung |

Knoten ↔ Tiefe: `../head02_depths.csv` (Spalte `chain`: `60m-Kette`, `10m-Kette`, `Luft`).
Verwendet in `b40_druckschwankungen.qmd`, `tutorial_druckmodell_b46.qmd`,
`poster/poster_box_figures.R`, `poster/poster_steps_B46.R`.
