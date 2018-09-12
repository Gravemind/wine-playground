
Personal wine playground: submodules, scripts, tests, etc...

There might be a couple interesting thing in there, or not...

Meant as a development environment to build and test wine and Steam-Proton-games
with custom wineprefixes, custom and latest versions of wine, dxvk, etc...

### Submodules:

- [wine fork](https://github.com/Gravemind/wine): wine + wine-staging patches +
  a few cherry-picked Steam Proton's hacks (to get steamclient working) + a
  couple of minor patches.

- [dxvk](https://github.com/doitsujin/dxvk.git): latest dxvk

- [Proton](https://github.com/ValveSoftware/Proton): Valve Software Steam Proton for `Proton/lsteamclient`

- [wine-staging](https://github.com/wine-staging/wine-staging): wine staging patches

- [winetricks](https://github.com/Winetricks/winetricks): wine tricks

### Scripts:

- [build.sh](build.sh): builds everything in the `build/` dir.

- [bin](bin/), [bin_mywinewrapper/](bin_mywinewrapper/): provides PATH-addable
  directory containing wrappers for wine's "build-dir-binaries" (so no need
  `make install`, dist etc..)

- [steam_games/](steam_games/) scripts to create, setup, and launch wineprefixes for steam games:
  - with sane setups (wintricks sandbox, no xrandr change, no menubuilder etc...)
  - setups dxvk, steam dlls etc...
  - symlink steam library as dosdevices drive
  - symlink game saves directories to steam's official wine prefix (so the
    prefix can trash and re-created without loosing saves)
  - ...
