#!/bin/bash
# scripts/patch.sh — PHASE 2 STUB
#
# Will graft the subset Nerd Font glyphs (from scripts/subset-nerd.sh)
# into each weight of Iosevka IDS, producing the merged
# `IosevkaIDS Nerd Font` variant.
#
# Intended pipeline (Phase 2):
#   1. For each IosevkaIDS-<weight>.ttf in out/:
#        fontforge -script font-patcher \
#          --use-single-width-glyphs \
#          --mono \
#          --custom out/nerd-subset.ttf \
#          out/IosevkaIDS-<weight>.ttf
#      → produces IosevkaIDSNerdFontMono-<weight>.ttf in out/
#   2. Rename to a clean family name; verify glyph counts.
#   3. Regenerate SHA256SUMS to include the new merged TTFs.
#
# Dependencies: fontforge (`apt install fontforge`), Nerd Fonts'
# font-patcher script (vendored or cloned from
# https://github.com/ryanoasis/nerd-fonts at a pinned tag).
#
# Not yet implemented. PR welcome.

set -euo pipefail
echo "patch.sh: not yet implemented (Phase 2 scaffold)" >&2
exit 64
