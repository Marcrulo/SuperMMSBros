"""The shared body of the 64 px sprite generator (docs/specs/art-guide.md#64-px-style-trial).

The head is hand-drawn per character (tools/fighter64_looks.py); the body is drawn here from a
pose: a shaded torso, limbs as thick shaded strokes, fists and shoes. Every body part gets its own
1 px outline, so a limb in front of the torso reads clearly. Poses use the same angles as the
48 px generator (0 = straight down, positive = forward/right), scaled up.

Everything one character brings (a weapon, props, its own poses and pictures) is in
tools/sprites/characters/<name>.py; those modules plug in through the tables below.
"""
import json  # noqa: F401  (for the character modules)
import math
import random  # noqa: F401
import sys
from pathlib import Path

from PIL import Image, ImageDraw  # noqa: F401

sys.path.insert(0, str(Path(__file__).resolve().parent.parent))
import fighter64_looks as looks  # noqa: E402

# --- Plug-in tables (filled by the character modules when they're imported) -------------------

# Weapons by the name a look's `weapon` gives: dict(draw=fn(grip, angle, opening) -> pixels,
# animations={name: [pose]}, back=((x, y), angle) on the back, and optional choke, lowest, foot).
WEAPONS = {}
# Props a pose can carry, by pose key (in the order they're drawn): dict with any of
#   to_mouth=fn(value) -> bool   the front fist goes up to the mouth (a sip, a bite);
#   floor=fn(pose, front_foot) -> (pixels, data)   drawn before the face (an iPad on the floor);
#   face=fn(face_pixels, data, pose) -> pixels     changes the face (the iPad's screen light);
#   hand=fn(pose, fist, neck, to_mouth) -> pixels  drawn over the front fist (a mug, a cake).
PROPS = {}
# Drawings made another way, by pose key: fn(pose, c, p, heads) -> image (Pia's belly flop).
DRAWERS = {}
# While drawing a strip that will be flipped for facing left: lettering is drawn mirrored, so after
# the flip it reads the right way round (Mads's stop sign).
MIRROR_TEXT = False
# The front fist when a prop goes to the mouth, from the neck point.
SIP_FIST = (7, 0)

FRAME = 64
OUTLINE = looks.OUTLINE
K = 4 / 3            # 48 px pose numbers (lean, crouch, bob, reach) -> 64 px

# Body measurements (px).
TORSO_HALF = 7       # torso is 15 px wide
TORSO_LEN = 11       # shoulder row to hip row
LEG = 4.8            # thigh and shin length
LEG_W = (6.4, 5.6)   # thigh, shin width
ARM = (6.0, 5.5)     # upper arm, forearm length
RAISED = 2.2         # an upper arm past this angle is raised: it hinges higher, behind the head
RAISED_LIFT = 5      # how much higher (px)
RAISED_OUT = 7       # from the torso's center to the shoulder edge it hinges at (px)
RAISED_MAX = 2.75    # at most this upright, so it leans out past the head
ARM_W = (4.6, 4.0)
ARM_PAIR_GAP = 1.5   # extra pairs of arms: each this much lower on the torso (px)...
ARM_PAIR_ELBOW = 0.4  # ...with straighter elbows (bend × this), and bare (skin)
ARM_PAIR_OUT = 1.5    # extra arms never go past this (rad from hanging): below the horizontal...
ARM_PAIR_IN = -0.2    # ...nor further back than this
ARM_PAIR_FORWARD = 0.75  # a main arm already this far out gets its extras fanned downward


def fanned(angle, k, side, extras):
    """Extra arm k's (1..extras) upper-arm angle on its side (1 = front, -1 = back): evenly spaced
    from the main arm's angle toward a limit, never raised unless the main arm is. Fanned out
    toward the horizontal (ARM_PAIR_OUT), or down toward hanging (ARM_PAIR_IN) when the main arm
    is already out; a raised main arm's extras step back down to the horizontal."""
    out = side * angle
    if out > RAISED or out < ARM_PAIR_FORWARD:
        target = ARM_PAIR_OUT
    else:
        target = ARM_PAIR_IN
    return side * (out + (target - out) * k / extras)


def fanned_elbow(upper, elbow, main_upper):
    """An extra arm's elbow bend: straighter than the main arm's, and its forearm never above the
    horizontal unless the main arm is raised."""
    e = elbow * ARM_PAIR_ELBOW
    if abs(main_upper) <= RAISED and abs(upper + e) > math.pi / 2:
        e = math.copysign(math.pi / 2, upper + e) - upper
    return e
FIST_R = 2.5
# A slim build (`build="slim"`, or `slim` from 0 to 1 for a lighter version) at full strength:
SLIM = 3             # the torso this much narrower on each side (px)...
SLIM_ARMS = 0.78     # ...arms this much thinner...
SLIM_LEGS = 0.6      # ...legs this much thinner...
SLIM_FLARE = 4       # ...and a skirt flaring out this much (instead of 3), so it still reads
CENTER_X = 31        # torso center when standing
GROUND = 61          # ankle row when standing; shoes reach row 62, their outline row 63


def down(angle):
    return (math.sin(angle), math.cos(angle))


def add(p, d, length):
    return (p[0] + d[0] * length, p[1] + d[1] * length)


# --- Drawing ----------------------------------------------------------------------------------


class Frame:
    def __init__(self):
        self.px = {}

    def part(self, pixels):
        """Draw a body part with its own outline (which may cover parts drawn before it)."""
        for (x, y) in pixels:
            for n in ((x + 1, y), (x - 1, y), (x, y + 1), (x, y - 1)):
                if n not in pixels:
                    self.px[n] = OUTLINE
        self.px.update(pixels)

    def image(self, canvas=(FRAME, FRAME)):
        """The frame on a canvas of this size, the 64x64 frame at its bottom center."""
        w, h = canvas
        ox, oy = (w - FRAME) // 2, h - FRAME
        img = Image.new("RGBA", canvas, (0, 0, 0, 0))
        for (x, y), color in self.px.items():
            if 0 <= x + ox < w and 0 <= y + oy < h:
                img.putpixel((x + ox, y + oy), color + (255,))
        return img


def segment_pixels(a, b, width):
    """Pixels whose centers lie within width/2 of segment a-b, with their signed side offset
    (positive = the lit side, facing up and right)."""
    r = width / 2
    dx, dy = b[0] - a[0], b[1] - a[1]
    length = math.hypot(dx, dy) or 1e-6
    ux, uy = dx / length, dy / length
    nx, ny = -uy, ux
    if nx - ny < 0:
        nx, ny = -nx, -ny
    out = {}
    for y in range(int(min(a[1], b[1]) - r) - 1, int(max(a[1], b[1]) + r) + 2):
        for x in range(int(min(a[0], b[0]) - r) - 1, int(max(a[0], b[0]) + r) + 2):
            px, py = x + 0.5 - a[0], y + 0.5 - a[1]
            t = max(0.0, min(length, px * ux + py * uy))
            ex, ey = px - ux * t, py - uy * t
            if ex * ex + ey * ey <= r * r:
                out[(x, y)] = ex * nx + ey * ny
    return out


def shaded(pixels, width, base, shade, light):
    edge = width / 2 - 1.1
    return {k: light if s > edge else shade if s < -edge else base for k, s in pixels.items()}


def disc(cx, cy, r):
    return {(x, y) for y in range(int(cy - r) - 1, int(cy + r) + 2)
            for x in range(int(cx - r) - 1, int(cx + r) + 2)
            if (x + 0.5 - cx) ** 2 + (y + 0.5 - cy) ** 2 <= r * r}


BOTH_HANDS_GAP = 5   # px between the two fists on a weapon held in both hands


def reach_to(root, target):
    """An arm from `root` whose fist is at `target` (as near as the arm reaches), the elbow bent
    downward: [shoulder, elbow, fist]."""
    l1, l2 = ARM
    dx, dy = target[0] - root[0], target[1] - root[1]
    d = min(math.hypot(dx, dy), l1 + l2 - 0.01) or 0.01
    base = math.atan2(dy, dx)
    bend = math.acos(max(-1.0, min(1.0, (l1 * l1 + d * d - l2 * l2) / (2 * l1 * d))))
    # Of the two elbow positions, the lower one (larger y).
    elbows = [(root[0] + math.cos(base + sgn * bend) * l1, root[1] + math.sin(base + sgn * bend) * l1)
              for sgn in (1, -1)]
    elbow = max(elbows, key=lambda e: e[1])
    hand = (root[0] + math.cos(base) * d, root[1] + math.sin(base) * d) \
        if math.hypot(dx, dy) > d else target
    return [root, elbow, hand]


def limb(points, widths, colors):
    """A two-segment limb through `points`, one part with no line at the joint."""
    out = {}
    for (a, b), w in zip(zip(points, points[1:]), widths):
        out.update(shaded(segment_pixels(a, b, w), w, *colors))
    return out


def fist(at, p, dim=False, r=FIST_R):
    hand, hand_shade = (p["j"], looks.scale(p["j"], 0.85)) if dim else (p["J"], p["j"])
    out = {}
    for (x, y) in disc(at[0], at[1], r):
        lower_back = (x + 0.5 - at[0]) - (y + 0.5 - at[1]) < -1.2
        out[(x, y)] = hand_shade if lower_back else hand
    return out


def shoe(ankle, p, dim=False, small=False):
    """A shoe pointing forward, its sole at most on GROUND + 1; `small` for a slim build."""
    x0 = round(ankle[0])
    y0 = min(round(ankle[1]) - 1, GROUND - 1)
    dark = looks.scale(p["N"], 0.8) if dim else p["N"]
    light = p["N"] if dim else p["n"]
    back, front = (2, 3) if small else (3, 5)
    out = {}
    for x in range(x0 - back + 1, x0 + front - 2):
        out[(x, y0)] = dark
    for x in range(x0 - back, x0 + front):
        out[(x, y0 + 1)] = light if x0 - back < x < x0 + front - 1 else dark
    for x in range(x0 - back, x0 + front + 1):
        out[(x, y0 + 2)] = dark
    return out


def torso_half(c):
    return TORSO_HALF - round(SLIM * slimness(c))


def slimness(c):
    """How slim a character is built: 0 normal, 1 fully slim (`build="slim"`)."""
    return 1.0 if c.get("build") == "slim" else c.get("slim", 0.0)


def torso(c, p, top, top_x, hip, hip_x):
    """The torso from the shoulder row to the hip row, with the collar and clothing details."""
    half = torso_half(c)
    heavy = c.get("build") == "heavy"
    back_extra = 2 if heavy else 0
    out = {}
    for y in range(top, hip + 1):
        t = (y - top) / max(1, hip - top)
        cx = top_x + (hip_x - top_x) * t
        left = round(cx - half) - back_extra
        right = round(cx + half)
        if heavy and top + 4 <= y < hip:
            right += 1 if y in (top + 4, hip - 1) else 2
        if y == top:
            left, right = left + 1, right - 1
        for x in range(left, right + 1):
            color = p["H"]
            if x == left or y == hip or (x == right and y > top + 4):
                color = p["h"]
            elif y in (top + 1, top + 2) and round(cx) - 3 <= x <= round(cx) + 1:
                color = p["K"]
            if "stripe" in c and y in (top + 5, top + 6):
                color = p["V"]
            elif "dots" in c and color == p["H"] and (x * 3 + y * 2) % 7 == 0:
                color = p["Q"]
            out[(x, y)] = color
    cx = round(top_x)
    collar = c.get("collar", "crew")
    if collar == "hood":
        # The hood bunched into a roll around the neck, and bulging behind the head.
        for y in range(top - 1, top + 2):
            for x in range(cx - half - 1, cx + half):
                out[(x, y)] = p["h"] if y == top + 1 or x == cx - half - 1 else p["H"]
        for (x, y) in disc(cx - 6.5, top - 2.0, 2.2):
            out[(x, y)] = p["h"]
    elif collar == "tee":
        # A white T-shirt's neckline showing above a vest.
        tee = c.get("sleeve", (240, 240, 240))
        for x in range(cx - 2, cx + 5):
            out[(x, top)] = tee
        for x in range(cx - 1, cx + 4):
            out[(x, top + 1)] = looks.scale(tee, 0.85)
    elif collar == "crew":
        for x in range(cx - 2, cx + 5):
            out[(x, top)] = p["s"]
        for x in range(cx - 2, cx + 6):
            out[(x, top + 1)] = p["h"]
    if c.get("belly"):
        # Light fur down the chest and belly, at the front of the body.
        mid_y = (top + hip) / 2
        rx, ry = 4.6, (hip - top) / 2 + 0.6
        for (x, y) in list(out):
            t = (y - top) / max(1, hip - top)
            bx = top_x + (hip_x - top_x) * t + 2.5
            d = ((x + 0.5 - bx) / rx) ** 2 + ((y + 0.5 - mid_y) / ry) ** 2
            if d <= 1.0 and y < hip:
                out[(x, y)] = p["y"] if d > 0.62 and (x + 0.5 < bx or y + 0.5 > mid_y) else p["Y"]
    if "inner" in c:
        # An open jacket: the shirt shows in a V at the front.
        for i, (a, b) in enumerate(((-2, 6), (-1, 5), (0, 4), (1, 3))):
            for x in range(cx + a, cx + b + 1):
                out[(x, top + i)] = p["h"] if x in (cx + a, cx + b) and i > 0 else p["I"]
    return out


def skirt(p, hip, hip_x, half=TORSO_HALF, flare=3):
    """A bell-shaped skirt from the waist down: it flares out quickly (at most `flare` px a side),
    with folds (light and shaded stripes) and a dark hem."""
    out = {}
    cx = round(hip_x)
    for i in range(5):
        y = hip - 1 + i
        spread = min(i + (1 if i else 0), flare)
        left, right = cx - half - spread, cx + half - 1 + spread
        for x in range(left, right + 1):
            fold = (x - cx) % 3
            if i == 4 or x in (left, right):
                color = p["h"]
            elif i >= 1 and fold == 1:
                color = p["h"]
            elif i >= 1 and fold == 0:
                color = p["K"]
            else:
                color = p["H"]
            out[(x, y)] = color
    return out


def tail(p, hip, hip_x):
    """A monkey's tail curling up behind the hips."""
    pts = [(hip_x - 7, hip - 1), (hip_x - 11, hip + 1), (hip_x - 13, hip - 3),
           (hip_x - 12, hip - 7), (hip_x - 9, hip - 8)]
    out = {}
    for a, b in zip(pts, pts[1:]):
        out.update(shaded(segment_pixels(a, b, 3.0), 3.0, p["A"], p["a"], p["Z"]))
    return out


def head_pixels(c, p, cells, neck):
    nr, nc = looks.NECK
    out = {}
    for (r, col), ch in cells.items():
        x, y = neck[0] + col - nc, neck[1] + r - nr
        color = p[ch]
        if "camo" in c and ch in "SL" and r < 16:
            color = looks.camo_color(c, col, r) or color
        out[(x, y)] = color
    return out


# --- A frame ----------------------------------------------------------------------------------

# Where each drawn frame's front fist ended up (art px), in drawing order (for fitting paths).
FISTS = []
# The last drawn frame's fists per pair of arms (0 = the main pair): pair -> {"front", "back"}.
HANDS = {}


def draw_frame(pose, c, p, heads):
    f = Frame()
    HANDS.clear()
    small = c.get("build") == "small"
    leg_len = LEG - (0.5 if small else 0)
    torso_len = TORSO_LEN - (1 if small else 0)
    lean = pose.get("lean", 0) * K
    hip = round(GROUND - 2 * leg_len + pose.get("crouch", 0) * K)
    top = hip - torso_len + round(pose.get("bob", 0) * K)
    hip_x = CENTER_X + lean * 0.3
    top_x = CENTER_X + lean
    neck = (round(top_x) + 2 + round(pose.get("head_dx", 0) * K),
            top - 1 + round(pose.get("head_dy", 0) * K))
    behind, front = heads[pose.get("face", "normal")]
    if pose.get("head_only"):
        # Only the head (Pia's belly flop sets it upright on her turned body).
        if behind:
            f.part(head_pixels(c, p, behind, neck))
        f.part(head_pixels(c, p, front, neck))
        return f.image(c.get("canvas", (FRAME, FRAME)))
    headless = pose.get("headless", False)
    if headless:
        behind = None
    dim = lambda color: looks.scale(color, 0.8)
    t = slimness(c)
    slim = t >= 0.75     # small shoes and fists, a flared skirt
    narrow = round(SLIM * t)
    leg_w = tuple(w * (1 - (1 - SLIM_LEGS) * t) for w in LEG_W)
    arm_w = tuple(w * (1 - (1 - SLIM_ARMS) * t) for w in ARM_W)

    def leg_points(root, thigh, knee):
        k = add(root, down(thigh), leg_len)
        return [root, k, add(k, down(thigh - knee), leg_len)]

    def arm_points(root, upper, elbow, reach):
        if abs(upper) > RAISED:
            # Raised: the big head would hide the arm, so it comes up from the outer edge of
            # the shoulder (front or back), hinging higher up behind the head, held fairly
            # straight and leaning out, so the forearm and fist show beside the head.
            side = 1 if upper > 0 else -1
            root = (top_x + side * RAISED_OUT, top + 1 - RAISED_LIFT)
            upper = side * min(abs(upper), RAISED_MAX)
            elbow = max(-0.3, min(0.3, elbow))
        e = add(root, down(upper), ARM[0] + reach)
        return [root, e, add(e, down(upper + elbow), ARM[1] + reach)]

    pants = (p["D"], p["d"], looks.scale(p["D"], 1.15))
    pants_back = (dim(p["D"]), dim(p["d"]), p["D"])
    sleeve = (p["H"], p["h"], p["K"])
    sleeve_back = (p["h"], dim(p["h"]), p["H"])
    if "sleeve" in c:
        # A T-shirt under a vest: its own sleeves.
        e = c["sleeve"]
        sleeve = (e, looks.scale(e, 0.82), looks.scale(e, 1.05))
        sleeve_back = (looks.scale(e, 0.82), looks.scale(e, 0.68), e)
    bare, bare_back = (p["S"], p["s"], p["L"]), (p["s"], dim(p["s"]), p["S"])
    if c.get("short_sleeves"):
        fore, fore_back = (p["S"], p["s"], p["L"]), (p["s"], dim(p["s"]), p["S"])
    else:
        fore, fore_back = sleeve, sleeve_back

    # Weapon on the back, or held behind the body: behind everything.
    weapon = WEAPONS.get(c.get("weapon"))
    hold = pose.get("hold")
    if weapon and not hold:
        (bx, by), back_angle = weapon["back"]
        f.part(weapon["draw"]((top_x + bx, top + by), back_angle, 0))

    # Behind everything: long hair down the back, a tail.
    if behind:
        f.part(head_pixels(c, p, behind, neck))
    if c.get("monkey"):
        f.part(tail(p, hip, hip_x))

    # Back leg and arm (darker).
    pts = leg_points((hip_x - 3 + narrow / 2, hip + 1), pose["bt"], pose["bk"])
    part = limb(pts, leg_w, pants_back)
    part.update(shoe(pts[2], p, dim=True, small=slim))
    f.part(part)
    pts = leg_points((hip_x + 3.5 - narrow / 2, hip + 1), pose["ft"], pose["fk"])
    part = limb(pts, leg_w, pants)
    part.update(shoe(pts[2], p, small=slim))
    f.part(part)
    front_foot = pts[2]
    reach = pose.get("reach", 0) * K
    fist_r = FIST_R * (0.85 if slim else 1)
    # Extra pairs of arms (the furthest fanned first, so the main arms overlap them), from just
    # below the shoulders, fanned out from the main arms' pose.
    extra = range(c.get("arm_pairs", 1) - 1, 0, -1)
    for k in extra:
        upper = fanned(pose["ba"], k, -1, len(extra))
        pts = arm_points((top_x + 5 - narrow, top + 2 + ARM_PAIR_GAP * k), upper,
                         fanned_elbow(upper, pose["be"], pose["ba"]), 0)
        part = limb(pts, arm_w, bare_back)
        part.update(fist(pts[2], p, dim=True, r=fist_r))
        f.part(part)
        HANDS.setdefault(k, {})["back"] = pts[2]
    pts = arm_points((top_x + 5 - narrow, top + 2), pose["ba"], pose["be"], 0)
    back_fist = None
    if pose.get("both_hands"):
        # Both hands on the weapon: the back fist just above the front one (reached by bending
        # the elbow down), drawn over the weapon later.
        front_arm = arm_points((top_x - 1 + narrow / 2, top + 3), pose["fa"], pose["fe"], reach)
        pts = reach_to(pts[0], (front_arm[2][0], front_arm[2][1] - BOTH_HANDS_GAP))
        back_fist = fist(pts[2], p, dim=True, r=fist_r)
    part = limb(pts[:2], arm_w[:1], sleeve_back)
    part.update(limb(pts[1:], arm_w[1:], fore_back))
    part.update(fist(pts[2], p, dim=True, r=fist_r))
    f.part(part)
    HANDS.setdefault(0, {})["back"] = pts[2]

    # Torso, skirt.
    f.part(torso(c, p, top, top_x, hip, hip_x))
    if c.get("legs") == "skirt":
        f.part(skirt(p, hip, hip_x, torso_half(c), SLIM_FLARE if slim else 3))

    # Extra front arms, under the main one.
    for k in extra:
        upper = fanned(pose["fa"], k, 1, len(extra))
        pts = arm_points((top_x - 1 + narrow / 2, top + 3 + ARM_PAIR_GAP * k), upper,
                         fanned_elbow(upper, pose["fe"], pose["fa"]), reach)
        part = limb(pts, arm_w, bare)
        part.update(fist(pts[2], p, r=fist_r))
        f.part(part)
        HANDS.setdefault(k, {})["front"] = pts[2]

    # Front arm: behind the head when raised, so it never covers the face.
    pts = arm_points((top_x - 1 + narrow / 2, top + 3), pose["fa"], pose["fe"], reach)
    props = [(key, prop) for key, prop in PROPS.items() if key in pose]
    sipping = any(prop.get("to_mouth", lambda v: False)(pose[key]) for key, prop in props)
    if sipping:
        # A sip or a bite: the fist up at the chin, holding the prop to the mouth.
        pts = reach_to(pts[0], (neck[0] + SIP_FIST[0], neck[1] + SIP_FIST[1]))
    arm = limb(pts[:2], arm_w[:1], sleeve)
    arm.update(limb(pts[1:], arm_w[1:], fore))
    arm.update(fist(pts[2], p, r=FIST_R * (0.85 if slim else 1)))
    # An arm whose fist is above the chin goes behind the head, so it never covers the face.
    raised = pts[2][1] < neck[1] and not sipping
    FISTS.append(pts[2])
    HANDS.setdefault(0, {})["front"] = pts[2]
    held = None
    if weapon and hold:
        # Choked up: the hand this far down the neck from the usual grip.
        a = math.radians(hold[0])
        # `grip`: this pose holds the weapon that far up from the usual grip (any weapon).
        choke = pose.get("grip", hold[2] if weapon.get("choke", True) else 0)
        if pose.get("plant"):
            # Planted: held upright, the foot of the beam (CROSS_FOOT below the grip) on the floor
            # (the shoes' bottom row).
            choke = GROUND + 2 - pts[2][1] + weapon["foot"]
        grip = (pts[2][0] + math.sin(a) * choke, pts[2][1] - math.cos(a) * choke)
        # A weapon that mustn't point lower than this (forward and down) is raised to it.
        angle = hold[0]
        if "lowest" in weapon and weapon["lowest"] < angle < 90 and not pose.get("into_floor"):
            angle = weapon["lowest"]
        held = weapon["draw"](grip, angle, hold[3])
    if held and not hold[1]:
        f.part(held)     # held behind the body
    if raised:
        f.part(arm)
    # Props on the floor in front of the feet (Trine's iPad), which may light the face.
    floor = [(prop, prop["floor"](pose, front_foot)) for _, prop in props if "floor" in prop]
    for _, (pixels, _) in floor:
        f.part(pixels)
    face = {} if headless else head_pixels(c, p, front, neck)
    for prop, (_, data) in floor:
        if "face" in prop:
            face = prop["face"](face, data, pose)
    if face:
        f.part(face)
    if held and hold[1]:
        f.part(held)     # swung in front, under the fist
        if back_fist:
            f.part(back_fist)
    if not raised:
        f.part(arm)
    # Props in the front hand, drawn over it (Pia's cake, Trine's mug).
    for _, prop in props:
        if "hand" in prop:
            f.part(prop["hand"](pose, pts[2], neck, sipping))
    return f.image(c.get("canvas", (FRAME, FRAME)))


# --- Poses ------------------------------------------------------------------------------------

BASE = dict(ft=0.08, fk=0.1, bt=-0.08, bk=0.1, fa=0.25, fe=0.5, ba=-0.2, be=0.5)
GUARD = dict(ft=0.4, fk=0.15, bt=-0.45, bk=0.1, fa=0.0, fe=1.9, ba=0.64, be=1.47)


def pose(**changes):
    p = dict(BASE)
    p.update(changes)
    return p


def guard(**changes):
    return pose(**{**GUARD, **changes})


def run_pose(i):
    phase = i / 6 * 2 * math.pi
    s = math.sin(phase)
    return pose(lean=1, bob=-round(abs(math.cos(phase))), ft=0.7 * s, bt=-0.7 * s,
                fk=0.25 + max(0, -s) * 0.9, bk=0.25 + max(0, s) * 0.9,
                fa=-0.9 * s, ba=0.9 * s, fe=1.0, be=1.0)


ATTACK = [pose(lean=-1, fa=-1.2, fe=1.6, ba=0.3),
          pose(lean=-1, fa=-1.5, fe=1.9, ba=0.5, ft=0.3, bt=-0.3),
          pose(lean=2, fa=1.57, fe=0.0, reach=1.6, ba=-0.6, ft=0.45, fk=0.2, bt=-0.4, bk=0.2),
          pose(lean=1, fa=1.3, fe=0.3, reach=0.6, ba=-0.4, ft=0.3, bt=-0.3),
          pose(lean=0, fa=0.8, fe=0.6, ft=0.15, bt=-0.15)]

AIR = dict(ft=0.35, fk=0.4, bt=-0.25, bk=0.5)


def air_pose(**changes):
    return pose(**{**AIR, **changes})


# Drawing counts and order follow docs/specs/art-guide.md; the strike pose is the drawing shown
# on a move's active frames.
ANIMATIONS = {
    "idle": [guard(), guard(), guard(bob=1), guard(bob=1)],
    "run": [run_pose(i) for i in range(6)],
    "crouch": [pose(crouch=2, ft=0.6, fk=1.1, bt=0.3, bk=0.9, fa=0.4),
               pose(crouch=4, lean=1, ft=1.1, fk=2.1, bt=0.7, bk=1.8, fa=0.7, fe=0.8, ba=0.3)],
    "jump": [pose(crouch=1, ft=0.4, fk=0.9, bt=-0.3, bk=0.9, fa=-0.6, ba=-0.9),
             pose(ft=1.1, fk=1.7, bt=0.3, bk=1.3, fa=1.9, fe=-0.4, ba=-1.2, be=0.5)],
    "fall": [pose(ft=0.35, fk=0.4, bt=-0.25, bk=0.5, fa=1.8, fe=0.5, ba=-1.8, be=-0.5),
             pose(ft=0.3, fk=0.5, bt=-0.3, bk=0.4, fa=2.0, fe=0.4, ba=-2.0, be=-0.4)],
    "helpless": [pose(face="shut", fa=2.8, fe=0.2, ba=-2.8, be=-0.2, ft=0.2, fk=0.3, bt=-0.2, bk=0.3),
                 pose(face="shut", head_dy=1, fa=2.6, fe=0.4, ba=-2.6, be=-0.4, ft=0.3, fk=0.4,
                      bt=-0.3, bk=0.4)],
    "shield": [pose(crouch=1, fa=1.2, fe=1.5, ba=1.0, be=1.6, ft=0.25, bt=-0.25)],
    "dizzy": [pose(head_dx=1, face="shut", fa=0.3, ba=-0.3, ft=0.1, bt=-0.2),
              pose(head_dx=-1, face="shut", lean=-1, fa=-0.2, ba=0.2, ft=0.2, bt=-0.1)],
    "hurt": [pose(lean=-2, head_dx=-1, head_dy=-1, face="hurt", fa=2.6, fe=0.6, ba=-2.6, be=-0.6,
                  ft=-0.5, fk=0.6, bt=0.4, bk=0.6),
             pose(lean=-2, head_dx=-1, face="hurt", fa=2.2, fe=0.9, ba=-2.8, be=-0.3,
                  ft=-0.3, fk=0.8, bt=0.5, bk=0.4)],
    "spot_dodge": [pose(crouch=1, lean=-1, fa=0.6, fe=1.4, ba=0.4, be=1.4),
                   pose(crouch=2, lean=-2, head_dx=-1, face="shut", fa=1.0, fe=1.8, ba=0.8, be=1.8,
                        ft=0.3, fk=0.7, bt=-0.4, bk=0.7),
                   pose(crouch=1, fa=0.5, fe=0.8, ba=-0.3, be=0.6)],
    "roll": [pose(crouch=3, lean=2, ft=0.9, fk=1.7, bt=0.5, bk=1.5, fa=1.2, fe=1.6, ba=0.9, be=1.6),
             pose(crouch=5, lean=3, head_dy=2, face="shut", ft=1.4, fk=2.3, bt=1.1, bk=2.2,
                  fa=1.6, fe=1.8, ba=1.4, be=1.8),
             pose(crouch=5, lean=2, head_dy=2, face="shut", ft=1.2, fk=2.2, bt=1.0, bk=2.1,
                  fa=1.0, fe=2.0, ba=1.0, be=2.0),
             pose(crouch=2, lean=-1, ft=0.5, fk=1.0, bt=-0.2, bk=0.8, fa=0.5, fe=1.0, ba=-0.4)],
    "air_dodge": [air_pose(fa=1.2, fe=1.6, ba=1.0, be=1.6, ft=0.8, fk=1.4, bt=0.6, bk=1.4),
                  air_pose(face="shut", fa=1.4, fe=1.9, ba=1.2, be=1.9, ft=1.0, fk=1.8, bt=0.8,
                           bk=1.7)],
    "ledge": [pose(fa=2.75, fe=0.1, reach=0.8, ba=2.6, be=0.1, ft=0.2, fk=0.4, bt=-0.1, bk=0.5),
              pose(fa=2.75, fe=0.1, reach=0.8, ba=2.6, be=0.1, ft=0.1, fk=0.6, bt=0.0, bk=0.3)],
    "ledge_climb": [pose(crouch=2, fa=2.4, fe=0.5, ba=2.2, be=0.5, ft=1.0, fk=1.8, bt=0.3, bk=1.0),
                    pose(crouch=4, lean=2, fa=1.2, fe=1.4, ba=1.0, be=1.4, ft=1.3, fk=2.2, bt=0.5,
                         bk=1.6),
                    pose(crouch=1, lean=1, fa=0.5, fe=0.8, ba=-0.3, ft=0.4, fk=0.6, bt=-0.2,
                         bk=0.4)],
    "jab": ATTACK,
    "down_tilt": [pose(crouch=2, lean=-1, ft=0.6, fk=1.2, bt=0.2, bk=0.8, fa=-0.4),
                  pose(crouch=3, lean=-1, ft=-0.3, fk=1.5, bt=0.4, bk=1.0, fa=-0.6),
                  pose(crouch=3, lean=-1, ft=1.5, fk=0.0, bt=0.5, bk=1.4, fa=-0.8, ba=0.4),
                  pose(crouch=2, ft=1.0, fk=0.6, bt=0.3, bk=1.0, fa=-0.4),
                  pose(crouch=1, ft=0.4, fk=0.4, bt=-0.1, bk=0.4)],
    "up_tilt": [pose(lean=-1, fa=-0.6, fe=1.2, ba=0.4),
                pose(lean=-1, crouch=1, fa=0.6, fe=1.4, ba=0.2),
                pose(lean=1, fa=3.0, fe=0.0, reach=1.0, ba=-0.8, ft=0.2, bt=-0.2),
                pose(fa=2.3, fe=0.4, ba=-0.5),
                pose(fa=1.0, fe=0.6)],
    "side_tilt": [pose(lean=-1, ft=-0.3, fk=0.9, bt=0.1, fa=0.6, ba=-0.6),
                  pose(lean=-2, ft=0.6, fk=1.6, bt=-0.1, fa=0.8, ba=-0.8),
                  pose(lean=-2, ft=1.57, fk=0.0, bt=-0.2, bk=0.2, fa=-0.6, ba=0.8),
                  pose(lean=-1, ft=1.0, fk=0.5, bt=-0.1, fa=-0.2, ba=0.4),
                  pose(ft=0.4, fk=0.4, bt=-0.2)],
    "neutral_air": [air_pose(crouch=1, ft=0.9, fk=1.6, bt=0.5, bk=1.5, fa=0.9, fe=1.4, ba=-0.9, be=-1.4),
                    air_pose(crouch=1, ft=1.0, fk=1.8, bt=0.6, bk=1.6, fa=0.7, fe=1.6, ba=-0.7, be=-1.6),
                    air_pose(fa=1.9, fe=0.0, reach=0.6, ba=-1.9, be=0.0, ft=0.9, fk=0.0, bt=-0.9, bk=0.0),
                    air_pose(fa=1.4, fe=0.4, ba=-1.4, be=-0.4, ft=0.6, fk=0.3, bt=-0.6, bk=0.3),
                    air_pose(fa=0.8, fe=0.6, ba=-0.8, be=-0.6)],
    "forward_air": [air_pose(lean=-1, fa=-1.2, fe=1.6, ba=0.3),
                    air_pose(lean=-1, fa=-1.5, fe=1.9, ba=0.5),
                    air_pose(lean=2, fa=1.57, fe=0.0, reach=1.6, ba=-0.6, ft=0.6, fk=0.3),
                    air_pose(lean=1, fa=1.3, fe=0.3, reach=0.6, ba=-0.4),
                    air_pose(fa=0.8, fe=0.6)],
    "back_air": [air_pose(lean=1, bt=0.4, bk=1.6, fa=0.6, ba=-0.4),
                 air_pose(lean=2, bt=0.6, bk=2.0, ft=0.6, fk=1.0, fa=0.9, ba=-0.2),
                 air_pose(lean=2, head_dx=1, bt=-1.57, bk=0.0, ft=0.5, fk=0.8, fa=1.0, fe=0.6, ba=-1.0),
                 air_pose(lean=1, bt=-1.0, bk=0.4, ft=0.4, fk=0.6, fa=0.7, ba=-0.6),
                 air_pose(fa=0.4, ba=-0.3)],
    "up_air": [air_pose(fa=-0.4, fe=1.0, ba=0.4, be=1.0),
               air_pose(crouch=1, fa=0.8, fe=1.2, ba=-0.8, be=-1.2, ft=0.7, fk=1.2, bt=0.4, bk=1.2),
               air_pose(head_dy=-1, fa=3.0, fe=0.0, reach=1.0, ba=-2.9, be=0.0, ft=0.2, fk=0.2, bt=-0.2, bk=0.2),
               air_pose(fa=2.4, fe=0.4, ba=-2.3, be=-0.4),
               air_pose(fa=1.4, fe=0.6, ba=-1.2, be=-0.6)],
    "down_air": [air_pose(crouch=-1, ft=1.1, fk=1.9, bt=0.8, bk=1.8, fa=1.6, fe=0.4, ba=-1.6, be=-0.4),
                 air_pose(crouch=-2, ft=1.3, fk=2.2, bt=1.0, bk=2.1, fa=2.0, fe=0.3, ba=-2.0, be=-0.3),
                 air_pose(head_dy=-1, ft=0.05, fk=0.0, bt=-0.05, bk=0.0, fa=2.6, fe=0.2, ba=-2.6, be=-0.2),
                 air_pose(ft=0.2, fk=0.2, bt=-0.2, bk=0.3, fa=2.0, fe=0.4, ba=-2.0, be=-0.4),
                 air_pose(fa=1.2, fe=0.5, ba=-1.2, be=-0.5)],
    "neutral_special_charge": [pose(crouch=1, lean=-1, fa=-0.8, fe=1.8, ba=-1.0, be=1.6, ft=0.35, bt=-0.3),
                               pose(crouch=2, lean=-1, fa=-0.9, fe=1.9, ba=-1.1, be=1.7, ft=0.4, bt=-0.35)],
    "neutral_special": [pose(lean=-2, fa=-1.4, fe=1.9, ba=0.4, ft=0.3, bt=-0.4),
                        pose(lean=3, fa=1.57, fe=0.0, reach=2.0, ba=-0.8, ft=0.6, fk=0.2, bt=-0.6, bk=0.2),
                        pose(lean=1, fa=1.2, fe=0.4, reach=0.8, ba=-0.4, ft=0.3, bt=-0.3),
                        pose(fa=0.6, fe=0.6, ft=0.15, bt=-0.15)],
    "down_special_dive": [pose(fa=2.9, fe=0.0, ba=-2.9, be=0.0, ft=0.1, fk=0.0, bt=-0.1, bk=0.0)],
    "down_special": [pose(crouch=1, fa=2.6, fe=0.3, ba=-2.6, be=-0.3),
                     pose(crouch=4, fa=0.4, fe=0.4, ba=-0.4, be=-0.4, ft=1.0, fk=1.9, bt=0.6, bk=1.6),
                     pose(crouch=3, fa=1.1, fe=0.0, ba=-1.1, be=0.0, ft=0.9, fk=1.6, bt=-0.6, bk=0.6),
                     pose(crouch=2, fa=0.7, fe=0.3, ba=-0.7, ft=0.6, fk=1.0, bt=-0.3, bk=0.6),
                     pose(crouch=1, ft=0.3, fk=0.5, bt=-0.2, bk=0.4)],
    "side_special": [pose(lean=-1, fa=-1.0, fe=1.4, ba=0.6),
                     pose(lean=-1, fa=-1.4, fe=1.8, ba=0.7, ft=0.3, bt=-0.3),
                     pose(lean=1, fa=1.57, fe=0.0, reach=1.2, ba=-0.6, ft=0.35, bt=-0.35),
                     pose(fa=0.9, fe=0.5)],
    "up_special": [pose(crouch=3, ft=0.9, fk=1.7, bt=0.6, bk=1.5, fa=-0.6, ba=-0.8),
                   pose(ft=1.0, fk=1.6, bt=0.4, bk=1.2, fa=3.1, fe=0.0, reach=1.0, ba=-1.6),
                   pose(ft=0.8, fk=1.4, bt=0.3, bk=1.1, fa=3.0, fe=0.2, reach=0.6, ba=-1.4)],
}
