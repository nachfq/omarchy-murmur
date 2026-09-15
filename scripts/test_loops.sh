#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
mkdir -p artifacts
runner="$(command -v qmltestrunner || true)"
if [[ -z "$runner" ]]; then runner=/usr/lib/qt6/bin/qmltestrunner; fi
test_sink="murmur-loop-$$"
module_id="$(pactl load-module module-null-sink sink_name="$test_sink" sink_properties=device.description=MurmurTest)"
recorder_pid=''
cleanup() {
  if [[ -n "$recorder_pid" ]]; then kill "$recorder_pid" 2>/dev/null || true; fi
  pactl unload-module "$module_id"
}
trap cleanup EXIT
ffmpeg -y -v error -f pulse -i "$test_sink.monitor" -ac 1 -ar 48000 \
  -t 68 artifacts/loop-capture.wav &
recorder_pid=$!
QT_QPA_PLATFORM=offscreen \
  "$runner" -input tests/tst_loop.qml
wait "$recorder_pid"
recorder_pid=''
python3 - <<'PY'
import array
import subprocess
import sys
pcm = subprocess.check_output(['ffmpeg', '-v', 'error', '-i', 'artifacts/loop-capture.wav', '-f', 'f32le', '-'])
samples = array.array('f')
samples.frombytes(pcm)
if sys.byteorder != 'little':
    samples.byteswap()
active = [i for i, value in enumerate(samples) if abs(value) > 0.0001]
assert active, 'No audio captured'
start = active[0]
end = start + 61 * 48000
assert active[-1] >= end, 'Capture must include two 29.75-second loops'
longest = current = 0
for value in samples[start:end]:
    current = current + 1 if abs(value) <= 0.0001 else 0
    longest = max(longest, current)
gap_ms = longest / 48
assert gap_ms < 20, f'Unexpected silent gap: {gap_ms:.2f} ms'
assert max(abs(v) for v in samples) < 1, 'Capture clipped'
print(f'Checked {(end-start)/48000:.2f}s across two loop boundaries; longest near-silent run {gap_ms:.2f}ms; no clipping')
PY
