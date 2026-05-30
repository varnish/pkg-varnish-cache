#!/usr/bin/env bash

set -eux

source ./pkg.env
source /etc/os-release
PKG_NAME=$(basename $(pwd))
if [ "`uname -m`" = "x86_64" ]; then
	ARCH="amd64"
else
	ARCH="arm64"
fi
PDIR="$PDIR/${ID/amzn/amazonlinux}/${VERSION_ID%.*}/${ARCH}"

cd redhat
sed -i -e '' *
dnf makecache --refresh
dnf -y install findutils 'dnf-command(config-manager)'
EXTRA_REPO=
case "$PLATFORM_ID" in
    platform:el8)
	EXTRA_REPO=powertools
	dnf -y install epel-release
        ;;
    platform:el*)
	EXTRA_REPO=crb
	dnf -y install epel-release
        ;;
esac

dnf config-manager --set-enabled $EXTRA_REPO
dnf -y install \
	dnf-utils \
	rpm-build \
	$(test -d /deps/ && find /deps/ -name '*.rpm')

# checksum
curl -sL  ${VARS[varnish_source]} | sha512sum | grep -q "^${VARS[varnish_sha512]}  -$"

# Update changelog version
if [ "$PKG_NAME" == "varnish" ]; then
	if [ -e .is_weekly ]; then
		WEEKLY='.weekly'
	else
		WEEKLY=
	fi
	curl -L "${VARS[${PKG_NAME}_source]}" | tar xvfz - --strip 1
	VERSION=$(./configure --version | awk 'NR == 1 {print $NF}')$WEEKLY
else
	VERSION="$(pkg-config --silence-errors --modversion varnishapi)"
fi

mkdir -p SOURCES/
dnf builddep \
	-D "versiontag ${VERSION}" \
	-D "releasetag ${package_release}"\
	-y *.spec
rpmbuild -bb \
	--undefine=_disable_source_fetch \
	--undefine=_debugsource_template \
	--define "debug_package %{nil}" \
	--define "_topdir $(pwd)" \
        --define "_smp_mflags -j10" \
        --define "versiontag ${VERSION}" \
        --define "releasetag ${package_release}" \
        --define "srcurl ${VARS[${PKG_NAME}_source]}" \
        --define "srcversion ${VARS[${PKG_NAME}_version]}" \
	*.spec

# Prepare the packages for storage
mkdir -p "$PDIR"
mv RPMS/*/*.rpm $PDIR
