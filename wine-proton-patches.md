
## ValveSoftware/wine Proton patches applied in [this wine fork](./wine):

### Cheat sheet

    $> cd wine/

(Upstreams remotes setup: https://github.com/wine-mirror/wine.git as upstream,
https://github.com/ValveSoftware/wine.git as valve,
https://github.com/zfigura/wine.git as esync)

- Apply wine-staging commits: (as submodule, we need to open
  `patches/patchinstall.sh` and force `workaround_git_bug=1`, because so far it
  works):

      $> ../wine-staging/patches/patchinstall.sh --backend=git-am --all DESTDIR=.
      $> git add -u .
      $> git commit -m 'wine-staging autoconf'

- List proton commits:

      $> git log --oneline wine-3.16..valve/proton_3.16

- List commits cherry-picked in proton, from `_esync_` or `_latest_staging_` for example:

      $> git cherry -v _latest_staging_ valve/proton_3.16 wine-3.16 --abbrev=12 | tee /tmp/proton_staging_cherries
      $> git cherry -v _esync_          valve/proton_3.16 wine-3.16 --abbrev=12 | tee /tmp/proton_esync_cherries
      $> ...

- List proton commits, removing those existing in `_latest_staging_`, or
  `_esync_`, ... (using list generated above):

      $> git log --oneline wine-3.16..valve/proton_3.16 --abbrev=12 | grep -vf <(sed -nE 's/^- ([0-9a-z]+) .*/^\1 /p' /tmp/proton_*_cherries)

  Note: only commits nearly exactly git-cherry-pick (or git-am, or git-apply)
  are removed (see `man git-cherry`).

- Cherry-pick commit selected here below (those prefixed by '->'):

      $> grep '^-> ' ../wine-proton-patches.md | cut -d\  -f 2 | tac | xargs git cherry-pick

### Commits enabled here (->)

Patches are enabled somewhat arbitrarily, vaguely trying to:
- not include those already in latest wine+staging (see how-to above)
- enable lsteamclient for steam-for-linux
- have better defaults (no home symlinks, no winemenubuilder...)
- get the simple useful patches (debugging...)
- but no big patches to try to stay close to wine+staging behaviors (no esync,
  no fullscreen hack...).

```
174d487bf8 wine.inf: Substitute Times New Roman for Palatino Linotype
-> 1091eaf136 HACK: wined3d: Fake an AMD card in place of Nvidia cards
66a7462d98 winex11: enable fullscreen clipping even if not already clipping
0fa3321136 winex11: ignore clip_reset when trying to clip the mouse after the desktop has been resized
(wine) 63f934962c wine.inf: Add font registry entries.
212551db58 dinput: Don't dump a NULL effect.
266d11ab06 d3d11: Remove unused 'depth_tex' variable.
d856e7a941 winevulkan: Enable VK_EXT_transform_feedback.
508e940d13 winevulkan: Update vk.xml to 1.1.86.
141ba5cf73 winex11.drv: Bypass compositor in fullscreen mode
7121928034 Revert "winevulkan: Check if device extensions are supported."
04a83c6f48 Revert "winevulkan: Check if instance extensions are supported."
d594b87433 d3d11: Pass IWineD3D11Texture2D to access_gl_texture().
edb56564cb wined3d: Load TEXTURE_RGB location for synchronous texture access.
1a540c0bc0 wined3d: Implement synchronous texture access.
867cfaca90 wined3d: Get rid of wined3d_cs_emit_wait_idle().
7a0711b3d3 winex11.drv: Fix sub pixel raw motion v3
-> d012d137e4 HACK: dbghelp: Disable DWARF parsing
e619f83959 winex11: Always show a close button
8c78517f1b winex11: Allow the application to change window size and states during PropertyNotify
eb87472b52 winex11: Detect erroneous FocusOut messages for longer
39075cb0aa winex11: Don't set ABOVE on minimized fullscreened windows
2e09c33f98 winex11: Fullscreen hack, don't clip when restoring real resolution
75fc0f36aa winex11: Fullscreen hack, don't ever blit to the frontbuffer after a wglSwapBuffers().
84a0501fed winex11: Fullscreen hack, also hook glBindFramebufferEXT().
2717f60b56 winex11: Fullscreen hack, don't setup the hack again on every wglMakeCurrent().
-> eece6bb2e4 ntdll,server: Never use CLOCK_MONOTONIC_RAW
fd316f75c8 winebus: Show an ERR on old SDL
15c6ecef86 dinput: Don't fail to load on old SDL
132b08339e winex11.drv: fs hack, round scaled coordinates to nearest int
830bef4031 winex11: Revamp display resolution options
daefcfea47 HACK: winex11: Grab mouse in fullscreen windows by default
f59f59650f HACK: winex11: Work around mutter WM bug
29a2c4f1b8 secur32: Return real Unix username from GetUserNameEx(NameDisplay)
1c327ac707 winex11: Also set up fs hack during framebuffer swap
c6152e760d winex11: Set up the context again for fs hack if the size changes
003c2092fd ntdll, server: Abort if esync is enabled for the server but not the client, and vice versa.
aa7fa7ce94 server: Set default timeout to 0
a3752f468d dinput: Use the VID/PID for the first chunk of the device product GUID
4d49baf456 winebus: Don't override real VID/PID for controllers
-> 3c9b9d5a29 wine.inf: Set amd_ags_x64 to built-in for Wolfenstein 2
-> e0c31d82fb amd_ags_x64: Add dll.
-> e10f7f83b4 amd_ags_x64: Make amd_ags.h usable with gcc.
-> afaf271f5a amd_ags_x64: Import v5.1.1 amd_ags.h.
-> 059a15a1d5 HACK: mshtml: Don't install wine-gecko on prefix creation
-> 7f3acf2172 HACK: mscoree: Don't install wine-mono on prefix creation
(staging) e9528f72ef winepulse: Don't rely on pulseaudio callbacks for timing
242ef5ef0d HACK: winex11: Let the WM focus our windows by default
7d6875dee3 xaudio2: Make a log file when the game uses WMA
9e872eff42 server, ntdll: Implement alertable waits.
df9df05bdb server, ntdll: Pass the shared memory index back from get_esync_fd.
68814f7005 ntdll: Use shared memory segments to store semaphore and mutex state.
aa4406c4da server: Allocate shared memory segments for semaphores and mutexes.
3f268381ef server: Create eventfd descriptors for timers.
ec0e8494c6 ntdll, server: Implement NtOpenSemaphore().
1ae7b2d1b6 server, ntdll: Also store the esync type in the server.
6fff0717e8 ntdll: Create esync objects for mutexes.
c9cf5e414a server, ntdll: Also wait on the queue fd when waiting for driver events.
113a3e44cf server: Create eventfd file descriptors for process objects.
f439667136 server: Add a request to get the eventfd file descriptor associated with a waitable handle.
bbac68a893 server: Create server objects for eventfd-based synchronization objects.
-> 971dc3c422 ntdll: Notice THREADNAME_INFO exceptions and set thread name on Linux
6cdbdae7e9 winex11: Fullscreen hack, handle multisample FBConfig.
e237641cd1 winex11: Fullscreen hack, attach a depth / stencil buffer when necessary.
-> f375f8dafa winex11.drv: Log more information about X errors
-> 59e3f7faf3 kernel32: Implement Set and GetThreadDescription
-> 134fa05a0e HACK: winex11.drv: Disable XIM by default
-> 68caf4ef0a winex11: Always load the indexed scissor functions
(staging ?) 6e4d4aefc3 xaudio2_7: Update ffmpeg usage for ffmpeg 4.0
(staging ?) 8caae1a0c4 xaudio2: Use ffmpeg to convert non-PCM formats
ef2ecf0f3c winex11: Set the scissor rect before doing fs hack blit
5483f4128b winex11: Use hacked fbo for drawing immediately After setting up fs hack
1f7d06d56b winex11: In FS hack, don't clear the front buffer during context setup
e07f2588f2 winex11: Set WM hints before setting FS state
d13af02716 winevulkan: Blit directly to swapchain images if possible
81f198f28e winevulkan: Implement fs hack
8efca5790f winevulkan: Track swapchains in VkDevice
cf9791c734 winevulkan: Wrap swapchain object
6dc193b560 winevulkan: Move FS hack functions out of thunk
b142c004fe Revert "winevulkan: Get rid of unused "phys_dev" field from VkDevice_T."
ac9cd627df wined3d: Support retrieving depth texture in GL texture callback
94b4e1e4fc wined3d: Implement wined3d_device_wait_idle().
3d4a261491 winevulkan: Add struct unwrappers for vrclient
50b26687ab d3d11: Add IWineD3D11Device interface.
517f0cc07f d3d11: Add IWineD3D11Texture2D interface.
98d5b35869 wined3d: Implement command stream callbacks.
0fce68f807 wined3d: Implement GL texture access callbacks.
-> a13270aea5 winedbg: When crash dialog is not shown, dump crash info to stderr
-> b902a1b789 xaudio2: Prefer native xaudio2 in 32-bit
-> 0400502cb3 HACK: wine.inf: Add native,builtin overrides for msvcrt DLLs
-> 3340c66267 HACK: Don't build winemenubuilder
-> a7542e9e27 wine.inf: Don't show crash dialog by default
e5f7b5460b HACK: user32: Replace Wine glass with generic window icon
-> bac899cd45 kernel32: Don't force-load Steam.dll
c569fbd676 HACK: winex11: Give fullscreen windows focus
d669b1e261 Frontbuffer blitting hack...
4cd1ae0e2c winex11.drv: Improved fullscreen hack
-> 15f05e3ee2 winex11.drv: Log errors that we pass on
ff8c17e8f9 user32: Correct monitor flags from EnumDisplayDevices
-> 81be78aa53 HACK: wineboot: Don't show "updating prefix" window
-> ec9e7190ea HACK: shell32: Never create links to the user's home dirs
819b923a3b HACK: advapi32: Use steamuser as Wine username
888a35da8e dinput: implement DISFFC_PAUSE/DISFFC_CONTINUE for SDL
8a7f8a41b2 dinput: Implement FF effects for SDL joysticks
30257203d3 dinput: Implement GetEffectInfo, SendForceFeedbackCommand and EnumCreatedEffectObjects
6ef7ecf144 dinput: Begin SDL haptic implemeting Get/SetProperty
337ef7e8ca dinput: Add SDL support
-> a2f9e2806a kernel32: Support steamclient64
-> aa88eb017b loader: Set up Steam stuff in the registry
-> 3835eee939 HACK: kernel32: Put Steam program files dir into PATH
-> 183eac81ab HACK: kernel32: Return steamclient instead of lsteamclient during GetModuleHandleEx
-> acda0915ca HACK: kernel32: Load hard-coded Steam.dll path if relative load fails
-> a277e32030 HACK: kernel32: Swap requests for steamclient.dll with lsteamclient
-> 7bd039f34f HACK: ws2_32: Fake success when trying to bind to an IPX address
-> bc614834ee HACK kernel32: Substitute the current pid for the Steam client pid
```
