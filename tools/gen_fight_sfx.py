"""Builds the fight sound effects (docs/specs/sound.md) from free CC0 packs on OpenGameArt.

Downloads each pack into <downloads_dir>/<pack>/ (once), unpacks it there, cuts and fades the
chosen file where needed, and prepares it with prepare_music.prepare_sfx (silence trimmed,
loudness-normalized, 16-bit 44.1 kHz WAV) into <out_dir>/<name>.wav. Then rewrites the fight
section of <out_dir>/../CREDITS.txt. Deterministic for the same packs.
Usage: python3 -I tools/gen_fight_sfx.py <downloads_dir> super-mms-bros/assets/sfx/fight
Needs curl, 7z, unzip and ffmpeg.
"""
import subprocess
import sys
import tempfile
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
from prepare_music import prepare_sfx  # noqa: E402

FILES = "https://opengameart.org/sites/default/files/"
PAGE = "https://opengameart.org/content/"
# pack: (archive file on OpenGameArt, page, title, author). All CC0.
PACKS = {
    "hits": ("independent_nu_ljudbank-hits_and_punches.7z", "37-hitspunches", "37 hits/punches",
             "qubodup"),
    "blocks": ("impact_-_starninjas.zip", "10-impactshield-blocks", "10 Impact/Shield Blocks",
               "StarNinjas"),
    "breaking": ("sfx_breaking_and_falling.zip", "75-cc0-breaking-falling-hit-sfx",
                 "75 CC0 breaking / falling / hit sfx", "rubberduck"),
    "swishes": ("swishes.zip", "swishes-sound-pack", "Swishes Sound Pack", "artisticdude"),
    "whoosh": ("whoosh2_0.wav", "air-whoosh", "Air whoosh", "pyranostudios"),
    "rpg": ("RPGsounds_Kenney.zip", "50-rpg-sound-effects", "50 RPG sound effects", "Kenney"),
    "scifi": ("sci-fi_sounds.zip", "sci-fi-sounds", "Sci-Fi Sounds", "Kenney"),
    "rpg80": ("80-CC0-RPG-SFX_0.zip", "80-cc0-rpg-sfx", "80 CC0 RPG SFX", "rubberduck"),
}
# name: (pack, file inside it, cut: (start s, length s) or None). A cut fades out over its last
# quarter.
SOUNDS = {
    "hit_light": ("hits", "hits/hit15.mp3.flac", None),
    "hit_medium": ("hits", "hits/hit29.mp3.flac", None),
    "hit_heavy": ("hits", "hits/hit33.mp3.flac", None),
    "block": ("blocks", "impact.8.ogg", None),
    "swing": ("swishes", "swishes/swish-3.wav", None),
    "swing_heavy": ("swishes", "swishes/swish-8.wav", None),
    "dodge": ("swishes", "swishes/swish-9.wav", None),
    "double_jump": ("swishes", "swishes/swish-1.wav", None),
    "dive": ("whoosh", "whoosh2_0.wav", (0.0, 0.6)),
    "jump": ("rpg", "OGG/cloth2.ogg", None),
    "land": ("rpg", "OGG/dropLeather.ogg", None),
    "step_1": ("rpg", "OGG/footstep06.ogg", None),
    "step_2": ("rpg", "OGG/footstep09.ogg", None),
    "ledge_grab": ("rpg", "OGG/handleSmallLeather.ogg", None),
    "shield_on": ("scifi", "Audio/forceField_000.ogg", (0.0, 0.35)),
    "charge": ("scifi", "Audio/forceField_001.ogg", None),
    "zap": ("scifi", "Audio/laserSmall_000.ogg", None),
    "burst": ("scifi", "Audio/explosionCrunch_000.ogg", None),
    "boost": ("scifi", "Audio/thrusterFire_001.ogg", (0.0, 0.5)),
    "ko": ("scifi", "Audio/lowFrequency_explosion_000.ogg", None),
    "shield_break": ("breaking", "bfh1_glass_breaking_01.ogg", None),
    "respawn": ("rpg80", "spell_01.ogg", None),
}
CREDITS_START = "# Fight sounds (tools/gen_fight_sfx.py)"


def fetch(downloads, pack):
    """The pack's folder with its files unpacked, downloading it the first time."""
    archive, _, _, _ = PACKS[pack]
    folder = downloads / pack
    unpacked = folder / "unpacked"
    if unpacked.exists():
        return unpacked
    folder.mkdir(parents=True, exist_ok=True)
    target = folder / archive
    subprocess.run(["curl", "-sSfL", "-o", str(target), FILES + archive], check=True)
    unpacked.mkdir()
    if archive.endswith(".7z"):
        subprocess.run(["7z", "x", "-y", "-bso0", "-bsp0", str(target), f"-o{unpacked}"],
                       check=True)
    elif archive.endswith(".zip"):
        subprocess.run(["unzip", "-q", "-o", str(target), "-d", str(unpacked)], check=True)
    else:
        (unpacked / archive).write_bytes(target.read_bytes())
    return unpacked


def find(unpacked, inner):
    """The file inside a pack, wherever the archive's own top folder put it."""
    direct = unpacked / inner
    if direct.exists():
        return direct
    matches = [p for p in unpacked.rglob(Path(inner).name) if not p.name.startswith("._")]
    if not matches:
        raise FileNotFoundError(f"{inner} not in {unpacked}")
    return matches[0]


def build(downloads, out):
    out.mkdir(parents=True, exist_ok=True)
    with tempfile.TemporaryDirectory() as tmp:
        for name, (pack, inner, cut) in SOUNDS.items():
            source = find(fetch(downloads, pack), inner)
            if cut:
                start, length = cut
                fade = length / 4
                cut_file = Path(tmp) / f"{name}.wav"
                subprocess.run(["ffmpeg", "-v", "error", "-y", "-ss", str(start), "-t", str(length),
                                "-i", str(source), "-af", f"afade=t=out:st={length - fade}:d={fade}",
                                str(cut_file)], check=True)
                source = cut_file
            prepare_sfx(str(source), str(out / f"{name}.wav"))
            print(name)
    write_credits(out.parent / "CREDITS.txt")


def write_credits(path):
    text = path.read_text() if path.exists() else ""
    if CREDITS_START in text:
        text = text[:text.index(CREDITS_START)].rstrip() + "\n"
    lines = ["", CREDITS_START, "", "All CC0 (public domain): http://creativecommons.org/publicdomain/zero/1.0/",
             "Changes: cut where noted, silence trimmed, loudness normalized, 44.1 kHz WAV.", ""]
    for name, (pack, inner, cut) in SOUNDS.items():
        _, page, title, author = PACKS[pack]
        note = f", cut to {cut[1]} s with a fade-out" if cut else ""
        lines.append(f"fight/{name}.wav")
        lines.append(f"  \"{Path(inner).name}\" from \"{title}\" by {author}, {PAGE}{page}{note}")
    path.write_text(text + "\n".join(lines) + "\n")


if __name__ == "__main__":
    build(Path(sys.argv[1]), Path(sys.argv[2]))
