#!/usr/bin/env python3
"""Convert @phosphor-icons/core src/icons.ts to phosphor-icons.json.

Step in the Phosphor build pipeline that emits a flat JSON catalogue
the downstream Go generator (pebble2impl/.../iconsgen) can consume
without parsing TypeScript. See ADR-0044 §SD3 for the design rationale.

Only the four fields the Go generator needs are kept (name, pascal_name,
codepoint, optional alias). All other metadata (categories, tags,
figma_category, version) is intentionally dropped — keeping it would
force this script to resolve TypeScript enum references, and the Go
side does not consume those fields.

Usage:
    ts-to-json.py <icons.ts> <icons.json>

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
    codepoint_re = re.compile(r"codepoint:\s*(\d+)")
    alias_re = re.compile(
        r'alias:\s*\{\s*name:\s*"([^"]+)",\s*pascal_name:\s*"([^"]+)"\s*\}'
    )

    entries: list[dict] = []
    current: dict | None = None
    in_array = False
    depth = 0  # brace depth, relative to the outer array entry

    for line in src.splitlines():
        s = line.strip()

        if not in_array:
            if "export const icons" in s:
                in_array = True
            continue

        # Track outer-object boundaries by brace depth.
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
                current["codepoint"] = int(m.group(1))

        if depth == 0 and current is not None:
            if (
                "name" in current
                and "pascal_name" in current
                and "codepoint" in current
            ):
                entries.append(current)
            else:
                print(
                    f"warning: skipping incomplete entry: {current}",
                    file=sys.stderr,
                )
            current = None

    with open(dst_path, "w", encoding="utf-8") as f:
        json.dump(entries, f, indent=2, ensure_ascii=False)
        f.write("\n")

    print(f"converted {len(entries)} entries to {dst_path}", file=sys.stderr)
    return 0


if __name__ == "__main__":
    sys.exit(main())
