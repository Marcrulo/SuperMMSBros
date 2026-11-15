"""Pia's banner at game scale for the sprite viewer: the drawings timed like the game, with the
range ring the game draws (radius 100 round her center, while the banner is up), every 2 ticks.
Usage: python3 -I tools/sprite_viewer/pia_banner_preview.py <fighters_dir> <previews_dir>
  writes <previews_dir>/slot_01/pia_banner_preview.png
"""
import sys
from pathlib import Path

from PIL import Image, ImageDraw

RAISE, HELD_UNTIL, TOTAL, WAVE = 8, 98, 108, 8      # characters/pia/moves (banner_ability.gd)
RADIUS, CENTER_DY = 100, -12                        # BannerData.radius; the fighter's body center
RING = (214, 34, 41, 84)                            # BannerAbility.RING_COLOR
SCALE = 0.75                                        # 64 px frames drawn at 48
W, H, FEET = 216, 176, (108, 150)
FLOOR = (96, 104, 112, 255)


def drawing(tick):
    if tick <= RAISE:
        return 0
    if tick > HELD_UNTIL:
        return 3
    return 1 + ((tick - RAISE - 1) // WAVE) % 2


def main(fighters_dir, previews_dir):
    strip = Image.open(Path(fighters_dir) / "slot_01" / "fighter_banner.png").convert("RGBA")
    n = strip.height
    size = round(n * SCALE)
    frames = []
    for tick in range(1, TOTAL + 1, 2):
        frame = Image.new("RGBA", (W, H), (0, 0, 0, 0))
        d = ImageDraw.Draw(frame)
        d.rectangle((0, FEET[1], W, FEET[1] + 2), fill=FLOOR)
        if RAISE < tick <= HELD_UNTIL:
            ring = Image.new("RGBA", (W, H), (0, 0, 0, 0))
            cx, cy = FEET[0], FEET[1] + CENTER_DY
            ImageDraw.Draw(ring).ellipse((cx - RADIUS, cy - RADIUS, cx + RADIUS, cy + RADIUS),
                                         outline=RING, width=1)
            frame.alpha_composite(ring)
        i = drawing(tick)
        sprite = strip.crop((i * n, 0, i * n + n, n)).resize((size, size), Image.NEAREST)
        frame.alpha_composite(sprite, (FEET[0] - size // 2, FEET[1] - size))
        frames.append(frame)
    out = Image.new("RGBA", (W * len(frames), H), (0, 0, 0, 0))
    for k, frame in enumerate(frames):
        out.paste(frame, (k * W, 0))
    target = Path(previews_dir) / "slot_01"
    target.mkdir(parents=True, exist_ok=True)
    out.save(target / "pia_banner_preview.png")
    print(len(frames), "drawings")


if __name__ == "__main__":
    main(sys.argv[1], sys.argv[2])
