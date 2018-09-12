#!/bin/bash

wine_sandox_path="$(cd "$here/.." ; pwd)"

origin_cwd="$(pwd)"

export ORIG_PATH="$PATH"
export PATH="$ORIG_PATH:$wine_sandox_path/bin"

## My steam library (will fallback if game not foud there)
SteamLibrary="$HOME/SteamLibrary"

SymlinksToSteamPrefix=( "Saved Games" "My Documents" )

WineDebug=()
WineDllOverrides=()

main() {
    local setup=0
    local keep_origin_cwd=0
    while [[ "${1:-}" = --* ]]
    do
        case "$1" in
            --setup) setup=1 ; shift ;;
            --cwd) keep_origin_cwd=1 ; shift ;;
            --) shift ; break ;;
            *) echo "$0: unkown arguement: $1" 1>&2 ; exit 2 ;;
        esac
    done

    GameName="${GameName:-$(basename "$0" .sh)}"

    ## wine
    export WINEARCH="${WINEARCH:-win64}"
    export WINEPREFIX="${WINEPREFIX:-$HOME/wine/steam_$GameName}"
    [[ -z "${WINEDEBUG:-}" ]] || WineDebug+=( "$WINEDEBUG" )
    export WINEDEBUG="$(array_join "," "${WineDebug[@]}")"
    [[ -z "${WINEDLLOVERRIDES:-}" ]] || WineDllOverrides+=( "$WINEDLLOVERRIDES" )
    export WINEDLLOVERRIDES="$(array_join ";" "${WineDllOverrides[@]}")"

    ## dxvk
    export DXVK_HUD="${DXVK_HUD:-fps}"

    ## steam
    export STEAM_COMPAT_CLIENT_INSTALL_PATH="${STEAM_COMPAT_CLIENT_INSTALL_PATH:-$HOME/.local/share/Steam}"
    export SteamGameId="${SteamGameId:-0}"
    export SteamAppId="${SteamGameId}"

    ## internal vars

    SetupDxvk="${SetupDxvk:-1}"

    if [[ ! -e "$SteamLibrary/$GameExe" ]]
    then
        if [[ -e "$STEAM_COMPAT_CLIENT_INSTALL_PATH/$GameExe" ]]
        then
            SteamLibrary="$STEAM_COMPAT_CLIENT_INSTALL_PATH"
        else
            echo "$0: error: cannot find game exe: $SteamLibrary/$GameExe nor $STEAM_COMPAT_CLIENT_INSTALL_PATH/$GameExe"
            exit 44
        fi
    fi

    GamePath="$SteamLibrary/$GameExe"

    SteamGameWinePrefix="$SteamLibrary/steamapps/compatdata/$SteamGameId/pfx"
    [[ -e "$SteamGameWinePrefix" ]] || { echo "$0: error: Steam's wine prefix not found: $SteamGameWinePrefix" ; exit 45 ; }

    SteamLibraryDrive="s:"

    echo "
---- $GameName ----
Wine Prefix: ${WINEPREFIX/#$HOME/\~}
Wine Arch: $WINEARCH
Wine Debug: $WINEDEBUG
Wine DllOverrides: $WINEDLLOVERRIDES
Wine: $(w="$(which wine)"; echo "${w/#$HOME/\~}")

Steam exe: ${GamePath/#$HOME/\~}
Steam GameId: $SteamGameId
Steam local: ${STEAM_COMPAT_CLIENT_INSTALL_PATH/#$HOME/\~}
Steam pfx: ${SteamGameWinePrefix/#$HOME/\~}
Symlink dirs:
$(printf -- "- ${WINEPREFIX/#$HOME/\~}/drive_c/users/$USER/%s\n" "${SymlinksToSteamPrefix[@]}")
--------
"

    [[ -e "$WINEPREFIX" ]] || setup = 1

    if [[ $setup = 1 ]]
    then
        echo "---- BOOTING ----"
        ( boot_wine_prefix )
        cd "$WINEPREFIX/drive_c"

        echo "---- SETUP ----"
        ( setup_wine_prefix )
    fi

    echo "---- PREPARE ----"
    cd "$WINEPREFIX/drive_c"
    ( prepare_wine_prefix )

    if [[ "$#" -eq 0 ]]
    then
        echo "---- RUN wine $GamePath ----"
        if [[ "$keep_origin_cwd" = 1 ]]
        then
            cd "$origin_cwd"
        else
            cd "$(dirname "$GamePath")"
        fi
        wine "$GamePath"
        ret=$?
    else
        echo "---- RUN $@ ----"
        if [[ "$keep_origin_cwd" = 1 ]]
        then
            cd "$origin_cwd"
        else
            cd "$WINEPREFIX/drive_c"
        fi
        "$@"
        ret=$?
    fi

    wait_wineserver
    echo "---- end ($ret) ----"
}

boot_wine_prefix() { _boot_wine_prefix ; }

setup_wine_prefix() { _setup_wine_prefix ; }

prepare_wine_prefix() { _prepare_wine_prefix ; }

_boot_wine_prefix() {
    ## Create/Update wine prefix
    run wineboot -u
    wait_wineserver

    ## Remove all links to HOME
    wait_wineserver
    run winetricks sandbox
}

_setup_wine_prefix() {
    ## Setup DXVK links
    wait_wineserver # !important, required for dxvk setup script to work
    if [[ "$SetupDxvk" = 1 ]]
    then
        echo "---- Setup dxvk ----"
        "$wine_sandox_path/setup_dxvk_to.sh"
    else
        echo "---- Skipping dxvk ----"
    fi

    ## Symink steam dlls from install to wine prefix
    mkdir -p "$WINEPREFIX/drive_c/Program Files (x86)/Steam/"
    (
        cd "$WINEPREFIX/drive_c/Program Files (x86)/Steam/"
        for dll in "$STEAM_COMPAT_CLIENT_INSTALL_PATH/legacycompat/"*.dll
        do
            ln -fs "$dll"
        done
    )

    ## Steam library as drive
    rm -f "$WINEPREFIX/dosdevices/$SteamLibraryDrive"
    ln -fs "$SteamLibrary" "$WINEPREFIX/dosdevices/$SteamLibraryDrive"

    ## Sym link saved game directories to steam official prefix
    for link in "${SymlinksToSteamPrefix[@]}"
    do
        wine_dir="$WINEPREFIX/drive_c/users/$USER/$link"
        steam_dir="$SteamGameWinePrefix/drive_c/users/steamuser/$link"
        echo "---- Symlink to Steam pfx: $link ----"
        echo "from: $wine_dir"
        echo "to  : $steam_dir"
        if [[ ! -d "$steam_dir" ]]
        then
            echo "error: cannot symlink $link: no such directory in steam pfx: $steam_dir"
            exit 47
        fi
        if [[ -e "$wine_dir" && ! -L "$wine_dir" ]]
        then
            if [[ "$(find "$wine_dir" -not -type d | wc -l)" -gt 0 ]]
            then
                echo "error: will not symlink $link: wine directory not empty: $wine_dir"
                exit 48
            fi
            rm -rf "$wine_dir"
        fi
        ln -fs "$steam_dir" "$wine_dir"
    done

    ## Regedit files
    regfile "$WINEPREFIX/../my_wine_regs.reg"
    regfile "$WINEPREFIX/my_wine_regs.reg"

    ## More regedit: custom
    regmem "${MyRegistry:-}"

    wait_wineserver
}

_prepare_wine_prefix() {
    true # nothing to do, for now
}

wait_wineserver() {
    echo "Waiting for wineserver ..."
    wineserver -w
}

regmem() {
    if [[ -n "$*" ]]
    then
        echo "---- Registry update ----"
        echo "$@"
        (
            ( echo -e 'Windows Registry Editor Version 5.00\n' ; echo "$@" ) \
                > "$WINEPREFIX/drive_c/tmp_regfile.reg"
            cd "$WINEPREFIX/drive_c"
            wine regedit "C:/tmp_regfile.reg"
        )
    fi
}

regfile() {
    local file="$1"
    if [[ -r "$file" ]]
    then
        echo "---- Registry update: $file ----"
        (
            \cat "$file" > "$WINEPREFIX/drive_c/tmp_regfile.reg"
            cd "$WINEPREFIX/drive_c"
            wine regedit "C:/tmp_regfile.reg"
        )
    else
        echo "---- Skipping registry update: no such $file ----"
    fi
}

array_join() {
    local sep="$1"
    shift
    ( IFS="$sep" ; echo "$*" )
}

set_term_title() {
    echo -ne '\033]2;$0: '"$*"'\007'
}

run() {
    echo "---- Run $@ ----"
    set_term_title "$*"
    "$@"
}

run_sync() {
    run "$@"
    echo "Waiting for $@ ..."
    wineserver -w
}
