"""Preview strip of Gitte's hand glow for the sprite viewer (the game draws it itself, see
characters/gitte/stance_ability.gd draw(); this repeats that drawing so the viewer can show it).
Every drawing of every animation in order, at her strips' resolution, with the glow on both fists
from hands.json: red (+) on one animation, blue (−) on the next, then orange (÷), green (×), and so on.
Usage: python3 -I tools/sprite_viewer/gitte_previews.py <project_dir> <out_dir>
  writes <out_dir>/slot_02/gitte_glow_preview.png and gitte_popup_preview.png
"""
import json
import math
import sys
from pathlib import Path

from PIL import Image, ImageDraw

SCALE = 0.75   # strip px → game px
# As StanceAbility: PLUS_GLOW, MINUS_GLOW, GLOW_HALO, GLOW_CORE, GLOW_PULSE, GLOW_PULSE_TICKS.
COLORS = [(255, 74, 61), (74, 168, 255), (255, 154, 61), (95, 211, 95)]
HALO, CORE, PULSE, PULSE_TICKS = 4.0, 2.0, 0.5, 30


def glow_frames(project):
    sprites = Path(project) / "assets/fighters/slot_02"
    hands = json.loads((sprites / "hands.json").read_text())
    frames = []
    tick = 0
    for k, (name, drawings) in enumerate(hands.items()):
        strip = Image.open(sprites / f"fighter_{name}.png").convert("RGBA")
        w, h = strip.width // len(drawings), strip.height
        color = COLORS[k % 4]
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


# The switch pop-up (StanceAbility._draw_popup): POPUP_TICKS, POPUP_GROW, POPUP_FADE, POPUP_RISE,
# POPUP_UNIT, POPUP_HEIGHT; the sizes ÷ and × draw her at; the badge's sign grids (StanceBadge).
POPUP = dict(ticks=45, grow=6, fade=12, rise=8.0, unit=2.0, height=34.0)
BACKGROUND = (26, 28, 44)
SIZES = [1.0, 1.0, 0.75, 1.25]
SIGNS = [[(2, 4, 5, 1), (4, 2, 1, 5)],
         [(2, 4, 5, 1)],
         [(2, 4, 5, 1), (4, 2, 1, 1), (4, 6, 1, 1)],
         [(2 + i, 2 + i, 1, 1) for i in range(5)] + [(6 - i, 2 + i, 1, 1) for i in range(5)]]
PAD = 56   # extra room above the 112×80 frame


def popup_frames(project):
    """One stance after the other: her idle pose, and the icon popping up over her head, every
    3 ticks of its 45."""
    strip = Image.open(Path(project) / "assets/fighters/slot_02/fighter_idle.png").convert("RGBA")
    w, h = strip.width // 4, strip.height
    idle = strip.crop((0, 0, w, h))
    frames = []
    for stance, color in enumerate(COLORS):
        s = SIZES[stance]
        for age in range(0, POPUP["ticks"], 3):
            frame = Image.new("RGBA", (w, h + PAD), (0, 0, 0, 0))
            body = idle.resize((round(w * s), round(h * s)), Image.NEAREST)
            frame.paste(body, ((w - body.width) // 2, h + PAD - body.height), body)
            grow = min((age + 1) / POPUP["grow"], 1.0)
            pop = (1 + 0.3 * math.sin(grow * math.pi)) * grow
            alpha = min((POPUP["ticks"] - age) / POPUP["fade"], 1.0)
            unit = POPUP["unit"] * pop / SCALE        # game px → strip px
            side = 9 * unit
            rise = POPUP["rise"] * age / POPUP["ticks"]
            cy = h + PAD - (POPUP["height"] * s + rise) / SCALE - side / 2
            x0, y0 = w / 2 - side / 2, cy - side / 2
            layer = Image.new("RGBA", frame.size, (0, 0, 0, 0))
            d = ImageDraw.Draw(layer)
            a = round(255 * alpha)
            d.rectangle((x0, y0, x0 + max(side - 1, 1), y0 + max(side - 1, 1)),
                        fill=BACKGROUND + (a,), outline=color + (a,), width=max(1, round(unit)))
            for x, y, rw, rh in SIGNS[stance]:
                sx, sy = x0 + x * unit, y0 + y * unit
                d.rectangle((sx, sy, max(sx, sx + rw * unit - 1), max(sy, sy + rh * unit - 1)),
                            fill=color + (a,))
            frames.append(Image.alpha_composite(frame, layer))
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
    image, count = popup_frames(sys.argv[1])
    image.save(target / "gitte_popup_preview.png")
    print(f"{target / 'gitte_popup_preview.png'}: {count} drawings")
