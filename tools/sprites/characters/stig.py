"""Stig's own drawings for the 64 px sprite generator (docs/specs/characters/stig.md#look).

Loaded by tools/gen_fighter_sprites64.py; the hooks at the bottom say which looks use it."""
from sprites import body  # noqa: F401
from sprites.body import *  # noqa: F401,F403  (the shared body, poses, drawing)
from sprites.weapons import *  # noqa: F401,F403


GOLD = ((226, 182, 56), (168, 120, 28), (255, 228, 128))
CROSS_FOOT = -6        # from the grip (the hand) back to the foot of the long beam, px
CROSS_TOP = 33         # from the grip to the top of the long beam
CROSS_BAR_AT = 27      # from the grip to the crossbar's middle (the top arm shorter than the side arms)
CROSS_ARM = 8          # crossbar arm length each side of the beam
CROSS_HALF = 1.8       # half the width of both beams


def cross(grip, angle, opening=0):
    """A solid gold Latin cross, held near the foot of its long beam at `grip` and pointing at
    `angle` (as the guitar: 0 = hanging straight down, -90 = forward, 180 = straight up): the
    crossbar sits near the far end, so it reads as a cross even when swung like a sword. Each
    pixel within 1 px of an edge is lit or shaded by which way that edge faces on screen."""
    a = math.radians(angle)
    ax, ay = -math.sin(a), math.cos(a)        # along, grip -> top
    cx_, cy_ = -ay, ax                        # across
    out = {}
    gx, gy = grip
    for y in range(int(gy) - 40, int(gy) + 41):
        for x in range(int(gx) - 40, int(gx) + 41):
            dx, dy = x + 0.5 - gx, y + 0.5 - gy
            u = dx * ax + dy * ay
            v = dx * cx_ + dy * cy_
            g = u - CROSS_BAR_AT
            beam = CROSS_FOOT <= u <= CROSS_TOP and abs(v) <= CROSS_HALF
            bar = abs(g) <= CROSS_HALF and abs(v) <= CROSS_ARM
            if not (beam or bar):
                continue
            # Edges (distance to it, outward direction in (along, across)).
            side = 1 if v > 0 else -1
            edges = []
            if beam:
                edges += [(u - CROSS_FOOT, (-1, 0)), (CROSS_TOP - u, (1, 0))]
                if not bar:
                    edges.append((CROSS_HALF - abs(v), (0, side)))
            if bar:
                edges.append((CROSS_ARM - abs(v), (0, side)))
                if not beam:
                    edges.append((CROSS_HALF - abs(g), (1 if g > 0 else -1, 0)))
            depth, (du, dv) = min(edges, key=lambda e: e[0])
            if depth > 1.0:
                out[(x, y)] = GOLD[0]
            else:
                sx, sy = du * ax + dv * cx_, du * ay + dv * cy_
                out[(x, y)] = GOLD[2] if sx - sy > 0 else GOLD[1]
    return out


# On his back diagonally like Gitte's scissors: the cross head up behind his neck, the foot
# poking out in front of his hip. Held by the foot of the long beam even where Henrik chokes
# up on the neck; never pointing below level, so in the follow-throughs the crossbar at the
# far end stays above the floor.
WEAPONS["cross"] = dict(draw=cross, animations=GUITAR_ANIMATIONS, back=((7, 9), 126), choke=False,
                        foot=CROSS_FOOT, lowest=-90)


def applies(c):
    return c.get("cross_smash")


def animations(c):
    return dict(CROSS_SMASH_ANIMATIONS)


def extra_files(c, out, strips):
    burst_image().save(out / "burst.png")
