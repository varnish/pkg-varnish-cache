#!/bin/sh

set -eux

if apt-get -v 2>/dev/null; then
	export DEBIAN_FRONTEND=noninteractive
	export DEBCONF_NONINTERACTIVE_SEEN=true
	apt-get update
	apt-get install -y ./*deb
elif pacman -V > /dev/null 2>&1; then
	pacman -Sy --noconfirm
	pacman -S --noconfirm git base-devel
	useradd -m builder
	echo "builder ALL=(ALL) NOPASSWD: /usr/bin/pacman" > /etc/sudoers.d/builder
	su builder -c "git clone https://aur.archlinux.org/uuid.git /tmp/aur-uuid && cd /tmp/aur-uuid && makepkg -s --noconfirm --noprogressbar"
	pacman -U --noconfirm /tmp/aur-uuid/uuid-*.pkg.tar.zst
	pacman -U --noconfirm ./*.pkg.tar.zst
else
	dnf install -y 'dnf-command(config-manager)' || true
	yum config-manager --set-enabled powertools || true
	yum config-manager --set-enabled crb || true
	yum install -y epel-release || true
	yum install -y redhat-rpm-config || true
	yum install -y ./*.rpm
fi

varnishtest build_scripts/main.vtc

if [ -e "./vmod-digest*" ]; then
	varnishtest build_scripts/digest.vtc
fi

varnishlog-json -V
