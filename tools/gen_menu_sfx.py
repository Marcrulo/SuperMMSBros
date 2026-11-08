"""Synthesizes the menu sound effects that are ours (docs/specs/menus.md#sound: back and locked) and normalizes them with
prepare_music.py --sfx. Chiptune-style square waves; deterministic, so the output is the same
every run.
Usage: python3 -I tools/gen_menu_sfx.py super-mms-bros/assets/sfx
Needs numpy and ffmpeg.
"""
import subprocess
import sys
import tempfile
import wave
from pathlib import Path

import numpy as np

RATE = 44100
PREPARE = Path(__file__).with_name("prepare_music.py")


def square(freq, seconds, duty=0.5):
    t = np.arange(int(RATE * seconds)) / RATE
    return np.where((t * freq) % 1.0 < duty, 1.0, -1.0)


def envelope(samples, attack=0.002, release=0.02, decay=0.0):
    """Short fade in and out (no clicks); `decay` adds an exponential fade over the whole note."""
    n = len(samples)
    env = np.ones(n)
    a, r = int(RATE * attack), int(RATE * release)
    env[:a] = np.linspace(0.0, 1.0, a)
    env[n - r:] *= np.linspace(1.0, 0.0, r)
    if decay > 0.0:
        env *= np.exp(-np.arange(n) / (RATE * decay))
    return samples * env


def notes(*parts):
    """(frequency, seconds) pairs, played one after another."""
    return np.concatenate([envelope(square(f, s, 0.5), release=0.01) for f, s in parts])


SOUNDS = {
    # G5 then C5: going back.
    "menu_back": lambda: notes((784.0, 0.06), (523.25, 0.09)),
    # Two detuned low squares: a dull "nope".
    "menu_locked": lambda: envelope(
        0.5 * square(110.0, 0.2, 0.5) + 0.5 * square(116.5, 0.2, 0.5), release=0.04, decay=0.15),
}


def write_wav(path, samples):
    data = (np.clip(samples, -1.0, 1.0) * 0.5 * 32767).astype("<i2")
    with wave.open(str(path), "wb") as out:
        out.setnchannels(1)
        out.setsampwidth(2)
        out.setframerate(RATE)
        out.writeframes(data.tobytes())


def main(out_dir):
    out = Path(out_dir)
    out.mkdir(parents=True, exist_ok=True)
    with tempfile.TemporaryDirectory() as raw_dir:
        for name, make in SOUNDS.items():
            raw = Path(raw_dir) / f"{name}.wav"
            write_wav(raw, make())
            subprocess.run([sys.executable, "-I", str(PREPARE), "--sfx", str(raw),
                            str(out / f"{name}.wav")], check=True)


if __name__ == "__main__":
    main(sys.argv[1])
