"""Preview strip of Henrik's speaker jam for the sprite viewer (the game places the speakers and
draws the sound waves itself, see characters/henrik/speaker.gd and speaker_ability.gd; this
repeats that so the viewer can show it). Drawn at game scale (1 px = 1 game px; sprites at ¾),
one drawing per tick of the whole move: 12 startup, 72 playing, 12 lowering the guitar.
Usage: python3 -I tools/sprite_viewer/henrik_previews.py <project_dir> <out_dir>
  writes <out_dir>/slot_06/speaker_jam_preview.png
"""
import math
import sys
from pathlib import Path

from PIL import Image, ImageDraw

W, H, FEET = 160, 64, (80, 58)
# As in speakers.tres / speaker_blast.tres and SpeakerAbility / Speaker.
STARTUP, JAM, END, FIRST_BEAT, BEAT_EVERY, BLAST, SINK = 12, 72, 12, 6, 18, 4, 8
OFFSET, RISE, STRUM = 26, 4, 4
REACH = 46            # the blast's far edge from the speaker
WOOFER = (0, -8)
WAVE, WAVE_EDGE = (255, 255, 255, 242), (26, 28, 44, 153)
SPEAKER = (24, 32)


def blasting(age):
    return FIRST_BEAT <= age < JAM and (age - FIRST_BEAT) % BEAT_EVERY < BLAST


def drawing(tick):
    """Henrik's down_special drawing on move tick `tick` (SpeakerAbility.drawing())."""
    if tick < STARTUP:
        return 0
    age = tick - STARTUP
    if age >= JAM:
        return 4
    if blasting(age):
        return 3
    return 1 if (age // STRUM) % 2 == 0 else 2


def cell(sheet, i, n):
    fw = sheet.width // n
    c = sheet.crop((i * fw, 0, i * fw + fw, sheet.height))
    return c.resize((fw * 3 // 4, sheet.height * 3 // 4), Image.NEAREST)


def frame(fighter, speaker, tick):
    f = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    age = tick - STARTUP
    if age >= 0:
        sinking = age >= JAM
        shown = 1 - min((age - JAM + 1) / SINK, 1) if sinking else min((age + 1) / RISE, 1)
        pic = cell(speaker, 1 if blasting(age) else 0, 2)
        rows = round(pic.height * shown)
        for side in (-1, 1):
            s = pic if side < 0 else pic.transpose(Image.FLIP_LEFT_RIGHT)
            if rows > 0:
                part = s.crop((0, 0, s.width, rows))
                x = FEET[0] + side * OFFSET - s.width // 2
                f.alpha_composite(part, (x, FEET[1] - rows))
    body = cell(fighter, drawing(tick), 5)
    f.alpha_composite(body, (FEET[0] - body.width // 2, FEET[1] - body.height + 4))
    if age >= 0 and blasting(age):
        d = ImageDraw.Draw(f)
        t = ((age - FIRST_BEAT) % BEAT_EVERY) / BLAST
        for side in (-1, 1):
            cx, cy = FEET[0] + side * OFFSET + WOOFER[0], FEET[1] + WOOFER[1]
            facing = 0 if side > 0 else 180
            for i in range(3):
                r = 6 + (REACH - 6) * min(max(t + i * 0.22, 0), 1) * 0.85
                half = math.degrees(0.75 - i * 0.08)
                box = (cx - r, cy - r, cx + r, cy + r)
                d.arc(box, facing - half, facing + half, fill=WAVE_EDGE, width=3)
                d.arc(box, facing - half, facing + half, fill=WAVE, width=1)
    return f


def main(project, out_dir):
    sprites = Path(project) / "assets/fighters/slot_06"
    fighter = Image.open(sprites / "fighter_down_special.png").convert("RGBA")
    speaker = Image.open(sprites / "speaker.png").convert("RGBA")
    total = STARTUP + JAM + END
    out = Image.new("RGBA", (W * total, H), (0, 0, 0, 0))
    for tick in range(total):
        out.paste(frame(fighter, speaker, tick), (tick * W, 0))
    dest = Path(out_dir) / "slot_06"
    dest.mkdir(parents=True, exist_ok=True)
    out.save(dest / "speaker_jam_preview.png")
    print("speaker jam", total, "drawings")


if __name__ == "__main__":
    main(sys.argv[1], sys.argv[2])
