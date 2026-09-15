# Working on Murmur

Keep this plugin small: QML, Qt Multimedia, and the existing Omarchy shell UI.
No extra runtime processes, network requests, installers, or package managers.
Never edit packaged Omarchy files. Follow the installed shell contract.

- Human merges only. Work in focused branches and open reviewable PRs.
- Preserve the shared service: audio must not belong to a panel or monitor.
- Persist user choices only, never random animation frames or playback state.
- Every audio asset needs a source, exact license, attribution, and checksum.
- Run `python scripts/check_assets.py` and, when present,
  `node --test tests/model.test.cjs` and `scripts/check_qml.sh`.
- Include actual validation evidence in PRs. Do not claim listening, graphical,
  multi-monitor, or device tests that were not performed.
- Keep the UI in English. Donations belong on GitHub, not in the panel.
