#!/bin/bash
# scripts/subset-nerd.sh — PHASE 2 STUB
#
# Will subset Symbols Nerd Font Mono to just the codepoints declared in
# ../icons.toml, producing a small (~50 KB) intermediate TTF that the
# patch step grafts into Iosevka IDS.
#
# Intended pipeline (Phase 2):
#   1. Download SymbolsNerdFontMono-Regular.ttf from the pinned Nerd
#      Fonts release tag.
#   2. Extract codepoints from ../icons.toml (one entry per [[icon]]).
#   3. Run pyftsubset to drop everything outside the manifest:
#        pyftsubset SymbolsNerdFontMono-Regular.ttf \
#          --unicodes=<comma-separated codepoints> \
#          --output-file=out/nerd-subset.ttf
#   4. Verify the subset font has exactly the expected glyph count.
#
# Dependencies: python3-fonttools (pyftsubset) — `apt install python3-fonttools`.
#
# Not yet implemented. PR welcome.

set -euo pipefail
echo "subset-nerd.sh: not yet implemented (Phase 2 scaffold)" >&2
exit 64
