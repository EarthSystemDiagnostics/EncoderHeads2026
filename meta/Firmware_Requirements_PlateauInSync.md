# Firmware-Anforderungen für PlateauInSync

Abgeleitet aus der Auswertung der Kampagne 2026 (head02/head03/head04, Grönland-Doppelkette).
Belege in `Greenland2026/druck_temperatur.qmd`, `KohnenRecords_Analyse/head02_profile.qmd` und
`KohnenRecords_Analyse/head02_ausfall.qmd`.

Randbedingungen: kein Rückbau, keine SD-Karten-Bergung — alles muss über Iridium; kaum
Wetterstationen in der Nähe; die Kette schneit ein, die Tiefe jedes Knotens wächst mit der Zeit.

## 1 Kanäle je Knoten

| Nr. | Anforderung | Grund |
|---|---|---|
| 1.1 | **Rohdruck und Rohtemperatur des DPS368** übertragen, nicht nur den kompensierten Wert (6 B je Sensor) | Unter −45 °C extrapoliert die werkseitige Kompensation: Skala fällt auf 0,82 (−45…−50 °C) und 0,67 (−50…−55 °C). Ohne Rohwerte ist keine eigene Kompensation und keine rückwirkende Korrektur möglich. |
| 1.2 | **Referenzwiderstand im selben Messpfad** mitmessen und übertragen | In head02 lag eine Verstärkungsänderung von 0,1 % (200 ppm/K) auf allen Kanälen. Sichtbar wurde sie erst über die Korrelationsstruktur von 24 Knoten; ein Referenzkanal zeigt sie direkt. GND allein reicht nicht (0,8 Counts Signal bei 4 Counts Rauschen). |
| 1.3 | **NTC1 und NTC2 je Knoten** übertragen | head02 sendete nur NTC1. Die Replikatdifferenz war das Mittel, um physikalische von kanalspezifischen Effekten zu trennen. |
| 1.4 | **Si-Kanal (outSi/TestSB)** mindestens für einen Knoten je Kette | Linear in T, unabhängig vom NTC-Zweig; erlaubt die Trennung von Sensor- und Messkettenfehlern. |
| 1.5 | GND je Knoten beibehalten | Diagnose des Nullpunkts. |

## 2 Abtastung und Sendeplan

| Nr. | Anforderung | Grund |
|---|---|---|
| 2.1 | **Abtastrate je Knotengruppe konfigurierbar**: oberes Array (10 Knoten, 0,05–1 m) 3-stündlich, tiefe Knoten täglich | Der Windpumpen-Test läuft im synoptischen Band (Dämpfungslänge 0,13–0,29 m); vier bis acht Messungen am Tag genügen dort. Die tiefen Knoten tragen nur die Druckkorrektur, dafür reichen 1–2 Messungen am Tag (head03: R² = 0,83 bei 10 m mit zwei Messungen täglich). |
| 2.2 | **Sendezeiten konfigurierbar, mit Versatz von Tag zu Tag** | Feste Sendestunden bilden einen Tagesgang auf einen konstanten Versatz ab. head04 sendet nur um 17 UTC, head03 um 09 und 21 UTC — beide liegen nahe den Nulldurchgängen des in head02 gemessenen Tagesgangs; ein solcher Effekt wäre dort unsichtbar. |
| 2.3 | Zeitstempel der **Messung**, nicht der Sendung | Bereits erfüllt; für die Zuordnung zum Referenzbarometer notwendig (Tagesmittel statt Momentanwert kostet zehnmal so viel wie 30 km Entfernung). |

## 3 Telemetriebudget

| Nr. | Anforderung | Grund |
|---|---|---|
| 3.1 | Zielwert **≤ 340 B/Tag**, also eine SBD-Nachricht | Rechnung: oberes Array 10 × 8 × 3 B + tiefe Kette 25 × 3 B = 315 B/Tag. Alle 35 Knoten zehnminütig wären 15 kB/Tag = 44 Nachrichten/Tag. |
| 3.2 | Bordreduktion (Amplitude, Phase, Mittel der Tagesharmonischen je Knoten) als **späterer, zuschaltbarer** Modus | Spart weiter, verhindert aber jede spätere Neuauswertung. Erst einsetzen, wenn die Auswertung steht. |

## 4 Payload-Format

| Nr. | Anforderung | Grund |
|---|---|---|
| 4.1 | **Feste Feldbreiten** statt wertabhängiger | Die wertabhängige Breite verschiebt bei jedem Überlauf alles Folgende; ein Decoder mit fester Annahme liest Unsinn (head02: „Batterie 0 mV" war ein Artefakt). |
| 4.2 | **Formatkennung im Kopf** jeder Nachricht: Version, Knotenzahl, Feldliste | head02 wechselte während des Betriebs zwischen 340 B mit `0x7C`, 334 B und 209 B ohne Trenner. Die Zuordnung war nur über Byteanalyse rekonstruierbar. |
| 4.3 | **Explizite Längenangabe** statt Abbruch über Nullbytes | Die `ArrayLen()`-Heuristik (fünf Nullbytes beenden die Nachricht) hat zusammen mit dem Overflow-Sentinel `01 00 00 00` Telegramme mitten im Datenstrom abgeschnitten. |
| 4.4 | Overflow-Sentinel ohne Nullbytes | Siehe 4.3. |
| 4.5 | Druck-Timeout-Marker (`6F 6F`) beibehalten | War das Signal, an dem der Kettenausfall von head02 erkennbar wurde (25 von 25 Knoten). |

## 5 Diagnose

| Nr. | Anforderung | Grund |
|---|---|---|
| 5.1 | Platinentemperatur und Batteriespannung je Telegramm | Bereits erfüllt; erlaubte den Ausschluss von Brown-out und Kälteproblem bei head02. |
| 5.2 | Zähler für Kommunikationsfehler je Knoten seit dem letzten Telegramm | Der achtstündige Vorbote am 19.01.2026 war nur über die Timeout-Marker sichtbar; ein Zähler macht ihn ohne Byteanalyse auffindbar. |

## 6 Nicht Firmware, aber gleiche Auslegung

* **Drucksensoren erst ab der Tiefe bestücken, in der die Jahreswelle über −45 °C bleibt** — an
  Kohnen ab 4 m. An Dome C, Vostok und Dome A gibt es keine solche Tiefe (Firntemperatur
  −54 bis −58 °C); dort ein bis −60 °C spezifiziertes Barometer oder der Reanalyse-Bodendruck.
* **Knotenabstand im oberen Array 5–10 cm.** `κ_eff` folgt aus dem Amplitudenverhältnis
  benachbarter Knoten, `d = Δz/ln(A₁/A₂)`; Δz ist mechanisch fest und vom Einschneien
  unabhängig. Bei 0,07–0,08 m/a Akkumulation an den kalten Standorten bleibt das Array fünf bis
  sechs Jahre im relevanten Tiefenbereich.

## 7 Einschneitiefe der Kette

Die Tiefe jedes Knotens unter der Oberfläche geht in jede Auswertung des oberen Profils ein.
Der belastbarste Schätzer nutzt bisher den Übergang vom überhöhten Tagesgang (Sensor über der
Fläche) zum gedämpften (Sensor darunter); seine Auflösung ist der halbe Knotenabstand, also
±2 cm bei 4 cm Teilung. Zwei Änderungen verbessern ihn, beide an der bestehenden Hardware.

| Nr. | Anforderung | Begründung |
|---|---|---|
| 7.1 | Knotenabstand im untersten Meter auf 2 cm halbieren | Die Unsicherheit des Übergangsschätzers ist direkt der halbe Knotenabstand. 2 cm Teilung ergibt ±1 cm, besser als jedes Einzelpunktverfahren am selben Ort. |
| 7.2 | Aktiver Wärmepuls je Knoten, einmal täglich | Der Übergang braucht direkte Einstrahlung; an bedeckten Tagen und in der Polarnacht fehlt die Überhöhung. Ein kurzer Selbstheizpuls über den NTC (wenige Sekunden erhöhter Messstrom) und die Abklingrate trennen Luft von Schnee ohne Sonne: Wärmeleitfähigkeit 0,024 gegen 0,15–0,30 W/(m·K), Faktor 6–12. Ergebnis ist eine Ja/Nein-Klassifikation je Knoten, nicht ein Modellfit. |
| 7.3 | Abklingrate als eigenes Feld senden, nicht nur die Endtemperatur | Die Rate ist das Diskriminanzmaß; die Endtemperatur allein hängt von der Umgebungstemperatur ab. |

| 7.4 | Abschattungstest im Feldprotokoll: die Kette an einem klaren Tag für eine Stunde zu bekannter Zeit beschatten | Sledd et al. (2026) messen die Eigenerwärmung der Kette daran, dass ihr Tragrohr die untere Sektion bei bestimmten Sonnenständen beschattete; der Temperatursprung ist eine direkte In-situ-Messung des Artefakts. Kostet keine Hardware und trennt Eigenerwärmung der Kette von der Strahlungsabsorption im Schnee. |

**Referenzen zu Abschnitt 7**

* Sledd, A. et al. (2026): *Summer subsurface temperature variability in the percolation zone of
  southwest Greenland*, egusphere-2026-1842. 2 cm / 15 min Thermistorkette. Oberflächendetektion
  aus dem Maximum der 24-h-Varianz von ΔT/Δz (vertikal normiert), plus empirischer Versatz +4 cm
  gegen eine Handmessung. Korrektur der Eigenerwärmung nach Beer: κ = 19 m⁻¹ (Abklinglänge
  5,3 cm; zulässiger Bereich 10–35 m⁻¹), NIR-Anteil 0,5 unmittelbar unter der Oberfläche;
  34 % der Netto-Kurzwelle werden mindestens 2 cm tief transmittiert. κ ist dort ein
  **angepasster** Parameter, gewählt um Temperaturen über 0 °C wegzukorrigieren, keine Messung;
  bei einer Albedo von 0,84 und dem im obersten Millimeter absorbierten NIR fällt die
  Energiedeposition ohnehin fast vollständig in die obersten ein bis zwei Zentimeter. Akustik-, Laser- und
  GNSS-Oberflächensensoren am selben Standort weichen „um Dezimeter" voneinander ab, weil sie
  3 m und weiter von der Kette entfernt stehen — Begründung, die Oberfläche aus der Kette selbst
  zu bestimmen.
* Zuhr, A. M. et al. (2021): *Local-scale deposition of surface snow on the Greenland ice sheet*,
  The Cryosphere 15, 4873–4900. Dekorrelationslänge 5 m; ein Einzelpunkt liefert 7,4–14,8 cm
  (10-/90-%-Quantil) gegen 11 cm Flächenmittel; der PROMICE-Ultraschallsensor 5,8–7,6 cm.
