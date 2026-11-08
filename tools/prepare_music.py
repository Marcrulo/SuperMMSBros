"""Prepares a music track for the game (docs/specs/controls-and-display.md#audio).

Trims leading and trailing silence (so the loop has no gap), normalizes loudness to -18 LUFS with
true peaks below -1.5 dBTP (two-pass EBU R128 loudnorm), and writes OGG Vorbis, 44.1 kHz stereo.
Usage: python3 -I tools/prepare_music.py <input audio> <output .ogg>
Needs ffmpeg on the PATH.
"""
import json
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


if __name__ == "__main__":
    prepare(sys.argv[1], sys.argv[2])
