# Sound licenses

Code is MIT; each recording retains the license below. No audio is downloaded
from A Soft Murmur. Yuragi prepares independently sourced recordings.

## Sources and attribution

| File | Creator | Source | License | Prior edits |
| --- | --- | --- | --- | --- |
| `assets/rain.wav` | MikeNavajas | [Rain](https://freesound.org/people/MikeNavajas/sounds/681490/) | [CC0-1.0](https://creativecommons.org/publicdomain/zero/1.0/) | None |
| `assets/thunder.wav` | Sclolex | [Thunder](https://freesound.org/people/Sclolex/sounds/172883/) | [CC0-1.0](https://creativecommons.org/publicdomain/zero/1.0/) | None |
| `assets/waves.wav` | esh9419; subtyrant; indieground | [Waves](https://freesound.org/people/esh9419/sounds/417797/) | [CC0-1.0](https://creativecommons.org/publicdomain/zero/1.0/) | esh9419 composite of subtyrant https://freesound.org/people/subtyrant/sounds/132079/ and indieground https://freesound.org/people/indieground/sounds/322139/ (both CC0) |
| `assets/wind.wav` | UnderlinedDesigns | [Wind](https://freesound.org/people/UnderlinedDesigns/sounds/172666/) | [CC0-1.0](https://creativecommons.org/publicdomain/zero/1.0/) | None |
| `assets/fire.wav` | courter | [Fire](https://freesound.org/people/courter/sounds/447818/) | [CC0-1.0](https://creativecommons.org/publicdomain/zero/1.0/) | None |
| `assets/birds.wav` | BurghRecords | [Birds](https://freesound.org/people/BurghRecords/sounds/490846/) | [CC0-1.0](https://creativecommons.org/publicdomain/zero/1.0/) | None |
| `assets/crickets.wav` | Lisa Redfern | [Crickets](https://soundbible.com/2083-Crickets-Chirping-At-Night.html) | [Public Domain](https://soundbible.com/2083-Crickets-Chirping-At-Night.html) | None |
| `assets/coffee.wav` | waweee | [Coffee shop](https://freesound.org/people/waweee/sounds/370973/) | [CC0-1.0](https://creativecommons.org/publicdomain/zero/1.0/) | None |
| `assets/bowl.wav` | Coleco | [Singing bowl](https://freesound.org/people/Coleco/sounds/59152/) | [CC0-1.0](https://creativecommons.org/publicdomain/zero/1.0/) | None |
| `assets/noise.wav` | Nacho fq | [White noise](scripts/prepare_audio.py) | [CC0-1.0](https://creativecommons.org/publicdomain/zero/1.0/) | None |

Source pages checked on 2026-09-15. The eight selected Freesound recordings
identify CC0, including both originals used by esh9419:
[subtyrant](https://freesound.org/people/subtyrant/sounds/132079/) and
[indieground](https://freesound.org/people/indieground/sounds/322139/).
Credit to all three authors is retained. Public Domain denotes the dedication
on the linked SoundBible page. Neither creators nor projects endorse Yuragi.

Rain, thunder, waves, wind, birds, coffee and bowl use the original WAVs
downloaded by the maintainer, not the compressed previews. Fire uses courter’s
original 256 kbps MP3; converting it to WAV does not restore lost information.

The unchanged cricket input comes from [Blanket at commit
`9d229d2be7cb6619135d55ff9e49926e40298686`](https://github.com/rafaelmardojai/blanket/blob/9d229d2be7cb6619135d55ff9e49926e40298686/SOUNDS_LICENSING.md),
which licenses sounds separately from its application code. No Blanket code
is included. White noise is generated locally with a fixed seed and dedicated
to CC0. The shipped cricket and white-noise files are unchanged.

## Yuragi modifications

Recordings are downmixed/resampled to mono 48 kHz, cropped from the beginning,
given a wrap crossfade, calibrated with the existing fixed per-track peak/RMS
budgets and encoded as 16-bit PCM WAV. This preserves the common PCM format
required by the single native Qt output. No noise gate or timing compression
is applied to thunder; its quiet background and decay remain in the crop.

| Channel | Final loop | Wrap overlap |
| --- | ---: | ---: |
| Rain | 60 s | 1 s |
| Thunder | 120 s | 1 s |
| Waves | 60 s | 2 s |
| Wind | 45 s | 2 s |
| Fire | 60 s | 1 s |
| Birds | 60 s | 1 s |
| Coffee shop | 55 s | 1 s |
| Singing bowl | 40 s | 2 s |
| Crickets | 49.07 s (unchanged) | 0.25 s |
| White noise | 29.75 s (unchanged) | 0.25 s |

The ten WAVs total **52.99 MiB (55.57 MB)**. Only the prepared crops are shipped;
the 425.25 MiB of downloaded originals remain outside the repository.

Exact original filenames, download URLs, input SHA-256 and shipped SHA-256
are recorded in [assets/sources.json](assets/sources.json).

## Verification and regeneration

```sh
python scripts/check_assets.py
python scripts/prepare_audio.py
```

Preparation is a maintainer operation requiring Python 3 and ffmpeg; it never
runs inside the plugin. Freesound original downloads require login: download
each original using the linked source page and cache it as `.cache/audio/<id>`
(for example, `.cache/audio/rain`). The catalog pins each input checksum.
Do not substitute a preview for a selected lossless original.

`--only rain thunder` prepares just those IDs and leaves other WAVs untouched.
Optional `crop_seconds` and `crossfade_seconds` control each recording; defaults
remain 60 and 0.25 seconds. Crops start at zero. Overlapping the ends reduces
the final length by the overlap, capped at one quarter of a short input.

Encoder versions can change output bytes. Use `--record` only for an intentional,
reviewed update of catalog hashes. Cached originals are not shipped.

## Reference site

[A Soft Murmur terms](https://asoftmurmur.com/docs/terms-of-use.html) reserve
rights to site materials; its [credits](https://asoftmurmur.com/about/) do not
grant a license to redistribute its mixes. Yuragi uses independently prepared
open recordings and original code, branding and interface.
