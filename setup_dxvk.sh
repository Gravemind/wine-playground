#!/bin/bash

set -euo pipefail

here="$(cd "$(dirname "$0")"; pwd)"
builddir="$here/build"

usage() {
    echo -n "usage: $0 [-h|--help] /path/to/wine/prefix

  Runs dxvk's 32 and 64 setup_dxvk.sh scripts on /path/to/wine/prefix

"
}

if [[ "${1:-}" = -h || "${1:-}" = --help ]]
then
    usage
    exit 0
fi

set -x

export PATH="$PATH:$here/bin"

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

def_cmd=(install)

export WINEARCH=win64
cd "$builddir/dxvk32/bin"
bash ./setup_dxvk.sh "${@:-${def_cmd[@]}}"
cd "$builddir/dxvk64/bin"
bash ./setup_dxvk.sh "${@:-${def_cmd[@]}}"
