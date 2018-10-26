#!/bin/bash

set -euo pipefail

here="$(cd "$(dirname "$0")" ; pwd)"
faudio="$here/FAudio"

usage() {
    echo -n "usage: $0 [-h|--help] /path/to/wine/prefix

  Replace xaudio dlls to links to FAudio's.

"
}

if [[ "${1:-}" = -h || "${1:-}" = --help ]]
then
    usage
    exit 0
fi

# set -x

if [[ -n "${1:-}" && -d "${1}" ]]
then
    export WINEPREFIX="$(readlink -f "$1")"
    shift
fi

if [[ ! -e "$WINEPREFIX/drive_c" ]]
then
    echo "error: invalid WINEPREFIX: $WINEPREFIX"
    exit 1
fi

wine_install_dest="$WINEPREFIX/drive_c/windows/system32"

ln_install() {
    local src="$1"
    local name="${src##*/}"
    local dst="$wine_install_dest/$name"

    if [[ -e "$dst" && ! -L "$dst" ]]
    then
        local bak="${dst}.bak"
        if [[ ! -e "$bak" ]]
        then
            echo "Backing up $bak"
            cp -a "$dst" "$bak"
        fi
        echo "Deleting existing $dst"
        rm "$dst"
    fi

    echo "linking $name: $dst -> $src"
    ln -sfT "$src" "$dst"
}

for dll in "$faudio/cpp/build_win64/"*.dll
do
    ln_install "$dll"
done

libwinpthread="$(echo /usr/x86_64-w64-mingw32/**/libwinpthread-1.dll)"
[[ -e "$libwinpthread" ]] || { echo "error: libwinpthread-1.dll not found, expected $libwinpthread" ; exit 1; }
echo "linking $wine_install_dest/libwinpthread-1.dll -> $libwinpthread"
ln -sfT  "$libwinpthread" "$wine_install_dest/libwinpthread-1.dll"
