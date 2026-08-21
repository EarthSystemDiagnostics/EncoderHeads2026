# ESD-Schutz für die Iridium-Heads und Teststrategie

Kontext: Beide Kohnen-Heads sind im Winter 2026 exakt an den zwei stärksten
Sturm-/Drifttagen des Jahres verstummt (Details und Beweiskette in
`ausfallanalyse_kohnen.qmd`). Arbeitshypothese: **elektrostatische Entladung
(ESD) durch triboelektrisch aufgeladenen Driftschnee** — Antenne sammelt
Ladung, das lange Koaxkabel zur vergrabenen Box wirkt als Kondensator, die
Entladung geht durch den RF-Eingang des Modems. Dieses Dokument beschreibt
das Schutzkonzept für ein Redesign und wo man es testen kann.

## Verbaute Hardware: Calian/Tallysman TW3600 — ESD-Schutz mehrdeutig dokumentiert

Die Antenne (TW3600, passive Dual-Feed-RHCP-Keramik-Patch,
1616–1626,5 MHz, TNC) wurde **wegen des ESD-Schutzes gewählt** — die
Feature-Liste des Datenblatts (Rev. 202407, S. 1) nennt explizit
„15 kV ESD circuit protection". Die Spezifikationstabelle (S. 2) führt
„ESD Circuit Protection: —", **aber** diese Zeile steht in der
LNA-Sektion, in der bei der passiven Antenne jede Zeile gestrichen ist
(kein LNA) — der Strich widerlegt das Feature nicht. Beides ist möglich:
(a) ESD-Shunt am Feed real (bei passiven Antennen typisch als
Induktivität → DC-Kurzschluss Pin↔Masse; 15 kV ≙ IEC-61000-4-2-
Luftentladung) oder (b) Template-Bullet der aktiven Modelle.

**Geklärt — Antwort von Calian Engineering (08/2026):**

- **Kein dedizierter ESD-/Surge-Schutz** in der passiven TW3600, aber
  **Shunt-Induktivitäten an den Patch-Feed-Punkten**, die statische
  Aufladung der Strahlerelemente ableiten.
- **Der Strahler ist DC-geerdet** zum TNC-Gehäuse (Shunt-Induktivitäten
  + PCB-Montageschrauben) → die „Patch-Insel" existiert nicht; die
  Antennenwahl war auch in dieser Hinsicht richtig.
- Calians eigene Empfehlung für unsere Umgebung: **Inline-Surge-Schutz
  TW170**. Zweite Calian-Antwort (08/2026) + Datenblatt (Rev. 202408):
  - **Hybrid TVS + GDT, Turn-on 14 V** — die TVS-Stufe klemmt in ns
    (kein µs-Zünddelay wie bei reinem GDT), Durchlassenergie ≤175 µJ
    bei 3 kA (8/20 µs), Surge bis 20 kA; Kapsel nach Großereignis
    wechselbar.
  - **0,2 Ω Pin↔Gehäuse gemessen** (Calian) = permanenter DC-Bleed der
    Leitung — faktisch der gewünschte DC-grounded-Typ in einem Bauteil.
  - **1100–1700 MHz** → Iridium abgedeckt; Insertion Loss 0,3–0,5 dB.
  - **Floating-Betrieb von Calian abgesegnet** („preferable … rather
    than no protection at all") — Bonding an die Box genügt.
  - **TNC-Version: 32-0170-01** (2× TNC female), Montage-/Erdungsschellen
    beiliegend; IP67, Edelstahl.
  - Vorbehalte: Operating −40 °C (Kohnen-Box-Minimum −38,5 °C — knapp
    innerhalb, ohne Marge); Baugröße 113 mm × Ø34 mm, 270 g —
    Platz in der Box prüfen; **Inline-Bauform, kein Schott** → fürs
    neue Design bleiben die Schott-Kandidaten unten maßgeblich.
- Calian bietet einen Engineering-Call an → **nach der Antennen-Bergung
  wahrnehmen** (dann mit Befund statt Hypothese).
- [x] ~~Anfrage an Calian~~ (beantwortet, s. o.)
- [ ] Ohmmeter-Verifikation an Ersatz-TW3600: Pin ↔ Gehäuse muss
      **DC-durchgängig** sein (Erwartung laut Hersteller; Calian bietet
      an, einen Referenzwert zu messen).

**Konsequenz für den Mechanismus:** Der *langsame* Aufladungspfad
(Patch/Innenleiter gegen Schirm) wird antennenseitig abgeleitet. Übrig
bleiben **schnelle Transienten** — Insel-Ausgleichsströme der
Kohnen-Geometrie mit Pulsdauern unter der ~50 ns Kabellaufzeit, für die
der Antennen-Shunt am falschen Ende sitzt — sowie mechanischer
Sturmschaden. Der GDT am Modemende + Bonding bleibt die Maßnahme;
da die Leitung über die Antennen-Induktivitäten bereits DC-entladen
wird, genügt am Modemende ein **einfacher GDT-Zwischenstecker (z. B.
Calian TW170)**; die DC-grounded-Stub-Bauform ist nicht mehr zwingend.
Randnotiz: Operating Range der Antenne −40 °C — die Kohnen-Winterluft
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

**Einordnung Grönland-Systeme (GRIP, Dye-3):** Koax nur ~50 cm, Box am
selben Mast — alles ein gebondetes Gestell, das Kohnen-Energiereservoir
(Insel-Ausgleich Mast↔tiefe Box über ~1 nF) existiert nicht. Und die
frühere Restsorge „Patch-Insel" ist durch die Calian-Antwort entschärft:
der Strahler ist über Shunt-Induktivitäten DC-geerdet, langsame
Aufladung fließt ab. Verbleibendes Risiko damit gering (schnelle
Nahfeld-Transienten bei extremem Drift, µJ-Klasse); bei Standortbesuch
GDT-Zwischenstecker als Fünf-Minuten-Versicherung, bis dahin fängt
SD-Logging den Worst Case ab, Status-Diagnostik zeigt einen Ausfall
sofort.

**Folgerung:** vergrabene Architektur behalten, die Mast↔Box-Entkopplung
explizit reparieren: (1) Bonding-Leiter (Cu-Band) parallel zum Koax von
Antennensockel/Mast bis zur Box, beidseitig angeschlossen — Mast, Schirm
und Box auf einem Potenzial, die Aufladung entsteht gar nicht erst;
(2)+(3) **ein Bauteil:** der **Calian TW170 (32-0170-01, 2× TNC)** als
Inline-Element **am Modemanschluss in der Box** — Hybrid TVS + GDT
(Turn-on 14 V in ns, Durchlass ≤175 µJ), Pin↔Gehäuse 0,2 Ω = eigener
permanenter DC-Bleed der Leitung (zusätzlich zu den
Shunt-Induktivitäten in der TW3600). Beiliegende Erdungsschelle auf
Boxbolzen/-wand = Bonding miterledigt. Kabel, KEL-Verschraubung und der
TNC oben im Mast bleiben unberührt (dort ist ohnehin kein Zugang). Rein
passiv, kein Strombedarf, Thermik unverändert. (Platz prüfen: 113 mm ×
Ø34 mm.)

Vorab-Prüfpunkt (Ohmmeter, Verifikation): TW3600 zwischen
TNC-Innenleiter und -Gehäuse muss **DC-durchgängig** messen
(Herstellerangabe: Shunt-Induktivitäten + PCB-Schrauben). Falls eine
Antenne offen misst → Exemplar defekt/abweichend, dann DC-grounded-
Ableiter statt einfachem GDT verwenden.

**Antennen-Alternative für die nächste Generation — Marine-Rohrantennen
(Quadrifilar-Helix):** z. B. Beam RST710/RST210, 2J-QFH; passiv, TNC,
−40…+85 °C. Viele Helix-Bauformen sind konstruktiv **DC-geerdet**
(kurzgeschlossene Arme/induktive Speisung) → Patch-Insel entfällt,
Statik fließt permanent ab; zudem weniger horizontale
Ablagerungsfläche als der Pilz-Radom und tolerant gegen
Mast-Schiefstand. Bauartabhängig, in Datenblättern nicht spezifiziert —
**per Ohmmeter verifizieren** (TNC-Pin↔Gehäuse, DC-Kurzschluss =
inhärent statik-sicher). Jetzt nicht tauschen (Mechanik + Tests);
Kandidat fürs Redesign.

**Gehäuse-Bonding — die zwei Konfigurationen unterscheiden sich:**

*Grönland (GRIP, Dye-3):* mechanisch durchgebondet — Antennensockel
(Gewindestutzen, Zamak) → gefrästes Alu-Teil → Alu-Mast →
Schlauchschellen → Alu-Box, Koax nur ~50 cm. Implizit die
AWS-Architektur „alles ein Metallgestell": Groundplane, Mast und Box auf
einem Potenzial, der Mast **ist** der Bonding-Leiter; Elektronik-GND
hängt über den Koax-Schirm am selben Netz. Prüfpunkte sind nur die
Kontaktstellen (Durchgangsmessung: Gewinde Sockel↔Frästeil,
Frästeil↔Mast, Schellen↔Box — **eloxiertes/lackiertes Alu isoliert**).

*Antarktis (Kohnen):* Antenne über TNC-Gehäuse/Frästeil mit dem Mast
verbunden, aber **der Mast steht im Schnee, entkoppelt von der ~8 m
tiefen Box** mit Elektronik und Modem. Zwei Potenzialinseln, einzige
leitende Verbindung ist der Koax-Schirm — jeder Ladungsausgleich und
jede Entladung zwischen Mast/Antenne und Box läuft zwangsläufig über
den Schirm **direkt am Modemstecker vorbei**. Deshalb ist hier das
Cu-Bonding-Band Mast↔Box parallel zum Koax zwingend (Punkt 1 der
Folgerung), dazu der GDT in der Box.

**Einbauform des GDT — Retrofit vs. Neubau:** Für die **Nachrüstung im
Feld** der Inline-Zwischenstecker direkt am Modemanschluss: alle
Steckverbindungen bleiben in der dichten Box, KEL-Durchführung und
Kabel unberührt, zwei Schraubvorgänge, Bonding-Fahne auf Gehäusebolzen.
Der **Schott-Ableiter in der Boxwand** (Durchführungsgehäuse mit
Montagegewinde, 360°-Chassisbond am Eintritt, Entladestrom bleibt auf
der Außenhaut — EMV-ideal) ist die Lösung für die **nächste
Box-Generation** ab Werkstatt: Im Feld erforderte er Adapterplatte an
der KEL-Position, einen Innen-Jumper zum Modem und verlagerte die
Kabel-Steckverbindung nach außen (Firn/Wetterseite) — eine neue
Dichtungs-Schwachstelle, wo der Zwischenstecker alle Übergänge im
Trockenen lässt.

Schott-Kandidaten für den Neubau (GDT, wechselbare Kapsel, ≥1,63 GHz,
−55 °C, DC-pass; N-Anschluss ist Klassenstandard → Durchführung in N
planen, Innen-Jumper N→Modem): **Huber+Suhner 3402-Serie** (EMP
Protector, Flansch/Schott), **PolyPhaser IS-B50-Serie** (z. B.
IS-B50LN-C2), **Times Microwave LP-GTR**, **Citel P8AX**. Calian TW170:
Datenblatt/Montagevarianten bei Calian angefragt (s. Antwortmail);
Kapsel-Zündspannung ~90–230 V wählen.

**Patch-Insel: durch Calian-Antwort entschärft.** Der Strahler ist über
Shunt-Induktivitäten DC-geerdet (s. o.) — langsame Radom-/Patch-Aufladung
fließt ab. Was kein antennenseitiger Shunt abdeckt, sind **schnelle
Transienten am Modemende** (Kohnen-Inselgeometrie); dafür der GDT in
der Box.

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

**Einsatzstrategie — Zwei-Phasen-Plan (Randbedingungen: wenige Stunden
vor Ort, Person ohne Systemkenntnis; Modem verlötet, Ketten an
PicoBlades in der Elektronik — Elektroniktausch im Feld zu riskant.
Die Elektronik hängt an Rohr/Seil im luftgefüllten Bohrloch und ist
einfach hochziehbar; Kabel im Rohr → keine Setzungslasten):**

*Phase 1 — diese Saison, narrensicher (laminierte Schrittkarte):*

1. Foto-Doku: Mast, Antenne, Abspannung, Überschlagspuren.
2. **NanoVNA ans obere Kabelende** (Antenne ab, Analyzer an, Preset,
   Bildschirmfoto): angepasstes S11 = Kabel + Modem-Frontend intakt;
   Totalreflexion = Fehler unten. Klärt in 2 min Antenne vs. Pfad und
   die Kabelfrage (Stecker-Lichtbogenschäden, Reif im oberen TNC).
3. **Antenne tauschen** (Ohmmeter-verifizierte Ersatz-TW3600).
4. Elektronik **hochziehen, SD kopieren/tauschen** — Kettenstecker
   (PicoBlade) bleiben unberührt — wieder ablassen (Seillänge stellt
   Position wieder her).
5. **Besuch um einen Sendeslot planen** (head03 09:03/21:03 UTC,
   head04 17:38 UTC): Erfolg nach Antennentausch live in Cloudloop.
6. Alte Antenne mit nach Hause (Forensik).

Fallnetz: Lebt die Elektronik (Telemetrie-Historie spricht dafür),
**läuft die Messung auch ohne Telemetrie weiter** — Daten via jährliche
SD-Bergung. War die Antenne der Fehler, sind die Systeme wieder live.

Prüfpunkt vorab: Endet das Koax in der Box an einem **Steckverbinder**
zum Modem (u.FL/SMA-Pigtail)? Dann GDT-Zwischenstecker schon in
Phase 1; verlötet → GDT erst Phase 2.

*Phase 2 — Saison mit Entwickler/Zeit:* Kompletttausch mit zuhause
gebauten und getesteten Einheiten (Schott-GDT, Bonding ab Werk; Gates:
Iridium-Session durch den Ableiter + Puls-Test), PicoBlade-Transfer im
Windschutz; ausgefallene Elektronik zur Forensik (Frontend durchmessen,
Überschlagspuren) — der definitive Hypothesentest. Vorbereitung: neue
Modem-IMEIs bei Cloudloop aktivieren + Pipeline-Mapping anpassen.

**Design-Lehren nächste Generation** (aus diesem Dilemma): steckbares
Telemetrie-Modul (Modem feldtauschbar in Minuten), Schott-GDT ab Werk,
feldfreundliche Kettensteckverbindung statt PicoBlade, Servicekonzept
„hochziehen + Modul tauschen".

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
