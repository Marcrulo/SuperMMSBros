"""Weapon poses and pictures shared by several characters (docs/specs/art-guide.md#weapons):
Henrik's swings (also Stig's and Mads's), Stig's smash poses (also Mads's) and the smash's floor
burst. Changing one changes every character that uses it, so it's a shared change."""
from sprites.body import *  # noqa: F401,F403


def held(angle, front=True, choke=0, opening=0, **changes):
    """A drawing with the weapon in the front fist at `angle`, the back hand on it too; `front`
    draws it over the body (swung), else behind (wound up); `choke` holds it that many px further
    down the neck (a shorter swing); `opening` opens a weapon that opens (scissors: degrees between
    the blades)."""
    ps = pose(**changes)
    if "ba" not in changes:
        ps["ba"], ps["be"] = ps["fa"] - 0.25, ps["fe"]
    ps["hold"] = (angle, front, choke, opening)
    return ps


# Henrik's guitar swings (the drawing counts and the strike drawing as in ANIMATIONS).
GUITAR_ANIMATIONS = {
    "jab": [held(110, False, 9, lean=-1, fa=-0.7, fe=0.6, ft=0.2, bt=-0.2),
            held(125, False, 9, lean=-1, fa=-0.9, fe=0.5, ft=0.3, bt=-0.3),
            held(-80, True, 9, lean=1, fa=1.2, fe=0.0, ft=0.45, fk=0.2, bt=-0.4, bk=0.2),
            held(-40, False, 9, lean=1, fa=0.8, fe=0.2, ft=0.3, bt=-0.3),
            held(-20, False, 9, fa=0.6, fe=0.3, ft=0.15, bt=-0.15)],
    "side_tilt": [held(105, False, lean=-1, fa=-0.8, fe=0.6, ft=-0.2, fk=0.6),
                  held(115, False, lean=-2, fa=-1.1, fe=0.4, ft=0.3, fk=1.0, bt=-0.2),
                  held(-90, lean=3, fa=1.57, fe=0.0, reach=2.4, ft=0.7, fk=0.3, bt=-0.5, bk=0.2),
                  held(-60, lean=2, fa=1.3, fe=0.0, reach=1.2, ft=0.5, fk=0.3, bt=-0.4),
                  held(-25, fa=0.7, fe=0.3, ft=0.2, bt=-0.2)],
    "neutral_special_charge": [
        held(150, False, crouch=1, lean=-1, fa=-2.7, fe=0.0, ft=0.35, bt=-0.3),
        held(160, False, crouch=2, lean=-2, fa=-2.75, fe=0.0, ft=0.4, bt=-0.35)],
    "neutral_special": [held(180, False, lean=-1, fa=3.0, fe=0.0, ft=0.3, bt=-0.3),
                        held(-105, lean=2, fa=2.5, fe=0.0, reach=1.0, ft=0.6, fk=0.2, bt=-0.6,
                             bk=0.2),
                        held(-40, lean=3, crouch=1, fa=1.5, fe=0.0, reach=1.0, ft=0.6, fk=0.4,
                             bt=-0.6, bk=0.2),
                        held(-20, lean=1, fa=0.8, fe=0.3, ft=0.3, bt=-0.3)],
}


# Stig's cross smash (down special, 5 drawings, the strike drawing 3rd), like a wizard driving his
# staff into the ground: both hands round the upright cross, lifted, then pushed straight down
# onto the floor in front of him as he drops to one knee (held there), then he gets up.
GRIP0, FA0, FE0, R0 = 0, 1.5, 0.0, 1.6
GRIP1, FA1, FE1, R1 = -7, 1.75, 0.0, 1.6
FA2, FE2, R2 = 1.45, 0.05, 1.8
KNEEL = dict(crouch=3.6, ft=1.45, fk=1.45, bt=-0.15, bk=1.75)
CROSS_SMASH_ANIMATIONS = {
    "down_special": [
        held(180, both_hands=True, grip=GRIP0, fa=FA0, fe=FE0, reach=R0, crouch=1, lean=1, ft=0.2, bt=-0.2),
        held(180, both_hands=True, grip=GRIP1, fa=FA1, fe=FE1, reach=R1, lean=1, ft=0.2, bt=-0.2, head_dy=-1),
        held(180, both_hands=True, into_floor=True, plant=True, fa=FA2, fe=FE2, reach=R2, lean=3, **KNEEL),
        held(180, both_hands=True, into_floor=True, plant=True, fa=FA2, fe=FE2, reach=R2, lean=3, **KNEEL),
        held(180, both_hands=True, grip=GRIP0, fa=FA0, fe=FE0, reach=R0, crouch=2, lean=1, ft=0.6, fk=1.0, bt=-0.2, bk=0.8)],
}


# The holy light the smash sends along the floor: 4 drawings of 80×28 (drawn at ¾). The cross
# hits the floor at (BURST_ORIGIN, bottom): a flash there, then light fanning out forward and a
# little up along the floor (a white core on the floor, rays, a soft far end), then it fades.
LIGHT = ((255, 255, 236), (255, 238, 150), (246, 196, 72))   # core, glow, rim
BURST_SIZE = (80, 28)
BURST_ORIGIN = 8
SPARKLES = [(34, 8), (52, 13), (64, 5), (24, 15)]


def burst_image(light=None):
    """The smash's burst along the floor, in `light` colors (core, glow, rim; Stig's gold light by
    default)."""
    light = light or LIGHT
    (w, h), n, ox = BURST_SIZE, 4, BURST_ORIGIN
    out = Image.new("RGBA", (w * n, h), (0, 0, 0, 0))
    px = out.load()
    for i in range(n):
        def put(x, y, color):
            if 0 <= x < w and 0 <= y < h:
                px[i * w + x, y] = color + (255,)
        reach = (0, 70, 70, 64)[i]
        for y in range(h):
            for x in range(w):
                dx, dy = x + 0.5 - ox, h - (y + 0.5)         # up is positive
                r = math.hypot(dx, dy)
                ang = math.degrees(math.atan2(dy, dx))
                color = None
                if i < 2 and r <= (5.5 if i == 0 else 4):
                    color = light[0]                         # the flash where the cross hit
                elif i == 0 and r <= 8.5:
                    color = light[1]
                elif i == 0 and r <= 13 and any(abs(ang - a) < 5 for a in (25, 60, 95, 130)):
                    color = light[2] if r > 11 else light[1]  # short rays of the flash
                elif 0 <= ang <= 26 and dx > 0 and r <= reach:
                    fade = r / reach
                    if fade > 0.82 and (x + y) % 2:
                        continue                             # soft far end
                    if i == 3 and (x + y) % 2 == (y // 2) % 2:
                        continue                             # breaking up as it fades
                    ray = any(abs(ang - a) < 1.5 for a in (11, 18, 24))
                    if ang < 7 and fade < 0.85 and i < 3:
                        color = light[0]
                    elif ray or ang < 15:
                        color = light[1]
                    else:
                        color = light[2]
                if color:
                    put(x, y, color)
        if i == 2:
            for sx, sy in SPARKLES:                         # little 4-point twinkles
                for ddx, ddy in ((0, 0), (1, 0), (-1, 0), (0, 1), (0, -1)):
                    put(sx + ddx, sy + ddy, light[0])
    return out
