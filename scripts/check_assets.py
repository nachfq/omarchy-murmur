#!/usr/bin/env python3
"""Check shipped assets, attribution coverage, decodability and mix headroom."""
import array
import hashlib
import json
from pathlib import Path
import subprocess
import sys

root = Path(__file__).resolve().parent.parent
sounds = json.loads((root / 'assets/sources.json').read_text())
assert len(sounds) == 10 and len({s['id'] for s in sounds}) == 10
assert {s['id'] for s in sounds} == set('rain thunder waves wind fire birds crickets coffee bowl noise'.split())
assert {p.name for p in (root / 'assets').glob('*.wav')} == {Path(s['file']).name for s in sounds}
# Guard against accidentally shipping full multi-minute stereo originals.
assert sum((root / s['file']).stat().st_size for s in sounds) < 55 * 1024**2, 'Audio catalog exceeds the 55 MiB budget'
credits = (root / 'SOUNDS_LICENSES.md').read_text()
peaks = []
for sound in sounds:
    path = root / sound['file']
    assert hashlib.sha256(path.read_bytes()).hexdigest() == sound['sha256'], path
    assert len(sound['source_sha256']) == 64
    for key in ['author', 'source', 'license', 'license_url']:
        assert sound[key] and sound[key] in credits, (path, key)
    assert sound['license'] in ['CC0-1.0', 'CC-BY-4.0', 'Public Domain']
    meta = json.loads(subprocess.check_output(['ffprobe', '-v', 'error', '-show_streams', '-of', 'json', str(path)]))['streams'][0]
    assert meta['codec_name'] == 'pcm_s16le' and int(meta['sample_rate']) == 48000 and meta['channels'] == 1
    pcm = subprocess.check_output(['ffmpeg', '-v', 'error', '-i', str(path), '-f', 'f32le', '-'])
    samples = array.array('f')
    samples.frombytes(pcm)
    if sys.byteorder != 'little':
        samples.byteswap()
    if 'crop_seconds' in sound:
        expected_frames = round((sound['crop_seconds'] - sound['crossfade_seconds']) * 48000)
        assert len(samples) == expected_frames, (path, len(samples), expected_frames)
    peak = max(abs(x) for x in samples)
    assert len(samples) > 48000 and 0.001 < peak < 0.1, (path, peak)
    # Loop boundary must not introduce a discontinuity larger than the
    # largest existing adjacent-sample change (noise naturally has jumps).
    jumps = max(abs(samples[i] - samples[i - 1]) for i in range(1, len(samples)))
    assert abs(samples[0] - samples[-1]) <= jumps + 0.001, path
    if 'loudness' in sound:
        scan = subprocess.run([
            'ffmpeg', '-hide_banner', '-nostats', '-i', str(path),
            '-af', 'loudnorm=I=-24:TP=-2:LRA=50:print_format=json',
            '-f', 'null', '-'], capture_output=True, text=True, check=True)
        measured = json.JSONDecoder().raw_decode(scan.stderr[scan.stderr.rfind('{'):])[0]
        loudness = float(measured['input_i'])
        assert abs(loudness - sound['loudness']['target_lufs']) <= 0.3, (path, loudness)
        print(f"{sound['id']}: {loudness:.2f} LUFS")
    peaks.append(peak)
    print(f"{sound['id']}: OK, peak {peak:.4f}")
assert sum(peaks) < 1, 'Ten-channel conservative peak sum must stay below full scale'
print(f'10 assets verified; maximum possible summed peak: {sum(peaks):.4f}')
