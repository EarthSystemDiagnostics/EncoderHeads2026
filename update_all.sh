#!/usr/bin/env bash
# update_all.sh — one-shot refresh: fetch all Cloudloop data, decode, re-render all reports.
#
# Auth: needs the Cloudloop token in $CLOUDLOOP_TOKEN or cloudloop/.token (git-ignored).
# Idempotent: both fetchers dedup against what is already on disk, so re-running is safe.
#
# Usage:  ./update_all.sh
set -euo pipefail
cd "$(dirname "$0")"

echo "== 1/4  Greenland fetch (Cloudloop API → testdata/*.bin) =="
Rscript fetch_cloudloop_greenland.R

echo "== 2/4  Antarctic fetch + decode (→ KohnenRecords_Analyse/data/) =="
(cd KohnenRecords_Analyse &&
   Rscript fetch_antarctic_cloudloop.R &&
   Rscript decode_combined.R)

echo "== 3/4  Render Greenland reports =="
(cd Greenland2026 &&
   for d in decode_snowmelt_newgrip decode_snowmelt_dye3 decode_chain system_state; do
     quarto render "$d.qmd"
   done)

echo "== 4/4  Render Kohnen reports =="
(cd KohnenRecords_Analyse &&
   for d in head03_profile head04_profile ausfallanalyse_kohnen vergleich_b50_b40; do
     quarto render "$d.qmd"
   done)

echo "Done. Reports: Greenland2026/*.html, KohnenRecords_Analyse/head0{3,4}_profile.html"
