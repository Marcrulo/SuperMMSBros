"""Magnus's own drawings for the 64 px sprite generator (docs/specs/characters/magnus.md#look).

Loaded by tools/gen_fighter_sprites64.py; the hooks at the bottom say which looks use it."""
import math

from PIL import Image

import fighter64_looks as looks
from sprites import body  # noqa: F401
from sprites.body import *  # noqa: F401,F403  (the shared body, poses, drawing)
from sprites.weapons import *  # noqa: F401,F403


# --- The Naruto run ------------------------------------------------------------------------------

# Body leaning far forward, head low and forward, both arms stretched straight back behind him
# (about level with the shoulders), long strides.
NARUTO_ARMS = dict(fa=-1.65, fe=-0.05, ba=-1.5, be=-0.05)


def naruto_run_pose(i):
    phase = i / 6 * 2 * math.pi
    s = math.sin(phase)
    return pose(lean=8, crouch=2, head_dx=1, head_dy=2, bob=-round(abs(math.cos(phase))),
                ft=0.15 + 0.95 * s, bt=0.15 - 0.95 * s,
                fk=0.35 + max(0, -s) * 1.3, bk=0.35 + max(0, s) * 1.3,
                fa=NARUTO_ARMS["fa"] + 0.08 * s, fe=NARUTO_ARMS["fe"],
                ba=NARUTO_ARMS["ba"] - 0.08 * s, be=NARUTO_ARMS["be"])


NARUTO_ANIMATIONS = {"run": [naruto_run_pose(i) for i in range(6)]}


# --- The Avatar State (avatar.png) ---------------------------------------------------------------

# Glowing eyes: the eye white and iris roles in a pale cyan-white.
GLOW_WHITE = (150, 238, 255)
GLOW_IRIS = (250, 255, 255)
AVATAR_POSES = [
    # The rise: upright, arms spread low at his sides, legs together, feet off the floor.
    pose(crouch=-3, fa=0.75, fe=-0.15, ba=-0.75, be=0.15, ft=0.05, fk=0.25, bt=-0.05, bk=0.3),
    # The flight: leaning into it, arms back, legs trailing.
    pose(crouch=-2, lean=7, head_dx=1, head_dy=1, fa=-1.7, fe=-0.1, ba=-1.55, be=-0.1,
         ft=-0.35, fk=0.5, bt=-0.6, bk=0.4),
]


def avatar_image(c):
    """His Avatar State strip: the rise and flight drawings, eyes glowing."""
    p = dict(looks.palette(c))
    p["W"], p["B"] = GLOW_WHITE, GLOW_IRIS
    heads = {face: looks.build_head(c, face) for face in ("normal", "shut", "hurt")}
    frames = [draw_frame(ps, c, p, heads) for ps in AVATAR_POSES]
    w, h = frames[0].size
    out = Image.new("RGBA", (w * len(frames), h), (0, 0, 0, 0))
    for i, frame in enumerate(frames):
        out.paste(frame, (i * w, 0))
    return out


def applies(c):
    return c.get("naruto_run") or c.get("avatar")


def animations(c):
    return dict(NARUTO_ANIMATIONS) if c.get("naruto_run") else {}


def extra_files(c, out, strips):
    if c.get("avatar"):
        avatar_image(c).save(out / "avatar.png")
