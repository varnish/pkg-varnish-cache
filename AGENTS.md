# AGENTS.md

Guidance for AI agents working on this repository.

## What this is

`all-packager` contains **packaging metadata only** — no upstream source code. Each directory is one package; build scripts download the upstream tarball, inject the packaging files, and produce `.deb`, `.rpm`, or Arch `.pkg.tar.zst` artifacts.

## Repository layout

```
pkg.env                    # central config: all versions, source URLs, sha512 checksums
build_scripts/             # build orchestration scripts (called from CI)
  make-deb-packages.sh     # Debian/Ubuntu: downloads tarball, runs dpkg-buildpackage
  make-rpm-packages.sh     # RHEL/AmazonLinux: runs rpmbuild with macros
  make-arch-packages.sh    # Arch Linux: generates PKGBUILD, runs makepkg
  update-aur.sh            # syncs built PKGBUILD to AUR
<package>/
  arch/PKGBUILD.tmpl       # Arch template; @PKGVER@/@PKGREL@/@SRCVER@ substituted at build time
  debian/control           # Debian package metadata and build dependencies
  debian/rules             # Debhelper rules for configure/build/install
  redhat/<name>.spec       # RPM spec; uses macros %{versiontag} %{releasetag} %{srcurl} %{srcversion}
```

## pkg.env

Bash associative array. Every package needs three entries:

```bash
VARS[<name>_version]=<upstream-version>
VARS[<name>_source]=<tarball-url>
VARS[<name>_sha512]=<sha512sum-of-tarball>
```

The pre-commit hook verifies sha512 values by downloading every tarball. To get (and set) the correct sha512 for a new or updated package without running the full hook:

```bash
curl -sL <source-url> | sha512sum | cut -d' ' -f1
```

Paste the result into `pkg.env`. You can also run the full hook manually from the repo root:

```bash
./build_scripts/pre-commit
```

It exits non-zero and prints expected vs actual for any mismatch. Leave `CHANGEME` as a placeholder if the URL isn't live yet.

`<name>` must match the package directory name exactly (used by build scripts as `$(basename $(pwd))`).

## Versioning scheme

All packages are versioned against Varnish: `X.Y.Z-R` where `X.Y.Z` = varnish version, `R` = `$package_release` from `pkg.env`.

In packaging files:
- `@PKGVER@` (PKGBUILD) / `%{versiontag}` (RPM) → the Varnish version (e.g. `9.0.3`)
- `@SRCVER@` (PKGBUILD) / `%{srcversion}` (RPM) → the upstream vmod version from `pkg.env`
- `@PKGREL@` (PKGBUILD) / `%{releasetag}` (RPM) → `$package_release`

## Adding a new package

1. Create `<name>/arch/PKGBUILD.tmpl`, `<name>/debian/control`, `<name>/debian/rules`, `<name>/redhat/<name>.spec`.
2. Add three lines to `pkg.env` (version, source, sha512=`CHANGEME`).
3. Use the closest existing package as a template:
   - **Autotools vmod** (C): `vmod-digest`
   - **Rust vmod**: `vmod-reqwest`
   - **CMake vmod with submodules**: `vmod-tinykvm`

Key patterns:

**Debian `rules`** always extracts the varnishd ABI and injects it into substvars:
```makefile
VARNISHD_ABI = $(shell varnishd -V 2>&1 | sed -En 's/.*revision ([0-9a-f]*).*/\1/p')
override_dh_gencontrol:
	echo "varnishd:ABI=varnishd-abi-$(VARNISHD_ABI)" >> debian/substvars
	dh_gencontrol -- -Tdebian/substvars
```

**RPM spec** `%prep` uses `%autosetup -n %{name}-%{srcversion}` for most packages; use explicit `%setup -n <extracted-dir>` when the tarball's top-level directory name doesn't match `%{name}`.

**PKGBUILD.tmpl** uses `_srcver=@SRCVER@` for the upstream version and `pkgver=@PKGVER@` for the Varnish version. If the GitHub repo name differs from `pkgname` (e.g. underscores vs hyphens), add a `_srcname` variable and use it in `cd` calls.

## What NOT to do

- Do not add upstream source code to this repo — only packaging metadata.
- Do not hardcode Varnish version numbers; use `@PKGVER@`/`%{versiontag}` macros.
- Do not set a real sha512 value manually — let the pre-commit hook compute it.
- Do not run `make-*.sh` scripts locally; they expect a Docker environment with distro-specific tools.
