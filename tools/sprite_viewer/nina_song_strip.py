"""Joins the frames of nina_song_capture.gd into one strip for the sprite viewer.
Usage: python3 -I tools/sprite_viewer/nina_song_strip.py <frames_dir> <previews_dir>
  writes <previews_dir>/slot_04/nina_song_preview.png
"""
import sys
from pathlib import Path

from PIL import Image


def main(frames_dir, previews_dir):
    frames = sorted(Path(frames_dir).glob("f*.png"))
    first = Image.open(frames[0])
    strip = Image.new("RGBA", (first.width * len(frames), first.height))
    for i, f in enumerate(frames):
        strip.paste(Image.open(f).convert("RGBA"), (i * first.width, 0))
    out = Path(previews_dir) / "slot_04"
    out.mkdir(parents=True, exist_ok=True)
    strip.save(out / "nina_song_preview.png")
    print(len(frames), "drawings")


if __name__ == "__main__":
    main(sys.argv[1], sys.argv[2])
