#!/bin/bash
# scripts/subset-nerd.sh — Phase 2 (NFBrand)
#
# Subsets Symbols Nerd Font Mono down to the codepoint ranges declared
# in ../icons.toml, producing NFBrand.ttf (~150 KB) — the brand-mark
# slot (Slot B) for ADR-0044's two-slot iconography. The standalone
# subsetted font is shipped as-is (not merged into IDS Mono — the
# original Phase 2 plan was to font-patcher it into IDS Mono; ADR-0044
# pivoted to standalone fallback registration in egui).
#
# Pinned via ../NERDFONTS_VERSION (Nerd Fonts release tag).
#
# Outputs (in ./out/):
#   SymbolsNerdFontMono-Regular.ttf  — upstream input (audit trail, ~3 MB)
#   NFBrand.ttf                      — subsetted output (~150 KB)
#
# Dependencies: curl, python3, python3-fonttools (pyftsubset).

set -euo pipefail
here=$(dirname "$(readlink -f "$BASH_SOURCE")")
cd "$here/.."

NERDFONTS_VERSION="$(cat NERDFONTS_VERSION | tr -d '[:space:]')"
OUT_DIR="${OUT_DIR:-out}"
mkdir -p "$OUT_DIR"

UPSTREAM_URL="https://github.com/ryanoasis/nerd-fonts/raw/$NERDFONTS_VERSION/patched-fonts/NerdFontsSymbolsOnly/SymbolsNerdFontMono-Regular.ttf"
INPUT="$OUT_DIR/SymbolsNerdFontMono-Regular.ttf"

if [ ! -f "$INPUT" ]; then
    echo "==> fetching SymbolsNerdFontMono at Nerd Fonts $NERDFONTS_VERSION"
    curl -fsSL -o "$INPUT" "$UPSTREAM_URL"
fi

# Build the comma-separated --unicodes argument from icons.toml. The
# manifest declares two block types: [[range]] (start/end) and
# [[codepoint]] (single value). We collect both into a pyftsubset
# range list.
RANGES="$(python3 - <<'PY'
import tomllib
with open("icons.toml", "rb") as f:
    data = tomllib.load(f)
parts = []
for r in data.get("range", []):
    s = r["start"].removeprefix("U+")
    e = r["end"].removeprefix("U+")
    parts.append(f"{s}-{e}")
for c in data.get("codepoint", []):
    v = c["value"].removeprefix("U+")
    parts.append(v)
print(",".join(parts))
PY
)"

echo "==> subsetting with --unicodes=$RANGES"
pyftsubset "$INPUT" \
    --unicodes="$RANGES" \
    --output-file="$OUT_DIR/NFBrand.ttf" \
    --no-hinting \
    --desubroutinize

echo "==> NFBrand.ttf produced"
ls -la "$OUT_DIR/NFBrand.ttf"
