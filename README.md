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
    ├── decode_core.R          # Shared decode + calibration functions (sourced by all docs)
    ├── decode_snowmelt_newgrip.qmd  # ← SnowMelt GRIP (IMEI 300434065508020): melt profile
    ├── decode_snowmelt_dye3.qmd     # ← SnowMelt Dye3 (IMEI 301434062008160): melt profile
    ├── decode_chain.qmd       # ← Doppelkette (IMEI 301434062008130): borehole depth profile
    ├── system_state.qmd       # ← Betriebs-Dashboard: Latenz (Uhr-Offset) & Batterie, alle 3
    ├── tape_experiment.qmd    # Black-tape solar-absorption experiment (SnowMelt)
    ├── derive_mean_calibration.R  # Universal mean lab-S4 fallback coefficients
    └── data/                  # Field decode outputs (tracked; filenames keyed by message time)
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

The decoder is **field-driven and keyed solely by IMEI** (the `.bin` filename prefix, e.g.
`300434065508020-57.bin`). **Three** heads send in parallel, each with its own report
document sharing `decode_core.R`. IMEI ↔ Rockblock modem serial (payload-verified):

| Head | IMEI | Rockblock device | Document |
|---|---|---|---|
| SnowMelt GRIP | `300434065508020` | 234048 – Head_26-04 | `decode_snowmelt_newgrip.qmd` |
| SnowMelt Dye3 | `301434062008160` | 228679 – Head_26-05 | `decode_snowmelt_dye3.qmd` |
| Doppelkette (chain) | `301434062008130` | 228680 – Head_26-02 | `decode_chain.qmd` |

Workflow:

1. Add `.bin` messages to `testdata/` — either the Cloudloop e-mail attachment, or from a
   Rockblock CSV export in `download/` (extract per IMEI; the CSV names devices by modem
   serial, see the table above).
2. Open the matching document in RStudio. `BIN_FILE` already globs all `.bin` for that IMEI;
   a vector of files renders a time series. (A hex payload can still be pasted into `MSG1` /
   `MSG2` in the SnowMelt docs instead.)
3. Render (`Ctrl+Shift+K`) → profile, diagnostics, and CSV(s) saved to `Greenland2026/data/`.

The head's `n_nodes` / `fields` / `type` / `spacing` / calibration come from `head_config[[IMEI]]`
inside each document — never derived from the message body. Counts→°C use the per-sensor lab
Steinhart–Hart fit where a calibration table exists, else the universal **mean lab-S4 curve**
(`derive_mean_calibration.R`); the legacy Beta curve is kept only for diagnostics.

Expected `.bin` message sizes (two firmware variants — every field is `0x7C`-separated or
concatenated; a defective sensor can add a few bytes):

| Device (IMEI)              | Nodes × fields              | sep (B) | nosep (B) |
|----------------------------|-----------------------------|--------:|----------:|
| SnowMelt (300434065508020) | 24 × NTC1/NTC2/TestSB        | 299     | 225       |
| Doppelkette (301434062008130) | 20 × NTC1/NTC2/GND/Pressure | 311     | 229       |

## Dependencies

```r
install.packages(c("dplyr", "tidyr", "ggplot2", "lubridate", "patchwork",
                   "httr2", "base64enc", "readr", "purrr"))
```
