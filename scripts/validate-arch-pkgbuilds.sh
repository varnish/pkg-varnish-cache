#!/usr/bin/env bash
set -euo pipefail

cd "$(git rev-parse --show-toplevel)"
source ./pkg.env

FAIL=0
packages=(varnish varnish-modules vmod-cfg vmod-digest vmod-fileserver vmod-geoip2 vmod-jq vmod-querystring vmod-redis vmod-reqwest vmod-rers vmod-uuid)

for pkg in "${packages[@]}"; do
    pkgbuild="$pkg/arch/PKGBUILD"
    if [[ ! -f "$pkgbuild" ]]; then
        echo "SKIP $pkg (no PKGBUILD)"
        continue
    fi

    actual_ver=$(grep '^pkgver=' "$pkgbuild" | cut -d= -f2)
    actual_rel=$(grep '^pkgrel=' "$pkgbuild" | cut -d= -f2)

    if [[ "$actual_ver" != "${VARS[varnish_version]}" ]]; then
        echo "FAIL $pkgbuild: pkgver=$actual_ver expected=${VARS[varnish_version]}"
        FAIL=1
    fi

    if [[ "$actual_rel" != "$package_release" ]]; then
        echo "FAIL $pkgbuild: pkgrel=$actual_rel expected=$package_release"
        FAIL=1
    fi

    if grep -q '^_srcver=' "$pkgbuild"; then
        actual_src=$(grep '^_srcver=' "$pkgbuild" | head -1 | cut -d= -f2)
        # normalize: some PKGBUILDs store _srcver with underscores instead of hyphens
        actual_src_normalized="${actual_src//_/-}"
        if [[ "$actual_src_normalized" != "${VARS[${pkg}_version]}" ]]; then
            echo "FAIL $pkgbuild: _srcver=$actual_src expected=${VARS[${pkg}_version]}"
            FAIL=1
        fi
    fi
done

if [[ $FAIL -eq 0 ]]; then
    echo "OK all arch PKGBUILDs aligned with pkg.env"
fi

exit $FAIL
