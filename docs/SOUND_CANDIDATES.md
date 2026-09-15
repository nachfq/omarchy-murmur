[← Yuragi](../README.md) · [Documentation](README.md)

# Sound candidates for listening

## Maintainer selections

Selected on 2026-09-15: **R-B, T-B, W-B, V-A, B-A, K-A, S-B and F-E**.
The maintainer supplied the seven original WAVs and courter's original MP3.
They are now prepared in `assets/`, with crops starting at zero. The existing
crickets remain byte-for-byte unchanged. Generated white noise keeps its source
and duration, with the approved loudness adjustment.

Final loop lengths: rain 60 s, thunder 120 s, waves 60 s, wind 45 s,
birds 60 s, coffee 55 s, bowl 40 s and fire 60 s. The complete catalog is
**52.99 MiB (55.57 MB)**, up from 35.96 MiB. The extra fire duration adds
3.18 MiB to the earlier 49.8 MiB proposal. The downloaded originals total
425.25 MiB and are not shipped. Keeping all five minutes of thunder instead
would add about 16.5 MiB to the current prepared catalog.

Wrap overlaps are 1–2 seconds; the input crop includes that overlap so the
final durations above are exact. See [credits and preparation](../SOUNDS_LICENSES.md)
for per-track settings and source/output checksums. CI checks exact crop
lengths and a 55 MiB audio budget, preventing accidental full-original imports.
The maintainer selected the sources and approved the local prepared loudness
trial. Seven channels now target −42 LUFS; thunder, fire and crickets are excluded.
See [preparation and calibration](../SOUNDS_LICENSES.md#loudness-calibration).

The two source recordings credited in W-B have now also been checked:
[subtyrant, Xerokambos beach](https://freesound.org/people/subtyrant/sounds/132079/)
and [indieground, Low tide](https://freesound.org/people/indieground/sounds/322139/)
both identify CC0. Preserve all three authors in the imported recording's credits.

### Fire alternatives (F-E selected)

All three pages identify CC0. Descriptions below are the authors' recording
notes, not our own listening assessment. F-C and F-D have lossless originals;
F-E's original is already MP3.

| ID | Listen | Source length | Character / original |
| --- | --- | --- | --- |
| F-C | [Fire crackling in fireplace — Davor](https://freesound.org/people/Davor/sounds/382616/) | 1:20 | Fireplace recorded with a Zoom H1; normalized, no EQ/effects. WAV, 48 kHz/24-bit stereo. |
| F-D | [Fireplace — BonnyOrbit](https://freesound.org/people/BonnyOrbit/sounds/484337/) | 2:04 | Burning logs and flames in an old building, Zoom H6. WAV, 48 kHz/24-bit stereo. |
| F-E | [Crackeling Fireplace — courter](https://freesound.org/people/courter/sounds/447818/) | 6:43 | Wet pine chosen for frequent pops, Zoom H4n Pro. MP3, 44.1 kHz/256 kbps stereo. |

### Thunder background

Replacing low-level samples with zeros does **not** reduce PCM WAV size or
SoundEffect's decoded buffer size: every second still stores 48,000 samples.
It can improve compression in a future compressed distribution, but that is
separate from the current playback format. Removing time would reduce size,
but would also move thunderclaps closer together.

If background cleanup is desirable, use a slowly changing level envelope
(a noise gate with attack/release), not a per-sample threshold: cutting each
waveform's quiet samples creates distortion. The imported thunder keeps its
background and decay intact. A gate is not applied merely to turn quiet
sections into zeros, because that would not save
PCM storage or sample RAM; any later cleanup needs a listening comparison.

## Original shortlist

Shortlist checked on 2026-09-15. The selections above are now prepared assets;
other entries remain listening candidates.
All twenty linked sound pages identify CC0. Names, durations, formats and notes
come from the authors' pages; this is not a claim that we listened to or approved
the recordings. Listen using each source page's player and choose A or B per row.
Freesound requires login for original downloads; its previews are compressed
and should not be used to judge the final file's fidelity or loop seam.

## Two options per sound

Durations below describe the **source**, not a proposed shipped loop. The source
can be several minutes long while we ship a selected 45–90 second passage.

| Sound | A | B |
| --- | --- | --- |
| Rain | [R-A: Gentle Rain on Leaves — Garuda1982](https://freesound.org/people/Garuda1982/sounds/757276/) · 19:01 · WAV, 48 kHz/24-bit stereo. Leaves, breeze and suburban surroundings; Sony M10 + Clippy EM272. | [R-B: Rain / Lluvia — MikeNavajas](https://freesound.org/people/MikeNavajas/sounds/681490/) · 3:13 · WAV, 44.1 kHz/24-bit stereo. Heavy rain. |
| Thunder | [T-A: thunder — Andy_Gardner](https://freesound.org/people/Andy_Gardner/sounds/238145/) · 2:21 · WAV, 96 kHz/16-bit mono. Storm recorded at a window with Tascam DR-05. | [T-B: ThunderInTuscany — Sclolex](https://freesound.org/people/Sclolex/sounds/172883/) · 5:01 · WAV, 48 kHz/16-bit stereo. Passing summer storm, Microtrack II. |
| Waves | [W-A: Ocean Waves — MamickaBeeGames](https://freesound.org/people/MamickaBeeGames/sounds/803330/) · 15:00 · WAV, 44.1 kHz/16-bit stereo. Beach and breaking waves. | [W-B: Gentle Ocean Waves Mix — esh9419](https://freesound.org/people/esh9419/sounds/417797/) · 12:00 · WAV, 48 kHz/16-bit stereo. Gentle waves and breeze; composite of two credited CC0 recordings.* |
| Wind | [V-A: Ambient Wind, Real Wind — UnderlinedDesigns](https://freesound.org/people/UnderlinedDesigns/sounds/172666/) · 10:21 · WAV, 44.1 kHz/16-bit stereo. Actual wind through trees, Zoom H4n. | [V-B: Wind ambience — haniebal](https://freesound.org/people/haniebal/sounds/423314/) · 2:57 · WAV, 44.1 kHz/16-bit mono. Designed in Audacity; compare its uniform texture with the field recording. |
| Fire | [F-A: Campfire, Position 1 — SKrafft](https://freesound.org/people/SKrafft/sounds/681366/) · 1:24 · WAV, 48 kHz/24-bit stereo. Quiet nighttime setting, Sony PCM-D100. | [F-B: Fireplace starting up — Sadiquecat](https://freesound.org/people/Sadiquecat/sounds/802208/) · 9:32 · FLAC, 96 kHz/24-bit mono. Fire building from embers, FR-AV2 + Rode NT5; select a stable passage. |
| Birds | [B-A: Birds In Forest, Scotland — BurghRecords](https://freesound.org/people/BurghRecords/sounds/490846/) · 1:53 · WAV, 44.1 kHz/16-bit stereo. Calls with wind in trees. | [B-B: Forest Birds — NightVoice](https://freesound.org/people/NightVoice/sounds/123999/) · 1:20 · WAV, 48 kHz/32-bit stereo. Spring birds in a Finnish forest. |
| Crickets | [C-A: Night Crickets, Rural Property — OwlStorm](https://freesound.org/people/OwlStorm/sounds/320145/) · 1:23 · WAV, 44.1 kHz/16-bit stereo. Australian crickets and other insects, Zoom H4n. | [C-B: Crickets at night in a forest — LukaCafuka](https://freesound.org/people/LukaCafuka/sounds/750874/) · 3:10 · WAV, 96 kHz/24-bit stereo. Forest insects; faint sheep bells need checking when choosing a passage. |
| Coffee shop | [K-A: coffee shop ambience — waweee](https://freesound.org/people/waweee/sounds/370973/) · 4:56 · WAV, 48 kHz/24-bit mono. Czech cafeteria, Sound Devices 633 + Sennheiser ME66. | [K-B: Cofee shop Ambience — aidansamuel](https://freesound.org/people/aidansamuel/sounds/540299/) · 2:17 · WAV, 48 kHz/24-bit stereo. Crowd, machines and light traffic, Zoom H6; author describes a loopable recording. |
| Singing bowl | [S-A: Singing Bowl, long without reverb — hollandm](https://freesound.org/people/hollandm/sounds/573805/) · 2:07 · WAV, 44.1 kHz/16-bit stereo. Sustained rim playing, AKG P220; EQ/compression. | [S-B: singingbowl1 — Coleco](https://freesound.org/people/Coleco/sounds/59152/) · 1:12 · WAV, 48 kHz/16-bit stereo. An alternative bowl recording; compare tone and decay. |
| White noise | [N-A: White Noise — ShawnyBoy](https://freesound.org/people/ShawnyBoy/sounds/165395/) · 1:30 · WAV, 44.1 kHz/16-bit mono. Plain white noise. | [N-B: NOISE-WHITE-10VU — mutantra](https://freesound.org/people/mutantra/sounds/571174/) · 1:04 · WAV, 48 kHz/24-bit stereo. Another white-noise reference. |

*W-B's two original source pages are verified above; retain their credits when
importing the composite. The selected files now have pinned original/output
checksums and mono loop/headroom validation; the prepared results still benefit
from listening.

White noise is already generated locally and dedicated to CC0. These two
options are listening references; a longer noise file is not automatically
higher quality or less recognizably repetitive. Keeping the local generator
avoids an unnecessary external asset if its sound is preferred.

Reply with IDs, for example `R-A, T-B, W-A, V-A, F-A, B-B, C-A, K-A, S-A`.
For any candidate, include a preferred timestamp or a reason to reject it
(traffic, voices too distinct, sharp crackles, etc.). “Keep current” is valid.

## Preparation rationale

The previous catalog was prepared from seven Vorbis files and two MP3 previews;
white noise is generated. Conversion to WAV does not recover information
already lost in those inputs. Mixing stereo down to mono reduces spatial width,
and its blanket 60-second trim and 250 ms seam treatment could make
recognizable events recur. Those are plausible contributors to the reported
quality; no listening assessment has yet isolated which matters most.

For chosen replacements, use the original WAV/FLAC rather than a preview,
select a passage without distracting foreground sounds, and choose matching
start/end textures before applying a short crossfade. Keep mono 48 kHz PCM16
so the same native Qt mixer still produces one system output. Higher source
bit depth is useful editing material, not proof of a better recording.

At this fixed output format, one minute costs **5.49 MiB**. Making every track
two minutes would cost about **110 MiB in assets**, plus decoded memory and
runtime overhead. A compressed source does not change the resulting WAV size.

The original proposal targeted 50 MiB. Including the selected fire recording
at 60 seconds results in 52.99 MiB; CI allows up to 55 MiB. Prefer a better seam
over more duration when memory cannot justify a longer recording.

See [resource measurements](PERFORMANCE.md) for actual active/paused RAM.
Asset RAM grows with loaded duration under SoundEffect; paused/muted channels
release their decoded samples. No playback-engine replacement is included.
