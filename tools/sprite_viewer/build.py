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
    "avatar_preview.png": ("Avatar State", [1] * 120, True,
                           "Preview at game scale: Magnus's Avatar State. 1 s frozen (the rise) while the four elements appear, eyes glowing, then the flight (orbs circling, one turn a second)."),
    "earth_preview.png": ("earth smash", [1] * 28, False,
                          "Preview at game scale: his down special; rocks jut out of the floor on both sides during the burst."),
    "wind_preview.png": ("wind burst", [1] * 20, False,
                         "Preview at game scale: his up special's wind burst (drawn in place; in the game he shoots upward)."),
    "shots_preview.png": ("fireball & water gun", [2] * 24, True,
                          "Preview at game scale (slowed down): the fireball (Side+B), then water gun droplets (B)."),
    "badge_preview.png": ("element badge", [20] * 5 + [6] * 8, True,
                          "Mock-up of his player card (no text): water, fire, air, earth light up as each lands a hit; with all four they flash (Avatar State)."),
    "fighter_down_special_left.png": ("down special (facing left)", [5, 5, 6, 6, 6], False,
                                      "Drawn for facing left so the stop sign's lettering isn't mirrored."),
    "fighter_banner.png": ("Leverkusen banner (Up+B)", [8, 8, 8, 10], True,
                           "Pia's up special: raising it, held high (the cloth waves: the two middle drawings alternate every 8 ticks for 1.5 s), lowering it. Everyone within 100 px is dizzy while it's up."),
    "fighter_banner_left.png": ("banner (facing left)", [8, 8, 8, 10], True,
                                "Drawn for facing left so \"B04\" isn't mirrored."),
    "pia_banner_preview.png": ("banner with its range", [2] * 54, True,
                               "Preview at game scale, every 2 ticks: the faint red ring the game draws while the banner is up shows its 100 px range."),
    "fighter_grab_throw.png": ("throw", [3, 5, 6, 4, 12, 10], False,
                               "Mads's command-grab throw (the victim is drawn by the game, in his hands). He turns round on drawing 4."),
    "hand.png": ("summoned hand", [60, 13], True,
                 "Hovers (open) for 60 ticks, then slams (flat). The game adds the shadow and bob."),
    "projectile.png": ("projectile", [4, 4, 4], True, "Spins while flying."),
    "peel.png": ("banana peel", [60], True, "Lies on the floor until someone slips on it."),
    "mette_smash_red_preview.png": ("flask smash, red (B)", [1] * 48, False,
                                    "Mette's neutral special with red: smashes the flask in front of her on frame 9. 12 %, light knockback. Every tick."),
    "mette_smash_blue_preview.png": ("flask smash, blue (B)", [1] * 48, False,
                                     "With blue: 4 %, strong knockback that grows fast with %. Every tick."),
    "mette_smash_green_preview.png": ("flask smash, green (B)", [1] * 48, False,
                                      "With green: 4 %, barely moves them, then they're dizzy for 1 s. Every tick."),
    "mette_flask_preview.png": ("flask in hand (every drawing)", [10] * 105, True,
                                "Every drawing of every animation in order (the last four: idle facing left), with the flask the game draws in her front hand. She always holds her current potion; the colours cycle here just to show all three."),
    "mette_switch_preview.png": ("pick a potion (down special)", [1] * 56, False,
                                 "Mette's down special three times, a real game frame every tick: red → blue → green → red. The flask in her hand shows only the new potion."),
    "mette_throw_preview.png": ("flask throw (side special)", [2] * 24, False,
                                "Mette's side special, every 2 ticks: the flask leaves her hand on frame 10, spins in an arc and leaves a puddle where it lands."),
    "mette_puddles_preview.png": ("puddles", [2] * 36, True,
                                  "Red acid (1 % every 15 ticks), blue ice (slippery), green glue (slow, low jumps). Each lasts 8 s, at most 2 of hers."),
    "mette_steam_preview.png": ("steam (red + blue)", [2] * 24, False,
                                "Blue lands on a red puddle: a steam column blows everyone in it upward (3 %). Every 2 ticks."),
    "mette_explosion_preview.png": ("explosion (red + green)", [1] * 28, False,
                                    "Green lands on a red puddle: it explodes (14 %, strong knockback, Mette too). Every tick."),
    "mette_foam_preview.png": ("foam pillar (blue + green)", [2] * 37, False,
                               "Green lands on a blue puddle: elephant toothpaste. The pillar rises in 12 ticks, popping up whoever stands there; its top is a platform for 5 s."),
    "kim_jab_preview.png": ("hammer blow (A)", [1] * 16, False,
                            "Kim's jab, a real game frame every tick (the game draws the hammer itself): 4 / 3 / 7 frames, 4 %."),
    "kim_axe_preview.png": ("axe chop (side A)", [1] * 31, False,
                            "Kim's side tilt: raised overhead for 12 frames, chopped down on 4, 14 to recover. Slow, 14 %, 43 px of reach."),
    "kim_screwdriver_preview.png": ("screwdriver stab (down A)", [1] * 19, False,
                                    "Kim's down tilt: drawn back, then stabbed low along the floor and swept (the sweep is only drawn). 5 %, pops up."),
    "kim_hammer_preview.png": ("hammer (neutral special)", [2] * 23, False,
                               "Kim's throw: a real game frame every 2 ticks (the game draws the hammer itself). Thrown on frame 10, spins while it flies, gone when it lands."),
    "kim_ladder_preview.png": ("ladder (up special)", [2] * 27, False,
                               "Kim's up special: the ladder goes up on frame 6, he climbs it for 16 ticks, then jumps off. Every 2 ticks, from a real game frame."),
    "kim_blower_preview.png": ("leaf blower (down special)", [2] * 27, False,
                               "Kim's down special: winds up for 20 ticks, then the gust (white lines) pushes the other fighter away for no damage."),
    "kim_torch_preview.png": ("torch (side special)", [2] * 30, False,
                              "Kim's side special: a small flamethrower for 40 ticks that hits again every 8 ticks."),
    "kim_burn_preview.png": ("torch + burning", [3] * 87, False,
                             "Real game frames every 3 ticks: Kim torches Pia (2 % every 8 ticks); once the flame stops hitting her she burns for 3 s, 1 % every 30 ticks (6 % in all), no knockback. Doesn't stack: catching fire again restarts the 3 s."),
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
