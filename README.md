# IDS Fonts

Font artefacts and build pipelines for the **ImZero2 Design System (IDS)**.
This repo houses the source-of-truth build configuration for every font
the IDS ships, plus the CI that turns those configs into SHA-pinned `.ttf`
releases.

The split exists so consumer projects (pebble2impl and any other adopters
of the IDS typography stack) never have to install Docker, Node.js,
`ttfautohint`, `fontforge`, or any other font-toolchain dependency on
their contributor machines. The toolchain runs once per release tag in
GitHub Actions; the output is a tagged release with the `.ttf` files plus
`SHA256SUMS` attached.

## Current scope

### Phase 1 — IDS Mono (bare custom build)

Status: scaffolded.

A custom [Iosevka](https://typeof.net/Iosevka/) build with the variant
picks the IDS commits to. Six TTF files per release (Regular / Italic /
Medium / MediumItalic / Bold / BoldItalic).

Variant intent — preserve across rename / Iosevka bumps:

| Variant | Pick | Reason |
|---|---|---|
| `g` | `single-storey-earless-corner` | Signature character; visually distinctive without going full-cursive. |
| `zero` | `dotted` | Numeric-table legibility; dotted-zero is unambiguous against `O` at sub-12pt. |
| `asterisk` | `high` | Six-pointed, centred. |
| `at` | `fourfold` | Cleaner `@` at small sizes. |
| `brace` | `curly` | Rounder `{ }`. |
| `six` / `nine` | `open-contour` | Open bowl; disambiguates from `8`. |
| `capital-i` | `serifed` | Resolves the canonical `Il1` monospace ambiguity. |
| (ligation) | disabled | Programming ligatures confuse character counting in data tables. |

The full source is [`private-build-plans.toml`](./private-build-plans.toml);
exact key names track the Iosevka customizer for the pinned release version
in [`IOSEVKA_VERSION`](./IOSEVKA_VERSION).

### Phase 2 — IDS Mono Nerd Font (planned)

A second variant per weight that bakes a curated subset of
[Nerd Fonts](https://www.nerdfonts.com/) icons into the IDS Mono PUA.
The icon manifest at [`icons.toml`](./icons.toml) is the source of truth
for which codepoints get baked in; CI subsets Nerd Fonts to that manifest
and uses `fontforge font-patcher` to graft the subset into each IDS Mono
weight.

Motivation: avoids the fallback-chain failure modes of shipping two
separate fonts, and curating the icon set brings each merged TTF under
~1 MB instead of the ~3 MB a full Nerd Fonts merge would produce.

The `scripts/subset-nerd.sh` and `scripts/patch.sh` stubs sketch the
pipeline; both currently exit with status 64 ("not implemented").

### Phase 3+ — other typefaces, as needed

The IDS will probably want a separate proportional font (Iosevka Aile or
its fallback ladder, per ADR-0030 §SD10) eventually. When that need
materialises, it lives here too — a new `aile/` directory with its own
build plan, its own Phase-1/2 sequence. Repo layout will grow per
typeface, not per phase.

## Releases

Each tagged release attaches the built TTFs and a `SHA256SUMS` manifest.
Pin a specific release from your consumer project — never `latest`:

```text
https://github.com/stergiotis/ids-fonts/releases/download/<tag>/IDSMono-Regular.ttf
https://github.com/stergiotis/ids-fonts/releases/download/<tag>/SHA256SUMS
```

Sample consumer-side download (mirror the SHA before trusting):

```bash
curl -fLO https://github.com/stergiotis/ids-fonts/releases/download/v0.1.0/IDSMono-Regular.ttf
sha256sum -c <(curl -fL https://github.com/stergiotis/ids-fonts/releases/download/v0.1.0/SHA256SUMS)
```

## Local build (rarely needed)

Most consumers should download release artefacts. If you need to rebuild
locally — to test a variant change before pushing the tag — install:

- Node.js 22+
- `ttfautohint` (`apt install ttfautohint` on Debian/Ubuntu)
- Python 3
- `p7zip-full` (`apt install p7zip-full`)
- `git`

Then:

```bash
make build      # clones Iosevka at the pinned version, builds IDSMono
make sums       # regenerates out/SHA256SUMS
```

The Iosevka version pin lives in [`IOSEVKA_VERSION`](./IOSEVKA_VERSION).
A bump means: edit that file, rerun `make build`, eyeball the output,
push a new tag.

## Bumping the upstream pin

1. Edit `IOSEVKA_VERSION` (e.g., `v34.5.0` → `v35.0.0`).
2. Run `make build` locally; verify the build completes and the variant
   picks in `private-build-plans.toml` are still valid (Iosevka occasionally
   renames stylistic variants between major versions — a rename fails the
   build fast with a clear error).
3. Diff a sample glyph at the same size between old and new to catch
   unintended shape changes.
4. `git commit && git tag v0.X.Y && git push --tags` — CI re-runs the build
   and publishes the release with the new bytes + SHAs.

## Attribution

`IDS Mono` is a derivative work of [Iosevka](https://github.com/be5invis/Iosevka)
by Renzhi Li (@be5invis), licensed under the SIL Open Font License 1.1.
The custom variant configuration in `private-build-plans.toml` is original
to this project; the glyph designs and the build pipeline come from
upstream Iosevka.

The IDS Mono family name does not include the Reserved Font Name
"Iosevka" (OFL §3), permitting redistribution without explicit upstream
permission.

When Phase 2 ships, `IDSMono Nerd Font` will additionally include
glyphs from the [Nerd Fonts](https://github.com/ryanoasis/nerd-fonts)
project (MIT) which aggregates icons from Material Icons, FontAwesome,
Octicons, Codicons, Powerline, Pomicons, Devicons, and Weather Icons
(each under their own permissive licenses). Per-glyph attribution flows
through Nerd Fonts' own catalogue.

## License

The font artefacts ship under the [SIL Open Font License 1.1](./LICENSE)
(same as upstream Iosevka). The build configuration and tooling in this
repo are released under the same OFL terms for simplicity — OFL is
unusual for non-font material but keeps the entire repo single-license.
