"""Trine's own drawings for the 64 px sprite generator (docs/specs/characters/trine.md#look).

Loaded by tools/gen_fighter_sprites64.py; the hooks at the bottom say which looks use it."""
from sprites import body  # noqa: F401
from sprites.body import *  # noqa: F401,F403  (the shared body, poses, drawing)
from sprites.weapons import *  # noqa: F401,F403


IPAD_BACK = ((178, 184, 196), (138, 144, 158), (214, 220, 230))   # aluminium back: base, shade, light
IPAD_SCREEN = (150, 220, 255)                                      # the screen's edge, facing her
IPAD_CAMERA = (40, 42, 52)
IPAD_W, IPAD_H = 6, 11
# The screen's light on her face: its color, reach (px) and strength per look (bending, two
# watching drawings that flicker a little).
SCREEN_LIGHT = (90, 175, 255)
SCREEN_REACH = 28
SCREEN_STRENGTH = [0.5, 0.85, 0.7]


def ipad(knee, look):
    """A tablet standing on the floor (its foot at `knee`) on a kickstand, leaning back toward her with its
    screen turned to her face (left), so we see its aluminium back: a 6x11 slab (lit top right,
    shaded bottom left), a camera dot near the top, and a 1 px line of screen light along the edge
    facing her. Returns (pixels, the screen's middle)."""
    x0 = round(knee[0]) - 1
    y_foot = round(knee[1]) - 1
    base, shade, light = IPAD_BACK
    out = {}
    for row in range(IPAD_H):             # 0 = the foot
        y = y_foot - row
        lean = row // 4                    # leans back, away from her
        for x in range(IPAD_W):
            if x == 0:
                color = IPAD_SCREEN
            elif x == IPAD_W - 1 or row == 0:
                color = shade
            elif row == IPAD_H - 1 or x == IPAD_W - 2:
                color = light
            else:
                color = base
            out[(x0 + x + lean, y)] = color
    for i in range(1, 5):                  # the kickstand, behind it
        out.setdefault((x0 + IPAD_W + 1 + i, y_foot - 4 + i), shade)
    top_lean = (IPAD_H - 3) // 4
    out[(x0 + IPAD_W - 3 + top_lean, y_foot - IPAD_H + 3)] = IPAD_CAMERA
    return out, (x0 - 1, y_foot - IPAD_H + 2)


MUG = ((238, 236, 232), (196, 192, 190))   # white mug, its shaded side
COFFEE = (92, 56, 34)
STEAM = (220, 226, 236)


# The tipped mug for a sip, as letters (W mug, S its shade, H handle), its rim (top left) at her
# lips: SIP_RIM from the neck point (the mouth is ~5 px above it); the fist at SIP_FIST.
SIP_MUG = ["WWW....",
           "WWWW...",
           "HWWWWS.",
           ".HWWWSS",
           "..HWSS.",
           "....S.."]
SIP_RIM = (2, -7)


def sip_mug(neck):
    """The coffee mug tipped up to her mouth (rim at her lips, foot down and forward)."""
    colors = {"W": MUG[0], "S": MUG[1], "H": MUG[1]}
    x0, y0 = neck[0] + SIP_RIM[0], neck[1] + SIP_RIM[1]
    return {(x0 + x, y0 + y): colors[ch] for y, row in enumerate(SIP_MUG)
            for x, ch in enumerate(row) if ch != "."}


def mug(fist, look):
    """A white coffee mug in the front fist, its handle toward her (left): 4x5, coffee showing on
    top; "low" = held at the chest with a wisp of steam (two variants, "low"/"low2"), "sip" = at
    her mouth, tipped (no coffee showing, no steam)."""
    fx, fy = round(fist[0]), round(fist[1])
    x0, y0 = fx - 1, fy - 4
    if look == "sip":
        y0 -= 3                              # held by its foot, its rim at her mouth
    out = {}
    for y in range(5):
        for x in range(4):
            out[(x0 + x, y0 + y)] = MUG[1] if x == 3 or y == 4 else MUG[0]
    out[(x0 - 1, y0 + 1)] = MUG[1]           # the handle
    out[(x0 - 1, y0 + 3)] = MUG[1]
    if look != "sip":
        for x in range(1, 3):
            out[(x0 + x, y0)] = COFFEE
        wisp = [(x0 + 1, y0 - 2), (x0 + 2, y0 - 3)] if look == "low" else [(x0 + 2, y0 - 2), (x0 + 1, y0 - 3)]
        for pt in wisp:
            out[pt] = STEAM
    return out


def screen_lit(pixels, screen, strength):
    """`pixels` (her head) lit blue by the screen at `screen`: nearer pixels more, outlines kept."""
    out = {}
    for (x, y), color in pixels.items():
        d = math.hypot(x - screen[0], y - screen[1])
        k = strength * max(0.0, 1 - d / SCREEN_REACH)
        if color == OUTLINE or k <= 0:
            out[(x, y)] = color
        else:
            out[(x, y)] = tuple(round(c + (l - c) * k) for c, l in zip(color, SCREEN_LIGHT))
    return out


# Trine's iPad break (down special, 5 drawings): bending down; seated on the floor with her legs
# out in front, the iPad propped on her lap, the coffee mug at her chest, watching (two drawings:
# the screen light and the steam shift); sipping (the mug at her mouth); getting up. The back hand
# rests on the floor behind her.
SIT = dict(crouch=7, ft=1.5, fk=0.0, bt=1.3, bk=0.15, ba=-0.9, be=-0.3)
BEND = dict(crouch=3, lean=2, ft=0.9, fk=1.5, bt=0.4, bk=1.3, fa=0.7, fe=1.4, ba=-0.5, be=0.6)
CUP_LOW = dict(fa=0.55, fe=1.9)
CUP_SIP = dict(fa=0.35, fe=2.5)
IPAD_ANIMATIONS = {
    "down_special": [pose(mug="low", **BEND),
                     pose(ipad=1, mug="low", **SIT, **CUP_LOW),
                     pose(ipad=2, mug="low2", lean=1, **SIT, **CUP_LOW),
                     pose(ipad=1, mug="sip", face="shut", head_dy=-1, **SIT, **CUP_SIP),
                     pose(mug="low", **BEND)],
}


# Her iPad on the floor in front of her feet; its screen lights her face.
PROPS["ipad"] = dict(
    floor=lambda pose, foot: ipad((foot[0] + 6, GROUND + 2), pose["ipad"]),
    face=lambda face, screen, pose: screen_lit(face, screen, SCREEN_STRENGTH[pose["ipad"]]))
# Her coffee mug, in the front hand (drawn over it); tipped to her lips for a sip, its foot resting
# in her fist.
PROPS["mug"] = dict(
    to_mouth=lambda value: value == "sip",
    hand=lambda pose, fist, neck, sipping: sip_mug(neck) if sipping else mug(fist, pose["mug"]))


def applies(c):
    return c.get("ipad")


def animations(c):
    return dict(IPAD_ANIMATIONS)
