"""Mads's own drawings for the 64 px sprite generator (docs/specs/characters/mads.md#look).

Loaded by tools/gen_fighter_sprites64.py; the hooks at the bottom say which looks use it."""
from sprites import body  # noqa: F401
from sprites.body import *  # noqa: F401,F403  (the shared body, poses, drawing)
from sprites.weapons import *  # noqa: F401,F403


# Mads's stop smash (down special, as Stig's cross smash): the lollipop held upright in both hands,
# turning into a stop sign as he lifts it (drawing 2), driven into the floor on a longer pole so
# the sign stands above his head (drawings 3-4); back to the lollipop as he gets up.
STOP_SMASH_ANIMATIONS = {
    "down_special": [dict(ps, hold=ps["hold"][:3] + ({1: 1, 2: 2, 3: 2}.get(i, 0),))
                     for i, ps in enumerate(CROSS_SMASH_ANIMATIONS["down_special"])],
}


# Mads's over-the-head slam. The reach (side special, 4 drawings): reaching forward with both
# arms, leaning in, the rest of the reach and a miss the same. The throw (its own strip
# fighter_grab_throw.png, 6 drawings): the catch, arms out front; lifting, arms up in front;
# overhead, leaning back; turned round (drawn facing the new way), arms overhead leaning toward the
# victim; the slam, bent forward, arms driven down in front; straightening up.
REACH = pose(lean=3, fa=1.5, fe=0.2, reach=1.2, ba=1.35, be=0.25, ft=0.55, fk=0.3, bt=-0.5, bk=0.2)
SLAM_ANIMATIONS = {
    "side_special": [REACH, REACH, REACH, pose(lean=1, fa=0.9, fe=0.6, ba=0.6, be=0.5)],
}
GRAB_THROW = [
    pose(lean=1, fa=1.55, fe=0.1, reach=0.8, ba=1.45, be=0.15, ft=0.4, fk=0.3, bt=-0.5, bk=0.2),
    pose(lean=0, fa=2.25, fe=0.1, ba=2.1, be=0.1, ft=0.3, fk=0.2, bt=-0.4, bk=0.2),
    pose(lean=-1, fa=2.75, fe=0.0, ba=-2.75, be=0.0, ft=0.25, fk=0.1, bt=-0.4, bk=0.1, head_dy=-1),
    pose(lean=1, fa=2.6, fe=0.0, ba=-2.6, be=0.0, ft=0.35, fk=0.15, bt=-0.3, bk=0.1, head_dy=-1),
    pose(lean=4, crouch=2, fa=0.95, fe=-0.1, reach=1.0, ba=0.8, be=0.0, ft=0.6, fk=0.9, bt=-0.6, bk=0.3),
    pose(lean=1, fa=0.5, fe=0.8, ba=0.2, be=0.6, ft=0.3, fk=0.2, bt=-0.3, bk=0.2),
]


# A school crossing guard's stop sign ("lollipop"): a white pole with a round yellow-green sign on
# top, a white rim round it.
POLE = ((236, 236, 240), (178, 180, 192), (255, 255, 255))
SIGN = ((214, 226, 74), (172, 186, 46), (238, 246, 132))     # face, shade, light
SIGN_RIM = (250, 250, 250)
POLE_FOOT = -4         # from the grip back to the foot of the pole, px
POLE_LEN = 21          # from the grip to where the sign starts
SIGN_R = 7.5           # the sign's radius (rim included)


# The stop sign it turns into (Mads's down special): a red octagon, STOP_SIZE across, with a white
# rim and STOP in a 3x5 pixel font (the game draws each art pixel about 2 screen pixels wide, so the
# letters stay readable).
STOP_RED = ((214, 40, 40), (166, 26, 30))     # face, shaded bottom right
STOP_SIZE = 21
STOP_EXTRA = 10        # the planted stop sign's pole is this much longer
STOP_FONT = {"S": ["111", "100", "111", "001", "111"], "T": ["111", "010", "010", "010", "010"],
             "O": ["111", "101", "101", "101", "111"], "P": ["111", "101", "111", "100", "100"]}
# The smash's burst in stop-sign colors: white core, pale red glow, red rim.
STOP_LIGHT = ((255, 250, 248), (255, 156, 146), (214, 40, 40))


def stop_sign(cx, cy):
    """The stop sign's pixels, centered at (cx, cy), upright whatever the pole's angle."""
    n = STOP_SIZE
    c = (n - 1) / 2
    cut = n * 0.29
    x0, y0 = round(cx - c), round(cy - c)
    face = {(x, y) for y in range(n) for x in range(n)
            if abs(x - c) + abs(y - c) <= 2 * c - cut + 0.5}
    flip = (lambda x: n - 1 - x) if body.MIRROR_TEXT else (lambda x: x)
    out = {}
    for (x, y) in face:
        edge = any(n_ not in face for n_ in ((x + 1, y), (x - 1, y), (x, y + 1), (x, y - 1)))
        out[(x0 + x, y0 + y)] = SIGN_RIM if edge else STOP_RED[1 if flip(x) + y > n + 3 else 0]
    tx = (n - 15) // 2
    ty = y0 + (n - 5) // 2
    for i, ch in enumerate("STOP"):
        for r, row in enumerate(STOP_FONT[ch]):
            for col, bit in enumerate(row):
                if bit == "1":
                    out[(x0 + flip(tx + i * 4 + col), ty + r)] = SIGN_RIM
    return out


def lollipop(grip, angle, opening=0):
    """The lollipop held at `grip` near the foot of its pole, pointing at `angle` (as the guitar:
    0 = hanging straight down, -90 = forward, 180 = straight up); `opening` 1 = turned into the
    stop sign, 2 = the stop sign on a pole STOP_EXTRA longer (planted, the sign above his head)."""
    a = math.radians(angle)
    ax, ay = -math.sin(a), math.cos(a)            # along, grip -> sign
    gx, gy = grip
    foot = (gx + ax * POLE_FOOT, gy + ay * POLE_FOOT)
    pole = POLE_LEN + (STOP_EXTRA if opening == 2 else 0)
    top = (gx + ax * (pole + 2), gy + ay * (pole + 2))
    out = shaded(segment_pixels(foot, top, 2.2), 2.2, *POLE)
    if opening:
        half = STOP_SIZE / 2
        out.update(stop_sign(gx + ax * (pole + half), gy + ay * (pole + half)))
        return out
    cx, cy = gx + ax * (POLE_LEN + SIGN_R), gy + ay * (POLE_LEN + SIGN_R)
    for (x, y) in disc(cx, cy, SIGN_R):
        d = math.hypot(x + 0.5 - cx, y + 0.5 - cy)
        if d > SIGN_R - 1.3:
            out[(x, y)] = SIGN_RIM
        elif (x + 0.5 - cx) - (y + 0.5 - cy) > SIGN_R * 0.9:
            out[(x, y)] = SIGN[1]                     # shaded bottom right
        elif (x + 0.5 - cx) - (y + 0.5 - cy) < -SIGN_R * 0.9:
            out[(x, y)] = SIGN[2]                     # lit top left
        else:
            out[(x, y)] = SIGN[0]
    return out


# On his back like Stig's cross, the sign up behind his head; only the side tilt swings it
# (Henrik's side tilt, held by the foot of the pole, never pointing below level).
WEAPONS["lollipop"] = dict(draw=lollipop, animations={"side_tilt": GUITAR_ANIMATIONS["side_tilt"]},
                           back=((7, 9), 140), choke=False, lowest=-90, foot=POLE_FOOT)


def throw_strip(c):
    """The grappler's throw: GRAB_THROW drawn side by side."""
    p = looks.palette(c)
    heads = {face: looks.build_head(c, face) for face in ("normal", "shut", "hurt")}
    frames = [draw_frame(ps, c, p, heads) for ps in GRAB_THROW]
    w, h = frames[0].size
    strip = Image.new("RGBA", (w * len(frames), h), (0, 0, 0, 0))
    for i, frame in enumerate(frames):
        strip.paste(frame, (i * w, 0))
    return strip


def applies(c):
    return c.get("grappler") or c.get("stop_smash")


def animations(c):
    own = {}
    if c.get("stop_smash"):
        own.update(STOP_SMASH_ANIMATIONS)
    if c.get("grappler"):
        own.update(SLAM_ANIMATIONS)
    return own


def extra_files(c, out, strips):
    if c.get("grappler"):
        throw_strip(c).save(out / "fighter_grab_throw.png")
    if c.get("stop_smash"):
        burst_image(STOP_LIGHT).save(out / "burst.png")
        strips.left_strip(c, "down_special").save(out / "fighter_down_special_left.png")
