# IDS Fonts

Font artefacts and build pipelines for the **ImZero2 Design System (IDS)**.
This repo houses the source-of-truth build configuration for every font
the IDS ships, plus the CI that turns those configs into SHA-pinned `.ttf`
releases.

The split exists so consumer projects (pebble2impl and any other adopters
of the IDS typography + iconography stack) never have to install Docker,
Node.js, `ttfautohint`, `fontforge`, `fonttools`, or any other font-
toolchain dependency on their contributor machines. The toolchain runs
once per release tag in GitHub Actions; the output is a tagged release
with the `.ttf` files, the supporting JSON catalogue, and a
`SHA256SUMS` manifest attached.

## Current scope

### Phase 1 — IDS Mono

Status: shipping.

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

### Phase 2 — iconography (Phosphor + NFBrand)

Status: scaffolded.

This phase serves the keelson IDS [ADR-0044](https://github.com/stergiotis/pebble2impl/blob/main/doc/adr/0044-imzero2-design-system-iconography.md)
two-slot iconography. Two standalone fonts ship per release, *not*
merged into IDS Mono — egui registers them as fallback families in the
font-family chain.

> **Note on the Phase 2 pivot:** the original Phase 2 plan was to
> `fontforge font-patcher` a curated Nerd Fonts subset *into* IDS Mono
> and ship a merged `IDSMono Nerd Font` variant. ADR-0044 supersedes
> that — the cost (a 4th font variant per weight, ~4 MB extra binary,
> patcher-introduced glyph regressions) outweighed the benefit (one
> fallback hop), and the chosen iconography moved from "subset of Nerd
> Fonts" to "Phosphor for affordances + smaller Nerd Fonts subset for
> brand marks only." Standalone fonts compose more cleanly.

#### Phase 2a — Phosphor

[`scripts/fetch-phosphor.sh`](./scripts/fetch-phosphor.sh) fetches the
regular-weight Phosphor TTF from [`@phosphor-icons/web`](https://github.com/phosphor-icons/web)
and the kebab-case + PascalCase + codepoint catalogue from
[`@phosphor-icons/core`](https://github.com/phosphor-icons/core), at the
single version pinned in [`PHOSPHOR_VERSION`](./PHOSPHOR_VERSION). The
catalogue is converted from TypeScript to JSON by
[`scripts/ts-to-json.py`](./scripts/ts-to-json.py) (Python-only, no
Node toolchain), keeping just the four fields the downstream Go
generator consumes (name, pascal_name, codepoint, optional alias).

Outputs per release:
- `Phosphor.ttf` — ~600 KB
- `phosphor-icons.ts` — upstream catalogue (audit trail)
- `phosphor-icons.json` — flattened catalogue (Go generator input)

#### Phase 2b — NFBrand

[`scripts/subset-nerd.sh`](./scripts/subset-nerd.sh) fetches the
`SymbolsNerdFontMono-Regular.ttf` from
[`ryanoasis/nerd-fonts`](https://github.com/ryanoasis/nerd-fonts) at the
version pinned in [`NERDFONTS_VERSION`](./NERDFONTS_VERSION) and uses
`pyftsubset` to strip everything outside the codepoint manifest in
[`icons.toml`](./icons.toml) — Devicons + Logos + Custom plus one
Material Design brand mark. The resulting NFBrand.ttf is the brand-
mark slot (Slot B) the IDS uses for language / tool logos.

Outputs per release:
- `NFBrand.ttf` — ~150 KB

### Phase 3+ — other typefaces, as needed

The IDS will probably want a separate proportional font (Iosevka Aile
or its fallback ladder, per ADR-0030 §SD10) baked here eventually.
When that need materialises, it lives here too — a new `aile/`
directory with its own build plan. Repo layout will grow per typeface,
not per phase.

## Releases

Each tagged release attaches every artefact across all phases plus a
single `SHA256SUMS` manifest covering them all. Pin a specific release
from your consumer project — never `latest`:

```text
# Fonts
https://github.com/stergiotis/ids-fonts/releases/download/<tag>/IDSMono-Regular.ttf
https://github.com/stergiotis/ids-fonts/releases/download/<tag>/Phosphor.ttf
https://github.com/stergiotis/ids-fonts/releases/download/<tag>/NFBrand.ttf

# Phosphor catalogue
https://github.com/stergiotis/ids-fonts/releases/download/<tag>/phosphor-icons.json
https://github.com/stergiotis/ids-fonts/releases/download/<tag>/phosphor-icons.mjs

# Licenses — each font is distributed under its own upstream license:
https://github.com/stergiotis/ids-fonts/releases/download/<tag>/LICENSE             # umbrella OFL (IDS Mono / Iosevka)
https://github.com/stergiotis/ids-fonts/releases/download/<tag>/Phosphor.LICENSE    # MIT (@phosphor-icons/web)
https://github.com/stergiotis/ids-fonts/releases/download/<tag>/NFBrand.LICENSE     # multi-source (ryanoasis/nerd-fonts)

# Integrity
https://github.com/stergiotis/ids-fonts/releases/download/<tag>/SHA256SUMS
```

Sample consumer-side download (mirror the SHA before trusting):

```bash
TAG=v0.2.3
for f in IDSMono-Regular.ttf Phosphor.ttf NFBrand.ttf \
         phosphor-icons.json phosphor-icons.mjs \
         LICENSE Phosphor.LICENSE NFBrand.LICENSE; do
  curl -fLO "https://github.com/stergiotis/ids-fonts/releases/download/$TAG/$f"
done
curl -fL "https://github.com/stergiotis/ids-fonts/releases/download/$TAG/SHA256SUMS" | sha256sum -c -
```

## Local build (rarely needed)

Most consumers should download release artefacts. If you need to
rebuild locally — to test a variant change before pushing the tag —
install:

- Node.js 22+
- `ttfautohint` (`apt install ttfautohint` on Debian/Ubuntu) — IDS Mono only
- Python 3.11+ (for `tomllib` stdlib module)
- `python3-fonttools` (`apt install python3-fonttools`) — NFBrand only
- `p7zip-full` (`apt install p7zip-full`) — IDS Mono only
- `curl`, `git`

Then:

```bash
make all        # builds idsmono + phosphor + nf-brand into out/
make sums       # regenerates out/SHA256SUMS

# Or one phase at a time:
make idsmono    # IDS Mono only
make phosphor   # Phosphor.ttf + phosphor-icons.json
make nf-brand   # NFBrand.ttf
```

The upstream version pins live in [`IOSEVKA_VERSION`](./IOSEVKA_VERSION),
[`PHOSPHOR_VERSION`](./PHOSPHOR_VERSION), and
[`NERDFONTS_VERSION`](./NERDFONTS_VERSION). Bumping any of them means:
edit the file, rerun the relevant `make` target, eyeball the output,
push a new tag.

## Bumping upstream pins

Each pin is independent:

1. **Iosevka** — edit `IOSEVKA_VERSION`. Run `make idsmono`; if the
   stylistic-variant keys in `private-build-plans.toml` were renamed
   the build fails fast.
2. **Phosphor** — edit `PHOSPHOR_VERSION`. Run `make phosphor`. Inspect
   `out/phosphor-icons.json` for added / removed entries (a removed
   `PhXxx` constant in pebble2impl's downstream generator output will
   surface as a compile error in callers, which is the right signal).
3. **Nerd Fonts** — edit `NERDFONTS_VERSION`. Run `make nf-brand`.
   Inspect `out/NFBrand.ttf` size — the brand-mark codepoint set is
   stable upstream, so size deltas usually mean upstream re-rasterised
   a glyph; verify with a screenshot diff if it changed by more than a
   few KB.

Then `git commit && git tag v0.X.Y && git push --tags` — CI rebuilds
and publishes the release with the new bytes + SHAs.

## Attribution

`IDS Mono` is a derivative work of
[Iosevka](https://github.com/be5invis/Iosevka) by Renzhi Li
(@be5invis), licensed under the SIL Open Font License 1.1. The custom
variant configuration in `private-build-plans.toml` is original to
this project; the glyph designs and the build pipeline come from
upstream Iosevka. The `IDS Mono` family name does not include the
Reserved Font Name "Iosevka" (OFL §3), permitting redistribution
without explicit upstream permission.

`Phosphor.ttf` and `phosphor-icons.json` are unmodified redistributions
of [Phosphor Icons](https://phosphoricons.com/) by Helena Zhang and
Tobias Fried (MIT license). No re-naming or modification of bytes —
the bundle ships exactly as upstream produces it.

`NFBrand.ttf` is a *subset* derivative of
[Nerd Fonts](https://github.com/ryanoasis/nerd-fonts) Symbols Nerd
Font Mono (MIT). Subsetting removes everything outside the codepoint
ranges declared in `icons.toml`; nothing else is altered. The
underlying glyph designs come from the upstream icon families Nerd
Fonts aggregates (Material Icons, FontAwesome, Octicons, Codicons,
Powerline, Pomicons, Devicons, and Weather Icons — each under its own
permissive license); per-glyph attribution flows through Nerd Fonts'
own catalogue.

## License

The font artefacts ship under the [SIL Open Font License 1.1](./LICENSE)
(IDS Mono / NFBrand) and the [MIT license](https://github.com/phosphor-icons/web/blob/master/LICENSE)
(Phosphor). The build configuration and tooling in this repo are
released under OFL for simplicity — OFL is unusual for non-font
material but keeps the repo single-license.
