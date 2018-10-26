#!/bin/bash

#set -x

wine_playground_path="$(cd "$here/.." ; pwd)"

origin_cwd="$(pwd)"

export ORIG_PATH="$PATH"
export PATH="$ORIG_PATH:$wine_playground_path/bin"

## My steam library (will fallback if game not foud there)
SteamLibrary="$HOME/SteamLibrary"

SymlinksToSteamPrefix=( "Saved Games" "My Documents" )

ScreenRes="$(xdpyinfo | awk '/dimensions:/{ print $2; exit 0; }')"

WineDebug=()
WineDllOverrides=()

opt_no_wineserver_wait=0

main() {
    local setup=0
    local keep_origin_cwd=0
    while [[ "${1:-}" = --* ]]
    do
        case "$1" in
            --setup) setup=1 ; shift ;;
            --cwd) keep_origin_cwd=1 ; shift ;;
            --no-wait) opt_no_wineserver_wait=1 ; shift ;;
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

    [[ -e "$WINEPREFIX" ]] || setup=1

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
    prepare_wine_prefix

    if [[ "$#" -eq 0 ]]
    then
        if [[ "$keep_origin_cwd" = 1 ]]
        then
            cd "$origin_cwd"
        else
            cd "$(dirname "$GamePath")"
        fi
        echo "---- RUN wine $GamePath ----"
        wine "$GamePath"
        ret=$?
    else
        if [[ "$keep_origin_cwd" = 1 ]]
        then
            cd "$origin_cwd"
        else
            cd "$(dirname "$GamePath")"
            #cd "$WINEPREFIX/drive_c"
        fi
        if ! pgrep -x steam >& /dev/null
        then
            echo
            echo "----- /!\\ steam not running !? game might silently fail to launch /!\\ ----"
            echo
        fi
        echo "---- RUN $@ ----"
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
        "$wine_playground_path/setup_dxvk_to.sh"
    else
        echo "---- Skipping dxvk ----"
    fi

    ## Symink steam dlls from install to wine prefix
    mkdir -p "$WINEPREFIX/drive_c/Program Files (x86)/Steam/"
    (
        cd "$WINEPREFIX/drive_c/Program Files (x86)/Steam/"
        for dll in "$STEAM_COMPAT_CLIENT_INSTALL_PATH/legacycompat/"*.dll
        do
            ln -sf "$dll"
        done
    )

    ## Steam library as drive
    ln -sfT "$SteamLibrary" "$WINEPREFIX/dosdevices/$SteamLibraryDrive"

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
        ln -sfT "$steam_dir" "$wine_dir"
    done

    wait_wineserver
}

_prepare_wine_prefix() {

    ## Regedit files
    autoreg "pfx..my_wine_regs.reg" "$WINEPREFIX/../my_wine_regs.reg"
    autoreg "pfx_my_wine_regs.reg" "$WINEPREFIX/my_wine_regs.reg"

    ## More regedit: custom
    autoreg_data "var_MyRegistry" "${MyRegistry:-}"

    wait_wineserver

    if [[ -z "${DXVK_CONFIG_FILE:-}" && -n "${DxvkConfig:-}" ]]
    then
        path="$WINEPREFIX/drive_c/generated_DxvkConfig.conf"
        echo "---- Dxvk config: $path ----"
        echo "$DxvkConfig" | tee "$path"
        export DXVK_CONFIG_FILE="$path"
    fi

}

autoreg() {
    local name="$1"
    local ext_file="$2"
    [[ -e "$ext_file" ]] || return 0

    local int_file="$WINEPREFIX/drive_c/autoreg_$name.reg"
    if diff -q "$ext_file" "$int_file" >& /dev/null
    then
        echo "---- Registry $name up to date ----"
        # SAME files
        return 0
    fi
    echo "---- Registry update $name ----"
    cat "$ext_file" > "$int_file"
    wine reg import "$int_file"
}

autoreg_data()
{
    local name="$1"
    local data="$2"
    local tmp="$(mktemp -t steamautoreg.XXXXXXXX)"
    (
        echo -e 'Windows Registry Editor Version 5.00\n'
        echo "$data"
    ) > "$tmp"
    autoreg "$name" "$tmp"
    rm "$tmp"
}

wait_wineserver() {
    [[ "$opt_no_wineserver_wait" = 0 ]] || return 0
    echo "Waiting for wineserver ..."
    wineserver -w
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
    [[ "$opt_no_wineserver_wait" = 0 ]] || return 0
    wineserver -w
}
