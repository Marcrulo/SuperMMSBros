"""Generates the pause menu's mute button icons (docs/specs/match-and-stage.md#pause).

Pixel art, 18x12, on a transparent background (the button draws its own box):
  icon_music.png - a speaker with a music note
  icon_sfx.png   - a speaker with a spiky "bang" burst
  icon_*_off.png - muted: the same icon dimmed, with a red cross on top
Usage: python3 -I tools/gen_ui_icons.py super-mms-bros/assets/ui [--preview]
"""
import sys
from pathlib import Path

from PIL import Image

W, H = 18, 12
LIGHT = (244, 244, 244, 255)     # the game's text white
BANG = (255, 205, 117, 255)      # the burst's middle (the viewer's accent yellow)
RED = (240, 82, 79, 255)         # the HUD's high-damage red

SPEAKER = [
    "..................",
    ".....#............",
    "....##............",
    "...###............",
    "######............",
    "######............",
    "######............",
    "######............",
    "...###............",
    "....##............",
    ".....#............",
    "..................",
]

NOTE = [
    "...........#......",
    "...........##.....",
    "...........#.#....",
    "...........#..#...",
    "...........#..#...",
    "...........#.#....",
    "...........#......",
    ".........###......",
    "........####......",
    "........####......",
    ".........##.......",
    "..................",
]

CROSS = [
    "..................",
    "....##......##....",
    ".....##....##.....",
    "......##..##......",
    ".......####.......",
    "........##........",
    ".......####.......",
    "......##..##......",
    ".....##....##.....",
    "....##......##....",
    "...##........##...",
    "..................",
]
DIMMING = 0.4  # muted icons keep this much of each colour's brightness


# A comic "bang" (like a cartoon hit burst): uneven spikes in white round a yellow middle (o).
BURST = [
    ".......#....#.....",
    ".......##...#..#..",
    "........##.##.##..",
    "........#######...",
    ".......####ooo###.",
    "........##ooooo###",
    ".........#ooooo#..",
    "........##ooooo##.",
    ".......####ooo###.",
    ".........#######..",
    ".........##.#.##..",
    "........#...#...#.",
]


def burst():
    out = grid(BURST, LIGHT)
    out.update({(x, y): BANG for y, row in enumerate(BURST) for x, ch in enumerate(row) if ch == "o"})
    return out


def grid(rows, color):
    return {(x, y): color for y, row in enumerate(rows) for x, ch in enumerate(row) if ch == "#"}


def icon(*layers):
    image = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    for layer in layers:
        for (x, y), color in layer.items():
            image.putpixel((x, y), color)
    return image


def dimmed(*layers):
    out = {}
    for layer in layers:
        for xy, (r, g, b, a) in layer.items():
            out[xy] = (round(r * DIMMING), round(g * DIMMING), round(b * DIMMING), a)
    return out


def main():
    out = Path(sys.argv[1])
    out.mkdir(parents=True, exist_ok=True)
    icons = {
        "icon_music": icon(grid(SPEAKER, LIGHT), grid(NOTE, LIGHT)),
        "icon_music_off": icon(dimmed(grid(SPEAKER, LIGHT), grid(NOTE, LIGHT)), grid(CROSS, RED)),
        "icon_sfx": icon(grid(SPEAKER, LIGHT), burst()),
        "icon_sfx_off": icon(dimmed(grid(SPEAKER, LIGHT), burst()), grid(CROSS, RED)),
    }
    for name, image in icons.items():
        image.save(out / f"{name}.png")
    if "--preview" in sys.argv:
        z = 12
        sheet = Image.new("RGBA", (len(icons) * (W + 4) * z, (H + 4) * z), (51, 60, 87, 255))
        for i, image in enumerate(icons.values()):
            sheet.alpha_composite(image.resize((W * z, H * z), Image.NEAREST), (i * (W + 4) * z + 2 * z, 2 * z))
        sheet.save(out.parent / "ui_icons_preview.png")


if __name__ == "__main__":
    main()
