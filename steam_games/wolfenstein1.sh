#!/bin/bash

set -euo pipefail
here="$(cd "$(dirname "$0")" ; pwd)"
. "$here/_common.sh"

SteamGameId="201810"
GameExe="steamapps/common/Wolfenstein.The.New.Order/WolfNewOrder_x64.exe"

MyRegistry='
[HKEY_CURRENT_USER\Software\Wine\X11 Driver]
"Managed"="Y"
[HKEY_CURRENT_USER\Software\Wine\Explorer]
"Desktop"="Default"
[HKEY_CURRENT_USER\Software\Wine\Explorer\Desktops]
"Default"="1920x1200"
'

#WineDllOverrides+=("xaudio2_7=n,b")

WineDebug+=("fps")

setup_wine_prefix()
{
    ( _setup_wine_prefix )
    redist="$SteamLibrary/steamapps/common/Wolfenstein.The.New.Order/_CommonRedist"
    run wine "$redist/vcredist/2008/vcredist_x86.exe" /q /norestart
    run wine "$redist/vcredist/2008/vcredist_x64.exe" /q /norestart
    run wine "$redist/vcredist/2010/vcredist_x86.exe" /quiet /norestart
    run wine "$redist/vcredist/2010/vcredist_x64.exe" /quiet /norestart
    run wine "$redist/DirectX/Jun2010/DXSETUP.exe" /silent
    ( _setup_wine_prefix ) # re-patch links if necessary etc...
}

main "$@"
