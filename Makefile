# Local build orchestration for IDS Mono.
#
# Mirrors the GitHub Actions workflow at .github/workflows/build.yml.
# Contributors should rarely need this — pull a tagged release's artefacts
# from GitHub instead. Run locally only when iterating on
# private-build-plans.toml or when bumping IOSEVKA_VERSION before
# pushing the tag.
#
# Requires (Debian/Ubuntu): apt install ttfautohint p7zip-full python3 git
# Plus Node.js 22+ on PATH (nvm install 22 / nodesource).

IOSEVKA_VERSION := $(shell cat IOSEVKA_VERSION | tr -d '[:space:]')

.PHONY: build sums clean print-version help

help:
	@echo "make build   — clone Iosevka $(IOSEVKA_VERSION), build IDSMono, stage to out/"
	@echo "make sums    — recompute out/SHA256SUMS"
	@echo "make clean   — remove iosevka-source/ and out/"
	@echo "make print-version — print resolved IOSEVKA_VERSION"

print-version:
	@echo "IOSEVKA_VERSION = $(IOSEVKA_VERSION)"

build: out
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
	$(MAKE) sums
	@echo "==> done. Artefacts in out/"
	@ls -la out/

sums: out
	(cd out && sha256sum *.ttf > SHA256SUMS)
	@echo "==> SHA256SUMS regenerated"

out:
	mkdir -p out

clean:
	rm -rf iosevka-source out
