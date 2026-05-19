# Local build orchestration for the IDS font family.
#
# Mirrors the GitHub Actions workflow at .github/workflows/build.yml.
# Contributors should rarely need this — pull a tagged release's
# artefacts from GitHub instead. Run locally only when iterating on a
# version pin or build plan before pushing the tag.
#
# Requires (Debian/Ubuntu): apt install ttfautohint p7zip-full python3 \
#                                       python3-fonttools curl git
# Plus Node.js 22+ on PATH (for the IDS Mono Iosevka build only).

IOSEVKA_VERSION  := $(shell cat IOSEVKA_VERSION | tr -d '[:space:]')
PHOSPHOR_VERSION := $(shell cat PHOSPHOR_VERSION | tr -d '[:space:]')

.PHONY: all idsmono phosphor build sums clean print-versions help

help:
	@echo "make all       — build everything (idsmono + phosphor)"
	@echo "make idsmono   — build IDS Mono from Iosevka source"
	@echo "make phosphor  — fetch Phosphor.ttf + icons.ts; emit phosphor-icons.json"
	@echo "make build     — alias for idsmono (back-compat)"
	@echo "make sums      — recompute out/SHA256SUMS over all staged artefacts"
	@echo "make clean     — remove iosevka-source/ and out/"
	@echo "make print-versions — print all resolved upstream version pins"

print-versions:
	@echo "IOSEVKA_VERSION   = $(IOSEVKA_VERSION)"
	@echo "PHOSPHOR_VERSION  = $(PHOSPHOR_VERSION)"

all: idsmono phosphor sums

# IDS Mono — Phase 1. Bare custom Iosevka build.
idsmono: out
	@if [ ! -d iosevka-source ]; then \
		echo "==> cloning Iosevka $(IOSEVKA_VERSION)"; \
		git clone --depth 1 --branch "$(IOSEVKA_VERSION)" \
			https://github.com/be5invis/Iosevka.git iosevka-source; \
	else \
		echo "==> reusing existing iosevka-source/ (delete to re-clone)"; \
	fi
	@echo "==> staging private-build-plans.toml"
	cp private-build-plans.toml iosevka-source/private-build-plans.toml
	@echo "==> npm install (one-time per source tree)"
	(cd iosevka-source && npm install --no-audit --no-fund)
	@echo "==> building IDSMono"
	(cd iosevka-source && npm run build -- ttf::IDSMono)
	@echo "==> staging .ttf artefacts to out/"
	cp iosevka-source/dist/IDSMono/TTF/*.ttf out/
	cp private-build-plans.toml out/
	cp IOSEVKA_VERSION out/
	@echo "==> idsmono done"

# Phosphor — Phase 2. Fetch upstream font + catalogue; emit JSON.
phosphor: out
	OUT_DIR="$$(pwd)/out" bash scripts/fetch-phosphor.sh
	cp PHOSPHOR_VERSION out/

# Back-compat alias for the original `make build` (IDS Mono only).
build: idsmono sums

sums: out
	(cd out && sha256sum *.ttf *.json 2>/dev/null > SHA256SUMS || true)
	@echo "==> SHA256SUMS regenerated"
	@cat out/SHA256SUMS

out:
	mkdir -p out

clean:
	rm -rf iosevka-source out
