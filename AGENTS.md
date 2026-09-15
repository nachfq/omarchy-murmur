# Working on Murmur

Keep this plugin small: QML, Qt Multimedia, and the existing Omarchy shell UI.
No extra runtime processes, network requests, installers, or package managers.
Never edit packaged Omarchy files. Follow the installed shell contract.

- Human merges only. Work in focused branches and open reviewable PRs.
- Preserve the shared service: audio must not belong to a panel or monitor.
- Persist user choices only, never random animation frames or playback state.
- Every audio asset needs a source, exact license, attribution, and checksum.
- Keep all sounds mono 48 kHz PCM16 WAV. Qt 6.11's native PipeWire backend
  shares one SoundEffect mixer only when device and PCM formats match.
- Run `python scripts/check_assets.py` and, when present,
  `node --test tests/model.test.cjs` and `scripts/check_qml.sh`.
- For audio changes, run the service, output-count, and loop tests through
  `scripts/with_test_audio.sh`. Never change desktop defaults for a test.
- For control changes, run `python scripts/test_ui.py` at scale 1 and 1.5.
  Test actual pointer/keyboard events, not just assignments to model values.
- Include actual validation evidence in PRs. Do not claim listening, graphical,
  multi-monitor, or device tests that were not performed.
- Keep the UI in English. Donations belong on GitHub, not in the panel.
