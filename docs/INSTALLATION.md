[← Yuragi](../README.md) · [Documentation](README.md)

# Installation

Requires **Omarchy 4 with Omarchy Shell**, Quickshell, and **Qt Multimedia 6.11+ with the native PipeWire audio backend**
(`qt6-multimedia` and `qt6-multimedia-ffmpeg`). Tested on Omarchy 4.0.3,
Quickshell 0.3.1 and Qt 6.11.2. Omarchy 3/Waybar is not supported.

```sh
omarchy plugin add https://github.com/nachfq/omarchy-yuragi.git --enable
omarchy bar move nachfq.yuragi --section center --before omarchy.clock
```

The install command uses the repository's default branch.
Omarchy installs the files and asks before enabling; there are no install hooks,
extra processes or runtime package downloads. If Qt Multimedia is missing,
install the two packages with Omarchy's package manager before enabling.

Yuragi is a separate bar widget beside `omarchy.indicators`. It reuses the
native indicator component and center-hover behavior. Omarchy 4.0.3's bundled
indicator group loads only its built-in entries; it does not expose a plugin
registration API for adding Yuragi inside that group.

## Update and remove

```sh
omarchy plugin update nachfq.yuragi
omarchy plugin disable nachfq.yuragi
omarchy plugin remove nachfq.yuragi
```

Disabling or removing Yuragi stops its audio. Code reloads also start paused.
If an update leaves old icons or controls visible, run `omarchy restart shell`
to reload all QML components. This restarts the desktop shell and pauses Yuragi;
saved volumes and Randomize are preserved.
Yuragi does not install services, modify system files, or leave audio processes
running. A channel whose recording cannot load shows “Audio unavailable”; the
remaining channels still work. Reinstall the plugin to restore a damaged file.
