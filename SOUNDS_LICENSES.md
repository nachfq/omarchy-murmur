# Sound licenses

Code is MIT; each recording retains the license below. No audio is downloaded
from A Soft Murmur. Its credits helped identify original recordings, not a
redistribution license for its edited tracks.

## Sources and attribution

| File | Creator | Source | License | Prior edits |
| --- | --- | --- | --- | --- |
| `assets/rain.wav` | alex36917 | [Rain](https://freesound.org/people/alex36917/sounds/524605/) | [CC-BY-4.0](https://creativecommons.org/licenses/by/4.0/) | Porrumentzio (Blanket) |
| `assets/thunder.wav` | OroborosNZ | [Thunder](https://freesound.org/people/OroborosNZ/sounds/141251/) | [CC0-1.0](https://creativecommons.org/publicdomain/zero/1.0/) | None |
| `assets/waves.wav` | Luftrum | [Waves](https://freesound.org/people/Luftrum/sounds/48412/) | [CC-BY-4.0](https://creativecommons.org/licenses/by/4.0/) | Porrumentzio (Blanket) |
| `assets/wind.wav` | felix.blume | [Wind](https://freesound.org/people/felix.blume/sounds/217506/) | [CC0-1.0](https://creativecommons.org/publicdomain/zero/1.0/) | Porrumentzio (Blanket) |
| `assets/fire.wav` | ezwa | [Fire](https://soundbible.com/1543-Fireplace.html) | [Public Domain](https://soundbible.com/1543-Fireplace.html) | None |
| `assets/birds.wav` | kvgarlic | [Birds](https://freesound.org/people/kvgarlic/sounds/156826/) | [CC0-1.0](https://creativecommons.org/publicdomain/zero/1.0/) | Porrumentzio (Blanket) |
| `assets/crickets.wav` | Lisa Redfern | [Crickets](https://soundbible.com/2083-Crickets-Chirping-At-Night.html) | [Public Domain](https://soundbible.com/2083-Crickets-Chirping-At-Night.html) | None |
| `assets/coffee.wav` | stephan | [Coffee shop](https://soundbible.com/1664-Restaurant-Ambiance.html) | [Public Domain](https://soundbible.com/1664-Restaurant-Ambiance.html) | None |
| `assets/bowl.wav` | Monkay; qubodup | [Singing bowl](https://freesound.org/people/qubodup/sounds/169289/) | [CC0-1.0](https://creativecommons.org/publicdomain/zero/1.0/) | qubodup, from Monkay https://freesound.org/people/Monkay/sounds/48325/ (also CC0) |
| `assets/noise.wav` | Nacho fq | [White noise](scripts/prepare_audio.py) | [CC0-1.0](https://creativecommons.org/publicdomain/zero/1.0/) | None |

Source pages checked on 2026-09-15. The CC BY sources currently identify
Attribution 4.0. Public Domain denotes the dedication on the linked SoundBible
page. The original [Monkay recording](https://freesound.org/people/Monkay/sounds/48325/)
and the qubodup edit both identify CC0. Credit to both is retained.

Seven prepared inputs come from [Blanket at commit
`9d229d2be7cb6619135d55ff9e49926e40298686`](https://github.com/rafaelmardojai/blanket/blob/9d229d2be7cb6619135d55ff9e49926e40298686/SOUNDS_LICENSING.md),
which licenses its sounds separately from its application code. No Blanket
application code is included. Thunder and bowl use the high-quality previews
served by Freesound under the source recording licenses. White noise is
generated locally with a fixed seed; we dedicate that recording to CC0.

## Murmur modifications

All files are converted to 48 kHz mono, trimmed to at most 60 seconds, given
a 250 ms wrap crossfade, calibrated with a fixed per-track peak budget, and
encoded as mono 48 kHz, 16-bit PCM WAV. All tracks use the same PCM format
so Qt can mix them through one output. Prior edits by Porrumentzio and qubodup are
credited above. Neither creators nor projects endorse Murmur.

Exact download URLs, original-input SHA-256 and shipped-file SHA-256 are in
[assets/sources.json](assets/sources.json). To verify files:

```sh
python scripts/check_assets.py
```

To regenerate (maintainer operation; Python 3 and ffmpeg required):

```sh
python scripts/prepare_audio.py
```

Source checksums are enforced. Encoder versions can change output bytes;
use `--record` only for an intentional, reviewed update of the catalog hashes.
Cached source files live in `.cache/audio/` and are not shipped.

## Reference site

[A Soft Murmur terms](https://asoftmurmur.com/docs/terms-of-use.html) reserve
rights to site materials and restrict reuse; its
[credits](https://asoftmurmur.com/about/) do not grant a general license to
redistribute its mixes. Murmur uses independent preparation of openly licensed
sources and original code, branding and interface.
