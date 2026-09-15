#!/usr/bin/env python3
"""Maintainer-only preparation. Python 3 + ffmpeg; never run by the plugin.

Sources are cached and hash-checked. --record updates source/output hashes after
an intentional asset change. Encoder versions can change output bytes; normal
regeneration verifies the pinned inputs without rewriting the lock file.
"""
import argparse
import array
import hashlib
import json
import math
from pathlib import Path
import random
import subprocess
import sys
import tempfile
import urllib.request

ROOT = Path(__file__).resolve().parent.parent
RATE = 48000


def digest(data):
    return hashlib.sha256(data).hexdigest()


def apply_loudness(target, sound, frames):
    """Bake the approved calibration into PCM; never run during playback."""
    calibration = sound.get('loudness')
    if not calibration:
        return
    if digest(target.read_bytes()) != calibration['input_sha256']:
        raise SystemExit(f"Calibration input changed; remeasure {sound['id']}")
    gain_db = float(calibration['gain_db'])
    if not math.isfinite(gain_db) or not -60 <= gain_db <= 60:
        raise SystemExit(f"Invalid loudness gain: {sound['id']}")
    pcm = subprocess.check_output([
        'ffmpeg', '-v', 'error', '-i', str(target), '-f', 'f32le', '-'])
    # Periodic padding settles the limiter across the loop seam. Compensate
    # its lookahead delay and keep exactly the existing number of frames.
    pad = RATE * 4
    filters = (f'volume={gain_db:.8f}dB:precision=double,'
               'alimiter=limit=0.085:attack=5:release=50:level=false:latency=true,'
               f'atrim=start_sample={RATE}:end_sample={RATE + frames},'
               'asetpts=PTS-STARTPTS')
    with tempfile.TemporaryDirectory(prefix='yuragi-loudness-') as directory:
        output = Path(directory) / 'normalized.wav'
        subprocess.run([
            'ffmpeg', '-y', '-v', 'error', '-f', 'f32le', '-ar', str(RATE),
            '-ac', '1', '-i', '-', '-af', filters, '-ar', str(RATE), '-ac', '1',
            '-c:a', 'pcm_s16le', '-map_metadata', '-1',
            '-metadata', f"title={sound['name']}",
            '-metadata', f"artist={sound['author']}",
            '-metadata', f"license={sound['license_url']}", str(output)
        ], input=pcm[-pad:] + pcm + pcm[:pad], check=True)
        target.write_bytes(output.read_bytes())


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--record', action='store_true')
    parser.add_argument('--only', nargs='+', metavar='ID',
                        help='Prepare only these channels; leave other WAVs untouched')
    args = parser.parse_args()
    catalog = ROOT / 'assets/sources.json'
    sounds = json.loads(catalog.read_text())
    if args.only and set(args.only) - {s['id'] for s in sounds}:
        parser.error('Unknown channel ID in --only')
    cache = ROOT / '.cache/audio'
    cache.mkdir(parents=True, exist_ok=True)
    for sound in sounds:
        if args.only and sound['id'] not in args.only:
            continue
        crop = float(sound.get('crop_seconds', 60))
        crossfade = float(sound.get('crossfade_seconds', 0.25))
        if not (math.isfinite(crop) and math.isfinite(crossfade)
                and crop > 0 and 1 / RATE <= crossfade <= crop / 4):
            raise SystemExit(f"Invalid crop/crossfade: {sound['id']}")
        if sound['id'] == 'noise':
            rng = random.Random(2026)
            samples = array.array('f', (rng.uniform(-1, 1) for _ in range(RATE * 30)))
            if sys.byteorder != 'little':
                samples.byteswap()
            original = samples.tobytes()
        else:
            source = cache / sound['id']
            if not source.exists():
                with urllib.request.urlopen(sound['download'], timeout=60) as response:
                    source.write_bytes(response.read())
            original = source.read_bytes()
            if sound.get('source_sha256') and digest(original) != sound['source_sha256']:
                raise SystemExit(f"Source checksum mismatch: {sound['id']}")
            pcm = subprocess.check_output([
                'ffmpeg', '-v', 'error', '-i', str(source), '-t', str(crop),
                '-ac', '1', '-ar', str(RATE), '-f', 'f32le', '-'])
            samples = array.array('f')
            samples.frombytes(pcm)
        if sys.byteorder != 'little':
            samples.byteswap()
        # Join the end to the beginning; the periodic boundary then
        # meets the untouched body, rather than fading to silence every loop.
        overlap = min(round(RATE * crossfade), len(samples) // 4)
        for i in range(overlap):
            t = i / overlap
            samples[i] = samples[-overlap + i] * (1 - t) + samples[i] * t
        del samples[-overlap:]
        # A fixed peak budget per track keeps ten full-volume streams below
        # full scale without changing another track when a channel is muted.
        peak = max(abs(x) for x in samples)
        rms = math.sqrt(sum(x * x for x in samples) / len(samples))
        # Preserve the existing conservative headroom for noise.
        peak_budget = 0.04 if sound['id'] == 'noise' else 0.085
        gain = min(peak_budget / max(peak, 1e-9), 0.035 / max(rms, 1e-9))
        samples = array.array('f', (x * gain for x in samples))
        if sys.byteorder != 'little':
            samples.byteswap()
        target = ROOT / sound['file']
        subprocess.run([
            'ffmpeg', '-y', '-v', 'error', '-f', 'f32le', '-ar', str(RATE),
            '-ac', '1', '-i', '-', '-c:a', 'pcm_s16le',
            '-map_metadata', '-1', '-metadata', f"title={sound['name']}",
            '-metadata', f"artist={sound['author']}", '-metadata',
            f"license={sound['license_url']}", str(target)
        ], input=samples.tobytes(), check=True)
        apply_loudness(target, sound, len(samples))
        if args.record:
            sound['source_sha256'] = digest(original)
            sound['sha256'] = digest(target.read_bytes())
        print(f"{sound['id']}: {len(samples) / RATE:.2f}s, {target.stat().st_size:,} bytes")
    if args.record:
        catalog.write_text(json.dumps(sounds, indent=2, ensure_ascii=False) + '\n')


if __name__ == '__main__':
    main()
