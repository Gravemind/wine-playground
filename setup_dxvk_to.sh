#!/bin/bash

set -euo pipefail
set -x

here="$(cd "$(dirname "$0")"; pwd)"
builddir="$here/build"

export PATH="$PATH:$here/bin"

if [[ -n "${1:-}" && -d "${1}" ]]
then
    export WINEPREFIX="$(readlink -f "$1")"
    shift
fi

if [[ ! -e "$WINEPREFIX" ]]
then
    echo "error: invalid WINEPREFIX: $WINEPREFIX"
fi

export WINEARCH=win64
cd "$builddir/dxvk32/bin"
bash ./setup_dxvk.sh "$@"
cd "$builddir/dxvk64/bin"
bash ./setup_dxvk.sh "$@"
