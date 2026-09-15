# Validation record

Validated on 2026-09-15 with Omarchy package **4.0.3-1**, Quickshell **0.3.1-1**,
Qt **6.11.2**, and Qt's FFmpeg backend. The installed source `version` file still
said `4.0.0.alpha`; the package/runtime versions above identify the actual test
environment. CI also validates against the official Omarchy shell at commit
`6ea3215542fbb269dfe5c2be928e6144f9cb6466`.

## Automated evidence

| Check | Result |
| --- | --- |
| Asset checksums and attribution coverage | All 10 pass |
| Ogg decoding, duration and boundary discontinuities | All 10 pass |
| Sum of decoded individual peaks | 0.8225; below full scale with all channels at maximum |
| Deterministic mixer model | 9 tests, including one simulated hour of drift |
| Qt service integration | 4 scenarios: ten players and pause/resume; persistence; random/mute; error isolation |
| Actual looping | Qt player crosses two boundaries during 64 seconds of playback |
| Recorded loop continuity | 61-second interval, longest near-silent run 0.04 ms, no clipping |
| Manifest validation and QML analysis | Pass, no lint warnings |

Integration tests explicitly route players to a temporary test device. Setting
`PULSE_SINK` alone did not select Qt's device in this environment, so the tests
choose the device via Qt Multimedia. Neither the tests nor the plugin change
the user's default audio output. Loop capture excludes startup and shutdown
silence and includes both 29.75-second white-noise boundaries.

The continuity recording tests the playback mechanism with continuous noise.
The remaining files pass decoded boundary checks; this does not replace human
listening to every recording or guarantee every audio backend is gapless.

## Desktop checks

- Installed and enabled using Omarchy's plugin discovery, with the icon placed
  immediately after the clock and existing widget order preserved.
- Opened and closed the native panel through shell IPC; observed Play/Pause
  changing in the live panel, and persisted master changes in the plugin entry.
- Captured `preview.png` from the actual panel, using the existing desktop theme.
- Confirmed bar rendering on a temporary second headless 1920×1080 output at
  scale 1, then removed that output. The primary display retained focus.
- Reloaded the plugin, retaining preferences and returning to paused playback.
- The shared-service design creates audio outside the per-monitor widget;
  unit tests exercise the single service independently of any panel.

Fractional scaling, extended Bluetooth reconnection scenarios, other themes,
replacement bars, and long-duration soak testing were not exhaustively tested.
Runtime compatibility targets Omarchy's built-in bar and shared service API.

## Resource sample and pause fix

An isolated Qt test process sampled `/proc` CPU time and resident memory around
three phases. It selected ten channels at 50%, master at 50%, with Randomize
enabled. Values include the Qt test process, not just the plugin; this is a
short local sample, not a cross-machine performance guarantee.

| Phase | CPU, percent of one core | Process RSS |
| --- | ---: | ---: |
| Before playback, 3 seconds | 0.33% | 113.26 MiB |
| Ten channels with drift, 5 seconds | 12.00% | 129.13 MiB |
| Paused, 3 seconds | 0.33% | 109.91 MiB |

Using `MediaPlayer.pause()` initially retained approximately 13.6% of one CPU
core, including after settling. Murmur now stores playback position and calls
`stop()` to release decoders, then seeks back when Play is pressed. The test
suite asserts stopped native players, remembered position and successful resume.
The random timer also stops while paused.

Run the commands in the README to reproduce the functional checks. Full CI
logs are available in the repository's Actions tab and attached to each PR.
