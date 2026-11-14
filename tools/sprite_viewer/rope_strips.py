"""Preview strips of Sjippepigen's spinning ropes for the sprite viewer (the game draws the ropes
itself, see FighterVisuals._draw_ropes; this repeats that drawing so the viewer can show it).
Reads the numbers from her ropes.tres. Drawn at game scale (1 px = 1 game px; her sprite at ¾),
112×80 per drawing, her feet at (56, 58), one drawing per tick for one full turn.
Usage: python3 -I tools/sprite_viewer/rope_strips.py <project_dir> <out_dir>
  writes <out_dir>/slot_12/rope_preview_short.png and rope_preview_long.png
"""
import json
import math
import re
import sys
from pathlib import Path

from PIL import Image, ImageDraw

W, H, FEET = 112, 80, (56, 58)
COLORS = [(220, 64, 64), (72, 124, 220), (240, 200, 64)]
DARK = (26, 28, 44)
LAG, TRAIL = 0.6, 0.9          # as FighterVisuals.ROPE_LAG / ROPE_TRAIL
IDLE_TICKS = 8                 # idle: 4 drawings of 8 ticks


def tres_values(path):
    text = Path(path).read_text()
    vec = lambda k: tuple(float(v) for v in re.search(k + r" = Vector2\(([^)]*)\)", text).group(1).split(","))
    num = lambda k: float(re.search(k + r" = ([0-9.]+)", text).group(1))
    return dict(count=int(num("count")), center=vec("center"),
                short=(vec("short_radius"), int(num("short_period"))),
                long=(vec("long_radius"), int(num("long_period"))))


def strip(project, length, frenzy=False, charge=False):
    """One turn of the ropes at `length` while she skips (idle). `frenzy`: twice as fast and lit up
    (FighterVisuals: color.lightened(0.45)). `charge`: her frenzy charge instead: 64 ticks of the
    charge drawings, the ropes lighting up and the meter above her head filling (as
    FighterVisuals._draw_frenzy_charge: dim before 20 ticks, bright after, flashing when full).
    Returns (strip, drawings)."""
    r = tres_values(Path(project) / "fighter/moves/sjippepigen/ropes.tres")
    (rx, ry), period = r[length]
    if frenzy:
        period //= 2
    total = 64 if charge else period
    anim = "neutral_special_charge" if charge else "idle"
    body_strip = Image.open(Path(project) / f"assets/fighters/slot_12/fighter_{anim}.png").convert("RGBA")
    drawings, per = (2, 6) if charge else (4, IDLE_TICKS)
    cx, cy = r["center"]
    hands_of = json.loads((Path(project) / "assets/fighters/slot_12/hands.json").read_text())[anim]
    colors = COLORS
    m = re.search(r"rope_colors = PackedColorArray\(([^)]*)\)", (Path(project) / "fighter/characters/slot_12.tres").read_text())
    if m:
        v = [float(x) for x in m.group(1).split(",")]
        colors = [tuple(round(c * 255) for c in v[k:k + 3]) for k in range(0, len(v), 4)]
    light = lambda c, k: tuple(round(x + (255 - x) * k) for x in c)
    fw = body_strip.width // drawings
    out = Image.new("RGBA", (W * total, H), (0, 0, 0, 0))
    for tick in range(total):
        frame = Image.new("RGBA", (W, H), (0, 0, 0, 0))
        n = (tick // per) % drawings
        body = body_strip.crop((n * fw, 0, n * fw + fw, body_strip.height))
        body = body.resize((round(fw * 0.75), round(body_strip.height * 0.75)), Image.NEAREST)
        frame.alpha_composite(body, (FEET[0] - body.width // 2, FEET[1] - body.height))
        d = ImageDraw.Draw(frame)
        amount = min((tick + 1) / 60, 1.0) if charge else 0.0

        def tip(i, ahead=0.0):
            a = 2 * math.pi * (tick / period + i / r["count"]) + ahead
            return (FEET[0] + cx + math.sin(a) * rx, FEET[1] + cy - math.cos(a) * ry)

        drawing = hands_of[n]
        for i in range(r["count"]):
            color = colors[i % len(colors)]
            if frenzy:
                color = light(color, 0.45)
            elif charge:
                color = light(color, 0.45 * amount)
            streak = [tip(i, -TRAIL * (1 - k / 6)) for k in range(7)]
            d.line(streak, fill=color + (90,), width=2)
            t0, behind = tip(i), tip(i, -LAG)
            a = (FEET[0] + drawing[i][0][0], FEET[1] + drawing[i][0][1])
            b = (FEET[0] + drawing[i][1][0], FEET[1] + drawing[i][1][1])
            # As FighterVisuals._draw_ropes / rope_loop_point: a rounded loop from hand a out
            # round the tip to hand b, bowed back.
            lag = ((behind[0] - t0[0]) * 0.4, (behind[1] - t0[1]) * 0.4)
            mid = ((a[0] + b[0]) / 2, (a[1] + b[1]) / 2)
            reach_v = (t0[0] - mid[0], t0[1] - mid[1])
            ln = math.hypot(*reach_v) or 1
            across = (reach_v[1] / ln, -reach_v[0] / ln)          # Vector2.orthogonal(), normalized
            if (a[0] - b[0]) * across[0] + (a[1] - b[1]) * across[1] < 0:
                across = (-across[0], -across[1])
            pts = []
            for k in range(21):
                u = math.pi * k / 20
                f = (1 - math.cos(u)) / 2
                sw = ln * 0.5 * math.sin(u) * math.cos(u)
                s2 = math.sin(u) ** 2
                pts.append((a[0] + (b[0] - a[0]) * f + reach_v[0] * math.sin(u) + across[0] * sw + lag[0] * s2,
                            a[1] + (b[1] - a[1]) * f + reach_v[1] * math.sin(u) + across[1] * sw + lag[1] * s2))
            d.line(pts, fill=DARK + (255,), width=3)
            d.line(pts, fill=color + (255,), width=1)
        if charge:
            mx, my, mr = FEET[0], FEET[1] - 44, 5
            box = [mx - mr, my - mr, mx + mr, my + mr]
            d.ellipse(box, outline=DARK + (255,), width=3)
            if amount >= 1.0 and (tick // 4) % 2 == 0:
                mc = (255, 255, 255, 255)
            elif tick + 1 >= 20:
                mc = light(colors[0], 0.5) + (255,)
            else:
                mc = tuple(round(x * 0.8) for x in colors[0]) + (153,)
            d.arc(box, -90, -90 + 360 * amount, fill=mc, width=2)
        out.paste(frame, (tick * W, 0))
    return out, total


def meter_strip(project):
    """A mock of her player card's frenzy meter (ui/frenzy_bar.gd): the card (96×30, dark, a border
    in the player color, her head on the portrait) with the 62×4 bar at (30, 25) filling up over 48
    drawings, then 16 drawings full and flashing (8 on, 8 off). Not the real card's text."""
    m = re.search(r"rope_colors = PackedColorArray\(([^)]*)\)", (Path(project) / "fighter/characters/slot_12.tres").read_text())
    v = [float(x) for x in m.group(1).split(",")]
    green = tuple(round(c * 255) for c in v[:3])
    lit = tuple(round(c + (255 - c) * 0.6) for c in green)
    idle = Image.open(Path(project) / "assets/fighters/slot_12/fighter_idle.png").convert("RGBA")
    head = idle.crop((23, 20, 43, 40))                      # PlayerCard.HEAD_REGIONS[64]
    total = 64
    out = Image.new("RGBA", (W * total, H), (0, 0, 0, 0))
    for n in range(total):
        frame = Image.new("RGBA", (W, H), (0, 0, 0, 0))
        d = ImageDraw.Draw(frame)
        x0, y0 = (W - 96) // 2, H - 30 - 8
        d.rectangle([x0, y0, x0 + 95, y0 + 29], fill=(38, 43, 68, 255), outline=(239, 125, 87, 255))
        d.rectangle([x0 + 4, y0 + 4, x0 + 25, y0 + 25], fill=(120, 60, 50, 255))
        frame.alpha_composite(head, (x0 + 5, y0 + 5))
        value = min(n / 47, 1.0)
        bx, by = x0 + 30, y0 + 25
        d.rectangle([bx, by, bx + 61, by + 3], fill=(26, 28, 44, 255))
        if value > 0:
            fill = lit if value >= 1.0 and ((n - 48) // 8) % 2 == 0 else green
            d.rectangle([bx + 1, by + 1, bx + 1 + round(60 * value) - 1, by + 2], fill=fill + (255,))
        out.paste(frame, (n * W, 0))
    return out


def main(project, out_dir):
    out = Path(out_dir) / "slot_12"
    out.mkdir(parents=True, exist_ok=True)
    for length in ("short", "long"):
        img, period = strip(project, length)
        img.save(out / f"rope_preview_{length}.png")
        print(length, period, "drawings")
    img, period = strip(project, "short", frenzy=True)
    img.save(out / "rope_preview_frenzy.png")
    print("frenzy", period, "drawings")
    img, period = strip(project, "short", charge=True)
    img.save(out / "rope_preview_charge.png")
    print("charge", period, "drawings")
    meter_strip(project).save(out / "frenzy_meter_preview.png")
    print("meter 64 drawings")


if __name__ == "__main__":
    main(sys.argv[1], sys.argv[2])
