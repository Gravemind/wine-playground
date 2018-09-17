#!/bin/bash

set -euo pipefail
here="$(cd "$(dirname "$0")" ; pwd)"
. "$here/_common.sh"

SteamGameId="414340"
GameExe="steamapps/common/Hellblade/HellbladeGame.exe"

SetupDxvk=1

SymlinksToSteamPrefix+=( "Local Settings/Application Data/HellbladeGame"  )

WineDebug+=("-nvapi")

#WineDebug+=("+pulse,+alsa,+dsound")
#WineDebug+=("+dll,+module")
#WineDebug+=("+xaudio2")

DXVK_HUD="fps,frametimes"

DxvkConfig='
dxgi.maxFrameLatency = 1
dxgi.syncInterval = 1
'

# Fixes audio crackling/fluttering/glitching
# in combination with installing _CommonRedist sutff (_post_setup_wine_prefix)
WineDllOverrides+=("xaudio2_7=n,b")

setup_wine_prefix()
{
    ( _setup_wine_prefix )
    redist="$SteamLibrary/steamapps/common/Hellblade/_CommonRedist"
    run wine "$redist/vcredist/2012/vcredist_x86.exe" /quiet /norestart
    run wine "$redist/vcredist/2012/vcredist_x64.exe" /quiet /norestart
    run wine "$redist/vcredist/2013/vcredist_x86.exe" /quiet /norestart
    run wine "$redist/vcredist/2013/vcredist_x64.exe" /quiet /norestart
    run wine "$redist/vcredist/2015/vc_redist.x86.exe" /quiet /norestart
    run wine "$redist/vcredist/2015/vc_redist.x64.exe" /quiet /norestart
    run wine "$redist/DirectX/Jun2010/DXSETUP.exe" /silent
    ( _setup_wine_prefix ) # re-patch links if necessary etc...
}

main "$@"
