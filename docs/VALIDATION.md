# Validation record

Validated on 2026-09-15 with Omarchy package **4.0.3-1**, Quickshell **0.3.1-1**,
Qt **6.11.2**, and Qt's native PipeWire audio backend. The installed source `version` file still
said `4.0.0.alpha`; the package/runtime versions above identify the actual test
environment. CI also validates against the official Omarchy shell at commit
`6ea3215542fbb269dfe5c2be928e6144f9cb6466`.

## Automated evidence

| Check | Result |
| --- | --- |
| Asset checksums and attribution coverage | All 10 pass |
| PCM WAV format, duration and boundary discontinuities | All 10 pass |
| Sum of decoded individual peaks | 0.8049; below full scale with all channels at maximum |
| Deterministic mixer model | 9 tests, including one simulated hour of drift |
| Native slider gestures | 9 scenarios at scale 1 and 1.5, using actual Qt mouse/keyboard events and Omarchy drawing components |
| Native bar indicator | Hover reveal, click/reopen, playback opacity, stable anchor on Pause, reveal suppression, and vertical collapse at scale 1 and 1.5 |
| Qt service integration | 9 scenarios: ten players and pause/resume; persistence; random/mute and first-channel autoplay; error isolation; live edits; visible/audible drift; fade reversal and sample release; mute continuity; restoring settings without autoplay |
| Actual looping | Shared mixer plays through two boundaries during 64 seconds of playback |
| Recorded loop continuity | 61-second interval, longest near-silent run 0.08 ms, no clipping |
| Native stream count and recorded output | One stream with ten sounds, drift, one sound, pause/resume, and default-output removal/switch |
| Playback fades | Captured noise ramps up/down before silence; rapid reversal and sample release checked against real SoundEffect state |
| Manifest validation and QML analysis | Pass, no lint warnings |

The test wrapper starts a private native PipeWire/WirePlumber server with
hardware discovery disabled. Service and loop tests select a temporary output;
the output test exercises the real default-device binding and changes/removes
only its private server's devices. No desktop defaults are changed. Capture
confirms nonzero signal during playback and silence while paused. Loop capture
excludes startup/shutdown silence and includes both 29.75-second boundaries.

The continuity recording tests the playback mechanism with continuous noise.
The remaining files pass decoded boundary checks; this does not replace human
listening to every recording or guarantee every audio backend is gapless.

## Desktop checks

### Playback fades

Each voice fades over 600 ms after its sample becomes ready. Pause stops the
voice only after its envelope reaches zero; reversing a pending fade starts
from its current gain. The envelope is separate from user volumes, so
master/channel preferences and sliders never move as a side effect. After the
fade, normal volume changes use Qt's native 100 ms interpolation.

`test_fades.py` records native output with the shipped noise sample. RMS over
50 ms windows rises/falls gradually (0.40/0.45 s between 2% and 90% of plateau)
and is silent after pause. These thresholds exclude the quiet ends of the
600 ms curve. The service test also exercises quick Play/Pause reversal,
cancellation while loading, and unloaded sources after fade-out. Recorded
output-routing and two-loop-boundary tests still pass.

### Yuragi naming and footer

The installed plugin was moved to `nachfq.yuragi` and its inline bar ID was
updated with the same saved settings and position. Comparing the configuration
before and after confirmed that only the ID changed. A full shell restart
loaded the new service and panel; a desktop capture confirmed the Japanese
footer `ゆらぎ · by nachfq for everyone` and GitHub icon. `preview.png` is a
crop of that live panel. Native service/output tests and gesture tests at
scale 1 and 1.5 also passed with the renamed ID.

### Native UI polish

Removed Yuragi's added slider focus rectangle. Input still belongs to Qt's
standard Slider. Birds, singing bowl and white noise now use Nerd Fonts'
Material Design `bird`, `bowl-outline` and `waveform` glyphs; checked their
rendering in the installed JetBrainsMono Nerd Font.

The bar uses Omarchy's `BarIndicator` and public `centerSectionRevealHeld` /
`centerHoverRevealSuppressed` state. Paused icons collapse until center hover;
playing icons use the native full-opacity theme foreground. An open panel
keeps its anchor visible. Positioning uses `omarchy bar move --before`, without
modifying the built-in indicators list or packaged shell files.

The offscreen gesture suite also clicks the actual bar indicator through
reveal/open/pause/close/reopen. This scenario uses a panel lifecycle stub:
offscreen Quickshell has no layer-shell backend, so it does not test popup
rendering or the compositor's physical hover detection.

Follow-up desktop verification found that file-watch reload logs did not prove
all dependent QML/JavaScript had refreshed: the user still saw old icons and
the slider focus rectangle. After `omarchy restart shell`, a capture of the
actual panel confirmed all three new glyphs and no added slider rectangle.
The saved configuration was unchanged by the restart. The indicator remains
a separate bar entry: the installed built-in group resolves only its own
`../indicators/<name>.qml` files, without an external plugin registration API.

### Slider gesture regressions

An offscreen Quickshell window reproduces two failures from the previous
version with Randomize off: canceling a drag left `dragging` true, and replaying
an older settings response reset an ongoing 85% edit to 30% and cleared its
held state. Earlier tests inspected values and audio without driving real
pointer sequences, so they did not cover these failures.

`VolumeControl` now delegates input to Qt Quick Controls' standard `Slider`
while using the installed Omarchy `PanelSlider` for drawing only. The new input
path handles cancellation, pointer ownership and click-to-focus. Pointer
movement is continuous; keyboard and focused-wheel adjustments use 2% steps.
The service initializes preferences once, owns subsequent live state, and
debounces writes after interactions. File notifications update preserved
metadata without replacing the live mix; manual preference edits apply on
shell reload.

Eight tests cover every channel, crossing another slider while dragging,
cancellation followed by hover, scroll interruption, stale settings during
and after an edit, no writes during master/channel drags, keyboard/wheel focus,
and Randomize while holding a slider. Both scale 1 and 1.5 pass. These tests
use real controls in an offscreen window; they do not claim exhaustive testing
of every physical mouse, touchpad, or Wayland popup interaction.

### Feedback regression checks

The first integration tests read channel objects directly and missed stale
delegate bindings. Added tests reproduce the real binding chain (channel
object → displayed value) and inspect the native audio output while playing.
Before the fix, editing 40% to 80% left the bound value at 40%, and Randomize
failed to change the bound value. Both regressions now pass. Changed channels
get new object identities so QML updates the sliders and audio gains.

Live inspection also found orphaned output connections and a persisted
WirePlumber application volume of zero for `media.name:quickshell`. Reloading
the shell cleared the old connections; restoring that application volume
produced nonzero audio on the Speaker monitor (3-second capture: peak 0.0700,
RMS 0.0115). This was a local audio setting repair, not a runtime override of
the user's system volume. The plugin's Qt output selection remains unchanged.
A separate two-sink capture confirmed audio after removal of the first sink
and explicit selection of the second. Bluetooth reconnection remains untested.

The live panel shows `Randomize: On` / `Randomize: Off`; hover and focus retain
native outlines without borrowing the selected background fill.

### Initial desktop checks

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

## Shared mixer and resource sample

Qt 6.11's native PipeWire `SoundEffect` implementation shares an audio engine
for effects with the same output device and PCM format. The ten files are now
mono 48 kHz, 16-bit PCM WAV. This uses Qt's existing mixer without a helper
process, custom native module, or extra runtime package. Older Qt versions and
other audio backends are outside this single-stream compatibility target.

The maintainer chose restart-on-resume: Pause stops each voice and Play starts
the recordings from the beginning. Volumes and Randomize preferences persist.
Muting a channel also stops its voice. Disabled/removed plugin objects release
the shared stream. A paused, loaded mixer may retain one silent stream.

The native output test recorded exactly one stream in all six phases, including
ten simultaneous voices, Randomize, and removal of the previous default sink.
Three hundred milliseconds of recorded output in each playing phase had a
nonzero peak below full scale; the paused capture was silent.

An isolated Qt process measured `/proc` CPU and resident memory with all ten
channels at 50%, master at 50%, and Randomize on. This short local sample
includes the Qt test process; it is not a cross-machine performance guarantee.

| Phase | CPU, percent of one core | Process RSS |
| --- | ---: | ---: |
| Before playback, 3 seconds | 0.00% | 93.33 MiB |
| Ten channels with drift, 5 seconds | 1.00% | 169.93 MiB |
| Paused, 3 seconds | 0.67% | 169.93 MiB |

The shared mixer caches decoded samples, trading more memory/disk space for
lower playback CPU and one output. Shipped WAV files occupy 35.96 MiB; the
previous Ogg assets occupied 3.61 MiB. The earlier MediaPlayer implementation
sampled about 12% of one core with ten channels, but these are short samples
rather than a controlled benchmark. The random timer stops while paused.

Run the commands in the README to reproduce the functional checks. Full CI
logs are available in the repository's Actions tab and attached to each PR.

## Muting a channel must not interrupt the remaining mix

A captured ascending reference tone confirmed the reported interruption when a
second channel was set to zero: the reference kept its timeline but disappeared
briefly. Qt's `playing` flags stayed true, so the earlier state-only tests missed
this. Qt 6.11.2's [QSoundEffectVoice::playVoice](https://github.com/qt/qtmultimedia/blob/v6.11.2/src/multimedia/audio/qsoundeffectwithplayer.cpp)
uses `fill_n` on the shared output buffer for zero-volume/muted voices, erasing
contributions already mixed by other voices. Yuragi's 600 ms fade-out could leave
such a voice present after its channel level had reached zero.

AudioChannel now uses a `1e-9` (-180 dB) internal gain floor, avoiding that Qt
branch while the voice is still active. This is far below PCM16 resolution;
it does not alter slider values or saved settings. Muted channels still stop
and release their samples after the fade, and whole-mix Pause still unloads all
voices. No packaged Qt or Omarchy files are changed.

`scripts/test_mute.py` records the real service with a generated rising tone and
a second voice that is muted, re-enabled and muted again. It checks both the
absence of silent gaps over 20 ms and the tone's continued time progression.
The same test rejected the pre-fix baseline with a **593 ms** interruption.
The corrected local capture had a longest near-silent run of **0.02 ms**.
The test runs on the private PipeWire server in CI, alongside fade, routing and
loop captures. A service regression also watches the untouched player's state
and gain, distinguishing a timeline restart from an output interruption.

Bringing all channels to zero pauses playback and unloads their samples.
An explicit slider edit that raises the first channel from an all-zero mix
starts playback automatically. Editing a manually paused, nonempty mix keeps
it paused, as does restoring saved settings. Service tests cover those cases;
native slider tests reach zero with Home and raise a channel with an arrow key
at scales 1 and 1.5. Play remains disabled while all channels are zero.
