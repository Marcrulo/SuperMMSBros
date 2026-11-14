"""Henrik's own drawings for the 64 px sprite generator (docs/specs/characters/henrik.md#look).

Loaded by tools/gen_fighter_sprites64.py; the hooks at the bottom say which looks use it."""
from sprites import body  # noqa: F401
from sprites.body import *  # noqa: F401,F403  (the shared body, poses, drawing)
from sprites.weapons import *  # noqa: F401,F403


# Acoustic guitar: natural top (base, shade, light), sound hole, brown neck and headstock.
WOOD = ((226, 170, 96), (178, 118, 58), (246, 206, 140))
NECK = ((132, 80, 40), (96, 56, 28))
HOLE = (44, 30, 22)
# On the back: the grip (on the neck) from the torso top, and the angle it hangs at: the body
# against his back, the neck rising behind his head on the back side.
BACK_GRIP = (-15, -19)
BACK_ANGLE = -18


def guitar(grip, angle, opening=0):
    """The guitar's pixels, held at `grip` (on the neck below the headstock) and turned by
    `angle` degrees: 0 = hanging straight down from the grip, -90 = pointing forward, 180 =
    straight up (clockwise on screen)."""
    a = math.radians(angle)
    ax, ay = -math.sin(a), math.cos(a)        # along the guitar, grip -> body
    cx_, cy_ = -ay, ax                        # across
    out = {}
    gx, gy = grip
    for y in range(int(gy) - 40, int(gy) + 41):
        for x in range(int(gx) - 40, int(gx) + 41):
            dx, dy = x + 0.5 - gx, y + 0.5 - gy
            u = dx * ax + dy * ay             # along
            v = dx * cx_ + dy * cy_           # across
            lit = dx - dy                     # up and right is lit
            color = None
            upper = (u - 19) ** 2 + v * v
            lower = (u - 27.5) ** 2 + v * v
            if upper <= 5.2 ** 2 or lower <= 6.8 ** 2:
                if (u - 21) ** 2 + v * v <= 2.0 ** 2:
                    color = HOLE
                elif 28.5 <= u < 29.7 and abs(v) <= 2.6:
                    color = NECK[1]
                else:
                    edge = min(5.2 - math.sqrt(upper), 6.8 - math.sqrt(lower)) \
                        if upper <= 5.2 ** 2 and lower <= 6.8 ** 2 else \
                        (5.2 - math.sqrt(upper) if upper <= 5.2 ** 2 else 6.8 - math.sqrt(lower))
                    color = WOOD[0] if edge > 1.2 else WOOD[2] if lit > 0 else WOOD[1]
            elif -1 <= u <= 15 and abs(v) <= 1.3:
                color = NECK[0] if v * (cx_ - cy_) >= 0 else NECK[1]
            elif -5.5 <= u < -1 and abs(v) <= 2.0:
                color = NECK[1]
            if color:
                out[(x, y)] = color
    return out


WEAPONS["guitar"] = dict(draw=guitar, animations=GUITAR_ANIMATIONS, back=(BACK_GRIP, BACK_ANGLE))


def applies(c):
    return False  # Everything of his is the guitar (a weapon: its swings come with it).
