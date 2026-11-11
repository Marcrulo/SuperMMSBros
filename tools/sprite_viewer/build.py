"""Builds the sprite viewer page: tools/sprite_viewer/template.html with every character's strips
embedded (as data: URIs), so the page works on its own anywhere, e.g. published as an artifact.
Usage: python3 -I tools/sprite_viewer/build.py <strips_dir> <out.html>
  e.g. python3 -I tools/sprite_viewer/build.py super-mms-bros/assets/fighters viewer.html
"""
import base64
import json
import sys
from pathlib import Path

HERE = Path(__file__).resolve().parent
sys.path.insert(0, str(HERE.parent))
import fighter64_looks as looks  # noqa: E402

# Ticks per drawing and looping, as in fighter/fighter_visuals.gd; strike = the drawings shown on
# a move's active frames (docs/specs/art-guide.md, the bold numbers), 0-based.
ANIMS = {
    "idle": ([8, 8, 8, 8], True), "run": ([5] * 6, True), "crouch": ([2, 2], False),
    "jump": ([4, 4], False), "fall": ([6, 6], True), "helpless": ([6, 6], True),
    "shield": ([1], False), "dizzy": ([10, 10], True), "hurt": ([4, 4], True),
    "spot_dodge": ([3, 12, 5], False), "roll": ([6] * 4, False), "air_dodge": ([4, 4], False),
    "ledge": ([12, 12], True), "ledge_climb": ([6, 7, 7], False),
    "jab": ([2, 2, 3, 4, 3], False), "down_tilt": ([3, 2, 3, 4, 3], False),
    "up_tilt": ([3, 2, 4, 4, 4], False), "side_tilt": ([4, 3, 3, 5, 5], False),
    "neutral_air": ([2, 1, 6, 3, 3], False), "forward_air": ([3, 2, 3, 4, 3], False),
    "back_air": ([3, 3, 3, 4, 4], False), "up_air": ([2, 2, 4, 4, 3], False),
    "down_air": ([3, 3, 3, 4, 4], False), "neutral_special_charge": ([6, 6], True),
    "neutral_special": ([3, 4, 5, 5], False), "down_special_dive": ([1], False),
    "down_special": ([5, 5, 6, 6, 6], False), "side_special": ([5, 5, 6, 6], False),
    "up_special": ([4, 12, 1], False),
}
STRIKE = {"jab": [2], "down_tilt": [2], "up_tilt": [2], "side_tilt": [2], "neutral_air": [2],
          "forward_air": [2], "back_air": [2], "up_air": [2], "down_air": [2],
          "neutral_special": [1], "down_special": [2], "up_special": [1]}
NOTES = {
    "side_special": "The projectile appears at the start of drawing 3 (the game draws it).",
    "neutral_special_charge": "The game adds a growing glow on the fists while charging.",
    "shield": "The game draws the shield bubble around the body.",
    "up_special": "Drawing 3 is held while rising.",
    "down_special_dive": "Held for the whole dive.",
    "ledge": "Hanging from the ledge, which is to the right.",
}


def main(strips_dir, out):
    strips_dir = Path(strips_dir)
    data = {"characters": [], "anims": {}, "strips": {}}
    for name, (ticks, loop) in ANIMS.items():
        data["anims"][name] = {"ticks": ticks, "loop": loop, "strike": STRIKE.get(name, []),
                               "note": NOTES.get(name, "")}
    for cid, c in looks.CHARACTERS.items():
        data["characters"].append({"id": cid, "name": c["name"]})
        data["strips"][cid] = {}
        for name in ANIMS:
            png = (strips_dir / cid / f"fighter_{name}.png").read_bytes()
            data["strips"][cid][name] = "data:image/png;base64," + base64.b64encode(png).decode()
    html = (HERE / "template.html").read_text().replace("/*DATA*/null", json.dumps(data))
    Path(out).write_text(html)
    print(f"{out}: {len(html) / 1e6:.1f} MB")


if __name__ == "__main__":
    main(sys.argv[1], sys.argv[2])
