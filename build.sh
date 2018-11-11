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

dobuild=",${1:-dxvk,wine,steamclient,faudio},"

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

path_set() {
    local enable="$1"
    local mypath="$2"
    [[ -n "$mypath" ]] || return 0
    export PATH="${PATH//$mypath://}"
    if [[ "$enable" = "1" ]]
    then
        export PATH="${mypath}:$PATH"
        log "Added to PATH: $mypath"
    else
        log "Removed from PATH: $mypath"
    fi
}

# One way to use ccache everywhere is to use symlinks and PATH override, eg:
#   $> mkdir ~/bin/ccache_bin
#   $> ln -s /usr/bin/ccache ~/bin/ccache_bin/gcc
#   $> ln -s /usr/bin/ccache ~/bin/ccache_bin/g++
#   $> ln -s /usr/bin/ccache ~/bin/ccache_bin/x86_64-w64-mingw32-gcc
#   $> ln -s /usr/bin/ccache ~/bin/ccache_bin/x86_64-w64-mingw32-g++
#   etc...
#   $> export PATH="$HOME/bin/ccache_bin:$PATH"
if [[ -e "$HOME/bin/ccache_bin/gcc" ]]
then
    log "ccache ready to be enabled"
    ccacheon() { path_set 1 "$HOME/bin/ccache_bin"; }
    ccacheoff() { path_set 0 "$HOME/bin/ccache_bin"; }
else
    log "ccache not found"
    ccacheon() { true; }
    ccacheoff() { true; }
fi

# Same as above for rtags, with:
#   $> ln -s /path/to/rtags/bin/gcc-rtags-wrapper.sh ~/bin/rtags_bin/gcc
#   etc...
if [[ -e "$HOME/bin/rtags_bin/gcc" ]] && rc --project > /dev/null 2>&1
then
    log "rtags ready to be enabled"
    rtagson() { path_set 1 "$HOME/bin/rtags_bin"; }
    rtagsoff() { path_set 0 "$HOME/bin/rtags_bin"; }
else
    log "rtags not found or not running"
    rtagson() { true; }
    rtagsoff() { true; }
fi

unsetcc

ccacheon

# export CC="clang"
# export CXX="clang++"
# export LD="ld.lld"

#export CFLAGS="-O2 -march=native -g"
#export CXXFLAGS="-O2 -march=native -g"
export CFLAGS="-O3 -march=native -g"
export CXXFLAGS="-O3 -march=native -g"
# export CFLAGS="-g -Og -mmmx -msse -msse2 -mfpmath=sse"
# export CXXFLAGS="-g -Og -mmmx -msse -msse2 -mfpmath=sse"
nproc="$(( $(nproc) * 9 / 10 ))"
export MAKEFLAGS="-j$nproc  -Orecurse"

CFLAGS+=" -fwrapv -fno-strict-aliasing"

#CFLAGS+=" -g3 -gdwarf-5 -fvar-tracking-assignments"
#CXXFLAGS+=" -g3 -gdwarf-5 -fvar-tracking-assignments"

#CFLAGS+=" -fno-omit-frame-pointer"
#CXXFLAGS+=" -fno-omit-frame-pointer"

# CFLAGS+=" -flto"
# CXXFLAGS+=" -flto"
# LDFLAGS+=" -flto"
# export LDFLAGS

####

path_set 1 "$here/bin"

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

    [[ $arch != 64 ]] || rtagson
    make
    rtagsoff

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

    reconfigure=
    [[ ! -e "$builddir/build-dxvk$arch/build.ninja" ]] || reconfigure="--reconfigure"

    meson $reconfigure --cross-file build-win$arch.txt --buildtype release --prefix "$builddir/dxvk$arch" "$builddir/build-dxvk$arch"

    cd "$builddir/build-dxvk$arch"

    log dxvk$arch build

    ninja -j$nproc

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

####

build_faudio() {
    # unsetcc

    local arch=$1

    cd "$here/FAudio"

    log faudio$arch build FAudio

    local old_path="$PATH"
    . "cpp/scripts/cross_compile_$arch"

    # If there was any *ccache* path, re-force it in front
    if [[ ":$old_path:" =~ :([^:]+ccache[^:]+): ]]
    then
        local ccache_path="${BASH_REMATCH[1]}"
        echo "Re-applying ccache PATH override: $ccache_path"
        PATH="ccache_path:$PATH"
        which $CC
    fi

    make clean
    make all

    log faudio$arch build xaudio
    cd "cpp"
    mkdir -p "build_win$arch" # avoid make clean error
    make clean
    make all
}

if [[ "$dobuild" == *,faudio,* ]]
then
    #( build_faudio 32 )
    ( build_faudio 64 )
fi

log END
