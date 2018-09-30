#!/bin/bash

set -euo pipefail
here="$(cd "$(dirname "$0")" ; pwd)"
. "$here/_common.sh"

SteamGameId="350080"
GameExe="steamapps/common/Wolfenstein The Old Blood/WolfOldBlood_x64.exe"

MyRegistry='
[HKEY_CURRENT_USER\Software\Wine\Explorer]
"Desktop"="Default"
[HKEY_CURRENT_USER\Software\Wine\Explorer\Desktops]
"Default"="1920x1200"
'

WineDllOverrides+=("xaudio2_7=n,b")

#WineDebug+=("fps")
export __GL_SHOW_GRAPHICS_OSD=1

setup_wine_prefix()
{
    ( _setup_wine_prefix )
    redist="$SteamLibrary/steamapps/common/Wolfenstein The Old Blood/_CommonRedist"
    run wine "$redist/vcredist/2012/vcredist_x86.exe" /quiet /norestart
    run wine "$redist/vcredist/2012/vcredist_x64.exe" /quiet /norestart
    run wine "$redist/DirectX/Jun2010/DXSETUP.exe" /silent
    ( _setup_wine_prefix ) # re-patch links if necessary etc...
}

main "$@"
