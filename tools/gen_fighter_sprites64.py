"""Generates a fighter's pixel-art strips at 64x64 (docs/specs/art-guide.md, 64 px draft).

The head is hand-drawn per character (tools/fighter64_looks.py); the body is drawn here from a
pose: a shaded torso, limbs as thick shaded strokes, fists and shoes. Every body part gets its own
1 px outline, so a limb in front of the torso reads clearly. Poses use the same angles as the
48 px generator (0 = straight down, positive = forward/right), scaled up.
Usage:
  python3 -I tools/gen_fighter_sprites64.py <out_dir> [ids...] [--preview]
Strips go to <out_dir>/<id>/; --preview also writes <out_dir>/<id>_preview.png (every frame).
The game's strips: python3 -I tools/gen_fighter_sprites64.py super-mms-bros/assets/fighters slot_05
"""
import math
import random
import sys
from pathlib import Path

from PIL import Image, ImageDraw

sys.path.insert(0, str(Path(__file__).resolve().parent))
import fighter64_looks as looks  # noqa: E402

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
            color = looks.camo_color(c, col, r)
        out[(x, y)] = color
    return out


# --- A frame ----------------------------------------------------------------------------------


def draw_frame(pose, c, p, heads):
    f = Frame()
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
    pts = arm_points((top_x + 5 - narrow, top + 2), pose["ba"], pose["be"], 0)
    part = limb(pts[:2], arm_w[:1], sleeve_back)
    part.update(limb(pts[1:], arm_w[1:], fore_back))
    part.update(fist(pts[2], p, dim=True, r=fist_r))
    f.part(part)

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

    # Front arm: behind the head when raised, so it never covers the face.
    pts = arm_points((top_x - 1 + narrow / 2, top + 3), pose["fa"], pose["fe"], reach)
    arm = limb(pts[:2], arm_w[:1], sleeve)
    arm.update(limb(pts[1:], arm_w[1:], fore))
    arm.update(fist(pts[2], p, r=FIST_R * (0.85 if slim else 1)))
    # An arm whose fist is above the chin goes behind the head, so it never covers the face.
    raised = pts[2][1] < neck[1]
    held = None
    if weapon and hold:
        # Choked up: the hand this far down the neck from the usual grip.
        a = math.radians(hold[0])
        grip = (pts[2][0] + math.sin(a) * hold[2], pts[2][1] - math.cos(a) * hold[2])
        held = weapon["draw"](grip, hold[0], hold[3])
    if held and not hold[1]:
        f.part(held)     # held behind the body
    if raised:
        f.part(arm)
    f.part(head_pixels(c, p, front, neck))
    if held and hold[1]:
        f.part(held)     # swung in front, under the fist
    if not raised:
        f.part(arm)
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


# --- Weapons (docs/specs/art-guide.md#weapons) -----------------------------------------------

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
# --- Gitte's scissors -------------------------------------------------------------------------

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

WEAPONS = {
    "guitar": dict(draw=guitar, animations=GUITAR_ANIMATIONS, back=(BACK_GRIP, BACK_ANGLE)),
    "scissors": dict(draw=scissors, animations=SCISSOR_ANIMATIONS, back=((-13, -7), -55)),
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


# --- Summoned hand (docs/specs/art-guide.md#michaels-hand) --------------------------------------

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


# --- Football (docs/specs/art-guide.md#michaels-football) ----------------------------------------

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


# --- Fidusen's peel and book (docs/specs/art-guide.md#fidusens-peel-and-book) ----------------------

BANANA = ((246, 214, 60), (206, 160, 30), (255, 240, 140))
BANANA_TIP = (110, 74, 34)
BOOK_COVER = ((178, 46, 52), (124, 28, 40), (220, 82, 80))
BOOK_PAGES = ((240, 236, 222), (200, 194, 178))


def peel_image():
    """A banana peel lying on the floor (16×8): a stub in the middle, three floppy flaps."""
    f = Frame()
    body = {}
    # Two flaps drooping to the sides, a shorter one in front, all from the top of the peel.
    for a, b, w in (((7.5, 3.6), (2.2, 6.8), 2.8), ((8.5, 3.6), (13.8, 6.8), 2.8),
                    ((8, 3.8), (9.2, 6.8), 2.6)):
        f.part(shaded(segment_pixels(a, b, w), w, *BANANA))
    stub = {(x, y): BANANA[1] for (x, y) in segment_pixels((8, 3.2), (8, 1.2), 1.8)}
    stub.update({(x, y): BANANA_TIP for (x, y) in segment_pixels((8, 1.6), (8, 0.8), 1.8)})
    f.part(stub)
    img = Image.new("RGBA", (16, 8), (0, 0, 0, 0))
    for (x, y), color in f.px.items():
        if 0 <= x < 16 and 0 <= y < 8:
            img.putpixel((x, y), color + (255,))
    return img


def book_image():
    """A book, 3 drawings of 16×16 each turned 120° further (it spins): a red cover with white
    page edges."""
    out = Image.new("RGBA", (48, 16), (0, 0, 0, 0))
    for i in range(3):
        f = Frame()
        a = math.radians(120 * i + 15)
        ux, uy = math.cos(a), math.sin(a)        # along the spine
        vx, vy = -uy, ux                          # across the cover
        px = {}
        for y in range(16):
            for x in range(16):
                dx, dy = x + 0.5 - 8, y + 0.5 - 8
                u, v = dx * ux + dy * uy, dx * vx + dy * vy
                if abs(u) <= 5.2 and abs(v) <= 4.0:
                    if v > 2.6:
                        px[(x, y)] = BOOK_PAGES[0] if u > -4 else BOOK_PAGES[1]
                    else:
                        px[(x, y)] = BOOK_COVER[2] if v < -2.6 else BOOK_COVER[0] \
                            if abs(u) < 4 else BOOK_COVER[1]
        f.part(px)
        frame = Image.new("RGBA", (16, 16), (0, 0, 0, 0))
        for (x, y), color in f.px.items():
            if 0 <= x < 16 and 0 <= y < 16:
                frame.putpixel((x, y), color + (255,))
        out.paste(frame, (i * 16, 0))
    return out


# Fidusen's drop (down special: bend, drop, crouch, rise, stand) and throw (side special: wind
# back, throw over the shoulder, follow-through, stand).
FIDUSEN_ANIMATIONS = {
    "down_special": [pose(crouch=1, lean=1, fa=0.5, fe=0.6, ba=-0.3),
                     pose(crouch=3, lean=2, ft=0.9, fk=1.7, bt=0.5, bk=1.5, fa=0.9, fe=0.2,
                          reach=0.6, ba=-0.2),
                     pose(crouch=3, lean=2, ft=0.9, fk=1.7, bt=0.5, bk=1.5, fa=0.7, fe=0.4,
                          ba=-0.2),
                     pose(crouch=1, lean=1, ft=0.4, fk=0.8, bt=0.2, bk=0.6, fa=0.4, fe=0.6),
                     pose()],
    "side_special": [pose(lean=-2, fa=-2.0, fe=0.8, ba=0.6, ft=0.3, bt=-0.3),
                     pose(lean=1, fa=2.0, fe=0.1, reach=0.8, ba=-0.6, ft=0.45, fk=0.2,
                          bt=-0.45, bk=0.2),
                     pose(lean=2, fa=1.2, fe=0.1, reach=1.0, ba=-0.7, ft=0.5, fk=0.2,
                          bt=-0.5, bk=0.2),
                     pose(fa=0.6, fe=0.6, ft=0.15, bt=-0.15)],
}


# --- Gitte's pyramid (docs/specs/art-guide.md#gittes-pyramid) -------------------------------------

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


# --- Output -----------------------------------------------------------------------------------


def frames_for(c):
    p = looks.palette(c)
    heads = {face: looks.build_head(c, face) for face in ("normal", "shut", "hurt")}
    weapon = WEAPONS.get(c.get("weapon"))
    own = dict(weapon["animations"]) if weapon else {}
    if c.get("hand"):
        own.update(SUMMON_ANIMATIONS)
    if c.get("football"):
        own.update(KICK_ANIMATIONS)
    if c.get("peel"):
        own.update(FIDUSEN_ANIMATIONS)
    if c.get("pyramid"):
        own.update(PYRAMID_ANIMATIONS)
    return {name: [draw_frame(ps, c, p, heads) for ps in own.get(name, poses)]
            for name, poses in ANIMATIONS.items()}


def write_character(c, out):
    out.mkdir(parents=True, exist_ok=True)
    for name, frames in frames_for(c).items():
        w, h = frames[0].size
        strip = Image.new("RGBA", (w * len(frames), h), (0, 0, 0, 0))
        for i, frame in enumerate(frames):
            strip.paste(frame, (i * w, 0))
        strip.save(out / f"fighter_{name}.png")
    if c.get("hand"):
        hand_image(c).save(out / "hand.png")
    if c.get("football"):
        ball_image().save(out / "projectile.png")
    if c.get("weapon") == "scissors":
        mini_scissors_image().save(out / "projectile.png")
    if c.get("pyramid"):
        pyramid_image().save(out / "pyramid.png")
    if c.get("peel"):
        peel_image().save(out / "peel.png")
        book_image().save(out / "projectile.png")


def preview_sheet(c, path, zoom=3):
    """Every animation as a row of frames, on a plain background, for reviewing."""
    frames = frames_for(c)
    cols = max(len(f) for f in frames.values())
    label = 110
    fw, fh = next(iter(frames.values()))[0].size
    cw, ch = fw * zoom, fh * zoom
    out = Image.new("RGBA", (label + cols * (cw + 2), len(frames) * (ch + 2)), (60, 66, 84, 255))
    draw = ImageDraw.Draw(out)
    for row, (name, fs) in enumerate(frames.items()):
        y = row * (ch + 2)
        draw.text((4, y + ch // 2 - 6), name, fill=(240, 240, 240))
        for i, frame in enumerate(fs):
            bg = Image.new("RGBA", frame.size, (90, 100, 120, 255))
            bg.alpha_composite(frame)
            out.paste(bg.resize((cw, ch), Image.NEAREST), (label + i * (cw + 2), y))
    out.save(path)


def main(out_dir, ids, preview=False):
    out = Path(out_dir)
    for cid in ids or list(looks.CHARACTERS):
        write_character(looks.CHARACTERS[cid], out / cid)
        if preview:
            preview_sheet(looks.CHARACTERS[cid], out / f"{cid}_preview.png")
        print(cid)


if __name__ == "__main__":
    args = [a for a in sys.argv[1:] if a != "--preview"]
    main(args[0], args[1:], preview="--preview" in sys.argv)
