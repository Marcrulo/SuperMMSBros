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


# --- Bun pitch and banana peel throw (docs/specs/characters/trine.md#look) ----------------------

BUN = ((196, 128, 58), (148, 88, 38), (234, 178, 98))   # golden brown: base, shade, light
BUN_FLOUR = (240, 222, 186)                             # the pale floury bottom edge
# A Danish bolle in her hand, as letters (L light, B base, S shade, F floury bottom), 6x5, its
# middle on the fist.
HAND_BUN = [".LLB..",
            "LLBBB.",
            "LBBBBS",
            "BBBBSS",
            ".FFFF."]


def hand_bun(fist):
    colors = {"L": BUN[2], "B": BUN[0], "S": BUN[1], "F": BUN_FLOUR}
    x0, y0 = round(fist[0]) - 3, round(fist[1]) - 3
    return {(x0 + x, y0 + y): colors[ch] for y, row in enumerate(HAND_BUN)
            for x, ch in enumerate(row) if ch != "."}


def bun_image():
    """The flying bun, 3 drawings of 10x10 each turned 120° further (it spins): a round bun with
    its light top and floury bottom going round."""
    out = Image.new("RGBA", (30, 10), (0, 0, 0, 0))
    for i in range(3):
        a = math.radians(-90 + 120 * i)          # where its top (the light side) points
        ux, uy = math.cos(a), math.sin(a)
        f = Frame()
        px = {}
        for y in range(10):
            for x in range(10):
                dx, dy = x + 0.5 - 5, y + 0.5 - 5
                if dx * dx + dy * dy * 1.1 > 3.9 ** 2:
                    continue
                up = dx * ux + dy * uy              # toward its top
                side = -dx * uy + dy * ux
                if up < -2.4:
                    px[(x, y)] = BUN_FLOUR
                elif up > 1.3 and side < 1.2:
                    px[(x, y)] = BUN[2]
                elif side > 1.8 or up < -1.4:
                    px[(x, y)] = BUN[1]
                else:
                    px[(x, y)] = BUN[0]
        f.part(px)
        frame = Image.new("RGBA", (10, 10), (0, 0, 0, 0))
        for (x, y), color in f.px.items():
            if 0 <= x < 10 and 0 <= y < 10:
                frame.putpixel((x, y), color + (255,))
        out.paste(frame, (i * 10, 0))
    return out


PEEL = ((246, 214, 60), (206, 160, 30))
PEEL_TIP = (110, 74, 34)


def hand_peel(fist):
    """A banana peel dangling from the fist: the brown stub in her grip, three flaps hanging down."""
    fx, fy = round(fist[0]), round(fist[1])
    out = {(fx, fy - 2): PEEL_TIP}
    for dx, length in ((-2, 4), (0, 5), (2, 4)):
        for k in range(length):
            x = fx + dx + (0 if k < 2 else (1 if dx > 0 else -1 if dx < 0 else 0))
            out[(x, fy + 1 + k)] = PEEL[1] if dx > 0 or k == length - 1 else PEEL[0]
    out[(fx - 1, fy + 1)] = PEEL[0]
    out[(fx + 1, fy + 1)] = PEEL[0]
    return out


# Her bun pitch: the windup is a pitcher's set stance (side-on, leaning back, front knee lifted,
# the bun cocked back behind her head, the back arm reaching forward), then the throw.
WINDUP = dict(lean=-2, crouch=1, bt=-0.15, bk=0.25, ba=1.2, be=0.4)
PITCH_ANIMATIONS = {
    "neutral_special_charge": [pose(bun=1, ft=1.6, fk=2.3, fa=-2.5, fe=-1.0, **WINDUP),
                               pose(bun=1, ft=1.8, fk=2.5, fa=-2.6, fe=-1.1, **WINDUP)],
    "neutral_special": [pose(bun=1, lean=-1, ft=0.5, fk=0.6, bt=-0.2, bk=0.2, fa=-2.4, fe=-0.8,
                             ba=0.9, be=0.4),
                        pose(lean=3, crouch=1, fa=1.9, fe=0.1, reach=1.6, ba=-0.9, be=0.5,
                             ft=0.6, fk=0.3, bt=-0.6, bk=0.4),
                        pose(lean=2, crouch=1, fa=1.1, fe=0.2, reach=0.8, ba=-0.6, be=0.5,
                             ft=0.45, fk=0.25, bt=-0.45, bk=0.3),
                        pose(fa=0.6, fe=0.6, ft=0.15, bt=-0.15)],
    # Her peel toss: underhand, the peel dangling from her fist until it goes.
    "side_special": [pose(held_peel=1, lean=-1, fa=-0.6, fe=0.2, ba=0.5, ft=0.25, bt=-0.25),
                     pose(held_peel=1, lean=-2, crouch=1, fa=-1.0, fe=0.1, ba=0.7, ft=0.35,
                          fk=0.3, bt=-0.35, bk=0.3),
                     pose(lean=2, fa=1.75, fe=0.3, reach=1.0, ba=-0.6, ft=0.4, bt=-0.4),
                     pose(fa=0.8, fe=0.5)],
}

# The bun in her front hand (drawn over it).
PROPS["bun"] = dict(hand=lambda pose, fist, neck, sipping: hand_bun(fist))
# A banana peel dangling from her front fist.
PROPS["held_peel"] = dict(hand=lambda pose, fist, neck, sipping: hand_peel(fist))


def applies(c):
    return c.get("ipad")


def animations(c):
    return {**IPAD_ANIMATIONS, **PITCH_ANIMATIONS}


def extra_files(c, out, strips):
    from sprites.characters.fidusen import peel_image   # the trap peel is Fidusen's drawing
    peel_image().save(out / "peel.png")
    bun_image().save(out / "projectile.png")
