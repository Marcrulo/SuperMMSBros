"""Builds the sprite viewer page: tools/sprite_viewer/template.html with every character's strips
embedded (as data: URIs), so the page works on its own anywhere, e.g. published as an artifact.
Usage: python3 -I tools/sprite_viewer/build.py <strips_dir> <out.html> [previews_dir]
  e.g. python3 -I tools/sprite_viewer/build.py super-mms-bros/assets/fighters viewer.html
"""
import base64
import json
import sys
from pathlib import Path

from PIL import Image

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
# Pictures a character has besides its strips, shown as extra tiles: file, ticks per drawing, loop.
EXTRAS = {
    "rope_preview_short.png": ("ropes (short)", [1] * 30, True,
                               "Preview at game scale: the game draws her ropes itself. Short ropes: one turn (30 ticks), 3 % a hit; only the tips hurt."),
    "rope_preview_long.png": ("ropes (long)", [1] * 48, True,
                              "Preview at game scale: long ropes, one turn (48 ticks), 2 % a hit. Down special switches short ↔ long."),
    "rope_preview_charge.png": ("frenzy charge", [1] * 64, False,
                                "Preview at game scale: holding B. The ring above her head fills over 1 s (dim until 20 ticks: let go earlier and nothing happens), flashing when full; her ropes light up as it fills."),
    "frenzy_meter_preview.png": ("frenzy meter", [6] * 48 + [1] * 16, False,
                                 "Mock-up of her player card (no text): the frenzy meter refills over 12 s (sped up here), then flashes when full: B can be charged only then."),
    "rope_preview_frenzy.png": ("ropes (frenzy)", [1] * 15, True,
                                "Preview at game scale: her charged neutral special: for 2 seconds the ropes spin twice as fast, lit up; their hits deal no damage but knock back hard."),
    "fighter_down_special_left.png": ("down special (facing left)", [5, 5, 6, 6, 6], False,
                                      "Drawn for facing left so the stop sign's lettering isn't mirrored."),
    "fighter_grab_throw.png": ("throw", [3, 5, 6, 4, 12, 10], False,
                               "Mads's command-grab throw (the victim is drawn by the game, in his hands). He turns round on drawing 4."),
    "hand.png": ("summoned hand", [60, 13], True,
                 "Hovers (open) for 60 ticks, then slams (flat). The game adds the shadow and bob."),
    "projectile.png": ("projectile", [4, 4, 4], True, "Spins while flying."),
    "peel.png": ("banana peel", [60], True, "Lies on the floor until someone slips on it."),
    "burst.png": ("light burst", [3, 3, 3, 3], False,
                  "Cross smash: drawn on the floor from where the cross hits, from the first active frame."),
    "dust.png": ("flop dust", [3, 3, 3, 3], False,
                 "Belly flop: drawn on the floor on both sides of her (mirrored), from the landing tick."),
    "pyramid.png": ("pyramid", [60], True,
                    "Rises out of the floor under her (only the part above the floor shows), then sinks back."),
}
NOTES = {
    "side_special": "The projectile appears at the start of drawing 3 (the game draws it).",
    "neutral_special_charge": "The game adds a growing glow on the fists while charging.",
    "shield": "The game draws the shield bubble around the body.",
    "up_special": "Drawing 3 is held while rising.",
    "down_special_dive": "Held for the whole dive.",
    "ledge": "Hanging from the ledge, which is to the right.",
}


def main(strips_dir, out, previews_dir=None):
    strips_dir = Path(strips_dir)
    data = {"characters": [], "anims": {}, "strips": {}, "extras": {}, "view": [64, 64]}
    for name, (ticks, loop) in ANIMS.items():
        data["anims"][name] = {"ticks": ticks, "loop": loop, "strike": STRIKE.get(name, []),
                               "note": NOTES.get(name, "")}
    for cid, c in looks.CHARACTERS.items():
        data["characters"].append({"id": cid, "name": c["name"]})
        data["strips"][cid] = {}
        for name, (ticks, _) in ANIMS.items():
            path = strips_dir / cid / f"fighter_{name}.png"
            png = path.read_bytes()
            data["strips"][cid][name] = "data:image/png;base64," + base64.b64encode(png).decode()
            with Image.open(path) as img:
                # The view fits the biggest frame (a character with a weapon has a bigger canvas).
                data["view"] = [max(data["view"][0], img.width // len(ticks)),
                                max(data["view"][1], img.height)]
        for file, (title, ticks, loop, note) in EXTRAS.items():
            path = strips_dir / cid / file
            if not path.exists() and previews_dir:
                path = Path(previews_dir) / cid / file
            if path.exists():
                data["extras"].setdefault(cid, {})[title] = {
                    "src": "data:image/png;base64," + base64.b64encode(path.read_bytes()).decode(),
                    "ticks": ticks, "loop": loop, "strike": [], "note": note}
    html = (HERE / "template.html").read_text().replace("/*DATA*/null", json.dumps(data))
    Path(out).write_text(html)
    print(f"{out}: {len(html) / 1e6:.1f} MB")


if __name__ == "__main__":
    # Optional 3rd argument: a folder of preview pictures (made by rope_strips.py) not in the game.
    main(sys.argv[1], sys.argv[2], sys.argv[3] if len(sys.argv) > 3 else None)
