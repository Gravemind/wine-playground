#!/bin/bash

set -euo pipefail
set -x

####

here="$(cd "$(dirname "$0")" ; pwd)"
cd "$here"

buildlogfile=".build.log"
date --iso-8601=seconds > "$buildlogfile"
exec >& >(tee -ia "$buildlogfile")
exec 2>&1

on_error() {
  echo "Error near line ${1:-\?}: ${2:-error}; exit ${3:-1}"
  exit "${3:-1}"
}
trap 'on_error ${LINENO}' ERR

set_term_title() {
    echo -e '\033]2;'"$*"'\007'
}

log() {
    local msg="$*"
    echo "----- $msg"
    set_term_title "$0: $msg"
}

####

install_wine=0
while [[ "${1:-}" = --* ]]
do
    case "$1" in
        --install) install_wine=1 ; shift ;;
        --) shift ; break ;;
        *) echo "$0: unkown arguement: $1" 1>&2 ; exit 2 ;;
    esac
done

dobuild=",${1:-dxvk,wine,steamclient},"

####

builddir="$here/build"
mkdir -p "$builddir"

wine_install_dir="$builddir/wine"
[[ $install_wine = 0 ]] || mkdir -p "$wine_install_dir"

####

unsetcc() {
    unset CC
    unset CXX
    unset CPP
}
unsetcc

# export CC="clang"
# export CXX="clang++"
# export LD="ld.lld"

export CFLAGS="-O3 -march=native -g"
export CXXFLAGS="-O3 -march=native -g"
export MAKEFLAGS="-j$(nproc) -Orecurse"

CFLAGS+=" -g3 -gdwarf-5 -fvar-tracking-assignments"
CXXFLAGS+=" -g3 -gdwarf-5 -fvar-tracking-assignments"

#CFLAGS+=" -fno-omit-frame-pointer"
#CXXFLAGS+=" -fno-omit-frame-pointer"

# CFLAGS+=" -flto"
# CXXFLAGS+=" -flto"
# LDFLAGS+=" -flto"
# export LDFLAGS

####

ORIG_PATH="$PATH"
#export PATH="$ORIG_PATH:$wine_install_dir/bin"
export PATH="$ORIG_PATH:$here/bin"

#which -a winegcc
#exit 1

####

winesrc="$here/wine"

build_wine() {
    local arch=$1

    local installdir="$wine_install_dir"

    mkdir -p "$builddir/wine$arch"
    cd "$builddir/wine$arch"

    if [[ ! -e "Makefile" ]]
    then
        log wine$arch configure

        local flags=()
        if [[ $arch == 32 ]]
        then
            export PKG_CONFIG_PATH=/usr/lib32/pkgconfig
            flags+=( --libdir=/usr/lib32 --with-wine64="$builddir/wine64" )
        else
            flags+=( --libdir=/usr/lib --enable-win64 )
        fi

        "$winesrc/configure" --prefix="$installdir" --with-x --with-xattr --disable-tests --enable-winegdb "${flags[@]}"
    fi

    log wine$arch build

    make

    if [[ "$install_wine" != 0 ]]
    then
        log wine$arch install

        local lib=lib
        [[ $arch == 32 ]] || lib=lib64
        make prefix="$installdir" libdir="$installdir/$lib" dlldir="$installdir/$lib/wine" install-dev install-lib
    fi
}

if [[ "$dobuild" == *,wine,* ]]
then
    #rm -rf "$wine_install_dir"
    ( build_wine 64 )
    ( build_wine 32 )
fi

####

build_dxvk() {
    unsetcc

    local arch=$1

    log dxvk$arch configure

    cd "$here/dxvk"
    meson --reconfigure --cross-file build-win$arch.txt --prefix "$builddir/dxvk$arch" "$builddir/build-dxvk$arch"

    cd "$builddir/build-dxvk$arch"
    meson configure -Dbuildtype=release

    log dxvk$arch build

    ninja

    log dxvk$arch install

    ninja install
}

if [[ "$dobuild" == *,dxvk,* ]]
then
    ( build_dxvk 64 )
    ( build_dxvk 32 )
fi

####

build_steamclient() {
    # unsetcc

    local arch=$1

    log steamclient$arch configure

    # copy from Proton
    local src="$here/Proton/lsteamclient"
    rm -rf "$builddir/lsteamclient.win$arch"
    cp -a "$src" "$builddir/lsteamclient.win$arch"
    cd "$builddir/lsteamclient.win$arch"

    #cp -a "lsteamclient.spec" "lsteamclient64.spec"

    local arg=
    [[ $arch == 64 ]] || arg="--wine32"
    local lib=lib
    [[ $arch == 32 ]] || lib=lib64

    "$winesrc/tools/winemaker/winemaker"  \
        --nosource-fix --nolower-include --nodlls --nomsvcrt $arg \
        -DSTEAM_API_EXPORTS \
        -I"$winesrc"/include/ \
        -I"$winesrc"/include/wine/ \
        -I"$winesrc"/include/wine/windows/ \
        -L"$builddir/wine$arch/libs/wine" \
        -L"$builddir/wine$arch/dlls" \
        --dll .

    log steamclient$arch build

    local flags=-m32
    [[ $arch == 32 ]] || flags=-m64
    CFLAGS="${CFLAGS:-} -Wno-attributes $flags" CXXFLAGS="${CXXFLAGS:-} -Wno-attributes $flags" LDFLAGS="${LDFLAGS:-} $flags" make

    log steamclient$arch install

    dll="$(pwd)/lsteamclient.dll.so"

    targetdir="$builddir/wine$arch/dlls/lsteamclient"
    mkdir -p "$targetdir"
    rm -rf "$targetdir/lsteamclient.dll.so"
    ln -s "$dll" "$targetdir/lsteamclient.dll.so"

    targetdir="$wine_install_dir/$lib/wine"
    mkdir -p "$targetdir"
    rm -rf "$targetdir/lsteamclient.dll.so"
    ln -s "$dll" "$targetdir/lsteamclient.dll.so"
}

if [[ "$dobuild" == *,steamclient,* ]]
then
    ( build_steamclient 32 )
    ( build_steamclient 64 )
fi

log END
