# ESD-Schutz für die Iridium-Heads und Teststrategie

Kontext: Beide Kohnen-Heads sind im Winter 2026 exakt an den zwei stärksten
Sturm-/Drifttagen des Jahres verstummt (Details und Beweiskette in
`ausfallanalyse_kohnen.qmd`). Arbeitshypothese: **elektrostatische Entladung
(ESD) durch triboelektrisch aufgeladenen Driftschnee** — Antenne sammelt
Ladung, das lange Koaxkabel zur vergrabenen Box wirkt als Kondensator, die
Entladung geht durch den RF-Eingang des Modems. Dieses Dokument beschreibt
das Schutzkonzept für ein Redesign und wo man es testen kann.

## Verbaute Hardware: Calian/Tallysman TW3600 — kein ESD-Schutz

Die verbaute Antenne (TW3600, passive Dual-Feed-RHCP-Keramik-Patch,
1616–1626,5 MHz, TNC) hat **keinen ESD-Schutz**: Die Spezifikationstabelle
des Datenblatts (Rev. 202407, S. 2) führt „ESD Circuit Protection: —";
der Feature-Bullet „15 kV ESD circuit protection" auf S. 1 ist Boilerplate
der aktiven Calian-Antennen und trifft auf die passive TW3600 nicht zu.
Konsequenzen:

- Das LEXAN-Radom ist ein Isolator und lädt sich im Driftschnee auf; der
  Patch koppelt direkt auf die Feeds — ohne dokumentierten DC-Pfad zur
  Masse geht jede Entladung über den Innenleiter zum Modem.
- Der Zamak-Metallsockel (Through-hole, 100-mm-Groundplane) ist bondbar —
  Sockel und Groundplane gehören aufs gemeinsame Potenzial.
- Der **externe Inline-GDT am Boxeintritt ist damit zwingend**, nicht
  optional.
- Operating Range der Antenne: −40 °C — die Kohnen-Winterluft
  unterschreitet auch diese Spezifikation.

Datenblatt: https://sites.calian.com/app/uploads/sites/8/2024/06/Calian%C2%AE-TW3600-Datasheet.pdf

## Schutzkonzept (kein Erdungs-, sondern ein Bonding-Problem)

Auf Firn gibt es keine Erde (trockener Schnee/Firn ist praktisch ein
Isolator, darunter km Eis). Es gilt das Flugzeug-Prinzip (P-Static): nicht
das Aufladen des Gesamtsystems verhindern, sondern **Potenzialdifferenzen
innerhalb des Systems** — nur die zerstören Elektronik.

1. **Bonding:** alle Metallteile (Mast, Antennenfuß, Box, Kettenrohr) leitend
   auf ein gemeinsames Potenzial.
2. **DC-kurzgeschlossene Antenne:** Bauform mit galvanischer Verbindung
   Strahler↔Schirm (Loop, kurzgeschlossener Stub) — Statik kann über den
   Feed keine Spannung aufbauen. Alternativ Bleed-Widerstand (1–10 MΩ)
   über den Feed.
3. **Gasableiter (GDT) am Modem-Eingang** (koaxialer Inline-Ableiter am
   Boxeintritt, gebondet): Edelgas-Funkenstrecke, unterhalb der Zündspannung
   offen (< 1 pF → RF-transparent bei 1,6 GHz), oberhalb (90–350 V)
   Townsend-Lawine → Bogenmodus mit < 1 Ω und ~10–20 V Brennspannung —
   leitet die Ladung am Frontend vorbei, löscht selbst (kein DC in der
   Antennenleitung), beliebig oft wiederverwendbar. Schwäche: µs-träge —
   gegen die *langsam* aufbauende Driftschnee-Aufladung genau richtig,
   gegen extrem steile Einzelpulse nur zusammen mit 1./2. (gestaffelter
   Schutz).
4. **λ/4-Stub als elegante Alternative:** kurzgeschlossener
   Viertelwellen-Stub = DC-Kurzschluss (Statik), bei 1,6 GHz auf offen
   transformiert (Nutzsignal unbeeinflusst).
5. **Static Wicks / Korona-Spitzen** an der Mastspitze: kontrollierter
   Ladungsabbau an die Luft, bevor Überschlagspotenziale erreicht werden
   (Luftfahrt-Standardlösung).

## Architektur-Entscheidung: Box bleibt vergraben

Die klassischen Plateau-AWS (AMRC/Wisconsin, IMAU, AAD) sind implizit
ESD-robust, weil Elektronikbox und Antenne am selben Metallmast sitzen
(Koax < 1 m, alles ein Potenzial). Diese Architektur ist für uns **nicht**
übernehmbar:

- Die mK-Thermometrie braucht eine thermisch stabile Messelektronik — die
  vergrabene Box (~8–10 m, Jahresgang ~1.2 K) ist Voraussetzung der
  Messqualität, nicht Bequemlichkeit.
- Batteriekapazität bei −37 °C statt −60 °C Winterluft.
- Variante „nur Modem an den Mast" (serielle Leitung statt RF-Koax hoch —
  digitale Leitungen wären trivial schützbar) scheitert an der
  Modem-Spezifikation (−40 °C) gegenüber −60 °C Mastluft; ein Heizer ist
  im Batterie-Budget nicht darstellbar.
- Einordnung: Es gibt für SBD nur die 9602/9603-Familie — die anderen
  Netze betreiben dieselben Modems am Mast **außerhalb der Spezifikation**
  (isolierte Box, Eigenerwärmung; −40 °C ist Garantiegrenze, kein hartes
  Funktionsende, kritisch sind Kaltstarts) und bezahlen mit den bekannten
  Winterlücken der Plateau-AWS-Records. Das vergrabene Design ist die
  einzige Architektur, die das Modem ganzjährig **innerhalb** der Spez
  hält — der einzige Konstruktionsfehler war der ungeschützte RF-Pfad.

**Folgerung:** vergrabene Architektur behalten, die Mast↔Box-Entkopplung
explizit reparieren: (1) Bonding-Leiter (Cu-Band) parallel zum Koax von
Antennensockel/Mast bis zur Box, beidseitig angeschlossen — Mast, Schirm
und Box auf einem Potenzial, die Aufladung entsteht gar nicht erst;
(2) GDT am Boxeintritt für den differentiellen Rest auf dem Innenleiter;
(3) Bleed/DC-Kurzschluss antennenseitig. Rein passiv, kein Strombedarf,
Thermik unverändert.

## Teststrategie

Zwei Testziele trennen:

### 1. Funktioniert der Schutz elektrisch? — Labor, ohne Schnee

Antenne über MΩ-Vorwiderstand mit HV-Netzteil bzw. ESD-Generator
(IEC 61000-4-2, bis ±30 kV) beaufschlagen; prüfen: GDT zündet, Modem
überlebt, S11/Empfindlichkeit des RF-Pfads unverändert. In-house oder mit
einem HV-Labor einer TU. **Zuerst machen — billig, beantwortet „hält der
Frontend das aus".**

### 2. Wie stark lädt sich das System im realen Drift auf? — Windkanal & Feld

- **SLF Davos, Kaltwindkanal mit Schneeverfrachtung:** driftender trockener
  Schnee bei kontrollierter Temperatur/Wind — einzige Umgebung für
  *kontrollierte* Aufladungsmessung (Feldmühle/Elektrometer am
  Mast-Mockup). Industrievariante: Klimawindkanal Rail Tec Arsenal Wien
  (bis −40 °C, Schneekanonen).
- **Alpen-Feldstationen:** Col du Lac Blanc (2720 m, INRAE/Météo-France-CEN
  — europäischer Referenzstandort für Schneedrift), SLF-Versuchsfelder
  Weissfluhjoch/Gaudergrat, Sonnblick-Observatorium (3106 m, GeoSphere
  Austria), UFS Schneefernerhaus/Zugspitze (deutsches Konsortium, einfacher
  Zugang), Jungfraujoch (eher Riming als trockener Drift).
- **Einschränkung Alpen:** alpiner Schnee ist wärmer/feuchter; maximale
  Aufladung braucht kalten, trockenen Schnee + Starkwind. Antarktische
  Größenordnung nur in Hochwinter-Kälteperioden > ~2500 m annähernd
  erreichbar. Für Mechanik (Mast, Kabel, Verwehung) sind die Alpen voll
  repräsentativ.

### 3. Realistischster Test: Neumayer III

Katabatische Stürme mit trockenem Drift, ganzjährig Personal, AWI-Logistik.
Redesignten Mast mit Feldmühle einen Winter durchlaufen lassen, bevor etwas
wieder nach Kohnen geht.

**Minimalprogramm (Zeit-/Testkapazität knapp, Iridium gesetzt):** Zwei
Tests genügen als Gate, beide in Tagen machbar: (1) Iridium-Session durch
den GDT (Einfügedämpfung verifizieren — halber Tag am Dach/Feld);
(2) Puls-Test auf die geschützte Leitung (ESD-Generator/HV über MΩ),
danach Session-Test. SLF-Windkanal und Neumayer-Winter sind damit
Optionen, keine Gates — ihr Restrisiko (Ladungsabfluss im realen Drift)
ist durch Bleed + Bonding konstruktiv adressiert.

**Nachrüstsatz Sommerbesuch:** 2× Inline-GDT (TNC, + Ersatzkapseln),
Cu-Bondingband + Schellen (mit Dehnungsreserve), MΩ-Bleed-Widerstände,
Ersatz-Antenne, Ersatz-Modem, SD-Lesegerät.

## Erfahrungswert SWARM: winterfest — und warum

Mit SWARM-Telemetrie (VHF 137–150 MHz, inzwischen von SpaceX eingestellt)
gab es in der Antarktis **keine Winterausfälle**. Das stützt die
ESD-Diagnose: VHF-Whips/Helices sind typischerweise **inhärent DC-geerdet**
(Shunt-Induktivität im Matching, geerdeter Strahlerfuß) — Statik fließt
kontinuierlich ab; zudem sind VHF-Frontends ESD-toleranter als
1,6-GHz-LNAs. Der Wechsel zu Iridium führte die Verwundbarkeit ein
(kapazitiver L-Band-Patch ohne DC-Pfad + langes Koax + ungeschützter
Frontend); der Bleed/DC-Kurzschluss im Schutzkonzept stellt genau die
SWARM-Eigenschaft wieder her.

**Echtzeit ist nicht gefordert** — damit sind die polartauglichen
Store-and-forward-Nachfolger vollwertige Kandidaten für die nächste
Gerätegeneration, denn sie lösen das Statikproblem an der Wurzel
(UHF/VHF-Klasse mit inhärent DC-geerdeten Antennen) statt es zu flicken:

- **Kinéis** (Argos-Nachfolge, 25 Nanosats, 401 MHz UHF): robusteste
  Frequenzklasse, gute Polabdeckung (Argos-Erbe); kleine Payloads —
  340 B müssten gestückelt werden.
- **Astrocast** (L-Band, polar, ~160 B/Message): größere Payloads, aber
  wieder L-Band-Patch → gleicher Schutzbedarf wie Iridium.
- **Myriota** (UHF, polar): sehr kleine Payloads.

**Entscheidung: Iridium bleibt.** Die gesamte Kette (Firmware, Encoder,
Cloudloop-Pipeline, Decoder) ist mit Iridium integriert und getestet;
Zeit und Testkapazität für eine Netz-Migration (neues Modem, neue
Firmware, neues Bodensegment, neue Tests) sind nicht vorhanden.
UHF/Kinéis bleibt als Langfrist-Option für eine spätere Generation
notiert (statik-sicherste Frequenzklasse; Prüfpunkte: Payload-Stückelung
340 B, Modem-Kältespez, Service-Langlebigkeit — SWARM-Lektion).

Der passive Schutz kostet **null Integrationsaufwand**: GDT =
Zwischenstecker, Bonding = Kupferband, Bleed = Widerstand — keine
Firmware-, Decoder- oder Vertragsänderung.

## Ist das sicher lösbar? — Einschätzung und Restrisiko

Der Schutz selbst ist erprobte Standardtechnik mit großen Reserven: die
~mJ-Energien (1 nF Koax auf einige kV) liegen Größenordnungen unter der
Auslegung üblicher Koax-Ableiter (Blitzschutz, kA); die langsame
Driftschnee-Aufladung ist der Idealfall für GDTs (µs-Zünddelay
irrelevant, keine Blitze auf dem Plateau); die drei Maßnahmen (Bleed,
Bonding, GDT) greifen redundant an verschiedenen Stellen; die Luftfahrt
löst dasselbe Problem routinemäßig an empfindlicherer Avionik.

Restrisiken:

1. **Die Ursache ist noch Hypothese** — gegen mechanischen Sturmschaden
   (Mast/Kabel) hilft ESD-Schutz nicht. Klärung: Sommerinspektion +
   SD-Auslese. Der Schutz ist unabhängig davon einzubauen (passiv, billig).
2. **Ausführungsqualität:** Bonding-Band braucht Dehnungsreserve für die
   Relativbewegung Mast↔Firn (Setzung/Akkumulation); Steckverbinder
   gasdicht bei −60 °C; GDT-Kapsel für Kälte spezifiziert (üblich −55 °C —
   prüfen).

Absicherung über die Teststaffel: ESD-Bench („Frontend überlebt") →
SLF-Windkanal mit Feldmühle („Aufladung wird abgeführt") →
Neumayer-Winter („übersteht reale Driftstürme"). Optionale Redundanz:
zweiter, geschalteter Antennenpfad (Diversity) gegen Einzelpfad-Schäden.

## Literatur (Driftschnee-Elektrifizierung)

- Herman (1965): Precipitation Static and Electrical Properties of Blowing
  Snow at Byrd Station, Antarctica. Antarctic Research Series —
  https://doi.org/10.1029/AR004p0221
- Gordon & Taylor: The Electrification of Blowing Snow.
- E-Feld-Messungen bei antarktischen Blizzards (Felder > 10³ V/m):
  https://www.sciencedirect.com/science/article/abs/pii/S0169809521003689
