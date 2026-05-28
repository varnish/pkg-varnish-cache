#!/usr/bin/env bash
set -euo pipefail

cd "$(git rev-parse --show-toplevel)"
source ./pkg.env

mapfile -t packages < <(echo "${!VARS[@]}" | tr ' ' '\n' | sort | sed -n 's/_version$//p')

for pkg in "${packages[@]}"; do
    tmpl="$pkg/arch/PKGBUILD.tmpl"
    if [[ ! -f "$tmpl" ]]; then
        echo "SKIP $pkg (no PKGBUILD.tmpl)"
        continue
    fi

    src_ver="${VARS[${pkg}_version]:-}"
    sed \
        -e "s/@PKGVER@/${VARS[varnish_version]}/g" \
        -e "s/@PKGREL@/$package_release/g" \
        -e "s/@SRCVER@/$src_ver/g" \
        "$tmpl" > "$pkg/arch/PKGBUILD"

    pkgbuild="$pkg/arch/PKGBUILD"

    echo "Syncing $pkg..."

    aur_dir="/tmp/aur-$pkg"
    rm -rf "$aur_dir"
    git clone "https://aur.archlinux.org/$pkg.git" "$aur_dir"

    # copy generated PKGBUILD
    cp "$pkgbuild" "$aur_dir/PKGBUILD"

    # copy all other non-template files from arch/, dereferencing symlinks
    find "$pkg/arch/" -maxdepth 1 \( -type f -o -type l \) \
        ! -name 'PKGBUILD' ! -name 'PKGBUILD.tmpl' ! -name '.gitignore' \
        | while read -r f; do
            cp -L "$f" "$aur_dir/$(basename "$f")"
        done

    (cd "$aur_dir" && updpkgsums && makepkg --printsrcinfo > .SRCINFO)

    echo "--- $pkg ---"
    echo "git -C $aur_dir add -A && git -C $aur_dir commit -m 'bump to ${VARS[varnish_version]}-$package_release' && git -C $aur_dir push"
done
