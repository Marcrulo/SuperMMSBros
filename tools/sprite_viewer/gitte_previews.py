"""Preview strip of Gitte's hand glow for the sprite viewer (the game draws it itself, see
characters/gitte/stance_ability.gd draw(); this repeats that drawing so the viewer can show it).
Every drawing of every animation in order, at her strips' resolution, with the glow on both fists
from hands.json: red (+) on one animation, blue (−) on the next, and so on.
Usage: python3 -I tools/sprite_viewer/gitte_previews.py <project_dir> <out_dir>
  writes <out_dir>/slot_02/gitte_glow_preview.png
"""
import json
import math
import sys
from pathlib import Path

from PIL import Image, ImageDraw

SCALE = 0.75   # strip px → game px
# As StanceAbility: PLUS_GLOW, MINUS_GLOW, GLOW_HALO, GLOW_CORE, GLOW_PULSE, GLOW_PULSE_TICKS.
COLORS = [(255, 74, 61), (74, 168, 255)]
HALO, CORE, PULSE, PULSE_TICKS = 4.0, 2.0, 0.5, 30


def glow_frames(project):
    sprites = Path(project) / "assets/fighters/slot_02"
    hands = json.loads((sprites / "hands.json").read_text())
    frames = []
    tick = 0
    for k, (name, drawings) in enumerate(hands.items()):
        strip = Image.open(sprites / f"fighter_{name}.png").convert("RGBA")
        w, h = strip.width // len(drawings), strip.height
        color = COLORS[k % 2]
        for i, fists in enumerate(drawings):
            frame = strip.crop((i * w, 0, (i + 1) * w, h))
            glow = Image.new("RGBA", frame.size, (0, 0, 0, 0))
            d = ImageDraw.Draw(glow)
            halo = (HALO + PULSE * math.sin(2 * math.pi * (tick % PULSE_TICKS) / PULSE_TICKS)) / SCALE
            for x, y in fists:
                cx, cy = x / SCALE + w / 2, y / SCALE + h
                d.ellipse((cx - halo, cy - halo, cx + halo, cy + halo), fill=color + (89,))
                core = CORE / SCALE
                d.ellipse((cx - core, cy - core, cx + core, cy + core), fill=color + (204,))
            frames.append(Image.alpha_composite(frame, glow))
            tick += 10
    out = Image.new("RGBA", (frames[0].width * len(frames), frames[0].height), (0, 0, 0, 0))
    for i, frame in enumerate(frames):
        out.paste(frame, (i * frame.width, 0))
    return out, len(frames)


if __name__ == "__main__":
    image, count = glow_frames(sys.argv[1])
    target = Path(sys.argv[2]) / "slot_02"
    target.mkdir(parents=True, exist_ok=True)
    image.save(target / "gitte_glow_preview.png")
    print(f"{target / 'gitte_glow_preview.png'}: {count} drawings")
