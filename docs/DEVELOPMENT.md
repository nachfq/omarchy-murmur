[← Yuragi](../README.md) · [Documentation](README.md)

# Development

Keep changes small and submit PRs; the maintainer reviews and merges them.
Run the commands below from the repository root.
See [AGENTS.md](../AGENTS.md) for contributor instructions.

```sh
python scripts/check_assets.py        # Python + ffmpeg
node --test tests/model.test.cjs       # Node 22+
omarchy plugin validate .
scripts/check_qml.sh                  # Qt tools + installed Omarchy shell
python scripts/test_ui.py             # Native mouse/keyboard gestures, offscreen
QT_SCALE_FACTOR=1.5 python scripts/test_ui.py
scripts/with_test_audio.sh scripts/test_service.sh
scripts/with_test_audio.sh python3 scripts/test_fades.py   # Recorded fade envelope
scripts/with_test_audio.sh python3 scripts/test_mute.py    # Other voices stay continuous
scripts/with_test_audio.sh python3 scripts/test_output.py  # One stream + output changes
scripts/with_test_audio.sh scripts/test_loops.sh           # ~70s loop capture
scripts/with_test_audio.sh python3 scripts/measure_resources.py --output /tmp/yuragi-resources.json
```

The audio test wrapper starts an isolated PipeWire/WirePlumber server with
hardware discovery disabled. Device changes affect only that private server;
your desktop output stays unchanged. Test tools require `pipewire-pulse`,
`wireplumber`, `pactl`, and ffmpeg. CI runs the same model, asset, QML and playback
checks. [Validation notes](VALIDATION.md) distinguish automated evidence
from desktop checks. Audio regeneration is documented in
[SOUNDS_LICENSES.md](../SOUNDS_LICENSES.md).
