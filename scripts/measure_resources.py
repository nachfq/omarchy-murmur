#!/usr/bin/env python3
"""Measure the real service in Quickshell, without desktop UI or real speakers."""
import argparse
import json
import os
from pathlib import Path
import shutil
import subprocess
import tempfile
import time

root = Path(__file__).resolve().parent.parent
parser = argparse.ArgumentParser()
parser.add_argument('--source', type=Path, default=root)
parser.add_argument('--repeats', type=int, default=2)
parser.add_argument('--seconds', type=int, default=15)
parser.add_argument('--output', type=Path, required=True)
args = parser.parse_args()
if os.environ.get('YURAGI_PRIVATE_AUDIO') != '1':
    parser.error('Run through scripts/with_test_audio.sh')
assert args.repeats > 0 and args.seconds > 0
module = subprocess.check_output(['pactl', 'load-module', 'module-null-sink',
                                  'sink_name=yuragi-bench'], text=True).strip()
subprocess.run(['pactl', 'set-default-sink', 'yuragi-bench'], check=True)
results = []
proc = None

def snapshot(pid):
    fields = Path(f'/proc/{pid}/stat').read_text().rsplit(')', 1)[1].split()
    ticks = (int(fields[11]) + int(fields[12])) / os.sysconf('SC_CLK_TCK')
    memory = {}
    for line in Path(f'/proc/{pid}/smaps_rollup').read_text().splitlines():
        if line.startswith(('Rss:', 'Pss:')):
            key, value, unit = line.split()
            memory[key[:-1].lower() + '_mib'] = round(int(value) / 1024, 2)
    return time.monotonic(), ticks, memory

try:
    with tempfile.TemporaryDirectory(prefix='yuragi-bench-') as directory:
        fixture = Path(directory)
        for name in ['Service.qml', 'AudioChannel.qml', 'Model.js']:
            shutil.copy2(args.source / name, fixture / name)
        (fixture / 'assets').symlink_to((args.source / 'assets').resolve(), target_is_directory=True)
        shutil.copy2(root / 'tests/bench/shell.qml', fixture / 'shell.qml')
        for repeat in range(args.repeats):
            env = dict(os.environ, YURAGI_BENCH_SECONDS=str(args.seconds))
            proc = subprocess.Popen(['quickshell', '-p', str(fixture), '--no-color'], env=env,
                                    stdout=subprocess.PIPE, stderr=subprocess.STDOUT, text=True)
            run = {}
            for line in proc.stdout:
                if 'YURAGI_BENCH_BEGIN ' in line:
                    start = snapshot(proc.pid)
                elif 'YURAGI_BENCH_END ' in line:
                    phase = line.strip().split()[-1]
                    end = snapshot(proc.pid)
                    run[phase] = dict(end[2], cpu_percent_one_core=round(100 * (end[1]-start[1]) / (end[0]-start[0]), 3),
                                      seconds=round(end[0]-start[0], 2))
                    print(f'run {repeat+1} {phase}: {run[phase]}', flush=True)
            assert proc.wait() == 0 and len(run) == 6, run
            results.append(run)
            args.output.write_text(json.dumps(results, indent=2) + '\n')
finally:
    if proc is not None and proc.poll() is None:
        proc.terminate()
        proc.wait()
    subprocess.run(['pactl', 'unload-module', module], check=True)
