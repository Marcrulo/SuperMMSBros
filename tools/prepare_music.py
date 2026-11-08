"""Prepares music and sound effects for the game (docs/specs/controls-and-display.md#audio).

Music: trims leading and trailing silence (so the loop has no gap), normalizes loudness to -18 LUFS
with true peaks below -1.5 dBTP (two-pass EBU R128 loudnorm), and writes OGG Vorbis, 44.1 kHz
stereo.
Sound effects (--sfx): leading and trailing silence trimmed the same way; too short for integrated
loudness, so the loudest 400 ms window (momentary loudness) is set to -18 LUFS, with sample peaks
kept below -1.5 dBFS; writes 16-bit WAV, 44.1 kHz.
Usage: python3 -I tools/prepare_music.py [--sfx] <input audio> <output>
Needs ffmpeg on the PATH.
"""
import json
import os
import re
import subprocess
import sys

TARGET_LUFS = -18.0
TRUE_PEAK = -1.5
LOUDNESS_RANGE = 11.0
# Below this level counts as silence when trimming the ends.
SILENCE = "-50dB"
TRIM = (
    f"silenceremove=start_periods=1:start_threshold={SILENCE},"
    f"areverse,silenceremove=start_periods=1:start_threshold={SILENCE},areverse"
)


def measure(source):
    """First pass: the trimmed track's loudness, as loudnorm reports it."""
    loudnorm = f"loudnorm=I={TARGET_LUFS}:TP={TRUE_PEAK}:LRA={LOUDNESS_RANGE}:print_format=json"
    result = subprocess.run(
        ["ffmpeg", "-hide_banner", "-nostats", "-i", source, "-af", f"{TRIM},{loudnorm}",
         "-f", "null", "-"],
        capture_output=True, text=True, check=True)
    report = result.stderr[result.stderr.rindex("{"):result.stderr.rindex("}") + 1]
    return json.loads(report)


def prepare(source, target):
    m = measure(source)
    loudnorm = (
        f"loudnorm=I={TARGET_LUFS}:TP={TRUE_PEAK}:LRA={LOUDNESS_RANGE}"
        f":measured_I={m['input_i']}:measured_TP={m['input_tp']}"
        f":measured_LRA={m['input_lra']}:measured_thresh={m['input_thresh']}"
        f":offset={m['target_offset']}:linear=true"
    )
    subprocess.run(
        ["ffmpeg", "-hide_banner", "-loglevel", "error", "-y", "-i", source,
         "-af", f"{TRIM},{loudnorm}", "-ar", "44100", "-ac", "2",
         "-c:a", "libvorbis", "-q:a", "5", "-vn", target],
        check=True)
    print(f"{target}: was {m['input_i']} LUFS, now {TARGET_LUFS} LUFS")


def _ffmpeg_report(source, audio_filter):
    result = subprocess.run(
        ["ffmpeg", "-hide_banner", "-nostats", "-i", source, "-af", audio_filter, "-f", "null", "-"],
        capture_output=True, text=True, check=True)
    return result.stderr


def max_momentary(source):
    """Loudest 400 ms window, in LUFS. Padded with silence so even a 40 ms sound gets measured."""
    report = _ffmpeg_report(source, "apad=pad_dur=0.5,ebur128")
    values = [float(v) for v in re.findall(r"M:\s*(-?[\d.]+)", report)]
    return max(values)


def peak(source):
    """Highest sample, in dBFS."""
    report = _ffmpeg_report(source, "volumedetect")
    return float(re.search(r"max_volume:\s*(-?[\d.]+) dB", report).group(1))


def prepare_sfx(source, target):
    trimmed = target + ".trimmed.wav"
    subprocess.run(
        ["ffmpeg", "-hide_banner", "-loglevel", "error", "-y", "-i", source,
         "-af", TRIM, "-ar", "44100", "-c:a", "pcm_s16le", trimmed],
        check=True)
    try:
        loudness = max_momentary(trimmed)
        gain = min(TARGET_LUFS - loudness, TRUE_PEAK - peak(trimmed))
        subprocess.run(
            ["ffmpeg", "-hide_banner", "-loglevel", "error", "-y", "-i", trimmed,
             "-af", f"volume={gain:.2f}dB", "-c:a", "pcm_s16le", target],
            check=True)
    finally:
        os.remove(trimmed)
    print(f"{target}: loudest window was {loudness:.1f} LUFS, gain {gain:+.1f} dB")


if __name__ == "__main__":
    if sys.argv[1] == "--sfx":
        prepare_sfx(sys.argv[2], sys.argv[3])
    else:
        prepare(sys.argv[1], sys.argv[2])
