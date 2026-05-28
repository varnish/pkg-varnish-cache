#!/usr/bin/env bash

set -eux

source ./pkg.env

PKG_NAME=$(basename $(pwd))
if [ "$(uname -m)" = "x86_64" ]; then
    ARCH="amd64"
else
    ARCH="arm64"
fi

if [ ! -f arch/PKGBUILD.tmpl ]; then
    echo "No arch/PKGBUILD.tmpl, skipping $PKG_NAME"
    exit 0
fi

PDIR="$PDIR/arch/$ARCH"
mkdir -p "$PDIR"

pacman -Sy --noconfirm --needed base-devel
id builder 2>/dev/null || useradd -m builder
echo "builder ALL=(ALL) NOPASSWD: /usr/bin/pacman" > /etc/sudoers.d/builder

if [ "$PKG_NAME" != "varnish" ]; then
    pacman -U --noconfirm /deps/arch/$ARCH/varnish-[0-9]*.pkg.tar.zst
fi

src_ver="${VARS[${PKG_NAME}_version]:-}"
sed \
    -e "s/@PKGVER@/${VARS[varnish_version]}/g" \
    -e "s/@PKGREL@/$package_release/g" \
    -e "s/@SRCVER@/$src_ver/g" \
    arch/PKGBUILD.tmpl > arch/PKGBUILD

chown -R builder arch/
su builder -c "cd '$(pwd)/arch' && makepkg -s --noconfirm --noprogressbar"

if [ "$PKG_NAME" = "varnish" ]; then
    pacman -U --noconfirm arch/varnish-[0-9]*.pkg.tar.zst
fi

cp arch/*.pkg.tar.zst "$PDIR/"
