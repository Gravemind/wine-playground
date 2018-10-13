#!/bin/bash

set -euo pipefail
here="$(cd "$(dirname "$0")" ; pwd)"
. "$here/_common.sh"

SteamGameId="612880"
GameExe="steamapps/common/Wolfenstein.II.The.New.Colossus/NewColossus_x64vk.exe"

# no need for dxvk, uses vulkan
SetupDxvk=0

MyRegistry='
[HKEY_CURRENT_USER\Software\Wine\Explorer]
"Desktop"="Default"
[HKEY_CURRENT_USER\Software\Wine\Explorer\Desktops]
"Default"="1920x1200"
'

#WineDllOverrides+=("xaudio2_7=n,b")
#WineDebug+=("fps")

setup_wine_prefix()
{
    ( _setup_wine_prefix )
    redist="$SteamLibrary/steamapps/common/Wolfenstein.II.The.New.Colossus/_CommonRedist"
    run wine "$redist/vcredist/2015/vc_redist.x86.exe" /q /norestart
    run wine "$redist/vcredist/2015/vc_redist.x64.exe" /q /norestart
    run wine "$redist/DirectX/Jun2010/DXSETUP.exe" /silent
    ( _setup_wine_prefix ) # re-patch links if necessary etc...
}

main "$@"
