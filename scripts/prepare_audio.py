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
import urllib.request

ROOT = Path(__file__).resolve().parent.parent
RATE = 48000


def digest(data):
    return hashlib.sha256(data).hexdigest()


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--record', action='store_true')
    args = parser.parse_args()
    catalog = ROOT / 'assets/sources.json'
    sounds = json.loads(catalog.read_text())
    cache = ROOT / '.cache/audio'
    cache.mkdir(parents=True, exist_ok=True)
    for sound in sounds:
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
                'ffmpeg', '-v', 'error', '-i', str(source), '-t', '60',
                '-ac', '1', '-ar', str(RATE), '-f', 'f32le', '-'])
            samples = array.array('f')
            samples.frombytes(pcm)
        if sys.byteorder != 'little':
            samples.byteswap()
        # Join the last 250ms to the first 250ms; the periodic boundary then
        # meets the untouched body, rather than fading to silence every loop.
        overlap = min(RATE // 4, len(samples) // 4)
        for i in range(overlap):
            t = i / overlap
            samples[i] = samples[-overlap + i] * (1 - t) + samples[i] * t
        del samples[-overlap:]
        # A fixed peak budget per track keeps ten full-volume streams below
        # full scale without changing another track when a channel is muted.
        peak = max(abs(x) for x in samples)
        rms = math.sqrt(sum(x * x for x in samples) / len(samples))
        # Noise needs extra margin for Vorbis reconstruction overshoot.
        peak_budget = 0.04 if sound['id'] == 'noise' else 0.085
        gain = min(peak_budget / max(peak, 1e-9), 0.035 / max(rms, 1e-9))
        samples = array.array('f', (x * gain for x in samples))
        if sys.byteorder != 'little':
            samples.byteswap()
        target = ROOT / sound['file']
        subprocess.run([
            'ffmpeg', '-y', '-v', 'error', '-f', 'f32le', '-ar', str(RATE),
            '-ac', '1', '-i', '-', '-c:a', 'libvorbis', '-q:a', '5',
            '-map_metadata', '-1', '-metadata', f"title={sound['name']}",
            '-metadata', f"artist={sound['author']}", '-metadata',
            f"license={sound['license_url']}", str(target)
        ], input=samples.tobytes(), check=True)
        if args.record:
            sound['source_sha256'] = digest(original)
            sound['sha256'] = digest(target.read_bytes())
        print(f"{sound['id']}: {len(samples) / RATE:.2f}s, {target.stat().st_size:,} bytes")
    if args.record:
        catalog.write_text(json.dumps(sounds, indent=2, ensure_ascii=False) + '\n')


if __name__ == '__main__':
    main()
