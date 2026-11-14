"""Gitte's own drawings for the 64 px sprite generator (docs/specs/characters/gitte.md#look).

Loaded by tools/gen_fighter_sprites64.py; the hooks at the bottom say which looks use it."""
from sprites import body  # noqa: F401
from sprites.body import *  # noqa: F401,F403  (the shared body, poses, drawing)
from sprites.weapons import *  # noqa: F401,F403


STEEL = ((200, 206, 216), (140, 148, 164), (236, 240, 246))
SCISSOR_HANDLE = ((204, 52, 52), (150, 30, 40), (236, 96, 90))
SCREW = (60, 62, 76)
SCISSOR_PIVOT = 7      # from the grip (the handles) to the pivot screw, px
SCISSOR_BLADE = 24     # from the pivot to a blade's tip
SCISSOR_RING = 3.9     # finger loop radius
SCISSOR_RING_BACK = 7  # loop centre: behind the pivot …
SCISSOR_RING_OUT = 3.6 # … and out to its side


def scissors(grip, angle, opening=0):
    """A large pair of scissors held by the handles at `grip`, pointing at `angle` (as the guitar:
    0 = hanging straight down, -90 = forward), the blades `opening` degrees apart."""
    a = math.radians(angle)
    d = (-math.sin(a), math.cos(a))
    pivot = (grip[0] + d[0] * SCISSOR_PIVOT, grip[1] + d[1] * SCISSOR_PIVOT)
    out = {}
    half = math.radians(opening) / 2
    for side in (1, -1):
        # A blade turned one way, its handle loop on the other side, behind the pivot.
        b = a + side * half
        bd = (-math.sin(b), math.cos(b))
        mid = (pivot[0] + bd[0] * SCISSOR_BLADE * 0.5, pivot[1] + bd[1] * SCISSOR_BLADE * 0.5)
        tip = (pivot[0] + bd[0] * SCISSOR_BLADE, pivot[1] + bd[1] * SCISSOR_BLADE)
        blade = shaded(segment_pixels(pivot, mid, 3.4), 3.4, *STEEL)
        blade.update(shaded(segment_pixels(mid, tip, 2.2), 2.2, *STEEL))
        nx, ny = -d[1] * side, d[0] * side
        ring_at = (pivot[0] - bd[0] * SCISSOR_RING_BACK + nx * SCISSOR_RING_OUT,
                   pivot[1] - bd[1] * SCISSOR_RING_BACK + ny * SCISSOR_RING_OUT)
        outer = disc(ring_at[0], ring_at[1], SCISSOR_RING)
        hole = disc(ring_at[0], ring_at[1], SCISSOR_RING - 1.7)
        handle = {k: SCISSOR_HANDLE[1] for k in segment_pixels(ring_at, pivot, 2.4)}
        handle.update({k: SCISSOR_HANDLE[0] for k in outer - hole})
        # A light edge on the loop's upper side so it reads as a rounded plastic handle.
        handle.update({k: SCISSOR_HANDLE[2] for k in outer - hole
                       if k[1] < ring_at[1] - SCISSOR_RING * 0.55})
        for k in hole:
            handle.pop(k, None)
        out.update(handle)
        out.update(blade)
    out.update({k: SCREW for k in disc(pivot[0], pivot[1], 1.0)})
    return out


# Gitte's scissor cut: held out in front, open while charging, snapped shut on the strike.
SCISSOR_ANIMATIONS = {
    "neutral_special_charge": [
        held(-80, crouch=1, lean=-1, fa=1.35, fe=0.1, ft=0.35, bt=-0.3, opening=40),
        held(-80, crouch=1, lean=-1, fa=1.35, fe=0.1, ft=0.4, bt=-0.35, opening=50)],
    "neutral_special": [held(-85, lean=1, fa=1.45, fe=0.0, reach=0.8, ft=0.4, bt=-0.4, opening=50),
                        held(-90, lean=3, fa=1.57, fe=0.0, reach=2.0, ft=0.6, fk=0.2, bt=-0.6,
                             bk=0.2),
                        held(-90, lean=2, fa=1.5, fe=0.0, reach=1.4, ft=0.45, bt=-0.45),
                        held(-60, fa=1.0, fe=0.3, ft=0.15, bt=-0.15)],
    # Stance switch: hands crossed in front, then flung out wide.
    "down_special": [pose(fa=1.2, fe=1.6, ba=1.0, be=1.8, crouch=1),
                     pose(fa=1.1, fe=1.7, ba=0.9, be=1.9, crouch=2, lean=-1),
                     pose(fa=1.45, fe=0.0, reach=1.0, ba=-1.45, be=0.0, lean=1),
                     pose(fa=1.35, fe=0.2, reach=0.6, ba=-1.35, be=-0.2),
                     pose(fa=0.6, fe=0.6, ba=-0.4)],
}



def mini_scissors_image():
    """Gitte's volley: a small pair of scissors, 3 drawings of 16×16 turned 120° further each."""
    out = Image.new("RGBA", (48, 16), (0, 0, 0, 0))
    for i in range(3):
        f = Frame()
        a = math.radians(120 * i + 30)
        d = (math.cos(a), math.sin(a))
        pivot = (8 - d[0] * 1, 8 - d[1] * 1)
        for side in (1, -1):
            b = a + side * 0.3
            bd = (math.cos(b), math.sin(b))
            tip = (pivot[0] + bd[0] * 6.5, pivot[1] + bd[1] * 6.5)
            f.part(shaded(segment_pixels(pivot, tip, 1.8), 1.8, *STEEL))
            ring = (pivot[0] - bd[0] * 4.0, pivot[1] - bd[1] * 4.0)
            f.part({k: SCISSOR_HANDLE[0]
                    for k in disc(ring[0], ring[1], 2.4) - disc(ring[0], ring[1], 0.9)})
        frame = Image.new("RGBA", (16, 16), (0, 0, 0, 0))
        for (x, y), color in f.px.items():
            if 0 <= x < 16 and 0 <= y < 16:
                frame.putpixel((x, y), color + (255,))
        out.paste(frame, (i * 16, 0))
    return out




PYRAMID_DRAWING = (168, 128)
PYRAMID_COURSES = 8          # rows of blocks, each COURSE_H tall...
COURSE_H = 16
PYRAMID_STEP = 10            # ...and this much narrower on each side than the one below
SAND = dict(base=(216, 180, 116), shade=(176, 138, 82), light=(240, 214, 156),
            grain_dark=(194, 156, 98), grain_light=(230, 198, 138), joint=(146, 108, 64),
            dark_end=(188, 150, 92))


def _sand_block(px, x0, x1, y0, y1, rng, exposed_top):
    """One rough-cut sandstone block over x0..x1-1, y0..y1-1: its own tone, grainy speckles, a
    light top edge (brighter where the step top is open to the sky), a darker bottom edge, a
    darker right end (the sun is on the left), and chipped corners (left out)."""
    tone = rng.randint(-10, 8)

    def tint(color, extra=0):
        return tuple(max(0, min(255, v + tone + extra)) for v in color)

    for y in range(y0, y1):
        for x in range(x0, x1):
            corner = (x in (x0, x1 - 1)) and (y in (y0, y1 - 1))
            if corner:
                continue
            if y == y0:
                color = tint(SAND["light"], 6 if exposed_top(x) else -6)
            elif y == y0 + 1 and exposed_top(x):
                color = tint(SAND["grain_light"])
            elif y == y1 - 1:
                color = tint(SAND["shade"])
            elif x >= x1 - 2:
                color = tint(SAND["dark_end"])
            else:
                r = rng.random()
                color = tint(SAND["grain_dark"] if r < 0.16 else SAND["grain_light"] if r < 0.30
                             else SAND["base"])
            px[(x, y)] = color


def pyramid_image():
    """Gitte's pyramid: a stepped pyramid of sandstone blocks, 8 courses, a capstone on top;
    its bottom center is the drawing's bottom center (on the floor). Fixed seed: always the same."""
    w, h = PYRAMID_DRAWING
    rng = random.Random(2026)
    px = {}
    for course in range(PYRAMID_COURSES):
        left = 1 + course * PYRAMID_STEP
        right = w - 1 - course * PYRAMID_STEP           # exclusive
        y1 = h - course * COURSE_H
        y0 = y1 - COURSE_H
        above = (left + PYRAMID_STEP, right - PYRAMID_STEP) if course < PYRAMID_COURSES - 1 \
            else (right, right)

        def exposed_top(x, above=above):
            return not (above[0] <= x < above[1])

        # Blocks 20-30 px wide; the first one's width varies per course so joints stagger.
        if course == PYRAMID_COURSES - 1:
            edges = [left, right]
        else:
            edges = [left]
            x = left + rng.randint(10, 22)
            while right - x > 14:
                edges.append(x)
                x += rng.randint(20, 30)
            edges.append(right)
        for a, b in zip(edges, edges[1:]):
            _sand_block(px, a, b - 1, y0, y1, rng, exposed_top)
            if b != right:
                for y in range(y0 + 1, y1 - 1):   # the joint
                    px[(b - 1, y)] = SAND["joint"]
    f = Frame()
    f.part(px)
    img = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    for (x, y), color in f.px.items():
        if 0 <= x < w and 0 <= y < h:
            img.putpixel((x, y), color + (255,))
    return img


# Gitte's pyramid call (up special): crouched, the front hand out low over the ground (calling it
# up); then riding the tip with her fist raised forward and up (shown for the whole rise); then the
# same with the legs tucked (the pop). Her back arm is hidden behind her body in this view.
PYRAMID_ANIMATIONS = {
    "up_special": [pose(crouch=2, lean=1, ft=0.5, fk=1.0, bt=0.3, bk=0.8, fa=1.3, fe=0.0,
                        reach=1.0, ba=-1.5, be=0.0),
                   pose(fa=2.0, fe=-0.2, reach=1.0, ba=-2.0, be=0.2, ft=0.06, fk=0.05, bt=-0.06,
                        bk=0.05),
                   pose(fa=1.8, fe=0.2, reach=1.0, ba=-1.9, be=-0.2, ft=0.3, fk=0.6, bt=-0.2,
                        bk=0.5)],
}


WEAPONS["scissors"] = dict(draw=scissors, animations=SCISSOR_ANIMATIONS, back=((-13, -7), -55))


def applies(c):
    return c.get("weapon") == "scissors" or c.get("pyramid")


def animations(c):
    return dict(PYRAMID_ANIMATIONS) if c.get("pyramid") else {}


def extra_files(c, out, strips):
    if c.get("weapon") == "scissors":
        mini_scissors_image().save(out / "projectile.png")
    if c.get("pyramid"):
        pyramid_image().save(out / "pyramid.png")
