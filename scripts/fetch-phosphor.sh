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
#   phosphor-icons.ts       — upstream catalogue (audit trail)
#   phosphor-icons.json     — flattened catalogue (Go generator input)
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

echo "==> fetching icons.ts at @phosphor-icons/core@$PHOSPHOR_VERSION"
curl -fsSL -o "$OUT_DIR/phosphor-icons.ts" \
    "https://unpkg.com/@phosphor-icons/core@$PHOSPHOR_VERSION/src/icons.ts"

echo "==> converting icons.ts → phosphor-icons.json"
python3 "$here/ts-to-json.py" "$OUT_DIR/phosphor-icons.ts" "$OUT_DIR/phosphor-icons.json"

echo "==> Phosphor artefacts staged"
ls -la "$OUT_DIR/Phosphor.ttf" "$OUT_DIR/phosphor-icons.ts" "$OUT_DIR/phosphor-icons.json"
