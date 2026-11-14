"""Sjippepigen's own drawings for the 64 px sprite generator (docs/specs/characters/sjippepigen.md#look).

Loaded by tools/gen_fighter_sprites64.py; the hooks at the bottom say which looks use it."""
from sprites import body  # noqa: F401
from sprites.body import *  # noqa: F401,F403  (the shared body, poses, drawing)
from sprites.weapons import *  # noqa: F401,F403


# Sjippepigen's idle: skipping on the spot (her ropes always spin), hands down by her hips holding
# the handles: land (knees bent), hop (off the floor, toes down), land, hop (the other foot leading).
SKIP_ARMS = dict(fa=0.55, fe=0.9, ba=0.35, be=0.9)
SKIP_ANIMATIONS = {
    "idle": [pose(crouch=1.5, ft=0.35, fk=0.7, bt=0.15, bk=0.6, **SKIP_ARMS),
             pose(crouch=-3, ft=0.15, fk=0.35, bt=-0.05, bk=0.45, head_dy=-0.5, **SKIP_ARMS),
             pose(crouch=1.5, ft=0.3, fk=0.65, bt=0.2, bk=0.7, **SKIP_ARMS),
             pose(crouch=-3, ft=0.05, fk=0.45, bt=0.1, bk=0.35, head_dy=-0.5, **SKIP_ARMS)],
    # Skipping along: the run's strides with a hop in each (land, up, coming down), the hands
    # staying down by her hips on the handles.
    "run": [dict(run_pose(i), crouch=(1.5, -3.5, -1.5)[i % 3], **SKIP_ARMS) for i in range(6)],
}


def hands_json(c):
    """Every drawing's fists per pair of arms, in game px from the feet (facing right):
    {animation: [drawing: [pair: [[front x, y], [back x, y]]]]}; the game hangs Sjippepigen's ropes
    between each pair's hands (RopeAbility's drawing)."""
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
            out[name].append([[game(HANDS[k]["front"]), game(HANDS[k]["back"])]
                              for k in sorted(HANDS)])
    return out


def applies(c):
    return c.get("ropes")


def animations(c):
    return dict(SKIP_ANIMATIONS)


def extra_files(c, out, strips):
    (out / "hands.json").write_text(json.dumps(hands_json(c)))
