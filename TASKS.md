# Tasks

## Active

- [ ] **SnowMelt Wärmebilanz: Antragszahlen prüfen** - InnoFond-Vollantrag, Abgabe Mo 16.11.2026; Ergebnis bis So 15.11., since 2026-11-11
  - Ziel: tragen GRIP- und Dye-3-Daten die Aussagen aus Antrag AP 4 und Problemstellung (iii)? Je Punkt Zahl mit Unsicherheit, dazu „bestätigt / nicht bestätigt / nicht prüfbar“.
  - Daten: nur eingeschneite Sensoren laut Einschneidiagnostik; Tiefe = Oberflächenlage (Übergangsschätzer, `analysen/2026-10-26_winter_oberflaeche`) minus Sensorhöhe; Knoten 6–8 GRIP (Tape) wie in `series_diag` ausschneiden.
  1. Rauschen der Profilkrümmung (T[i+1] − 2T[i] + T[i−1])/Δz², Δz = 4 cm, aus ruhigen Abschnitten. Antrag: 1,5 K/m² bei 1 mK. Gegenrechnung mit auf 1/16 K gerundeten Daten; Antrag: 28 K/m².
  2. Tagesgang im Schnee: Dämpfungstiefe aus Amplitude und aus Phase (Antrag: 7–11 cm); Amplitude in 50 cm Tiefe (Antrag: ~20 mK); Tiefe, ab der die Amplitude unter 62,5 mK fällt.
  3. Temperaturleitfähigkeit κ je 4-cm-Schicht aus Amplitude und Phase dreier Nachbarsensoren, als Zeitreihe. Dichteindex über k(ρ) nach Sturm et al. (1997); gegen eine publizierte Oberflächendichte für GRIP bzw. Dye-3 stellen (Quelle angeben). Streuung von κ je Schicht und Woche.
  4. Residuum der Wärmeleitungsgleichung ρc ∂T/∂t − ∂z(k ∂T/∂z) in W/m³: Nachweisgrenze je Schicht bei Stunden- und Tagesmitteln. Bezug: Wiedergefrieren von 1 mm Wasser pro Tag in 4 cm entspricht 97 W/m³. Ereignisse über der Nachweisgrenze auflisten.
  5. Faktor 1,3–1,9 zwischen den Abklinglängen aus Amplitude und Phase: Abhängigkeit von Windgeschwindigkeit (AWS Summit bzw. NASA-SE, GEUS-THREDDS) und Einstrahlung. Hängt er vom Wind ab, stützt das die Deutung als Ventilation.
  - Ablage: `Greenland2026/analysen/2026-11-1x_waermebilanz/` mit Skript, `ergebnis.txt` und je einer Abbildung zu 2 und 3; eine Zeile in `~/sharedAI/ANALYSEN.md`.
  - Rückfluss: Weichen Zahlen ab, die neuen Werte in `~/sharedAI/proposals/2026_Innofond/SnowMelt_Vollantrag/scripts/fill_form.py` (Problemstellung (iii), AP 4) eintragen bzw. dort melden.

## Waiting On

- [ ] **B50 Deckel-Experiment auswerten** - schnelle Messung mit und ohne Deckel; Thomas sucht die Daten, since 2026-10-01
  - Ziel: erklärt der Lochabschluss oben den Faktor 2–3 in K = b/(−Γ) zwischen B40 und B50 (beide Ø 12 cm)?
  - Auswertung wie B46: Hochpass T = G·(p − Tiefpass_τ p), τ und G je Tiefe, mit/ohne Deckel vergleichen
  - Dazu: Tiefe von B50 und B46 sowie Abschluss oben aller drei Löcher klären
  - Ergebnis in `KohnenRecords_Analyse/b40_druckschwankungen.qmd`

## Someday

## Done
