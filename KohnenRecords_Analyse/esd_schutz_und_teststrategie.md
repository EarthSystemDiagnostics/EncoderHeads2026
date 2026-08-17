# ESD-Schutz für die Iridium-Heads und Teststrategie

Kontext: Beide Kohnen-Heads sind im Winter 2026 exakt an den zwei stärksten
Sturm-/Drifttagen des Jahres verstummt (Details und Beweiskette in
`ausfallanalyse_kohnen.qmd`). Arbeitshypothese: **elektrostatische Entladung
(ESD) durch triboelektrisch aufgeladenen Driftschnee** — Antenne sammelt
Ladung, das lange Koaxkabel zur vergrabenen Box wirkt als Kondensator, die
Entladung geht durch den RF-Eingang des Modems. Dieses Dokument beschreibt
das Schutzkonzept für ein Redesign und wo man es testen kann.

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

**Pragmatische Reihenfolge:** ESD-Bench → SLF-Windkanal (1–2 Wochen
Kampagne) → Winter auf Neumayer → Kohnen.

## Literatur (Driftschnee-Elektrifizierung)

- Herman (1965): Precipitation Static and Electrical Properties of Blowing
  Snow at Byrd Station, Antarctica. Antarctic Research Series —
  https://doi.org/10.1029/AR004p0221
- Gordon & Taylor: The Electrification of Blowing Snow.
- E-Feld-Messungen bei antarktischen Blizzards (Felder > 10³ V/m):
  https://www.sciencedirect.com/science/article/abs/pii/S0169809521003689
