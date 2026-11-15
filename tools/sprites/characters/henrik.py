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


# --- Speaker jam (down special): playing the guitar -------------------------------------------
# The front (near) arm strums: its fist is on the sound hole (the guitar is held there: `choke` =
# the sound hole's distance from the usual grip), the guitar across his belly, its neck pointing
# forward and up. The far arm frets: it reaches forward from behind his body, so only its fist
# shows, on the neck past his chest (drawn behind the guitar).
PLAY_ANGLE = 62        # the guitar's line, grip -> body (as `guitar`: 0 down, 90 back)
SOUND_HOLE = 21        # from the grip along the guitar (see `guitar`)
FRET = dict(ba=1.5, be=0.0)


def play_animations(c):
    def playing(**changes):
        return held(PLAY_ANGLE, True, SOUND_HOLE, **{**FRET, **changes})

    return {
        "down_special": [
            # Swung round from his back: held up by the neck in front, the body hanging below.
            held(25, True, 6, fa=1.3, fe=0.5, ft=0.15, bt=-0.15, ba=0.4, be=0.8),
            playing(fa=0.25, fe=1.25, ft=0.25, bt=-0.2),               # strum, high
            playing(fa=0.4, fe=0.85, ft=0.25, bt=-0.2, bob=1),         # strum, low
            # The beat: a big downstroke, leaning back, head up.
            playing(fa=0.55, fe=0.5, lean=-2, head_dy=-1, crouch=1, ft=0.5, fk=0.4, bt=-0.4,
                    bk=0.3),
            # Lowering it, on its way to his back.
            held(10, False, 6, fa=0.7, fe=0.5, ft=0.1, bt=-0.1, ba=0.2, be=0.6)],
    }


# --- Speakers (docs/specs/characters/henrik.md#henriks-speakers) -------------------------------
SPEAKER_SIZE = (24, 32)
CABINET = ((46, 46, 54), (30, 30, 36), (80, 80, 94))       # front, side panel, top edge
CORNER = (192, 196, 206)
SURROUND = (22, 22, 26)
CONE = ((118, 120, 132), (150, 152, 166), (176, 180, 194))  # at rest, on the beat, highlight
CAP = (36, 36, 42)
TWEETER = (156, 158, 170)


def speaker_image():
    """2 drawings: at rest, and on the beat (the woofer cone pushed out: lighter, 1 px bigger).
    The side panel is on the right (the game turns it toward Henrik)."""
    (w, h), n = SPEAKER_SIZE, 2
    out = Image.new("RGBA", (w * n, h), (0, 0, 0, 0))
    px = out.load()
    for i in range(n):
        def put(x, y, color):
            px[i * w + x, y] = color + (255,)
        x0, x1, y0, y1 = 2, 21, 1, 31          # the cabinet, outline included
        for y in range(y0, y1 + 1):
            for x in range(x0, x1 + 1):
                edge = x in (x0, x1) or y in (y0, y1)
                color = OUTLINE if edge else CABINET[1] if x >= x1 - 3 else \
                    CABINET[2] if y == y0 + 1 else CABINET[0]
                if x == x1 - 4 and not edge:
                    color = OUTLINE                         # the front's edge to the side panel
                put(x, y, color)
        for cx, cy in ((x0 + 1, y0 + 1), (x1 - 2, y0 + 1), (x0 + 1, y1 - 2), (x1 - 2, y1 - 2)):
            for dx in range(2):
                for dy in range(2):
                    put(cx + dx, cy + dy, CORNER)       # metal corner caps
        mid = (x0 + x1 - 4) / 2 + 0.5               # the front's middle
        beat = i == 1
        for y in range(h):
            for x in range(x0 + 1, x1 - 4):
                dx, dy = x + 0.5 - mid, y + 0.5 - 9.5
                r = math.hypot(dx, dy)               # the tweeter
                if r <= 1.2:
                    put(x, y, CAP)
                elif r <= 2.6:
                    put(x, y, TWEETER)
                elif r <= 3.4:
                    put(x, y, SURROUND)
                dx, dy = x + 0.5 - mid, y + 0.5 - 21.5
                r = math.hypot(dx, dy)               # the woofer
                cone = 6.0 if beat else 5.0
                if r <= 2.0:
                    put(x, y, CAP)
                elif r <= cone:
                    lit = dx + dy < -2.5 and r > cone - 2
                    put(x, y, CONE[2] if lit else CONE[1] if beat else CONE[0])
                elif r <= 7.4:
                    put(x, y, SURROUND)
    return out


def applies(c):
    return c.get("speakers")  # His swings come with the guitar (a weapon); this is the jam.


def animations(c):
    return play_animations(c) if c.get("speakers") else {}


def extra_files(c, out, strips):
    if c.get("speakers"):
        speaker_image().save(out / "speaker.png")
