"""Preview strips of Magnus's game-drawn effects for the sprite viewer (the game draws them itself,
see characters/magnus/avatar_ability.gd, fireball.gd, droplet.gd, element_badge.gd; this repeats
that drawing so the viewer can show it). Drawn at game scale (1 px = 1 game px; his sprite at ¾),
112×80 per drawing, his feet at (56, 58).
The Avatar State is not redrawn here: it is joined from real game frames captured by
magnus_avatar_capture.gd (pass their folder as <avatar_frames_dir>).
Usage: python3 -I tools/sprite_viewer/magnus_previews.py <project_dir> <out_dir> <avatar_frames_dir>
  writes <out_dir>/slot_14/{avatar,earth,wind,shots,badge}_preview.png
"""
import math
import sys
from pathlib import Path

from PIL import Image, ImageDraw

W, H, FEET = 112, 80, (56, 58)
MIDDLE = (FEET[0], FEET[1] - 16)
OUTLINE = (26, 28, 44)
COLORS = [(77, 153, 255), (255, 128, 38), (230, 240, 255), (128, 173, 71)]   # water fire air earth
FLAME_CORE = (255, 224, 89)
ROCK, ROCK_LIGHT = (133, 112, 92), (168, 148, 122)


def strip(frames):
    out = Image.new("RGBA", (W * len(frames), H), (0, 0, 0, 0))
    for i, f in enumerate(frames):
        out.paste(f, (i * W, 0))
    return out


def body(sheet, drawing, drawings):
    """One drawing of a 64 px strip at ¾ on a blank canvas, feet at FEET."""
    fw = sheet.width // drawings
    cell = sheet.crop((drawing * fw, 0, drawing * fw + fw, sheet.height))
    cell = cell.resize((fw * 3 // 4, sheet.height * 3 // 4), Image.NEAREST)
    canvas = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    canvas.alpha_composite(cell, (FEET[0] - cell.width // 2, FEET[1] - cell.height))
    return canvas


def circle(d, at, r, color):
    d.ellipse((at[0] - r, at[1] - r, at[0] + r, at[1] + r), fill=color)


def earth_frames(sheet):
    """His down special (10 / 6 / 12): the rocks jut up during the 6 active frames."""
    ticks = [5, 5, 6, 6, 6]
    frames = []
    for t in range(1, 29):
        i, left = 0, t
        while i < len(ticks) - 1 and left > ticks[i]:
            left -= ticks[i]
            i += 1
        f = body(sheet, i, 5)
        if 10 < t <= 16:
            d = ImageDraw.Draw(f)
            rise = min((t - 10) / 3.0, 1.0)
            for side in (-1, 1):
                for x0, half, height in ((12, 5, 10), (21, 6, 14), (30, 4, 8)):
                    x, top = FEET[0] + x0 * side, FEET[1] - height * rise
                    d.polygon([(x - half - 1, FEET[1] + 1), (x - 1, top - 1), (x + half + 1, FEET[1] + 1)], fill=OUTLINE)
                    d.polygon([(x - half, FEET[1]), (x - 1, top), (x + half, FEET[1])], fill=ROCK)
                    d.line([(x - 1, top + 1), (x - half * 0.5, FEET[1] - 1)], fill=ROCK_LIGHT)
        frames.append(f)
    return frames


def wind_frames(sheet):
    """His up special's burst (frames 5–16), drawn in place (he rises in the game)."""
    frames = []
    for t in range(1, 21):
        f = body(sheet, 0 if t <= 4 else (1 if t <= 16 else 2), 3)
        if 4 < t <= 16:
            d = ImageDraw.Draw(f)
            k = t - 4
            for i in range(3):
                r = 12 + i * 7 + k * 0.8
                start = math.degrees(k * 0.35 + i * 2 * math.pi / 3)
                box = (MIDDLE[0] - r, MIDDLE[1] - r, MIDDLE[0] + r, MIDDLE[1] + r)
                d.arc(box, start, start + math.degrees(1.6), fill=(26, 28, 44, 128), width=3)
                d.arc(box, start, start + math.degrees(1.6), fill=(255, 255, 255), width=1)
        frames.append(f)
    return frames


def shots_frames(side):
    """His side special pose with a fireball, then a water stream, flying out."""
    frames = []
    for t in range(24):
        f = body(side, 2, 4)
        d = ImageDraw.Draw(f)
        x, y = FEET[0] + 12 + t * 4.3 * 0.5, FEET[1] - 14
        if t < 12:
            flick = (t // 3) % 2
            d.polygon([(x - 14 - flick * 2, y - 1 + flick), (x - 2, y - 5), (x - 2, y + 5)], fill=(219, 56, 26))
            circle(d, (x, y), 6, (64, 15, 10))
            circle(d, (x, y), 5, (219, 56, 26))
            circle(d, (x + 1, y), 4 - flick * 0.5, (250, 133, 31))
            circle(d, (x + 1.5, y - 0.5), 2, FLAME_CORE)
        else:
            for k in range((t - 12) // 2 + 1):
                dx = FEET[0] + 12 + (t - 12 - k * 2) * 5
                circle(d, (dx, y), 3, OUTLINE)
                d.polygon([(dx - 6, y), (dx - 1, y - 3), (dx - 1, y + 3)], fill=OUTLINE)
                circle(d, (dx, y), 2, COLORS[0])
                d.polygon([(dx - 5, y), (dx - 1, y - 2), (dx - 1, y + 2)], fill=COLORS[0])
                d.point((dx, y - 1.5), fill=(199, 235, 255))
        frames.append(f)
    return frames


ICON = {0: [(2, 0, 1, 1), (1, 1, 3, 1), (0, 2, 5, 2), (1, 4, 3, 1)],
        1: [(2, 0, 1, 1), (1, 1, 2, 1), (1, 2, 3, 1), (0, 3, 5, 2)],
        2: [(0, 1, 4, 1), (3, 2, 1, 1), (1, 3, 4, 1)],
        3: [(0, 1, 5, 4)]}


def badge_frames(head):
    """A mock-up of his player card (no text): the elements light one by one, then all flash
    (the Avatar State)."""
    frames = []
    for step in range(5 + 8):
        f = Image.new("RGBA", (W, H), (0, 0, 0, 0))
        d = ImageDraw.Draw(f)
        x0, y0 = 8, 25
        d.rectangle((x0, y0, x0 + 95, y0 + 29), fill=(26, 28, 44), outline=(219, 74, 92))
        d.rectangle((x0 + 4, y0 + 4, x0 + 25, y0 + 25), fill=(120, 40, 50))
        f.alpha_composite(head, (x0 + 5, y0 + 5))
        for e in range(4):
            ax, ay = x0 + 82 + (e % 2) * 6, y0 + 15 + (e // 2) * 6
            d.rectangle((ax, ay, ax + 4, ay + 4), fill=(26, 28, 44))
            if step >= 5:
                on = step % 2 == 0
                c = tuple(min(255, int(v + (255 - v) * (0.5 if on else 0))) for v in COLORS[e])
            else:
                c = COLORS[e] if e < step else (59, 64, 84)
            for rx, ry, rw, rh in ICON[e]:
                d.rectangle((ax + rx, ay + ry, ax + rx + rw - 1, ay + ry + rh - 1), fill=c)
        frames.append(f)
    return frames


def captured(frames_dir):
    """The game frames magnus_avatar_capture.gd saved, in order."""
    return [Image.open(f).convert("RGBA") for f in sorted(Path(frames_dir).glob("f*.png"))]


def main(project, out_dir, avatar_frames_dir):
    sprites = Path(project) / "assets/fighters/slot_14"
    out = Path(out_dir) / "slot_14"
    out.mkdir(parents=True, exist_ok=True)
    load = lambda name: Image.open(sprites / name).convert("RGBA")
    strip(captured(avatar_frames_dir)).save(out / "avatar_preview.png")
    strip(earth_frames(load("fighter_down_special.png"))).save(out / "earth_preview.png")
    strip(wind_frames(load("fighter_up_special.png"))).save(out / "wind_preview.png")
    strip(shots_frames(load("fighter_side_special.png"))).save(out / "shots_preview.png")
    idle = load("fighter_idle.png")
    head = idle.crop((23, 20, 43, 40))
    strip(badge_frames(head)).save(out / "badge_preview.png")


if __name__ == "__main__":
    main(sys.argv[1], sys.argv[2], sys.argv[3])
