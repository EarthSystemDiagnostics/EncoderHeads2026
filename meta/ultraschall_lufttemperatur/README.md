# Lufttemperatur für die Ultraschall-Schneehöhe — offene Aufgabe

Die Ultraschall-Höhenmessung hängt über die Schallgeschwindigkeit
`c = 331,3·√(1+T/273,15)` an der Lufttemperatur. Gebraucht wird das **Mittel entlang des
Wegs** zwischen Sensorkopf und Schneeoberfläche, nicht die Temperatur an einem Punkt. Der
Streckenfehler ist `ΔL/L = ½·ΔT/T`.

Kontext: PlateauInSync, 10 Ultraschallsensoren je Site, Akkumulation 75 mm/a.

## Fehlergrößen

Bei T = 223 K und 1,5 m Weg:

| Fehler der Wegtemperatur | 1 K | 3 K | 5 K | 10 K |
|---|---|---|---|---|
| Höhenfehler | 3 mm | 10 mm | 17 mm | 34 mm |

Zum Vergleich: Einzelmessgenauigkeit der Ultraschallklasse ±28 mm, Jahresakkumulation 75 mm.

## Gemessen an GRIP (September 2026, 7750 Messungen, 62 Höhen 0,14–2,58 m)

Die SnowMelt-Kette liefert ein Luftprofil im 4-cm-Raster über der Oberfläche.

| | Median | 95 % | max |
|---|---|---|---|
| Luftgradient (K/m, + = Inversion) | +0,05 | +0,90 | — |
| T(2 m) − T(0,3 m) | +0,16 K | +1,65 K | +6,10 K |
| Höhenfehler mit **einem** Sensor bei 2 m | +0,2 mm | +3,9 mm | +8,1 mm |
| Restfehler mit **zwei** Sensoren (0,3 / 2 m) | 0,0 mm | 0,8 mm | — |

Tag und Nacht unterscheiden sich kaum (+0,10 gegen +0,16 K). Skript:
`lufttemperatur_test.R`, Abschnitt A.

**Der Fall, auf den es ankommt, ist damit nicht geprüft.** GRIP im September hat schwache
Inversionen. Auf dem antarktischen Plateau im Winter sind 10–20 K über die ersten Meter zu
erwarten, was 17–34 mm ergäbe — systematisch und saisonal, also genau die Fehlerform, die
ein Akkumulationstrend nicht verträgt.

## Strahlungsschutz

**Polarwinter, keine Sonne.** Ein freier Sensor kühlt langwellig unter die Lufttemperatur.
Über einer unendlichen Ebene sieht er exakt halb Himmel, halb Fläche — unabhängig von der
Höhe. Mit Gegenstrahlung 80–120 W/m² (Dome C Winter) und h = 4–15 W/(m²·K):

| Gegenstrahlung | T_Himmel | Nettoverlust | ΔT bei h = 4 / 8 / 15 |
|---|---|---|---|
| 100 W/m² | 205 K | 10,7 W/m² | 2,67 / 1,34 / 0,71 K |
| 120 W/m² | 214 K | 0,7 W/m² | 0,17 / 0,09 / 0,05 K |

Der Fehler ist bei beiden Höhen **gleich** und verfälscht den Gradienten deshalb nicht. Als
gemeinsamer Versatz bleibt er im Wegmittel: 1,5 K → 5,3 mm absolut, aber als Skalenfehler nur
0,26 mm je 75 mm Akkumulation. Für die Akkumulation als Differenzgröße also unkritisch.

**Sommer, mit Sonne.** Ohne jeden Schutz ist es aussichtslos: für einen Zylinder gilt
ΔT = α·S/(π·h), also 3,2 K selbst bei α = 0,1 und h = 8. Ein einfacher Mehrplattenschutz
(6–10 weiße Teller, ~10 cm, ~100 g) liegt laut Literatur bei 0,5–2 K unter 1 m/s und unter
0,4 K über 3 m/s. Plateau-Mittelwind Dome C ~3 m/s, Kohnen ~5 m/s → **0,3–0,5 K, also
1–2 mm.** Ein Mehrplattenschutz genügt; Ansaugung oder große Gehäuse sind nicht nötig.

## Was nicht funktioniert hat

Vergleich der ungeschirmten GRIP-Luftsensoren gegen die Summit-AWS (30 km): Regression auf die
Einstrahlung ergibt −3,5 mK je W/m², also −2,8 K bei 800 W/m² — falsches Vorzeichen für einen
Strahlungsfehler, R² = 0,034, Streuung zwischen den Standorten 3,46 K. Die Standortdifferenz
überdeckt den gesuchten Effekt. Skript: `lufttemperatur_test.R`, Abschnitt C.

## Literatur (Recherche 19.09.2026)

**Eine publizierte Verteilung für die untersten 0,5–2 m auf dem ostantarktischen Plateau
existiert nicht.** Die Dome-C-Daten der untersten Niveaus sind gemessen, aber nicht statistisch
ausgewertet und nicht öffentlich archiviert. Was es gibt:

| Standort | Schicht | Wert | Art | Quelle |
|---|---|---|---|---|
| Dome C | 0,7–2,9 m | ≈ 5 K/m (≈ 11 K) im sehr stabilen Winterfall | Messung, Einzelfall | van der Linden 2019, doi 10.1007/s10546-019-00461-4 |
| Dome C | ~2 m gegen ~3–4 m | 1–2 K im Wintermonatsmittel | Messung | Genthon 2021, doi 10.5194/essd-13-5731-2021 |
| Dome C | 3–10 m | 0,47 K/m Dekadenmittel | Messung | Genthon 2021 |
| Südpol | Oberfläche–2 m | Median 1,0 K (all-sky), 1,3 K (klar); **> 60 % davon in 0–0,2 m** | Messung, Verteilung | Hudson & Brandt 2005, doi 10.1175/JCLI3360.1 |
| Südpol | 0,2–2 m | > 0,25 K/m (klar) | Messung | Hudson & Brandt 2005 |
| Dome A | 1–2 m | Inversion 71 % der Zeit | Messung, nur Histogramme | Hu 2014/2019, doi 10.1086/678327 |
| Ostantarktis | Kopf–Oberfläche | 5–10 K in den ersten Metern bei Windstille und klarem Himmel | Reviewaussage | Eisen 2008, doi 10.1029/2006RG000218 |

Der Südpol ist mit 5,5 m/s Mittelwind deutlich windiger als Dome C (2,9 m/s) oder Dome A
(1,5–4,2 m/s); seine Medianwerte sind für Hochplateaustandorte eine **Untergrenze**.

**Vorbild für die Anordnung:** der Dome-C-Hilfsmast (CALVA/IPEV, seit 2012, 2,5 m hoch) misst
Temperatur bei **0,45 / 0,9 / 1,9 m**, belüftete Vaisala HMP155. Die Daten liegen bei
IGE Grenoble, nicht auf PANGAEA; die Turmdaten ab 3 m dagegen unter
doi 10.1594/PANGAEA.932512.

**Stand der Praxis ist schlechter als unser Entwurf.** Die IMAU-AWS (van Tiggelen 2025,
doi 10.5194/essd-17-4933-2025, Daten doi 10.1594/PANGAEA.974080) haben **nur ein
Temperaturniveau** am Ausleger in 2,6–5 m, **keine aktive Belüftung**, und korrigieren die
Schallgeschwindigkeit mit `H = H_raw·√(T/273,15)` bei genau dieser Auslegertemperatur — weder
Pfadmittel noch 2-m-Wert. Ihr gemessener RMSD zwischen zwei parallel laufenden Rangern beträgt
40–80 mm, weit über der Herstellerangabe. Eisen et al. (2008) empfehlen ausdrücklich einen
eigenen **belüfteten** Sensor auf halber Höhe zwischen Kopf und Oberfläche.

**Schirmfehler, kurzwellig — hier lag ich falsch.** Über Schnee ist ein passiver
Mehrplattenschirm im Polarsommer nicht ausreichend:

| Quelle | Bedingung | Fehler |
|---|---|---|
| Genthon 2011, doi 10.1175/JTECH-D-11-00095.1 | Dome C, Sommer, schwacher Wind | gelegentlich > 10 K |
| Morino 2021, doi 10.1175/JTECH-D-21-0107.1 | Dome Fuji, klar, windschwach | Stundenmittel bis 8 K |
| Huwald 2009, doi 10.1029/2008WR007600 | über Schnee | 30-min-Mittel bis 10 K |
| Lacombe 2021, doi 10.5194/amt-14-6195-2021 | Schneedecke, mehrere Designs | 1,2–3,8 K, 95 % < 2,4 K, Maximum bei ~1 m/s, ab 3 m/s stark reduziert |

Der Fehler wächst mit der **reflektierten** Kurzwellenstrahlung, deshalb sind die polaren Werte
so viel größer als die mitteleuropäischen 0,5–2 K, die ich zitiert hatte. Genthon hat die
passiven Gill-Schirme am Dome-C-Turm aus genau diesem Grund durch mechanisch belüftete ersetzt.

**Schirmfehler, langwellig — meine Rechnung hat keine Stütze.** Ich hatte 1–2 K Unterkühlung
in der Polarnacht abgeschätzt. Lacombe et al. (2021) finden über Schnee nachts Differenzen
nahe null im Rahmen der Instrumentenunsicherheit. Eine publizierte Kaltbias-Zahl für
unbelüftete Schirme in der Polarnacht existiert nicht. Die Abschätzung bleibt als
Größenordnung stehen, ist aber nicht belegt.

## Was der Schirmfehler kostet

Ein gemeinsamer Temperaturversatz wirkt als Skalenfehler der Strecke:

| Versatz | absolut auf 1,5 m | je 75 mm Akkumulation |
|---|---|---|
| 2 K | 6,7 mm | 0,34 mm |
| 4 K | 13,4 mm | 0,67 mm |
| 8 K | 26,9 mm | 1,34 mm |

Für die Akkumulation als Differenzgröße ist das unkritisch. Kritisch ist, dass der Fehler
**saisonal** ist: ein Sommerbias von 8 K erzeugt einen scheinbaren Jahresgang der Höhe von
27 mm, in der Größenordnung der Einzelmessgenauigkeit und von einem realen Signal nicht zu
trennen.

## Wie viele Höhen, und wie interpolieren

Geprüft an den **gemessenen** GRIP-Profilen (149 Profile, 4-cm-Raster, keine Profilannahme):
Rekonstruktion des Pfadmittels aus zwei bzw. drei Sensorhöhen gegen das wahre Pfadmittel, als
Regression gegen die Inversionsstärke.

| Rekonstruktion | Fehler je K Inversion | extrapoliert auf 11 K |
|---|---|---|
| nur ein Sensor bei 2 m | +0,502 | **+24,1 mm** |
| linear aus 2 Sensoren (0,3 / 2,0 m) | −0,060 | −2,9 mm |
| log-Fit aus 2 Sensoren | +0,031 | +1,5 mm |
| log-Fit aus 3 Sensoren (0,45 / 0,9 / 1,9 m) | −0,056 | −2,7 mm |

**Der zweite Sensor bringt Faktor acht bis sechzehn, der dritte nichts.** Die Wahl des
Interpolationsschemas ist gegenüber dem Sprung von eins auf zwei nachrangig.

Vorbehalt: R² der Regressionen 0,03–0,11, und die Steigungen stammen aus Inversionen bis 6 K,
angewandt auf 11 K. Die Vorzeichen sind nicht konsistent (log-Fit aus zwei Punkten
überschätzt, aus dreien unterschätzt) — das ist Rauschen. Robust ist allein die Rangfolge.

**Zurückgezogen:** eine frühere Rechnung in dieser Notiz kam auf 0,4 mm für die lineare
Näherung. Sie verglich das Pfadmittel über 0,05–2 m mit dem Mittelwert zweier Sensorwerte bei
0,3 und 2 m, also zwei verschiedene Intervalle; die Fehler hoben sich zufällig auf. Sauber
gerechnet gibt die lineare Näherung für ein Log-Profil −4,5 % des Pfadmittels, bei 11 K also
−2,1 mm. Und alle getesteten Profilformen legen nur 44–48 % der Differenz in die untersten
20 cm, während Hudson & Brandt am Südpol über 60 % messen — das reale Profil ist steiler als
jede der Annahmen.

## Belüftung: am Energiebudget machbar, an der Mechanik nicht

| Betrieb | mittlere Leistung | Energie |
|---|---|---|
| Dauerbetrieb 1,4 W | 1,4 W | 12 kWh/a — ausgeschlossen |
| 4 Messungen/Tag, 3 min Vorlauf | **12 mW** | 0,28 Wh/Tag |
| dasselbe, nur an 150 Sonnentagen | — | **28–42 Wh je Sommer** |

Zum Vergleich: die Iridium-Telemetrie kostet 0,02 Wh/Tag. Ein 10-W-Panel liefert den
Sommerbedarf in vier bis acht Stunden. Der kurzwellige Schirmfehler existiert nur bei Sonne,
der Lüfter liefe also genau dann, wenn Strom da ist.

Der Einwand ist nicht die Energie, sondern das bewegliche Teil an einer Station ohne Rückkehr —
von den drei antarktischen Köpfen sind zwei an Stürmen ausgefallen. Deshalb passiv plus
Korrektur.

## Schirmfehler: Korrigieren, nicht filtern (Recherche 20.09.2026)

**Der Fehler ist größer und häufiger, als ich zuerst angesetzt hatte.** Angewandt auf 25 Jahre
Kohnen (IMAU-Parametrisierung nach van Tiggelen 2025 / Smeets 2018, Daten
doi 10.1594/PANGAEA.974118), Sommerstunden mit SWD > 300 W/m², n = 26 330:

| | Mittel | Median | p90 | p99 | max |
|---|---|---|---|---|---|
| Schirmfehler | 2,77 K | 2,36 K | 4,91 K | 8,00 K | 10,3 K |
| Höhenfehler | 12,1 mm | 10,3 mm | 21,5 mm | 35,0 mm | 45,0 mm |

2 bis 3 K sind im Sommer am Tag der **Normalfall**, nicht der Ausreißer; die in der Literatur
zitierten „über 10 K" sind das Maximum. Mein früherer Ansatz von 1 K im Median war um Faktor
2,4 zu klein.

**Es gibt keine brauchbare Windschwelle.** Binnenmittel nach Windklasse (Kohnen, SWD > 300):

| U (m/s) | 0–1 | 1–2 | 2–3 | 3–4 | 4–5 | 5–6 | 6–8 | 8–10 |
|---|---|---|---|---|---|---|---|---|
| Fehler | 3,4 K | 5,2 | 4,4 | 3,0 | 2,3 | 1,9 | 1,5 | 1,0 |
| Höhenfehler | 15 mm | 23 | 19 | 13 | 10 | 8 | 7 | 4 |
| Daten übrig | 100 % | | | 66 % | 51 % | 33 % | 20 % | 10 % |

Bei 3 m/s bleiben 13 mm stehen, bei 5 m/s noch 8 mm — und dann sind zwei Drittel der Stunden
verworfen. Genthon et al. (2011) empfehlen 4–6 m/s; Morino et al. (2021) finden am Dome Fuji
auch oberhalb 6 m/s noch signifikante Fehler, weil dort der Mittelwind nur 2,5 m/s beträgt.
**Meine Filter-Empfehlung vom Vortag war falsch.**

**Korrektur ist der Weg.** Alle drei publizierten Schemata folgen Nakamura & Mahrt (2005,
doi 10.1175/JTECH1762.1) mit X = SW_ref/(ρ·c_p·T·U):

| Schema | Rest-RMSE | Höhenfehler |
|---|---|---|
| Kurita 2024, **Zylinderschirm** | 0,8 K | 3,5 mm |
| Kurita 2024, 14-Platten-Schirm | 1,4 K | 6,1 mm |
| van Tiggelen 2025, U > 1 m/s | ~1,0 K | 4,4 mm |

RMSE-Reduktion 60–70 %. Der Rest ist irreduzibel und größer als die Sensorgenauigkeit;
Ursachen sind Reifansatz zwischen den Platten und Alterung der Schirmoberfläche (Kurita musste
für dieselbe Station verschiedene Regressionen je Zeitraum verwenden).

**Die Schirmform entscheidet mehr als die Größe.** Musacchio et al. 2021
(doi 10.5194/amt-14-6195-2021 — die Arbeit heißt Musacchio, nicht Lacombe, das war mein
Zitierfehler): passiv **helikoidal** 1,2–1,4 K Maximum, also gleichauf mit aspiriert (1,4 K),
gegen 3,1–3,8 K für klassische Mehrplattenschirme und 1,9 K für einen Zylinder. Auf dem
Plateau schlägt der einfache **UW-Zylinderschirm** (76 mm Aluminiumrohr, außen Folie niedriger
Emissivität, innen mattschwarz, unten offen) den 14-Platten-Young: Regressionssteigung 6,1
gegen 7,8, Rest-RMSE 0,8 gegen 1,4 K. Der physikalische Grund ist bekannt: Gill-Schirme
schützen schlecht gegen Strahlung **von unten** (Richardson et al. 1999), und über Schnee kommt
sie von dort.

Ein helikoidaler Schirm ist über Polarschnee nicht getestet.

## Windfilter: für die Akkumulation folgenlos, für die Temperatur nicht

Geprüft an zwei IMAU-Stationen (doi 10.1594/PANGAEA.974118, doi 10.1594/PANGAEA.974121):

| | Kohnen AWS9, 2892 m, 25 a | AWS12 Plateau, 3620 m, 8 a |
|---|---|---|
| Akkumulation | 219 ± 96 mm/a | **106 ± 72 mm/a** |
| Wind, Median | 3,9 m/s | 4,2 m/s |
| Anteil unter 3 m/s | 34 % | 20 % |
| Versatz des Monatsmedians der Höhe, ff > 3 | +0,2 ± 5,9 mm | +0,7 ± 6,2 mm |
| Jahresakkumulation ungefiltert / gefiltert | 219 / 219 | 106 / 106 |
| Korrelation stündliche Höhenänderung ↔ Wind | +0,006 | −0,001 |

Für die Höhe ist der Filter folgenlos. Für die **Temperatur** dagegen nicht: bei U > 3 m/s
verschiebt sich das Jahresmittel an Kohnen um **+2,57 K**, bei U > 4 um +3,92 K, im Winter um
bis zu +7,2 K. Wind und Inversion sind gekoppelt (Wintermittel je Windklasse −52,1 °C bei
0–2 m/s bis −35,0 °C über 8 m/s). Gefilterte Temperaturen dürfen also nicht als Klimatologie
verwendet werden — für die Schallgeschwindigkeitskorrektur zum Zeitpunkt der Höhenmessung
spielt es keine Rolle.

AWS13 am Pol der Unzugänglichkeit (doi 10.1594/PANGAEA.974122) lief nur Januar bis März 2008,
1614 Stunden; das Vorzeichen passt, die Reihe trägt aber keine Jahresakkumulation.

## Fehlerhaushalt, zwei Luftsensoren im Zylinderschirm mit Korrektur

Ein Kelvin Fehler im Pfadmittel = 4,4 mm bei 1,95 m Weg und −50 °C.

| Quelle | Größe | Höhenfehler | Charakter |
|---|---|---|---|
| Schirm, unkorrigiert, Sommertag | 2,4 K Median, 8,0 K p99 | 10 / 35 mm | saisonal systematisch |
| Schirm, korrigiert, Zylinderform | 0,8 K RMSE | 3,5 mm | überwiegend zufällig |
| Profilrekonstruktion, 2 Sensoren | −0,060 K je K Inversion | −2,9 mm bei 11 K | folgt der Inversion |
| dasselbe mit **einem** Sensor | +0,502 K je K | +24 mm bei 11 K | — |
| Ultraschall + Oberflächenrauigkeit | 40–80 mm je Messung | 13–25 mm bei 10 Sensoren | zufällig |

Für die **Jahresakkumulation als Differenz zum gleichen Datum** kürzen sich die saisonalen
Terme heraus; übrig bleibt der Zufallsanteil, über 10 Sensoren und 30 Tage 2–5 mm, also 3–6 %
von 75 mm/a. Für den **unterjährigen Verlauf** bleibt ohne Korrektur ein Scheinjahresgang von
10 mm im Median und 35 mm im p99 — mit Korrektur 3,5 mm.

## Offene Punkte

1. **GRIP-Winterprofil**, ab Dezember 2026: dieselbe Auswertung wie Abschnitt A, dann liegt
   eine Inversionsverteilung für eine polare Nacht vor — die es in der Literatur für 0,5–2 m
   nicht gibt.
2. **Dome-C-Daten der untersten drei Niveaus** (0,45 / 0,9 / 1,9 m) bei IGE Grenoble anfragen.
   Das ist die einzige existierende Messreihe in genau unserem Höhenbereich auf dem Plateau.
3. **Strahlungsmessung an der Site.** Die Korrektur braucht SW abwärts und aufwärts. Kurita
   et al. (2024) zeigen, dass ERA5-SW ausreicht, wenn keine Messung vorliegt — das wäre die
   Rückfallebene, wenn kein Pyranometer mitfährt.
4. **Zylinder- gegen Mehrplattenschirm** am eigenen Aufbau. Der Unterschied ist mit 0,8 gegen
   1,4 K Rest-RMSE so groß wie alle anderen Terme zusammen, und der Zylinder ist das einfachere
   Bauteil (76 mm Aluminiumrohr).
5. **Der Test an einem noch trockeneren Standort** als AWS12 (106 mm/a) steht aus; die IMAU-
   Sammlung enthält keine längere Reihe unter 100 mm/a.

## Auslegungsfolge

**Zwei Luftsensoren je Site bei 0,45 und 1,9 m, plus einen dritten bei 0,9 m als Ersatz für den
einschneienden untersten.** Zwei genügen für das Pfadmittel — an den gemessenen GRIP-Profilen
fällt der Fehler von 0,502 auf 0,060 K je K Inversion, während der dritte nichts mehr bringt.
Höhen — die Höhen des Dome-C-Hilfsmasts, der
einzigen vergleichbaren Messreihe auf dem Plateau. Schirm: siehe offener Punkt 3, ein einfacher
passiver Mehrplattenschirm genügt entgegen meiner ersten Einschätzung **nicht**.
Drei statt zwei nicht wegen der Profilform — zwei Höhen genügen für das Pfadmittel —, sondern
weil der unterste bei 75 mm/a nach sechs Jahren einschneit, der bei 0,9 m nach zwölf und der
bei 1,9 m nach 25 Jahren; das Array degradiert damit gestuft, und eingeschneite
Sensoren laufen als Schneetemperatursensoren weiter.
