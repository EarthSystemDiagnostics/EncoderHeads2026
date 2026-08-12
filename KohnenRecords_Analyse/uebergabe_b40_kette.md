# B40: was die Thermistorkette zum Bohrlochprofil beiträgt

**Von:** Thomas · **An:** Nora · **Stand:** 29. Juli 2026

---

## Worum es geht

Ich habe einen Nachmittag mit den head04-Kettendaten und einem KI-Assistenten
verbracht. Das meiste davon ist redundant zu deiner Auswertung und methodisch
schwächer: analytisch linearisiert statt MCMC, 14 statt ~50 Tiefen, 185 Tage
statt eines vollen Zyklus. Fünf Punkte sind übriggeblieben, die ich dir hiermit
weitergebe, damit du damit weiterarbeitest.

Vorweg das Ergebnis, das mich am meisten interessiert hat: **die Kette bestätigt
deine Messung unabhängig.** Zwei getrennte Instrumente, Elektroniken und
Kalibrationen, zwei Jahre auseinander, im selben Loch:

| | Winde, Jan 2024 | Kette, Jan–Jul 2026 |
|---|---|---|
| Temperaturbereich | −44.15 … −44.6 °C | −44.19 … −44.59 °C |
| Tiefe des Minimums | ~70 m | 75 m |
| relative Messgenauigkeit | 2.7 mK (2. Gerät) | 2.8 mK (NTC1−NTC2-Paare) |

Und eine unabhängige Inversion mit deinem Vorwärtsmodell ergibt für die letzten
20 Jahre +1.15 bis +1.45 K gegenüber deinen ~1.1 K.

---

## 1 Zahlen aus der Kette, die du direkt verwenden kannst

Das sind Messgrössen, keine Interpretationen — nimm sie, wenn sie dir nützen.

**Sensor-zu-Sensor-Genauigkeit ohne Wiederholungsfahrt.** NTC1 und NTC2 sitzen im
selben Knoten und messen dieselbe Temperatur; ihre Differenz *ist* der relative
Kalibrationsfehler. Über 18 Knoten ergibt das **2.8 mK (1σ je Sensor)** — der
gleiche Wert wie dein Zweitgerät-Vergleich, auf ganz anderem Weg. Das ist ein
brauchbares Argument in einem Methodenabschnitt.

**Weiteres aus derselben Rechnung:** weisses Sensorrauschen unter 90 m 0.13 mK;
Relativdrift zwischen zwei Sensoren im selben Knoten 0.04 mK/Jahr.

**Nicht-diffusive Variabilität im luftgefüllten Loch.** Die gemessene Streuung
übersteigt die Diffusionsvorhersage deutlich: bei 21 m 45.7 mK gegen 1.7 mK, bei
92 m 0.64 mK gegen 0.03 mK. Vermutlich verschieben Druckschwankungen die
Luftsäule und damit die Sensoren im Gradienten. Das ist der physikalische
Hintergrund deiner „representation uncertainty" im oberen Profilteil und
möglicherweise ein eigener Absatz wert. Der Versuch, es über den von head03
gemessenen Luftdruck nachzuweisen, ergibt $R^2 \approx 0.15$–0.23 gegen
$\mathrm{d}p/\mathrm{d}t$ — bei 8.5 h Zeitversatz zwischen den Ketten nicht
belastbar, aber ein Ansatzpunkt.

**Der Tiefengradient prüft dein Hintergrundmodell.** Gemessen über 158–201 m:
4.75 ± 0.09 K/km; dein Modell (volle Säule, $\theta_b$ = −1.85 °C, Lliboutry
$m$ = 11) gibt 4.50 K/km. Die gemessenen Gradienten nehmen nach oben ab
(3.66 K/km über 92–201 m), das Modell bleibt konstant — konsistent mit einem mit
der Tiefe abklingenden Erwärmungssignal.

---

## 2 Zwei Punkte zur Unsicherheitsangabe

**Der Vorwärtsmodellfehler ist quantifiziert, aber nicht in den σ enthalten.**
Gemeint ist der Anteil der Unsicherheit, der aus dem Wärmetransportmodell selbst
stammt — Akkumulation, Basisschmelze, Basistemperatur, Mächtigkeit,
Leitfähigkeit — im Unterschied zum Messfehler in $T(z)$ und zum
Repräsentationsfehler der Kernbasis. Du gibst die Empfindlichkeiten einzeln an
(22 / ~25 / 15 / 7 / ~23 mK), quadratisch addiert ~44 mK. Die angegebenen
Posterior-σ sind 0.02 °C für 2013 und 0.08 °C für 1973. Für die jüngsten
Jahrzehnte übersteigt der eigene Modellfehler die angegebene σ also um Faktor ~2.
Für 1823 (0.34 °C) ist er vernachlässigbar. Entweder beides zusammenführen oder
im Text kennzeichnen, dass die σ auf das Vorwärtsmodell konditioniert sind — ich
würde damit rechnen, dass ein Reviewer sonst genau hier ansetzt.

**Prior gegen Posterior:** steht in Fig. 1.4 mit Zahlen, das hatte ich beim
ersten Lesen übersehen. Da beide Kurven denselben Glättungsoperator durchlaufen,
ist das Verhältnis eine faire Messung des Informationsgewinns für die geglättete
Grösse — und die geglättete Grösse ist ja auch die, die du mit ERA5 und CMIP6
vergleichst. Ich habe geprüft, ob eine gemeinsame Glättung das Verhältnis
verzerren kann (unterschiedliche Korrelationsstruktur von Prior und Posterior
unter demselben Kern): in meinem Aufbau bleibt es für die ältesten Fenster
unverzerrt (Faktor 0.98–1.00) und weicht im Bereich 40–150 Jahre um bis zu 40 %
ab. Das ist zweiter Ordnung und kein Einwand gegen deine Darstellung.

Dazu eine reine Korrekturmeldung: S. 10 nennt als Maximum 2023 −44.13 °C und
+0.4 °C bis 1973, S. 12 nennt −44.5 °C und +0.6 °C bis 1970. Fig. 1.3 stützt
S. 10.

Was ich zurückziehe: ich hatte die α-Sensitivität von 23 mK für zu klein
gehalten. Das war ein falscher Vergleich — bei
$K_\text{firn}=K_\text{Eis}(\rho/\rho_\text{Eis})^{\alpha}$ wirkt α nur im
Firn und verschwindet bei Eisdichte (~7 % Effekt bei 20 m, ~0.3 % bei 200 m).
Mein Test hatte die Leitfähigkeit uniform skaliert, also auch das reine Eis.
Deine 23 mK sind plausibel.

Eine Frage bleibt trotzdem, und sie ist grösser als α: **liegt die
Muto-Parametrisierung im Dichtebereich 550–917 kg/m³ überhaupt richtig?**
Calonne et al. (2019, GRL, 3-D-Mikrotomographie) finden, dass die
schnee-abgeleiteten Formeln (Yen, Sturm, Calonne 2011) oberhalb 550 kg/m³ um
0.1–0.3 W m⁻¹ K⁻¹ zu niedrig liegen, bei k = 0.8–2.0 in diesem Bereich — also
10–25 %. Das ist genau der Bereich von 20 bis 200 m bei Kohnen. Ein
standortspezifisch getuntes α soll das auffangen, aber α = 2.4634 stammt von
NUS07-2, nicht von B40. Eine Gegenrechnung der Muto-Form gegen Calonne 2019 bei
den B40-Dichten wäre billig und würde die Leitfähigkeitsunsicherheit auf eine
belastbare Grundlage stellen. In meinem Aufbau verschiebt eine uniforme
K-Erhöhung um 15 % die rekonstruierte Erwärmung um +0.2 K.

Für die reine Eisleitfähigkeit (Yen 1981, über Cuffey & Paterson 2010) habe ich
keine ausgewiesene Unsicherheit gefunden; die ±5 %, die ich vorher genannt hatte,
waren eine Schätzung von mir, keine Literaturangabe.

## 3 Auflösung und Glättung — zur Diskussion mit Kshema

Das betrifft die Methode aus dem Shaju-Preprint, also euch beide. Ausgangspunkt
ist der Punkt, den du selbst benennst: der rohe Posterior schwingt zu stark
(Fig. 1.11), und deshalb wird mit $5\sqrt{t}$ nachgeglättet, ohne dass klar ist,
ob diese Breite die richtige ist.

**Die Schwingung ist der Nullraum.** Benachbarte Zeitfenster haben bei den
gemessenen Tiefen fast identische Kerne; ihre Gewichte sind im Posterior stark
antikorreliert. Ein Prior, der nur die Amplitude begrenzt, unterdrückt diese
Richtung nicht. Nachträglich zu glätten ist als *berichtete Grösse* zulässig —
ihr glättet jedes Sample und nehmt die Ensemble-Streuung, das ist ein korrekter
Posterior für $S\theta$. Als *Abhilfe gegen die Schwingung* ist es eine
Symptombehandlung, und der Leser bekommt die Unsicherheit der geglätteten
Grösse, nicht die der Temperatur zu einem Zeitpunkt.

**Die Auflösungsmatrix gibt die Breite, statt sie zu setzen.**
$\mathbf R = \mathbf C\,\mathbf G^\top\Sigma^{-1}\mathbf G$; die Breite jeder Zeile
ist die Mittelungslänge, die die Daten stützen. In meinem Aufbau
(Boxcar-Basis, 17 Fenster, Sensoren ab 26 m):

| t (a) | 10 | 23 | 52 | 120 | 183 | 280 | 640 |
|---|---|---|---|---|---|---|---|
| aus $\mathbf R$ (a) | 16 | 29 | 77 | 126 | 188 | 382 | 1283 |
| $5\sqrt{t}$ (a) | 16 | 24 | 36 | 55 | 68 | 83 | 127 |

$5\sqrt{t}$ trifft die ersten ~30 Jahre. Danach ist die Glättung zu schwach,
bei 280 a um Faktor 4.6. Der ältere Teil der Kurve enthält damit mehr Struktur,
als die Daten stützen — und dort liegt die vorindustrielle Referenz.

Dazu die Zahl, die die Prior-Frage in einem Wert beantwortet:
$\mathrm{Spur}(\mathbf R) = 5.6$ von 17 Parametern. Bei 40 Kernen entspräche das
einem Anteil von ~14 %.

**Warum der Posterior-Mittelwert nicht glatt ist.** Der Mittelwert eines
linear-gaussschen Posteriors ist ein Schrumpfungsschätzer: Richtungen im
Nullraum von $\mathbf G$ werden auf den Prior-Mittelwert gezogen, tragen also
nichts bei, während ihre Varianz voll erhalten bleibt. Glatter Mittelwert bei
breiter Unsicherheit ist damit der Normalfall, nicht die Ausnahme. Die
Singulärwertzerlegung zeigt, woran es hakt (skalierte Designmatrix, Prior-SD 2 K):

| Richtung | 5 | 6 | **7** | 8 | 9 |
|---|---|---|---|---|---|
| Singulärwert $s$ | 5.3 | 1.9 | **0.6** | 0.2 | 0.1 |
| Schrumpfung | 0.99 | 0.93 | **0.57** | 0.11 | 0.01 |
| Rauschverstärkung $\mathrm{shrink}/s$ | 0.19 | 0.50 | **0.99** | 0.62 | 0.24 |

Die Schrumpfung greift erst bei $s\,\sigma_\text{Prior} \ll 1$, also bei
$s < 0.5$. Richtung 7 liegt mit $s = 0.6$ genau auf der Schwelle: der Prior
dämpft sie nicht mehr, die Daten bestimmen sie kaum — und die Rauschverstärkung
ist dort maximal (~1 K pro Einheit skaliertem Rauschen). Diese halb aufgelösten
Richtungen sind die oszillierenden, und sie erzeugen die Schwingung im
Mittelwert. Es ist also kein Rechenfehler und kein Konvergenzproblem, sondern
Rauschverstärkung an der Schrumpfungsschwelle.

Daraus folgt der gezielte Eingriff: **nicht $\sigma_\text{Prior}$ global
verkleinern**, das würde auch die gut bestimmten Richtungen dämpfen und die
Amplitude nach unten verzerren. Stattdessen einen Prior mit Korrelationsstruktur,
der genau die oszillierenden Richtungen bindet und die glatten frei lässt. Eure
Korrelationslänge liegt bei 33 a; die problematische Richtung oszilliert auf
50–100 a. Ein Prior, dessen Korrelation über diesen Bereich reicht, dämpft sie —
bei unveränderter Unsicherheit in den echten Nullraum-Richtungen.

**Kostet ein längerer Prior die jüngsten Dekaden?** Nur bei einem Prior mit
spektralem Abschneiden. Zuerst die Frage, in welchen Richtungen die jüngsten
Dekaden überhaupt stecken — Schwerpunkt jeder Singulärrichtung in log-$t$:

| Richtung | d1 | d2 | d3 | d4 | d5 | d6 | d7 | d8 |
|---|---|---|---|---|---|---|---|---|
| $s$ | 294 | 97 | 34 | 13 | 5.3 | 1.9 | 0.6 | 0.2 |
| Schwerpunkt (a) | 177 | 64 | 41 | 29 | 26 | 24 | 27 | 8 |

Der Bereich **5–40 Jahre liegt in d3–d6**, also bei $s = 34\ldots1.9$ und
Schrumpfung ≥ 0.93. Diese Richtungen bestimmen die Daten; ein Prior berührt sie
nicht. Die **jüngsten 0–5 Jahre** liegen dagegen in d7/d8 ($s = 0.6$ und $0.2$);
das 0–2-a-Fenster lädt zu 0.48 auf d8. Sie sind aus Sensoren ab 26 m **unter
keinem Prior** auflösbar — das ist eine Datengrenze, keine Prior-Grenze, und
genau die, die flache Sensoren schliessen (dein eigener Punkt in 1.4.1).

Der direkte Vergleich, gleiche Daten und gleiches Vorwärtsmodell:

| Prior | (0–20 a) | σ | Rauheit | eff. Freiheitsgrade |
|---|---|---|---|---|
| iid, σ = 2 K | 1.37 | 0.47 | 1.30 | 5.7 |
| SE, ℓ = 33 a (eure) | 1.42 | 0.40 | 0.65 | 4.3 |
| SE, ℓ = 200 a | 1.41 | 0.37 | 0.66 | **3.3** |
| OU in log-$t$ (skalenfrei) | 1.36 | 0.46 | **0.59** | **5.4** |

Die Amplitude der letzten 20 Jahre ist über alle Varianten praktisch unverändert
(1.36–1.42) — sie kommt aus den Daten. Was sich unterscheidet, sind Rauheit und
Freiheitsgrade: ein langes SE kauft Glätte mit Auflösung (5.7 → 3.3), ein
skalenfreier Prior nicht (5.4 bei der geringsten Rauheit und praktisch
unveränderter Unsicherheit).

Der Grund ist das Spektrum. Ein SE-Kern fällt im Frequenzraum gaussisch ab und
verbietet damit alles, was schneller ist als ℓ — auch reale schnelle Änderungen.
Ein Potenzgesetz- oder Matérn-Prior fällt polynomiell ab: er dämpft schnelle
Komponenten nur graduell und sagt nicht „schnelle Änderungen gibt es nicht",
sondern „schnelle Änderungen haben nicht mehr Amplitude als langsame". Das ist
die Aussage, die zu beobachteten Klimaspektren passt.

Ein billiger Konvergenztest fällt dabei ab: der Sampler-Mittelwert muss bei
festem $\varphi$ mit dem analytischen linear-gaussschen Mittelwert
übereinstimmen. Tut er das nicht, liegt zusätzlich ein Mischungsproblem in den
entarteten Richtungen vor.

**Zirkularität.** $\mathbf R$ hängt über $\mathbf C$ vom Prior ab; ein schwächerer
Prior erhöht die Spur. Eine Glättungsbreite aus einem $\mathbf R$ abzuleiten, das
mit iid-Prior gerechnet wurde, ist nicht selbstkonsistent. Sauber wäre ein
Fixpunkt (Korrelationslänge $\ell(t)$ so wählen, dass die Auflösungsbreite gleich
$\ell(t)$ ist) oder die Marginalisierung des Hyperparameters. Als reine
Diagnostik — Spur und Breiten berichten — ist $\mathbf R$ davon unberührt.

**Was der Sampler in der jetzigen Konfiguration leistet.** Die Begründung ist die
Nichtlinearität des Wärmetransports. Ich habe sie gemessen: bei einem Signal von
1.2 K weicht die volle nichtlineare Rechnung von der Linearisierung um 1.1 mK ab,
der Superpositionstest ergibt 0.3 % — beides unter eurer Messgenauigkeit von
2.7–5 mK. Prior und Likelihood sind gaussch, Kernzahl und -breite fest. Der
Posterior ist damit nahezu gaussch.

Das ist kein Argument gegen die MCMC, sondern eines dafür, ihr etwas zu geben,
das sie braucht:

- **Vorwärtsmodell-Parameter marginalisieren** ($\alpha$, Akkumulation,
  Basisschmelze, $\theta_b$, $H$) statt separater Sensitivitätsläufe. Das
  Vorwärtsmodell läuft dann pro Sample — die Rechenlast, die den Cluster
  rechtfertigt — und die angegebenen σ enthielten den Modellfehler. Damit wird
  aus dem Punkt in Abschnitt 2 ein methodisches Argument.
- **Glattheits-Hyperparameter marginalisieren.** Dann entfallen die feste
  20-a-Kernbreite und die Nachglättung; die Zeitskalenstruktur kommt aus den
  Daten.

**Zu eurem Argument, keine Klima-Glättung vorzuschreiben.** Es trägt teilweise.
Ein iid-Prior auf den Gewichten schreibt weniger Struktur vor als ein
Glattheitsprior. Aber die feste Kernbreite von 20 Jahren ist bereits eine
Glättung, gleichmässig über den ganzen Zeitraum aufgeprägt. Die Wahl ist damit
nicht Glättung gegen keine Glättung, sondern uniforme 20-a-Glättung plus
Nachbearbeitung gegen eine zeitskalenbewusste Struktur, die vorne deklariert
wird. Und die volle Unsicherheit steht in Fig. 1.11, während Fig. 1.3 und 1.7
die geglättete zeigen; das Argument gilt also für den Anhang, nicht für die
Hauptabbildungen.

**Aufwand.** Billig und noch für diese Einreichung machbar: Spur($\mathbf R$) und
Auflösungsbreiten berichten, die σ als auf das Vorwärtsmodell konditioniert
kennzeichnen, die Glättungsbreite aus $\mathbf R$ nehmen (mit der Zirkularität
als benannter Näherung). Mittlerer Aufwand, eher Revision: Modellparameter in den
Sampler. Strukturell: Prior mit Korrelationsstruktur statt iid plus
Nachglättung — der Weg, den ihr in 1.4.2 selbst vorschlagt, nur im Prior statt
in der Basis.

Eine linearisierte Lösung würde ich nicht als Methode publizieren, sondern als
Gegenprüfung: sie reproduziert bei dieser Amplitude den Sampler innerhalb der
Messgenauigkeit, läuft in Sekunden und ist ein Konvergenztest. Als Methode
aufgezogen verliert ihr die Möglichkeit, die Modellparameter zu marginalisieren.

---

**Drei Präzisierungen dazu.**

*Liefert eine lineare Lösung die volle Unsicherheit?* Ja — die Posterior-Kovarianz
$\mathbf C = (\mathbf G^\top\Sigma^{-1}\mathbf G + \mathbf P^{-1})^{-1}$ ist exakt und
vollständig; jede lineare Funktion hat die Unsicherheit $\sqrt{a^\top\mathbf C a}$,
ohne Näherung. Was sie nicht liefert: nicht-gausssche Posteriors (bei euch
unkritisch, da $\theta_\text{pom}$ weit von den Grenzen des Uniform-Priors liegt)
und Unsicherheit aus Parametern, die *im Operator* $\mathbf G$ stehen (κ, w, α,
$\theta_b$, $H$). Genau der zweite Punkt ist der, der in den angegebenen σ heute
ohnehin fehlt. Kurz: linear gibt die volle Unsicherheit **bedingt auf das
Vorwärtsmodell**.

*Was Marginalisierung heisst.* Nicht „zusätzlich schätzen und berichten", sondern
$p(\theta\,|\,y) = \int p(\theta,\varphi\,|\,y)\,\mathrm d\varphi$: die
Modellparameter $\varphi$ kommen mit ihren Literaturbereichen als Prior in den
Parametervektor, das Vorwärtsmodell läuft pro Sample mit dem jeweiligen
$\varphi$, und beim Berichten wird über $\varphi$ integriert. Der Modellfehler
steckt dann automatisch in der Breite von $p(\theta|y)$; nichts wird nachträglich
quadratisch addiert. Ob die Daten $\varphi$ einschränken, sieht man nebenbei an
der Marginalverteilung — das ist Diagnostik, nicht das Produkt. Wichtig sind enge,
literaturbasierte Priors auf $\varphi$; sonst handelt der Sampler $\varphi$ gegen
$\theta$ ein und der Posterior wird künstlich breit.

*Stationäre oder zeitabhängige Glattheit?* Ich würde **stationär** wählen. Ein
Prior beschreibt das Klima, nicht das Instrument. Wenn die Glättung mit der Zeit
wächst, weil das Bohrloch weniger auflöst, dann steht eine Instrumenteneigenschaft
im Prior und die Auflösungsdiagnostik misst die eigene Annahme zurück. Der
Auflösungsverlust soll aus der Likelihood kommen, und das tut er: bei einem
stationären Prior wird der Posterior in der Vergangenheit von selbst glatt.

Das ist kein Widerspruch zu „mehr Glättung auf langen Zeitskalen". Ein
**skalenfreier** Prior — gleiche erwartete Varianz pro Oktave der Zeitskala, also
ein $1/f$-artiger Prozess — ist im relevanten Sinn stationär und erzeugt
trotzdem automatisch mehr Glättung bei langen Zeitskalen. Das entspricht dem, was
ich hier als Glättungsprior über log-verteilte Fenster verwendet habe, und es
passt zur beobachteten Skalierung antarktischer Temperaturvariabilität. Zu
vermeiden ist nur eine Glättung, deren Zeitabhängigkeit die Instrumentenauflösung
nachzeichnet (also $\propto\sqrt{t}$).

Zur Wirksamkeit: in meinem Aufbau reicht dieser Prior allein, um die Schwingung
zu beseitigen — ohne Glättung schwanken benachbarte Fenster um ±2 K, mit
skalenfreiem Prior ergibt sich eine monotone Kurve, bei praktisch gleichem
Datenfit.

## 4 Der eine Punkt, der geprüft werden sollte

Rechnet man deine publizierte Kurve mit deinem Vorwärtsmodell vorwärts und hält
sie gegen das Kettenprofil, bleiben systematische Residuen (RMS 58 mK bei
σ = 2.8–7.8 mK), und die gemessenen Raten unterhalb 92 m sind um Faktor ~2
grösser als deine Kurve vorhersagt. Die daraus folgende Korrektur ist mit
+1.29 ± 0.83 K nur 1.6σ, also weder belegt noch ausgeschlossen.

Zwei Erklärungen kommen in Frage, und sie lassen sich trennen:

- die Rekonstruktion ist stärker gedämpft, als die Daten verlangen, oder
- die Kette hat einen **tiefenabhängigen systematischen Messfehler** bei
  111–201 m, also eine mit der Tiefe variierende Abweichung, die die *Form* des
  Profils verzerrt (ein konstanter Offset wäre harmlos). Mögliche Quellen:
  Kalibrationsfehler, der mit der Position auf der Kette korreliert; Fehler in
  den angenommenen Einbautiefen; ein tiefenabhängiges Messartefakt. Die
  NTC1/NTC2-Paare können das nicht sehen, weil sie nur *innerhalb* eines Knotens
  vergleichen.

**Der Test ist die punktweise Differenz der beiden gemessenen Profile.** Dafür
brauche ich von dir nur Tiefe, T und Replikat-SD deines Januar-2024-Logs. Ich
würde das gern dir überlassen — es ist dein Instrument und dein Vergleich. Sag
mir, ob du es machen willst oder ob ich es rechnen soll.

Das ist kein Nebenbefund: falls die Profile abweichen, sollten wir das vor der
Einreichung wissen und nicht von einem Reviewer erfahren.

---

## 5 Ein zweites Paper, wenn du willst

Die Kette misst nicht nur $T(z)$, sondern auch $\partial T/\partial t\,(z)$. Das
ist eine eigenständige Messgrösse mit zwei Eigenschaften, die dem Einzelprofil
fehlen:

- Der **Sensor-zu-Sensor-Offset fällt heraus** — die dominierende Fehlerquelle
  des statischen Profils ist damit weg; übrig bleibt nur Drift.
- Der stationäre Hintergrund erfüllt $\partial_t T_\text{bg} \equiv 0$. Die Rate
  ist damit **strukturell unabhängig vom geothermischen Wärmestrom** und von der
  Basisrandbedingung — genau die Grössen, an denen ein 200-m-Loch sonst hängt.

Die Unsicherheit skaliert mit $T^{-3/2}$. Nach ~3 Jahren schlägt der Ratenkanal
das Profil im Bereich 10–150 Jahre; jenseits ~300 Jahren bleibt er blind. Dazu
kommt, dass dein Winch-Profil (Jan 2024) und das Kettenprofil (2026) zusammen
ein *repeat log* mit zweijähriger Basislinie ergeben — in der
Festgesteins-Geothermik Standard (Davis/Harris/Chapman; Majorowicz), im Eis nach
meiner Literatursuche noch nicht gemacht.

Wir haben die Kette zusammen entwickelt und ausgebracht. **Du hast das Vorrecht
als Erstautorin.** Wenn es nicht deine Richtung ist, suchen wir jemand anderen
und du bist über Instrument und Daten Koautorin. Lass uns das klären, bevor
jemand anfängt zu rechnen.

---

## Material

- `KohnenRecords_Analyse/head04_profile.qmd` — Kettendaten, Messgrössen,
  Fehlerbudget, Ratenprofil
- `KohnenRecords_Analyse/b40_inversion.qmd` — Vorwärtsmodell nach deinem Setup,
  Inversion aus $T(z)$ und $\partial T/\partial t(z)$, Sensitivitätstests,
  Vergleichsrechnungen. Abschnitt 2.3 enthält den Linearitätstest, Abschnitt 5
  die Parameter-Sensitivitäten, Abschnitt 7 die Auflösungsmatrix mit dem Code,
  der Spur und Kernbreiten berechnet.
- Beide gerendert als HTML im selben Verzeichnis.

Die Inversionszahlen darin würde ich nicht zitieren — die Methode ist gegenüber
deiner die schwächere (analytisch linearisiert, 14 Tiefen, 185 Tage). Nützlich
sind die Messgrössen, das Fehlerbudget, die Sensitivitätstabellen und die
Auflösungsrechnung; letztere lässt sich direkt auf deinen Posterior übertragen
und wird damit belastbarer als in meiner Fassung.
