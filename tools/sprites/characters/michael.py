"""Michael's own drawings for the 64 px sprite generator (docs/specs/characters/michael.md#look).

Loaded by tools/gen_fighter_sprites64.py; the hooks at the bottom say which looks use it."""
from sprites import body  # noqa: F401
from sprites.body import *  # noqa: F401,F403  (the shared body, poses, drawing)
from sprites.weapons import *  # noqa: F401,F403


# --- Summoned hand (docs/specs/characters/michael.md#michaels-hand) --------------------------------------

HAND_DRAWING = (56, 44)
GLOVE = ((242, 243, 248), (190, 196, 214), (255, 255, 255))
GLOVE_CREASE = (150, 156, 178)


def _finger(base, angle, length, width):
    """A gloved finger from `base` at `angle` degrees (0 = forward, positive = down), with a
    knuckle crease across it."""
    a = math.radians(angle)
    d = (math.cos(a), math.sin(a))
    tip = (base[0] + d[0] * length, base[1] + d[1] * length)
    px = shaded(segment_pixels(base, tip, width), width, *GLOVE)
    k = (base[0] + d[0] * length * 0.55, base[1] + d[1] * length * 0.55)
    n = (-d[1], d[0])
    for t in (-0.3, -0.1, 0.1, 0.3):
        x, y = k[0] + n[0] * width * t * 1.6, k[1] + n[1] * width * t * 1.6
        if (int(x), int(y)) in px:
            px[(int(x), int(y))] = GLOVE_CREASE
    return px


def hand_image(c):
    """The summoned hand, a giant white glove: open (hovering) and flat (slamming), side by side;
    seen from the side, palm down, fingers forward (right), the cuff at the back. The palm's
    bottom is the drawing's bottom row."""
    w, h = HAND_DRAWING
    out = Image.new("RGBA", (w * 2, h), (0, 0, 0, 0))
    for i, open_hand in enumerate((True, False)):
        f = Frame()
        if open_hand:
            cuff = ((9, 21), (9, 33))
            blob = disc(22, 28, 9.5) | disc(28, 29, 8.5)
            fingers = [((33, 22.5), -14, 14), ((35, 26.5), -5, 16), ((35, 30.5), 5, 15),
                       ((33, 34.5), 14, 11)]
            width = 6.0
            thumb = ((22, 34), 62, 7)
        else:
            cuff = ((9, 30), (9, 37))
            blob = {(x, y) for (x, y) in disc(23, 35, 10) | disc(29, 35, 9) if y < h}
            fingers = [((34, 30), 2, 15), ((35, 33.5), 1, 17), ((35, 37), 0, 16),
                       ((33, 40.5), 0, 13)]
            width = 4.6
            thumb = ((25, 41), 4, 8)
        # Rolled cuff: a flared band with a lighter rim at the front.
        band = segment_pixels(cuff[0], cuff[1], 12)
        f.part({k: GLOVE[1] if v < -3.5 else GLOVE[0] for k, v in band.items()})
        rim = {(x, y): GLOVE[2] for (x, y) in band if x >= int(cuff[0][0]) + 3}
        f.part(rim)
        cx = sum(x for x, _ in blob) / len(blob)
        f.part({(x, y): GLOVE[1] if y > 36 + (2 if not open_hand else 0) else
                GLOVE[2] if y < 26 and x > cx else GLOVE[0] for (x, y) in blob})
        for base, angle, length in fingers:
            f.part(_finger(base, angle, length, width))
        f.part(_finger(thumb[0], thumb[1], thumb[2], width + 0.6))
        frame = Image.new("RGBA", (w, h), (0, 0, 0, 0))
        for (x, y), color in f.px.items():
            if 0 <= x < w and 0 <= y < h:
                frame.putpixel((x, y), color + (255,))
        out.paste(frame, (i * w, 0))
    return out


# --- Football (docs/specs/characters/michael.md#michaels-football) ----------------------------------------

BALL_FRAME = 16
BALL_WHITE = ((240, 240, 244), (184, 190, 206), (255, 255, 255))
BALL_BLACK = (34, 36, 46)


def ball_image():
    """A black-and-white football, 3 drawings each turned 40° further (it spins)."""
    out = Image.new("RGBA", (BALL_FRAME * 3, BALL_FRAME), (0, 0, 0, 0))
    c = BALL_FRAME / 2
    r = 6.6
    for i in range(3):
        f = Frame()
        turn = math.radians(40 * i)
        # Patch centers: one in the middle, five around (pentagons as small discs).
        patches = [(0.0, 0.0, 1.8)] + [(math.cos(turn + k * 2 * math.pi / 5) * 5.4,
                                         math.sin(turn + k * 2 * math.pi / 5) * 5.4, 1.3)
                                        for k in range(5)]
        px = {}
        for (x, y) in disc(c, c, r):
            dx, dy = x + 0.5 - c, y + 0.5 - c
            black = any((dx - pxx) ** 2 + (dy - pyy) ** 2 <= pr * pr for pxx, pyy, pr in patches)
            lit = dx - dy
            edge = r - math.hypot(dx, dy)
            px[(x, y)] = BALL_BLACK if black else BALL_WHITE[2] if lit < -4 and edge > 1 \
                else BALL_WHITE[1] if lit > 4 and edge < 2.2 else BALL_WHITE[0]
        f.part(px)
        frame = Image.new("RGBA", (BALL_FRAME, BALL_FRAME), (0, 0, 0, 0))
        for (x, y), color in f.px.items():
            if 0 <= x < BALL_FRAME and 0 <= y < BALL_FRAME:
                frame.putpixel((x, y), color + (255,))
        out.paste(frame, (i * BALL_FRAME, 0))
    return out


# Michael's kick: leg back, swinging through, leg up high in front (follow-through), standing.
KICK_ANIMATIONS = {
    "side_special": [pose(lean=-1, ft=-0.9, fk=1.4, bt=0.1, bk=0.2, fa=0.6, fe=0.8, ba=-0.7),
                     pose(lean=0, ft=0.3, fk=0.9, bt=-0.1, bk=0.2, fa=-0.4, fe=0.6, ba=0.6),
                     pose(lean=-2, ft=1.9, fk=0.1, bt=-0.15, bk=0.3, fa=-0.9, fe=0.5, ba=1.0),
                     pose(ft=0.4, fk=0.4, bt=-0.2, fa=0.2, ba=-0.2)],
}




# Michael's summon: wind up, thrust the open hand forward and up, hold, come back (4 drawings; the
# hand appears on frame 10, in the hold).
SUMMON_ANIMATIONS = {
    "neutral_special": [pose(lean=-1, crouch=1, fa=-0.9, fe=1.4, ba=0.6, be=1.2, ft=0.3, bt=-0.3),
                        pose(lean=2, fa=2.35, fe=-0.3, reach=1.2, ba=-0.6, ft=0.5, fk=0.2,
                             bt=-0.5, bk=0.2),
                        pose(lean=2, fa=2.35, fe=-0.3, reach=1.0, ba=-0.5, ft=0.45, fk=0.2,
                             bt=-0.45, bk=0.2),
                        pose(fa=0.8, fe=0.6, ft=0.15, bt=-0.15)],
}


def applies(c):
    return c.get("hand") or c.get("football")


def animations(c):
    own = {}
    if c.get("hand"):
        own.update(SUMMON_ANIMATIONS)
    if c.get("football"):
        own.update(KICK_ANIMATIONS)
    return own


def extra_files(c, out, strips):
    if c.get("hand"):
        hand_image(c).save(out / "hand.png")
    if c.get("football"):
        ball_image().save(out / "projectile.png")
