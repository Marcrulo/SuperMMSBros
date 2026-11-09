"""An animated preview of one character's strips: every animation in a grid, playing at its
game timing (ticks per drawing from docs/specs/art-guide.md; 60 ticks per second).
Usage: python3 -I tools/preview_fighter_gif.py <strips_dir> <out.gif> [frame_size] [zoom]
"""
import sys
from pathlib import Path

from PIL import Image, ImageDraw

# Ticks per drawing; a non-looping animation holds its last drawing, then restarts.
TIMING = {
    "idle": [8, 8, 8, 8], "run": [5] * 6, "crouch": [2, 30], "jump": [4, 30], "fall": [6, 6],
    "helpless": [6, 6], "shield": [30], "dizzy": [10, 10], "hurt": [4, 4],
    "spot_dodge": [3, 12, 5], "roll": [6] * 4, "air_dodge": [4, 30], "ledge": [12, 12],
    "ledge_climb": [6, 7, 7], "jab": [2, 2, 3, 4, 3], "down_tilt": [3, 2, 3, 4, 3],
    "up_tilt": [3, 2, 4, 4, 4], "side_tilt": [4, 3, 3, 5, 5], "neutral_air": [2, 1, 6, 3, 3],
    "forward_air": [3, 2, 3, 4, 3], "back_air": [3, 3, 3, 4, 4], "up_air": [2, 2, 4, 4, 3],
    "down_air": [3, 3, 3, 4, 4], "neutral_special_charge": [6, 6],
    "neutral_special": [3, 4, 5, 5], "down_special_dive": [30], "down_special": [5, 5, 6, 6, 6],
    "side_special": [5, 5, 6, 6], "up_special": [4, 12, 20],
}
PAUSE = 12   # ticks between repeats of a one-shot move


def main(strips_dir, out, size=64, zoom=3):
    strips_dir = Path(strips_dir)
    anims = {}
    for name, ticks in TIMING.items():
        strip = Image.open(strips_dir / f"fighter_{name}.png").convert("RGBA")
        frames = [strip.crop((i * size, 0, (i + 1) * size, size)) for i in range(len(ticks))]
        anims[name] = (frames, ticks)
    cols, cell, label = 6, size * zoom, 12
    rows = (len(anims) + cols - 1) // cols
    total = 120
    out_frames = []
    for t in range(0, total, 2):
        img = Image.new("RGB", (cols * cell, rows * (cell + label)), (60, 66, 84))
        draw = ImageDraw.Draw(img)
        for i, (name, (frames, ticks)) in enumerate(anims.items()):
            cycle = sum(ticks) + PAUSE
            tt = t % cycle
            idx = len(ticks) - 1
            acc = 0
            for j, n in enumerate(ticks):
                acc += n
                if tt < acc:
                    idx = j
                    break
            x, y = (i % cols) * cell, (i // cols) * (cell + label)
            bg = Image.new("RGBA", (size, size), (90, 100, 120, 255))
            bg.alpha_composite(frames[idx])
            img.paste(bg.resize((cell, cell), Image.NEAREST).convert("RGB"), (x, y + label))
            draw.text((x + 3, y), name, fill=(235, 235, 235))
        out_frames.append(img)
    out_frames[0].save(out, save_all=True, append_images=out_frames[1:], duration=33, loop=0)


if __name__ == "__main__":
    args = sys.argv[1:]
    main(args[0], args[1], *(int(a) for a in args[2:]))
