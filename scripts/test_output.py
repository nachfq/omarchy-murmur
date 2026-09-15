#!/usr/bin/env python3
"""Count real streams and record signal on an isolated native PipeWire server."""
import array
import json
import os
from pathlib import Path
import subprocess
import sys

if os.environ.get('YURAGI_PRIVATE_AUDIO') != '1':
    sys.exit('Run via scripts/with_test_audio.sh; never change desktop defaults.')
root = Path(__file__).resolve().parent.parent
os.chdir(root)

def command(*args):
    return subprocess.check_output(args, text=True).strip()

def objects(kind):
    return json.loads(command('pactl', '-f', 'json', 'list', kind))

modules = []
proc = None
try:
    for name in ['A', 'B']:
        modules.append(command('pactl', 'load-module', 'module-null-sink',
                               'sink_name=yuragi-output-' + name,
                               'sink_properties=device.description=YuragiOutput' + name))
    command('pactl', 'set-default-sink', 'yuragi-output-A')
    runner = '/usr/lib/qt6/bin/qmltestrunner'
    proc = subprocess.Popen([runner, '-input', 'tests/tst_output.qml'], stdout=subprocess.PIPE,
                            stderr=subprocess.STDOUT, text=True)
    checked = []
    for line in proc.stdout:
        print(line, end='', flush=True)
        if 'qml: YURAGI_OUTPUT_' not in line:
            continue
        phase = line.strip().split('YURAGI_OUTPUT_')[-1]
        if phase == 'SWITCH':
            command('pactl', 'set-default-sink', 'yuragi-output-B')
            command('pactl', 'unload-module', modules.pop(0))
            continue
        sink_name = 'yuragi-output-' + ('B' if phase == 'SWITCHED' else 'A')
        sink = next(s for s in objects('sinks') if s['name'] == sink_name)
        streams = [s for s in objects('sink-inputs') if s['sink'] == sink['index']]
        assert len(streams) <= 1 if phase == 'PAUSED' else len(streams) == 1, (phase, streams)
        pcm = subprocess.check_output([
            'ffmpeg', '-v', 'error', '-f', 'pulse', '-i', sink_name + '.monitor',
            '-t', '0.3', '-ac', '1', '-ar', '48000', '-f', 'f32le', '-'])
        samples = array.array('f', pcm)
        if sys.byteorder != 'little':
            samples.byteswap()
        peak = max(map(abs, samples))
        assert peak < 0.0001 if phase == 'PAUSED' else 0.0001 < peak < 1, (phase, peak)
        print(f'{phase}: {len(streams)} stream(s), recorded peak {peak:.5f}', flush=True)
        checked.append(phase)
    assert proc.wait() == 0, 'Qt output tests failed'
    assert checked == ['TEN', 'DRIFT', 'ONE', 'PAUSED', 'RESUMED', 'SWITCHED'], checked
finally:
    if proc is not None and proc.poll() is None:
        proc.terminate()
        proc.wait()
    for module in modules:
        subprocess.run(['pactl', 'unload-module', module], check=True)
