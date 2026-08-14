# CLAUDE.md — EncoderHeads2026

Decoder und Analyse für Thermometrie-Encoder-Heads: Grönland-Kampagne 2026
(GRIP, Dye-3) und Kohnen-Station (Antarktis). Workflow-Details im README.

## Kernregeln

- **Identifikation ausschließlich per IMEI** (Präfix des `.bin`-Dateinamens bzw.
  IMEI-Zeile der Cloudloop-Mail). `head_config[[IMEI]]` in den Quarto-Dokumenten
  ist autoritativ für n_nodes / fields / type / spacing / Kalibrierung —
  **niemals** Konfiguration aus dem Nachrichteninhalt ableiten.
- **Daten-Update:** `./update_all.sh` (Cloudloop-Fetch Grönland + Antarktis,
  Decode, alle Reports rendern). Idempotent, beliebig oft ausführbar.
- **Cloudloop-Token:** `$CLOUDLOOP_TOKEN` oder `cloudloop/.token` (erste Zeile).
  Der Ordner ist git-ignored — Token nie committen; neue Mitarbeitende bekommen
  ihn über einen sicheren Kanal und legen die Datei selbst an.
- **Nur die Cloudloop-API verwenden** — der Web-CSV-Export kappt Payloads bei
  128 B.
- **Keine Auto-Commits:** committen und pushen nur auf ausdrückliche Anweisung.
- **Sachliche Sprache** in Dokumenten und Befunden: Zahl + Unsicherheit, keine
  rhetorischen Verstärker.

## Instrumente (Stand August 2026)

| System | IMEI / Modem | Besonderheiten |
|---|---|---|
| SnowMelt GRIP | 300434065508020 | Tape-/Folien-Experiment Knoten 6–8 (02.–12.07.) — in allen Diagnostiken ausgeschnitten (`series_diag`); ab 10.08. beginnendes Einschneien der untersten Sensoren |
| SnowMelt Dye3 | 301434062008160 | Kettenende ~40 cm über Oberfläche montiert; Knoten 1–2 mit exponierter Platine (weißes Silikon); N28_NTC2 defekt (auto-NA) |
| Doppelkette | 301434062008130 | NTC1/NTC2 Replikate, TestSB/TestN/GND diagnostisch, Druck decodiert |
| Kohnen head03 | Modem 231709 | 35 Knoten; **sendet seit 22.07.2026 nicht mehr** |
| Kohnen head04 | Modem 231710 | 25 Knoten; läuft; Lab-S4-Kalibrierung 2023 |

- Kalibrierung: Lab-S4 pro Sensor wo vorhanden, sonst universelle Mean-S4-Kurve
  (`Greenland2026/derive_mean_calibration.R`); Beta-Kurve nur für Diagnostik.
- Die Einschneidiagnostik in den SnowMelt-Dokumenten rechnet bei jedem Render
  neu (Dämpfung relativ zur Atmosphäre, Ein-Tages-Urteil, AWS-Abgleich via
  GEUS-THREDDS: GRIP↔Summit, Dye3↔NASA-SE).
