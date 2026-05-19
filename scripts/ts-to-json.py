#!/usr/bin/env python3
"""Convert the @phosphor-icons/core icons catalogue to phosphor-icons.json.

Step in the Phosphor build pipeline that emits a flat JSON catalogue
the downstream Go generator (pebble2impl/.../iconsgen) can consume
without parsing TypeScript or JavaScript. See ADR-0044 §SD3 for the
design rationale.

Accepts either:
  - The TypeScript source `src/icons.ts` (GitHub-only — npm publishes
    only `dist/`).
  - The compiled ESM bundle `dist/index.mjs` (published to npm; the
    durable source for our pipeline). Same per-entry field layout as
    the TS source; only the array opener and the enum-reference names
    differ, neither of which this parser inspects.

Only the four fields the Go generator needs are kept (name, pascal_name,
codepoint, optional alias). All other metadata (categories, tags,
figma_category, version) is intentionally dropped — keeping it would
force this script to resolve TypeScript / JavaScript enum references,
and the Go side does not consume those fields.

Usage:
    ts-to-json.py <icons.ts|index.mjs> <icons.json>

Parser model: line-oriented. Each entry's four fields each appear on
their own line; alias is single-line in every release verified so far.
The script tolerates field reordering inside an entry but assumes each
entry ends at the closing `},` of its outer object literal.
"""
import json
import re
import sys


def main() -> int:
    if len(sys.argv) != 3:
        print("usage: ts-to-json.py <icons.ts> <icons.json>", file=sys.stderr)
        return 1

    src_path, dst_path = sys.argv[1], sys.argv[2]

    with open(src_path, "r", encoding="utf-8") as f:
        src = f.read()

    name_re = re.compile(r'name:\s*"([^"]+)"')
    pascal_re = re.compile(r'pascal_name:\s*"([^"]+)"')
    # Accept both integer literals (`58000`) and the scientific-notation
    # form esbuild emits for round numbers in the compiled .mjs
    # (`58e3`). `int(float(...))` handles either.
    codepoint_re = re.compile(r"codepoint:\s*(\d+(?:e\d+)?)")
    alias_re = re.compile(
        r'alias:\s*\{\s*name:\s*"([^"]+)",\s*pascal_name:\s*"([^"]+)"\s*\}'
    )

    entries: list[dict] = []
    current: dict | None = None
    depth = 0  # brace depth (line-level), relative to the outer file scope

    # No explicit array-opener gating — the compiled .mjs minifies the
    # array's internal variable name (the export footer maps it back to
    # `icons`), so matching the opener line is fragile. Instead we
    # process every line and rely on the depth tracker plus the per-
    # entry required-fields check: entries that don't carry all three
    # of name / pascal_name / codepoint are silently discarded, which
    # catches the empty `{}` enum stubs that appear in the compiled
    # .mjs's first line.

    for line in src.splitlines():
        s = line.strip()

        # Net brace-depth change on this line. A single line containing
        # both `{` and `}` (e.g. an inline `alias: { ... }`) nets to 0
        # and does not transition depth.
        opens = s.count("{") - s.count("}")
        if depth == 0 and opens > 0:
            current = {}
        depth += opens

        if current is not None:
            if (m := name_re.search(s)) and "name" not in current:
                current["name"] = m.group(1)
            if (m := pascal_re.search(s)) and "pascal_name" not in current:
                current["pascal_name"] = m.group(1)
            if (m := alias_re.search(s)):
                current["alias"] = {"name": m.group(1), "pascal_name": m.group(2)}
            if (m := codepoint_re.search(s)):
                current["codepoint"] = int(float(m.group(1)))

        if depth == 0 and current is not None:
            if (
                "name" in current
                and "pascal_name" in current
                and "codepoint" in current
            ):
                entries.append(current)
            # Silently discard entries missing required fields — these
            # are non-icon-entry top-level `{}` blocks (most commonly
            # empty enum-default stubs at the start of the compiled
            # .mjs).
            current = None

    with open(dst_path, "w", encoding="utf-8") as f:
        json.dump(entries, f, indent=2, ensure_ascii=False)
        f.write("\n")

    print(f"converted {len(entries)} entries to {dst_path}", file=sys.stderr)
    return 0


if __name__ == "__main__":
    sys.exit(main())
