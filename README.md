# EncoderHeads 2026

R tooling for the thermometry encoder heads deployed at Kohnen Station (Antarctica) and on the Greenland ice sheet.

## Repository structure

```
EncoderHeads2026/
├── EncodingHeads.qmd          # Encoding documentation: binary → hex → physical units
├── rechner.qmd                # Message size / transmission budget calculator
├── meta/
│   └── HeadsUndKetten.xlsx    # Head and chain inventory
│
├── KohnenRecords_Analyse/     # Kohnen Station (Antarctica) — heads 03 & 04
│   ├── fetch_cloudloop.R      # Fetch MO messages from Cloudloop API
│   ├── decode_results3.R      # Decode from Cloudloop CSV export
│   ├── decode_combined.R      # Merge old + new CSV exports and decode
│   ├── head03_profile.qmd     # Analysis profile — head03 (35 nodes, modem 231709)
│   ├── head04_profile.qmd     # Analysis profile — head04 (25 nodes, modem 231710)
│   ├── explore_head04.R
│   ├── make_plots.R / plot_*.R
│   └── data/                  # Raw CSV exports and decoded results
│
└── Greenland2026/             # Greenland field campaign — heads 26-02…26-05
    ├── decode_field.qmd       # ← MAIN FIELD TOOL: paste hex → plots + CSV
    └── data/                  # Field decode outputs (gitignored)
```

## Instruments

| Head    | Modem  | Nodes | Fields per node          | Deployment     |
|---------|--------|-------|--------------------------|----------------|
| 26-02   | 228680 | 24    | NTC1, NTC2, TestSB       | Greenland 2026 |
| 26-03   | 234047 | 24    | NTC1, NTC2, TestSB       | Greenland 2026 |
| 26-04   | 234048 | 20    | NTC1, NTC2, GND          | Greenland 2026 |
| 26-05   | 228679 | 20    | NTC1, NTC2, GND          | Greenland 2026 |
| head03  | 231709 | 35    | NTC1, NTC2, GND, P       | Kohnen (Ant.)  |
| head04  | 231710 | 25    | NTC1, NTC2, TestSB, GND  | Kohnen (Ant.)  |

Heads 26-02 and 26-03 are SnowMelt sensors with nodes at 4 cm vertical spacing (node 1 = deepest).

## Greenland field use

1. Open `Greenland2026/decode_field.qmd` in RStudio
2. Set `HEAD_ID` and paste the hex payload(s) from the Cloudloop email into `MSG1` / `MSG2`
3. Render (`Ctrl+Shift+K`) → temperature profile, diagnostics, CSV saved to `Greenland2026/data/`

Expected message sizes:

| Head type     | Bytes | Hex chars |
|---------------|-------|-----------|
| 26-02 / 26-03 | 225   | 450       |
| 26-04 / 26-05 | 169   | 338       |

## Dependencies

```r
install.packages(c("dplyr", "tidyr", "ggplot2", "lubridate", "patchwork",
                   "httr2", "base64enc", "readr", "purrr"))
```
