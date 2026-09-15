[← Yuragi](../README.md) · [Documentation](README.md)

# Audio formats and longer loops

Research dated 2026-09-15. Production audio is unchanged. The question is how
to extend recordings while keeping a small download, bounded memory use,
independent controls and a single application output.

## What compression saves

Re-encoded all ten shipped mono 48 kHz recordings with FFmpeg 9.0.1. These are
actual file sizes for the same durations, not estimates for new recordings.

| Format | Total asset size | Reduction from WAV |
| --- | ---: | ---: |
| PCM16 WAV, current | 35.96 MiB | — |
| FLAC, lossless, compression level 8 | 14.80 MiB | 59% |
| Opus, 64 kb/s target, VBR | 2.84 MiB | 92% |
| Opus, 96 kb/s target, VBR | 4.31 MiB | 88% |

[Measurements, source durations and input hashes](audio-compression.json).
Reproduce a candidate outside the shipped asset directory:

```sh
ffmpeg -i assets/rain.wav -map_metadata -1 -c:a libopus -b:a 96k \
  -vbr on -application audio /tmp/yuragi-rain.opus
# Compare with -b:a 64k, or -c:a flac -compression_level 8.
```

Compression reduces stored bytes. It does not reduce the memory occupied by
the same fully decoded PCM samples. To keep memory from growing with recording
length, a player must decode small blocks as needed, with bounded queues.

For scale, ten three-minute mono recordings at a nominal 96 kb/s total about
20.6 MiB before container overhead and VBR variation. The same recordings
occupy about 164.8 MiB as PCM16, or 329.6 MiB as float32, before any extra buffers.
These are arithmetic projections, not measured production memory or quality.

## Why replacing WAV files is insufficient

Yuragi uses Qt's `SoundEffect` and the native PipeWire shared mixer.
[Qt documents SoundEffect for uncompressed audio](https://doc.qt.io/qt-6/qsoundeffect.html).
The current engine loads samples ahead of playback. Shipping Opus or FLAC and
expanding it back into WAV/PCM would retain that memory cost and add loading
work or a disk cache. It would not solve longer recordings in RAM.

`MediaPlayer` supports compressed media, but sharing one `AudioOutput` object
between players does not mix their audio: attaching it to another player
disconnects its previous owner. This follows Qt 6.11.2's
[`QMediaPlayer::setAudioOutput`](https://github.com/qt/qtmultimedia/blob/v6.11.2/src/multimedia/playback/qmediaplayer.cpp)
and [`QAudioOutput::setDisconnectFunction`](https://github.com/qt/qtmultimedia/blob/v6.11.2/src/multimedia/audio/qaudiooutput.cpp).

An isolated Quickshell probe on the same machine used ten `MediaPlayer`
instances, each playing an Opus 64 kb/s file into its own `AudioOutput`, on a
private PipeWire null sink. All ten reported playback and advancing positions;
`pactl` reported **ten output streams**. After five seconds of warmup, one
15-second sample reported approximately **120 MiB RSS, 76.6 MiB PSS and 10.1%
of one logical core**. This is an exploratory prototype, without the Yuragi
panel, controls or drift; normal desktop activity continued and routine checks
ran during the experiment. It is not a controlled comparison with
[production measurements](PERFORMANCE.md), nor a prediction for a custom mixer.
No listening or compressed-loop continuity test was performed.

## Options and implementation cost

| Approach | Memory with longer recordings | One output | Work and tradeoff |
| --- | --- | --- | --- |
| Longer WAVs with the current engine | Grows with total loaded duration | Yes | Small code change; increases disk and RAM |
| Compressed assets expanded in full | Still grows with decoded duration | Yes | Adds decoding/cache management; mostly saves stored assets |
| One MediaPlayer per sound | Can decode incrementally | No, as tested | Small QML change, but restores the unwanted output list |
| Bounded decoding plus a shared native mixer | Can remain bounded by queue size | Yes, by design | Substantial implementation and packaging work; needs a prototype |

The last option can preserve the existing QML panel, volume model, persistence
and Randomize. Audio decoding would run away from the UI thread; a native mixer
would apply the gains and feed one output. Qt provides
[`QAudioSink`](https://doc.qt.io/qt-6/qaudiosink.html), including a callback API
in 6.11. Its audio callback must not perform blocking file reads, decoding,
allocations or other work that could stall playback. A bounded decoder queue,
loop prefetch and a carefully prepared seam/crossfade would be needed.

This is achievable, but is an audio-engine change rather than a codec setting.
A compiled QML module would add binaries and Qt/architecture compatibility
maintenance. A helper process is another design, but adds a process and a
control protocol. Both expand the current QML-only, no-extra-process contract
in [AGENTS.md](../AGENTS.md); neither has been added to Yuragi.

## Longer recordings need longer sources

The cached licensed inputs already contain approximately 130 seconds of birds,
125 seconds of rain, 118 seconds of waves and 555 seconds of thunder. Yuragi
currently trims these to a maximum of 60 seconds before preparing the loop.

Other inputs are already short: wind 14.8 seconds, coffee shop 16.7, singing
bowl 18.9, fire 25.5 and crickets 49.3. Those need longer licensed recordings
or a deliberate variation design. Repeating a short file into a longer file
does not add variety. White noise can be generated for any duration; generating
it during playback would belong to a future native engine.

## Sound quality and compatibility

[Opus](https://opus-codec.org/) is an open audio codec with mono and stereo
support, intended for both speech and music. It is a reasonable candidate for
this research, not a promise that 64 kb/s is transparent for every recording.
Start comparisons at 96 kb/s mono, particularly for birds, crickets, rain and
noise; retain FLAC where lossless playback is worth the space. Encode from the
best licensed source available instead of repeatedly transcoding lossy copies.
Changing formats must preserve attribution and update checksums; lossy output
also needs fresh headroom/clipping checks.

There is no inherent dependency on this particular PC or sound card. Audio
codecs can run in software, and Qt's FFmpeg backend supports compressed playback.
However, [Qt notes that codec availability and behavior depend on the backend
and platform](https://doc.qt.io/qt-6/qtmultimedia-index.html#target-platform-and-backend-notes).
The current supported target remains Omarchy 4 / Qt 6.11+ / native PipeWire;
Omarchy 3/Waybar is not covered. A native extension would additionally need to
support the Qt versions and architectures we distribute for.

Before shipping a replacement engine, validate ten simultaneous streams through
one output, long-run memory bounds, gaps at wraparound, clipping, rapid fades,
responsive sliders, output hotplug and pause cleanup. Test on more than one
Omarchy machine, including a slower CPU, with speakers and headphones/Bluetooth.
The existing CI runs in a separate Arch environment with virtual audio; it does
not replace physical-device or listening checks.

## Recommendation

Keep the working engine for the initial release. For longer loops, evaluate
Opus around 96 kb/s with bounded decoding and one native output in a separate
prototype. Gate adoption on measured memory/CPU and the existing interaction
and audio tests, plus listening and additional-machine checks. A plain switch
to ten MediaPlayers fails the already-established single-output requirement.

One distribution detail also matters: the installed Omarchy 4.0.3
`omarchy plugin add` uses a full `git clone`, so old WAV blobs remain part of
repository history even if a future commit replaces them. The table above
measures assets, not clone size. Rewriting public history is not part of this
change; distribution size needs its own plan if the format changes.
