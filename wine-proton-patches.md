
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

- Compare commits in proton vs other branches:

      $> git range-diff --abbrev=12 wine-3.16 valve/proton_3.16 _latest_stating_ | tee /tmp/proton_rangediff_staging
      $> git range-diff --abbrev=12 wine-3.16 valve/proton_3.16 _latest_esync_ | tee /tmp/proton_rangediff_esync
      $> ...

- List proton commits, removing those existing in other branches (using list generated above):

      $> git log --abbrev=12 --oneline wine-3.16..valve/proton_3.16 | grep -vf <(awk '/^ *[0-9]+:/ && $2 ~ /^[0-9a-z]{12}$/ && $5 ~ /^[0-9a-z]{12}$/ { print "^ " $2 " " }' /tmp/proton_rangediff_*)

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
(conflicts) 0d666718091f xaudio2: Set PulseAudio application name property in the environment
-> 134953e8be78 xaudio2: Consistently prefer native on 32-bit
-> bf02d103fde2 Add missing InstallPath registry value.
ce7cacbbf782 xaudio2: Wait for engine thread to be ready
e0e3165c1534 [xaudio2] Add support for xactengine3
dc928a9f4789 Revert "xaudio2: Use ffmpeg to convert non-PCM formats"
e72407db12d3 Revert "xaudio2_7: Update ffmpeg usage for ffmpeg 4.0"
98a249011db5 Revert "xaudio2: Make a log file when the game uses WMA"
ac3adb3baae7 server: Add NtQueryInformationFile(FileIoCompletionNotificationInformation) implementation.
174d487bf8ef wine.inf: Substitute Times New Roman for Palatino Linotype
-> 1091eaf13692 HACK: wined3d: Fake an AMD card in place of Nvidia cards
66a7462d98e1 winex11: enable fullscreen clipping even if not already clipping
0fa33211362e winex11: ignore clip_reset when trying to clip the mouse after the desktop has been resized
63f934962cb9 wine.inf: Add font registry entries.
212551db587e dinput: Don't dump a NULL effect.
266d11ab06d5 d3d11: Remove unused 'depth_tex' variable.
141ba5cf7302 winex11.drv: Bypass compositor in fullscreen mode
7121928034ac Revert "winevulkan: Check if device extensions are supported."
04a83c6f485c Revert "winevulkan: Check if instance extensions are supported."
d594b8743322 d3d11: Pass IWineD3D11Texture2D to access_gl_texture().
edb56564cb2d wined3d: Load TEXTURE_RGB location for synchronous texture access.
1a540c0bc057 wined3d: Implement synchronous texture access.
867cfaca90ba wined3d: Get rid of wined3d_cs_emit_wait_idle().
-> d012d137e409 HACK: dbghelp: Disable DWARF parsing
e619f8395976 winex11: Always show a close button
8c78517f1b99 winex11: Allow the application to change window size and states during PropertyNotify
eb87472b5262 winex11: Detect erroneous FocusOut messages for longer
39075cb0aa30 winex11: Don't set ABOVE on minimized fullscreened windows
2e09c33f982f winex11: Fullscreen hack, don't clip when restoring real resolution
75fc0f36aa81 winex11: Fullscreen hack, don't ever blit to the frontbuffer after a wglSwapBuffers().
84a0501fedc2 winex11: Fullscreen hack, also hook glBindFramebufferEXT().
2717f60b56fb winex11: Fullscreen hack, don't setup the hack again on every wglMakeCurrent().
eece6bb2e453 ntdll,server: Never use CLOCK_MONOTONIC_RAW
fd316f75c89c winebus: Show an ERR on old SDL
15c6ecef8640 dinput: Don't fail to load on old SDL
132b08339ead winex11.drv: fs hack, round scaled coordinates to nearest int
830bef40319c winex11: Revamp display resolution options
daefcfea4724 HACK: winex11: Grab mouse in fullscreen windows by default
f59f59650fe3 HACK: winex11: Work around mutter WM bug
29a2c4f1b8ca secur32: Return real Unix username from GetUserNameEx(NameDisplay)
1c327ac707d3 winex11: Also set up fs hack during framebuffer swap
c6152e760d79 winex11: Set up the context again for fs hack if the size changes
aa7fa7ce94bd server: Set default timeout to 0
a3752f468dd8 dinput: Use the VID/PID for the first chunk of the device product GUID
-> 3c9b9d5a290c wine.inf: Set amd_ags_x64 to built-in for Wolfenstein 2
-> e0c31d82fb16 amd_ags_x64: Add dll.
-> e10f7f83b4d7 amd_ags_x64: Make amd_ags.h usable with gcc.
-> afaf271f5ae5 amd_ags_x64: Import v5.1.1 amd_ags.h.
-> 059a15a1d521 HACK: mshtml: Don't install wine-gecko on prefix creation
-> 7f3acf21721b HACK: mscoree: Don't install wine-mono on prefix creation
242ef5ef0d03 HACK: winex11: Let the WM focus our windows by default
7d6875dee3cc xaudio2: Make a log file when the game uses WMA
-> 971dc3c4225b ntdll: Notice THREADNAME_INFO exceptions and set thread name on Linux
6cdbdae7e9bc winex11: Fullscreen hack, handle multisample FBConfig.
e237641cd1ff winex11: Fullscreen hack, attach a depth / stencil buffer when necessary.
-> f375f8dafada winex11.drv: Log more information about X errors
-> 59e3f7faf3ac kernel32: Implement Set and GetThreadDescription
-> 134fa05a0e39 HACK: winex11.drv: Disable XIM by default
-> 68caf4ef0a27 winex11: Always load the indexed scissor functions
6e4d4aefc3b0 xaudio2_7: Update ffmpeg usage for ffmpeg 4.0
ef2ecf0f3c51 winex11: Set the scissor rect before doing fs hack blit
5483f4128b6a winex11: Use hacked fbo for drawing immediately After setting up fs hack
1f7d06d56b31 winex11: In FS hack, don't clear the front buffer during context setup
e07f2588f2e0 winex11: Set WM hints before setting FS state
d13af02716a4 winevulkan: Blit directly to swapchain images if possible
81f198f28e51 winevulkan: Implement fs hack
8efca5790fb1 winevulkan: Track swapchains in VkDevice
cf9791c73458 winevulkan: Wrap swapchain object
6dc193b560b9 winevulkan: Move FS hack functions out of thunk
b142c004fe67 Revert "winevulkan: Get rid of unused "phys_dev" field from VkDevice_T."
ac9cd627dfea wined3d: Support retrieving depth texture in GL texture callback
94b4e1e4fcb6 wined3d: Implement wined3d_device_wait_idle().
3d4a2614912d winevulkan: Add struct unwrappers for vrclient
50b26687abcd d3d11: Add IWineD3D11Device interface.
517f0cc07f63 d3d11: Add IWineD3D11Texture2D interface.
98d5b3586979 wined3d: Implement command stream callbacks.
0fce68f80760 wined3d: Implement GL texture access callbacks.
-> a13270aea50a winedbg: When crash dialog is not shown, dump crash info to stderr
-> b902a1b789b5 xaudio2: Prefer native xaudio2 in 32-bit
-> 0400502cb3bb HACK: wine.inf: Add native,builtin overrides for msvcrt DLLs
-> 3340c66267ef HACK: Don't build winemenubuilder
-> a7542e9e2799 wine.inf: Don't show crash dialog by default
e5f7b5460b5e HACK: user32: Replace Wine glass with generic window icon
-> bac899cd4531 kernel32: Don't force-load Steam.dll
c569fbd6769c HACK: winex11: Give fullscreen windows focus
d669b1e261a3 Frontbuffer blitting hack...
4cd1ae0e2cb8 winex11.drv: Improved fullscreen hack
-> 15f05e3ee2ba winex11.drv: Log errors that we pass on
ff8c17e8f94c user32: Correct monitor flags from EnumDisplayDevices
-> 81be78aa5335 HACK: wineboot: Don't show "updating prefix" window
-> ec9e7190ea70 HACK: shell32: Never create links to the user's home dirs
819b923a3b76 HACK: advapi32: Use steamuser as Wine username
888a35da8eca dinput: implement DISFFC_PAUSE/DISFFC_CONTINUE for SDL
8a7f8a41b2a2 dinput: Implement FF effects for SDL joysticks
30257203d3ed dinput: Implement GetEffectInfo, SendForceFeedbackCommand and EnumCreatedEffectObjects
6ef7ecf1446c dinput: Begin SDL haptic implemeting Get/SetProperty
337ef7e8ca49 dinput: Add SDL support
-> a2f9e2806acd kernel32: Support steamclient64
-> aa88eb017be4 loader: Set up Steam stuff in the registry
-> 3835eee939a9 HACK: kernel32: Put Steam program files dir into PATH
-> 183eac81ab47 HACK: kernel32: Return steamclient instead of lsteamclient during GetModuleHandleEx
-> acda0915ca65 HACK: kernel32: Load hard-coded Steam.dll path if relative load fails
-> a277e32030a3 HACK: kernel32: Swap requests for steamclient.dll with lsteamclient
-> 7bd039f34f5f HACK: ws2_32: Fake success when trying to bind to an IPX address
-> bc614834ee15 HACK kernel32: Substitute the current pid for the Steam client pid
```
