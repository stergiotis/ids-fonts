#!/bin/bash
# scripts/fetch-phosphor.sh — Phase 2 (Phosphor)
#
# Fetches the Phosphor regular .ttf from @phosphor-icons/web and the
# icons.ts catalogue from @phosphor-icons/core at the pinned version,
# then runs the TS→JSON conversion to emit phosphor-icons.json.
#
# Pinned via ../PHOSPHOR_VERSION (single pin — both /web and /core ship
# from the same monorepo and the released versions agree at the minor
# level where the catalogue is stable). If they desynchronise in a way
# that breaks our pinning, split into two version files.
#
# Outputs (in ./out/):
#   Phosphor.ttf            — the regular weight, ~600 KB
#   Phosphor.LICENSE        — upstream MIT license (must travel with bytes)
#   phosphor-icons.mjs      — upstream catalogue (audit trail)
#   phosphor-icons.json     — flattened catalogue (Go generator input)
#
# We pull the catalogue from `dist/index.mjs` (the compiled ESM bundle)
# rather than `src/icons.ts` because @phosphor-icons/core publishes
# only the `dist/` directory to npm — `src/` lives on GitHub. The .mjs
# preserves the same per-entry field layout as the TS source (only the
# array opener differs — `var icons = [` vs `export const icons =
# (<const>[`); ts-to-json.py handles both.
#
# Dependencies: curl, python3.

set -euo pipefail
here=$(dirname "$(readlink -f "$BASH_SOURCE")")
cd "$here/.."

PHOSPHOR_VERSION="$(cat PHOSPHOR_VERSION | tr -d '[:space:]')"
OUT_DIR="${OUT_DIR:-out}"
mkdir -p "$OUT_DIR"

echo "==> fetching Phosphor.ttf at @phosphor-icons/web@$PHOSPHOR_VERSION"
curl -fsSL -o "$OUT_DIR/Phosphor.ttf" \
    "https://unpkg.com/@phosphor-icons/web@$PHOSPHOR_VERSION/src/regular/Phosphor.ttf"

echo "==> fetching Phosphor LICENSE at @phosphor-icons/web@$PHOSPHOR_VERSION"
# Upstream MIT — must travel with the redistributed .ttf bytes.
curl -fsSL -o "$OUT_DIR/Phosphor.LICENSE" \
    "https://unpkg.com/@phosphor-icons/web@$PHOSPHOR_VERSION/LICENSE"

echo "==> fetching icons catalogue at @phosphor-icons/core@$PHOSPHOR_VERSION"
curl -fsSL -o "$OUT_DIR/phosphor-icons.mjs" \
    "https://unpkg.com/@phosphor-icons/core@$PHOSPHOR_VERSION/dist/index.mjs"

echo "==> converting phosphor-icons.mjs → phosphor-icons.json"
python3 "$here/ts-to-json.py" "$OUT_DIR/phosphor-icons.mjs" "$OUT_DIR/phosphor-icons.json"

echo "==> Phosphor artefacts staged"
ls -la "$OUT_DIR/Phosphor.ttf" "$OUT_DIR/Phosphor.LICENSE" \
       "$OUT_DIR/phosphor-icons.mjs" "$OUT_DIR/phosphor-icons.json"
