# Omarchy Murmur

A small offline ambient sound mixer for Omarchy Shell.

![Murmur's native mixer panel](preview.png)

Layer rain, thunder, waves, wind, fire, birds, crickets, coffee shop, singing
bowl and white noise. Set each volume, press Play, and let Randomize gently
change the mix while you work. Ten sounds, one panel, no account or connection.

## Install

Requires **Omarchy 4 with Omarchy Shell**, Quickshell, and **Qt Multimedia 6.11+ with the native PipeWire audio backend**
(`qt6-multimedia` and `qt6-multimedia-ffmpeg`). Tested on Omarchy 4.0.3,
Quickshell 0.3.1 and Qt 6.11.2. Omarchy 3/Waybar is not supported.

```sh
omarchy plugin add https://github.com/nachfq/omarchy-murmur.git --enable
omarchy bar move nachfq.murmur --section center --before omarchy.clock
```

The install command uses the repository's default branch. During initial
review, it becomes usable after the implementation PRs are merged.
Omarchy installs the files and asks before enabling; there are no install hooks,
extra processes or runtime package downloads. If Qt Multimedia is missing,
install the two packages with Omarchy's package manager before enabling.

## Use

- Hover the center of the bar to reveal Murmur's paused, dimmed wave icon
  before the clock. While playing, it stays visible in the normal theme color,
  like Omarchy's status indicators. An open panel keeps its icon visible.
- Click the wave icon to open the panel. Click again, click
  outside, or press Escape to close it. Closing does not stop the sounds.
- **Play / Pause** controls the whole mix. A channel at zero is off. With every
  channel off, Play is disabled until you raise one.
- **Master** changes only Murmur. The operating system volume remains separate.
- **Randomize** shows On / Off; only On has a filled background. Hover and
  keyboard focus use an outline. Drift runs during playback. Each active
  sound drifts within ±25% of its chosen volume over independent 15–30 second
  transitions. Zero-volume sounds stay off.
- Sliders follow the audible mix. Dragging one sets a new base volume and
  temporarily holds that channel. Turning Randomize off gently returns the
  mix to the chosen base volumes.
- Tab / Shift+Tab move through controls. Arrow keys adjust the focused slider;
  Home / End set zero / full volume. Space or Enter activates a focused button.
  Clicking a slider focuses it; its mouse wheel then adjusts that slider.

The first mix has rain at 40%, master at 50%, and Randomize off. Preferences are
stored in Murmur's own bar entry in `~/.config/omarchy/shell.json`. Restarting
the shell/session restores the mix **paused**. Random movement is not written
to disk. Pause stops all voices. Play restarts the recordings from the beginning,
keeping your volumes and Randomize setting. Removing the bar entry through disable/remove may discard its settings,
as with other Omarchy inline widget preferences.

The shared service owns the live mix. Changes are saved after you finish an
interaction; delayed file notifications cannot rewind it. If you edit Murmur's
settings in `shell.json` by hand, reload the shell to apply them.

One shared audio service serves all bar instances. Qt mixes all active sounds
into a single system audio stream. Audio follows the system's
default output, including changes between headphones and speakers. Sounds are
calibrated with fixed headroom so all ten can play together without clipping.

If Play is active but silent, check both the selected output and the
**Quickshell application volume** in Omarchy's audio panel. The system remembers
that application volume separately from Murmur's master and channel sliders.

## Update and remove

```sh
omarchy plugin update nachfq.murmur
omarchy plugin disable nachfq.murmur
omarchy plugin remove nachfq.murmur
```

Disabling or removing Murmur stops its audio. Code reloads also start paused.
Murmur does not install services, modify system files, or leave audio processes
running. A channel whose recording cannot load shows “Audio unavailable”; the
remaining channels still work. Reinstall the plugin to restore a damaged file.

## Development

Keep changes small and submit PRs; the maintainer reviews and merges them.
See [AGENTS.md](AGENTS.md) for contributor instructions.

```sh
python scripts/check_assets.py        # Python + ffmpeg
node --test tests/model.test.cjs       # Node 22+
omarchy plugin validate .
scripts/check_qml.sh                  # Qt tools + installed Omarchy shell
python scripts/test_ui.py             # Native mouse/keyboard gestures, offscreen
QT_SCALE_FACTOR=1.5 python scripts/test_ui.py
scripts/with_test_audio.sh scripts/test_service.sh
scripts/with_test_audio.sh python3 scripts/test_output.py  # One stream + output changes
scripts/with_test_audio.sh scripts/test_loops.sh           # ~70s loop capture
```

The audio test wrapper starts an isolated PipeWire/WirePlumber server with
hardware discovery disabled. Device changes affect only that private server;
your desktop output stays unchanged. Test tools require `pipewire-pulse`,
`wireplumber`, `pactl`, and ffmpeg. CI runs the same model, asset, QML and playback
checks. [Validation notes](docs/VALIDATION.md) distinguish automated evidence
from desktop checks. Audio regeneration is documented in
[SOUNDS_LICENSES.md](SOUNDS_LICENSES.md).

## License and credits

Code: [MIT](LICENSE). Audio: [individual licenses and credits](SOUNDS_LICENSES.md),
with exact sources and checksums. Assets occupy approximately 36.0 MiB (uncompressed WAV for Qt’s shared mixer).

Inspired by [A Soft Murmur](https://asoftmurmur.com/); independently implemented
and not affiliated with its author. No files are extracted from that website.
Thanks to the recording authors, Blanket's contributors, and Omarchy.

## Support

Murmur is free. Bug reports and small improvements are welcome. A donation
link may be added to this repository later; all features will remain free.
