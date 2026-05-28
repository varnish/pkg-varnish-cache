#!/usr/bin/env bash
set -euo pipefail

cd "$(git rev-parse --show-toplevel)"
source ./pkg.env

packages=(varnish varnish-modules vmod-cfg vmod-digest vmod-fileserver vmod-geoip2 vmod-jq vmod-querystring vmod-redis vmod-reqwest vmod-rers vmod-uuid)

for pkg in "${packages[@]}"; do
(
    pkgbuild="$pkg/arch/PKGBUILD"
    if [[ ! -f "$pkgbuild" ]]; then
        echo "SKIP $pkg (no PKGBUILD)"
        continue
    fi

    echo "Syncing $pkg..."

    sed -i "s/^pkgver=.*/pkgver=${VARS[varnish_version]}/" "$pkgbuild"
    sed -i "s/^pkgrel=.*/pkgrel=$package_release/" "$pkgbuild"

    if grep -q '^_srcver=' "$pkgbuild"; then
        src_ver="${VARS[${pkg}_version]}"
        # some PKGBUILDs store _srcver with underscores then reconvert via bash substitution;
        # detect by presence of the conversion line and match storage format
        if grep -qF '_srcver="${_srcver//_/-}"' "$pkgbuild"; then
            src_ver="${src_ver//-/_}"
        fi
        # skip the substitution expression line (starts with _srcver="), only update the bare assignment
        sed -i '/^_srcver="/!s/^_srcver=.*/_srcver='"$src_ver"'/' "$pkgbuild"
    fi

    cd "$(pwd)/$pkg/arch"
    updpkgsums
    makepkg --printsrcinfo > .SRCINFO
)
done
