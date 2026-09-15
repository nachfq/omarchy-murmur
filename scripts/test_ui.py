#!/usr/bin/env python3
"""Run real pointer/keyboard tests in an offscreen Quickshell window."""
import json
import os
from pathlib import Path
import shutil
import subprocess
import tempfile

root = Path(__file__).resolve().parent.parent
shell = Path(os.environ.get('OMARCHY_PATH', '/usr/share/omarchy')) / 'shell'
with tempfile.TemporaryDirectory(prefix='yuragi-ui-') as directory:
    fixture = Path(directory)
    # Quickshell's qs imports are rooted in its config directory. Copy the
    # installed/reference components unchanged; no desktop config is modified.
    for name in ['Ui', 'Commons']:
        shutil.copytree(shell / name, fixture / name)
    for name in ['VolumeControl.qml', 'BarWidget.qml', 'Service.qml', 'AudioChannel.qml', 'Model.js']:
        shutil.copy2(root / name, fixture / name)
    # Layer-shell panels need a Wayland compositor. Keep just their public
    # lifecycle here; indicator drawing and click handling remain native.
    shutil.copy2(root / 'tests/ui/PanelStub.qml', fixture / 'Panel.qml')
    shutil.copy2(root / 'tests/ui/shell.qml', fixture / 'shell.qml')
    env = dict(os.environ, QT_QPA_PLATFORM='offscreen', QT_QPA_PLATFORMTHEME='', QT_QUICK_BACKEND='software')
    env.pop('WAYLAND_DISPLAY', None)
    env.pop('DISPLAY', None)
    try:
        result = subprocess.run(['quickshell', '-p', str(fixture / 'shell.qml'), '--no-color'],
                                env=env, text=True, stdout=subprocess.PIPE, stderr=subprocess.STDOUT, timeout=45)
    except subprocess.TimeoutExpired as error:
        print((error.stdout or b'').decode(errors='replace'))
        raise
    print(result.stdout)
    summaries = [line.split('YURAGI_UI_RESULT ', 1)[1] for line in result.stdout.splitlines() if 'YURAGI_UI_RESULT ' in line]
    assert result.returncode == 0 and len(summaries) == 1, 'UI fixture did not finish'
    counts = json.loads(summaries[0])
    assert counts['failed'] == 0 and counts['passed'] >= 10, counts
