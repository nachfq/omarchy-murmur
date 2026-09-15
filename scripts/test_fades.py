#!/usr/bin/env python3
"""Check the fade in captured audio, independently of QML animation values."""
import array
import json
import math
import os
from pathlib import Path
import statistics
import subprocess
import sys

if os.environ.get('YURAGI_PRIVATE_AUDIO') != '1':
    sys.exit('Run through scripts/with_test_audio.sh')
root = Path(__file__).resolve().parent.parent
os.chdir(root)
out = root / 'artifacts/fades'
out.mkdir(parents=True, exist_ok=True)
module = subprocess.check_output(['pactl', 'load-module', 'module-null-sink',
                                  'sink_name=yuragi-fade', 'sink_properties=device.description=YuragiFade'], text=True).strip()
recorder = None
try:
    recorder = subprocess.Popen(['ffmpeg', '-y', '-v', 'error', '-f', 'pulse', '-i', 'yuragi-fade.monitor',
                                 '-t', '7', '-ac', '1', '-ar', '48000', str(out / 'capture.wav')])
    subprocess.run(['/usr/lib/qt6/bin/qmltestrunner', '-input', 'tests/tst_fade.qml'], check=True, timeout=20)
    assert recorder.wait(timeout=15) == 0
    pcm = subprocess.check_output(['ffmpeg', '-v', 'error', '-i', str(out / 'capture.wav'), '-f', 'f32le', '-'])
    samples = array.array('f', pcm)
    if sys.byteorder != 'little': samples.byteswap()
    block = 2400 # 50 ms, averaging noise fluctuations.
    rms = [math.sqrt(sum(v*v for v in samples[i:i+block]) / block)
           for i in range(0, len(samples)-block, block)]
    plateau = statistics.median(sorted(rms)[-20:])
    assert plateau > .001, 'No useful audio captured'
    active = [i for i, r in enumerate(rms) if r > plateau * .02]
    full = [i for i, r in enumerate(rms) if r > plateau * .9]
    rise = (full[0] - active[0]) * .05
    fall = (active[-1] - full[-1]) * .05
    assert .25 <= rise <= .9, ('abrupt or excessive fade-in', rise)
    assert .25 <= fall <= .9, ('abrupt or excessive fade-out', fall)
    assert (full[-1] - full[0]) * .05 >= 1, 'Missing sustained playback'
    assert all(r < .0001 for r in rms[-10:]), 'Not silent after pause'
    result = dict(fade_in_measured_seconds=rise, fade_out_measured_seconds=fall, rms=rms)
    (out / 'envelope.json').write_text(json.dumps(result, indent=2) + '\n')
    print(f'Recorded fade-in {rise:.2f}s, fade-out {fall:.2f}s; silent after pause')
finally:
    if recorder is not None and recorder.poll() is None:
        recorder.terminate()
        recorder.wait()
    subprocess.run(['pactl', 'unload-module', module], check=True)
