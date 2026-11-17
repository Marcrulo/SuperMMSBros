"""Builds one character's own sounds (docs/specs/sound.md#character-sounds).

Reads the character's list, tools/sfx/characters/<name>.py: a SOUNDS dict of
  sound name -> dict(
      url=...,            a Freesound high-quality preview (or other direct link), or
      file=...,           a file in this repo (relative to the repo root),
      title=, author=, page=, license=,   for the credit,
      cut=(start s, length s) or None,    a cut fades out over its last quarter,
      reverse=False,      played backwards,
      gain_db=0.0,        after loudness normalizing, to mix by ear,
  )
Downloads each url into <downloads_dir>/<name>/ (once), cuts / reverses it, prepares it with
prepare_music.prepare_sfx (silence trimmed, loudness-normalized, 16-bit 44.1 kHz WAV) into
super-mms-bros/characters/<name>/sounds/<sound>.wav, and writes the CREDITS.txt next to them.
Usage: python3 -I tools/gen_character_sfx.py <name> <downloads_dir>
Needs curl and ffmpeg.
"""
import importlib.util
import shutil
import subprocess
import sys
import tempfile
from pathlib import Path

TOOLS = Path(__file__).resolve().parent
REPO = TOOLS.parent
sys.path.insert(0, str(TOOLS))
from prepare_music import prepare_sfx  # noqa: E402

LICENSES = {
    "CC0": "Creative Commons 0 (public domain), http://creativecommons.org/publicdomain/zero/1.0/",
}


def load_list(name):
    path = TOOLS / "sfx" / "characters" / f"{name}.py"
    spec = importlib.util.spec_from_file_location(f"sfx_{name}", path)
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module.SOUNDS


def source_file(entry, downloads, sound):
    if "file" in entry:
        return REPO / entry["file"]
    downloads.mkdir(parents=True, exist_ok=True)
    target = downloads / (sound + Path(entry["url"]).suffix)
    if not target.exists():
        subprocess.run(["curl", "-sSfL", "-A", "Mozilla/5.0", "-o", str(target), entry["url"]],
                       check=True)
    return target


def build(name, downloads):
    sounds = load_list(name)
    out = REPO / "super-mms-bros" / "characters" / name / "sounds"
    out.mkdir(parents=True, exist_ok=True)
    with tempfile.TemporaryDirectory() as tmp:
        for sound, entry in sounds.items():
            source = source_file(entry, downloads / name, sound)
            filters = []
            if entry.get("reverse"):
                filters.append("areverse")
            cut = entry.get("cut")
            args = []
            if cut:
                start, length = cut
                fade = length / 4
                args = ["-ss", str(start), "-t", str(length)]
                filters.append(f"afade=t=out:st={length - fade}:d={fade}")
            edited = Path(tmp) / f"{sound}.wav"
            subprocess.run(["ffmpeg", "-v", "error", "-y", *args, "-i", str(source),
                            *(["-af", ",".join(filters)] if filters else []), str(edited)],
                           check=True)
            target = out / f"{sound}.wav"
            prepare_sfx(str(edited), str(target))
            gain = entry.get("gain_db", 0.0)
            if gain:
                mixed = Path(tmp) / f"{sound}.mixed.wav"
                subprocess.run(["ffmpeg", "-v", "error", "-y", "-i", str(target), "-af",
                                f"volume={gain}dB", "-c:a", "pcm_s16le", str(mixed)], check=True)
                shutil.move(mixed, target)
    write_credits(out / "CREDITS.txt", name, sounds)


def write_credits(path, name, sounds):
    lines = [f"{name.capitalize()}'s own sounds (tools/gen_character_sfx.py {name},",
             f"list in tools/sfx/characters/{name}.py).",
             "Changes: cut where noted, silence trimmed, loudness normalized, 44.1 kHz WAV.", ""]
    for sound, entry in sounds.items():
        changes = []
        if entry.get("reverse"):
            changes.append("reversed")
        if entry.get("cut"):
            changes.append(f"cut to {entry['cut'][1]} s with a fade-out")
        if entry.get("gain_db"):
            changes.append(f"{entry['gain_db']:+} dB")
        note = (", " + ", ".join(changes)) if changes else ""
        lines.append(f"{sound}.wav")
        lines.append(f"  \"{entry['title']}\" by {entry['author']}, {entry['page']}{note}")
        lines.append(f"  License: {LICENSES.get(entry['license'], entry['license'])}")
    path.write_text("\n".join(lines) + "\n")


if __name__ == "__main__":
    build(sys.argv[1], Path(sys.argv[2]))
