"""Mette's own extras for the 64 px sprite generator (docs/specs/characters/mette.md#look).

Loaded by tools/gen_fighter_sprites64.py; the hooks at the bottom say which looks use it. Her body
uses the default poses; the game draws the flask she holds, at her front hand (hands.json)."""
from sprites import body  # noqa: F401
from sprites.body import *  # noqa: F401,F403  (the shared body, poses, drawing)


def hands_json(c):
    """Every drawing's front fist, in game px from the feet (facing right):
    {animation: [drawing: [x, y]]}; the game draws Mette's flask there (PotionAbility's drawing)."""
    p = looks.palette(c)
    heads = {face: looks.build_head(c, face) for face in ("normal", "shut", "hurt")}
    w, h = c.get("canvas", (FRAME, FRAME))
    ox, oy = (w - FRAME) // 2, h - FRAME
    game = lambda pt: [round((pt[0] + 0.5 + ox - w / 2) * 0.75, 2), round((pt[1] + 0.5 + oy - h) * 0.75, 2)]
    out = {}
    for name, poses in ANIMATIONS.items():
        out[name] = []
        for ps in poses:
            draw_frame(ps, c, p, heads)
            out[name].append(game(HANDS[0]["front"]))
    return out


def applies(c):
    return c.get("flask")


def extra_files(c, out, strips):
    (out / "hands.json").write_text(json.dumps(hands_json(c)))
