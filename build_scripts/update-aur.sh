#!/usr/bin/env bash
set -euo pipefail

WORKDIR="${1:?Usage: $0 <workdir>}"

cd "$(git rev-parse --show-toplevel)"
source ./pkg.env

rm -rf "$WORKDIR"
mkdir -p "$WORKDIR"

mapfile -t packages < <(echo "${!VARS[@]}" | tr ' ' '\n' | sort | sed -n 's/_version$//p')

for pkg in "${packages[@]}"; do
    tmpl="$pkg/arch/PKGBUILD.tmpl"
    if [[ ! -f "$tmpl" ]]; then
        echo "SKIP $pkg (no arch/PKGBUILD.tmpl)"
        continue
    fi

    echo "Updating $pkg..."

    git clone "https://aur.archlinux.org/$pkg.git" "$WORKDIR/$pkg"

    src_ver="${VARS[${pkg}_version]:-}"
    sed \
        -e "s/@PKGVER@/${VARS[varnish_version]}/g" \
        -e "s/@PKGREL@/$package_release/g" \
        -e "s/@SRCVER@/$src_ver/g" \
        "$tmpl" > "$WORKDIR/$pkg/PKGBUILD"

    git ls-files "$pkg/arch/" | while read -r f; do
        base="$(basename "$f")"
        [[ "$base" == "PKGBUILD.tmpl" || "$base" == ".gitignore" ]] && continue
        cp -L "$f" "$WORKDIR/$pkg/$base"
    done

    git -C "$WORKDIR/$pkg" add -A
    git -C "$WORKDIR/$pkg" commit -m "$pkg ${VARS[varnish_version]}-$package_release"
done

echo ""
echo "for d in \"$WORKDIR\"/*/; do git -C \"\$d\" push; done"
