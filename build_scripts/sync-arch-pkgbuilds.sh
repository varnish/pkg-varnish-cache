#!/usr/bin/env bash
set -euo pipefail

cd "$(git rev-parse --show-toplevel)"
source ./pkg.env

# keep downloaded sources out of the AUR clones so they can't be committed by accident
export SRCDEST="${SRCDEST:-/tmp/aur-srcdest}"
mkdir -p "$SRCDEST"

# retry a command a few times, AUR ssh/https connections get reset regularly
retry() {
    local i
    for i in 1 2 3 4 5; do
        "$@" && return 0
        echo "retry $i/5 failed: $*" >&2
        sleep $((i * 3))
    done
    return 1
}

sync_pkg() {
    local pkg="$1"
    local tmpl="$pkg/arch/PKGBUILD.tmpl"
    local pkgbuild="$pkg/arch/PKGBUILD"
    local aur_dir="/tmp/aur-$pkg"
    local src_ver="${VARS[${pkg}_version]:-}"
    local files=(PKGBUILD .SRCINFO)
    local f

    sed \
        -e "s/@PKGVER@/${VARS[varnish_version]}/g" \
        -e "s/@PKGREL@/$package_release/g" \
        -e "s/@SRCVER@/$src_ver/g" \
        "$tmpl" > "$pkgbuild"

    echo "Syncing $pkg..."

    rm -rf "$aur_dir"
    # clone anonymously over https, ignoring user/system url rewrites (e.g. to ssh);
    # pushing requires ssh, so set the push url explicitly
    retry env GIT_CONFIG_GLOBAL=/dev/null GIT_CONFIG_NOSYSTEM=1 \
        git clone -q "https://aur.archlinux.org/$pkg.git" "$aur_dir" || return 1
    git -C "$aur_dir" remote set-url --push origin "ssh://aur@aur.archlinux.org/$pkg.git"

    # copy generated PKGBUILD
    cp "$pkgbuild" "$aur_dir/PKGBUILD"

    # copy all other non-template files from arch/, dereferencing symlinks
    while read -r f; do
        cp -L "$f" "$aur_dir/$(basename "$f")"
        files+=("$(basename "$f")")
    done < <(find "$pkg/arch/" -maxdepth 1 \( -type f -o -type l \) \
        ! -name 'PKGBUILD' ! -name 'PKGBUILD.tmpl' ! -name '.gitignore')

    (cd "$aur_dir" && retry updpkgsums && makepkg --printsrcinfo > .SRCINFO) || return 1

    if git -C "$aur_dir" rev-parse -q --verify HEAD >/dev/null &&
        git -C "$aur_dir" diff --quiet -- "${files[@]}"; then
        echo "--- $pkg: up to date ---"
        return 0
    fi

    echo "--- $pkg ---"
    git -C "$aur_dir" diff --stat -- "${files[@]}" 2>/dev/null || true
    commit_cmds+=("git -C $aur_dir add ${files[*]} && git -C $aur_dir commit -m 'bump to ${VARS[varnish_version]}-$package_release'")
    push_cmds+=("git -C $aur_dir push")
}

mapfile -t packages < <(echo "${!VARS[@]}" | tr ' ' '\n' | sort | sed -n 's/_version$//p')

commit_cmds=()
push_cmds=()
failed=()

for pkg in "${packages[@]}"; do
    if [[ ! -f "$pkg/arch/PKGBUILD.tmpl" ]]; then
        echo "SKIP $pkg (no PKGBUILD.tmpl)"
        continue
    fi
    sync_pkg "$pkg" || failed+=("$pkg")
done

echo
if [[ ${#commit_cmds[@]} -gt 0 ]]; then
    echo "=== review, then commit (only packaging files are added) ==="
    printf '%s\n' "${commit_cmds[@]}"
    echo
    echo "=== push (AUR ssh is flaky, retry on failure) ==="
    printf '%s\n' "${push_cmds[@]}"
else
    echo "Nothing to update."
fi

if [[ ${#failed[@]} -gt 0 ]]; then
    echo
    echo "FAILED: ${failed[*]}" >&2
    exit 1
fi
