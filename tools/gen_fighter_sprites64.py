"""Generates a fighter's pixel-art strips at 64x64 (docs/specs/art-guide.md, 64 px draft).

The shared body and poses are in tools/sprites/body.py (and weapon poses several characters use
in tools/sprites/weapons.py); each character's own weapon, props, poses and pictures are in
tools/sprites/characters/<name>.py, found here automatically.
Usage:
  python3 -I tools/gen_fighter_sprites64.py <out_dir> [ids...] [--preview]
Strips go to <out_dir>/<id>/; --preview also writes <out_dir>/<id>_preview.png (every frame).
The game's strips: python3 -I tools/gen_fighter_sprites64.py super-mms-bros/assets/fighters slot_05
"""
import importlib
import pkgutil
import sys
import types
from pathlib import Path

from PIL import Image, ImageDraw

sys.path.insert(0, str(Path(__file__).resolve().parent))
import fighter64_looks as looks  # noqa: E402
from sprites import body  # noqa: E402
from sprites import characters  # noqa: E402

# Every character module (importing one registers its weapons, props and drawers in `body`).
CHARACTER_MODULES = [importlib.import_module(f"sprites.characters.{m.name}")
                     for m in sorted(pkgutil.iter_modules(characters.__path__), key=lambda m: m.name)]


def _modules_for(c):
    return [m for m in CHARACTER_MODULES if getattr(m, "applies", lambda c: False)(c)]


def frames_for(c):
    p = looks.palette(c)
    heads = {face: looks.build_head(c, face) for face in ("normal", "shut", "hurt")}
    weapon = body.WEAPONS.get(c.get("weapon"))
    own = dict(weapon["animations"]) if weapon else {}
    for module in _modules_for(c):
        if hasattr(module, "animations"):
            own.update(module.animations(c))
    return {name: [draw_pose(ps, c, p, heads) for ps in own.get(name, poses)]
            for name, poses in body.ANIMATIONS.items()}


def draw_pose(ps, c, p, heads):
    """One drawing; a pose with a key in body.DRAWERS (Pia's `flat`) is drawn by that."""
    for key, drawer in body.DRAWERS.items():
        if ps.get(key):
            return drawer(ps, c, p, heads)
    return body.draw_frame(ps, c, p, heads)


def left_strip(c, name):
    """An animation's strip for facing left, already mirrored, with lettering (the stop sign) kept
    readable: the game draws it as it is instead of mirroring the usual strip."""
    body.MIRROR_TEXT = True
    try:
        frames = frames_for(c)[name]
    finally:
        body.MIRROR_TEXT = False
    w, h = frames[0].size
    strip = Image.new("RGBA", (w * len(frames), h), (0, 0, 0, 0))
    for i, frame in enumerate(frames):
        strip.paste(frame.transpose(Image.FLIP_LEFT_RIGHT), (i * w, 0))
    return strip


# What a character module's extra_files() gets to build its pictures with.
STRIPS = types.SimpleNamespace(frames_for=frames_for, left_strip=left_strip)


def write_character(c, out):
    out.mkdir(parents=True, exist_ok=True)
    for name, frames in frames_for(c).items():
        w, h = frames[0].size
        strip = Image.new("RGBA", (w * len(frames), h), (0, 0, 0, 0))
        for i, frame in enumerate(frames):
            strip.paste(frame, (i * w, 0))
        strip.save(out / f"fighter_{name}.png")
    for module in _modules_for(c):
        if hasattr(module, "extra_files"):
            module.extra_files(c, out, STRIPS)


def preview_sheet(c, path, zoom=3):
    """Every animation as a row of frames, on a plain background, for reviewing."""
    frames = frames_for(c)
    cols = max(len(f) for f in frames.values())
    label = 110
    fw, fh = next(iter(frames.values()))[0].size
    cw, ch = fw * zoom, fh * zoom
    out = Image.new("RGBA", (label + cols * (cw + 2), len(frames) * (ch + 2)), (60, 66, 84, 255))
    draw = ImageDraw.Draw(out)
    for row, (name, fs) in enumerate(frames.items()):
        y = row * (ch + 2)
        draw.text((4, y + ch // 2 - 6), name, fill=(240, 240, 240))
        for i, frame in enumerate(fs):
            bg = Image.new("RGBA", frame.size, (90, 100, 120, 255))
            bg.alpha_composite(frame)
            out.paste(bg.resize((cw, ch), Image.NEAREST), (label + i * (cw + 2), y))
    out.save(path)


def main(out_dir, ids, preview=False):
    out = Path(out_dir)
    for cid in ids or list(looks.CHARACTERS):
        write_character(looks.CHARACTERS[cid], out / cid)
        if preview:
            preview_sheet(looks.CHARACTERS[cid], out / f"{cid}_preview.png")
        print(cid)


if __name__ == "__main__":
    args = [a for a in sys.argv[1:] if a != "--preview"]
    main(args[0], args[1:], preview="--preview" in sys.argv)
