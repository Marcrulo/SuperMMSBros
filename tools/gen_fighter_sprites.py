"""Generates every fighter's pixel-art strips, projectile and stock icon (docs/specs/art-guide.md).

All characters share one body and one set of poses; each has a "look" (colors, hair, a few traits)
in tools/fighter_looks.py. Each frame is 48x48, figure facing right, feet on the bottom row
centered at x=24, body inside x 16-31 / y 24-47, a big head about 13 px tall.
Usage:
  python3 -I tools/gen_fighter_sprites.py super-mms-bros/assets/fighters          # every character
  python3 -I tools/gen_fighter_sprites.py super-mms-bros/assets/fighters slot_02  # just some
Each character goes to <out_dir>/<id>/, one PNG strip per animation and a stock icon; the shared
projectile to <out_dir>/projectile.png. Characters in HAND_EDITED are skipped unless named.
"""
import math
import sys
from pathlib import Path

from PIL import Image

sys.path.insert(0, str(Path(__file__).resolve().parent))
from fighter_looks import HAND_EDITED, LOOKS  # noqa: E402

FRAME = 48
HEAD = {"rx": 6.4, "ry": 6.4, "cy": 27.0}
OUTLINE = (26, 28, 44)


def scale(color, f):
    """`color` darkened (f < 1) or lightened toward white (f > 1)."""
    if f <= 1:
        return tuple(round(c * f) for c in color)
    return tuple(round(c + (255 - c) * (f - 1)) for c in color)


def palette(look):
    """Every color a drawing uses, with shades derived from the look's base colors."""
    p = {
        "skin": look["skin"], "skin_shade": look.get("skin_shade", scale(look["skin"], 0.82)),
        "skin_light": scale(look["skin"], 1.25),
        "hair": look["hair"], "hair_light": look.get("hair_light", scale(look["hair"], 1.3)),
        "eye": look.get("eye", (26, 28, 44)),
        "shirt": look["shirt"], "shirt_shade": look.get("shirt_shade", scale(look["shirt"], 0.72)),
        "shirt_light": look.get("shirt_light", scale(look["shirt"], 1.22)),
        "pants": look["pants"], "pants_back": scale(look["pants"], 0.75),
        "shoes": look.get("shoes", (26, 28, 44)),
        "hands": look.get("hands", look["skin"]),
        "inner": look.get("inner"), "stripe": look.get("stripe"),
        "beard": look.get("beard"), "glasses": look.get("glasses"),
        "blush": look.get("blush"), "face": look.get("face"),
    }
    return p


class Canvas:
    def __init__(self):
        self.px = {}

    def put(self, x, y, color):
        x, y = int(x), int(y)
        if 0 <= x < FRAME and 0 <= y < FRAME:
            self.px[(x, y)] = color

    def stroke(self, a, b, width, color):
        """A thick pixel line from a to b (stamps a width x width square along it)."""
        steps = max(1, int(max(abs(b[0] - a[0]), abs(b[1] - a[1])) * 3))
        for i in range(steps + 1):
            t = i / steps
            x = a[0] + (b[0] - a[0]) * t
            y = a[1] + (b[1] - a[1]) * t
            x0 = round(x - width / 2)
            y0 = round(y - width / 2)
            for dx in range(width):
                for dy in range(width):
                    self.put(x0 + dx, y0 + dy, color)

    def disc(self, cx, cy, r, color):
        for y in range(int(cy - r) - 1, int(cy + r) + 2):
            for x in range(int(cx - r) - 1, int(cx + r) + 2):
                if (x + 0.5 - cx) ** 2 + (y + 0.5 - cy) ** 2 <= r * r:
                    self.put(x, y, color)

    def image(self):
        img = Image.new("RGBA", (FRAME, FRAME), (0, 0, 0, 0))
        filled = set(self.px)
        # 1 px dark outline around the whole silhouette.
        for (x, y) in filled:
            for nx, ny in ((x + 1, y), (x - 1, y), (x, y + 1), (x, y - 1)):
                if (nx, ny) not in filled and 0 <= nx < FRAME and 0 <= ny < FRAME:
                    img.putpixel((nx, ny), OUTLINE + (255,))
        for (x, y), color in self.px.items():
            img.putpixel((x, y), color + (255,))
        return img


def down(angle):
    """Direction of a limb at `angle`: 0 = straight down, positive = forward (right)."""
    return (math.sin(angle), math.cos(angle))


def add(p, d, length):
    return (p[0] + d[0] * length, p[1] + d[1] * length)


def hair_at(style, ux, uy):
    """Hair color key ("hair", "hair_light" or None) at a point of the head, in head units
    (ux forward, uy down, the head's edge at distance 1)."""
    if style == "bald":
        return None
    top = uy < -0.3
    back = ux < -0.25 and uy < 0.45
    if style == "receding":
        top = uy < -0.3 and ux < 0.05
    elif style == "fringe":
        top = uy < -0.12 or (uy < 0.0 and ux > 0.55)
    elif style in ("bob", "long"):
        back = ux < -0.1 and uy < 0.95
    if not (top or back):
        return None
    shine = uy < -0.75 and -0.2 < ux < 0.4
    return "hair_light" if shine else "hair"


def draw_head(c, look, p, cx, cy, eyes):
    style = look.get("hair_style", "short")
    ry = HEAD["ry"] + look.get("head", 0.0)
    rx = ry + look.get("cheeks", 0.0)
    fur = style == "monkey"
    # Volume: big hair sticks out past the skull at the top and back.
    puff = look.get("puff", 0.0)
    for y in range(int(cy) - 10, int(cy) + 10):
        for x in range(int(cx) - 10, int(cx) + 11):
            ux, uy = (x + 0.5 - cx) / rx, (y + 0.5 - cy) / ry
            d = ux * ux + uy * uy
            if d > 1.0:
                if puff and d <= (1 + puff) ** 2 and (uy < -0.2 or (ux < 0 and uy < 0.6)):
                    c.put(x, y, p["hair"])
                continue
            if fur:
                # A light face patch at the front, fur everywhere else.
                face = (ux - 0.3) ** 2 / 0.55 + (uy - 0.2) ** 2 / 0.45 < 1.0 and uy > -0.5
                c.put(x, y, p["face"] if face else p["hair"] if uy > -0.7 else p["hair_light"])
                continue
            color = p["skin"]
            if ux < -0.35 and uy > 0.25:
                color = p["skin_shade"]
            if style == "bald" and -0.6 < uy < -0.4 and 0.0 < ux < 0.35:
                color = p["skin_light"]
            if look.get("camo") and color != p["skin_light"]:
                color = look["camo"][(x * 7 + y * 13 + (x // 2) * (y // 3)) % len(look["camo"])]
            if p["beard"] and ux > -0.45 and uy > 0.3:
                color = p["beard"]
            key = hair_at(style, ux, uy)
            if key:
                color = p[key]
            c.put(x, y, color)
    if p["beard"]:
        # The beard hangs a pixel or two below the chin.
        for x in range(round(cx) - 2, round(cx) + 5):
            c.put(x, round(cy + ry), p["beard"])
        for x in range(round(cx), round(cx) + 3):
            c.put(x, round(cy + ry) + 1, p["beard"])
    if fur:
        # An ear at the back of the head.
        c.disc(cx - rx + 0.2, cy - 0.5, 2.3, p["hair"])
        c.disc(cx - rx + 0.4, cy - 0.5, 1.2, p["face"])
    if style == "bun":
        c.disc(cx - rx + 0.3, cy + 1.0, 1.9, p["hair"])
    if style == "ponytail":
        c.stroke((cx - rx + 1.5, cy - 4.0), (cx - rx - 1.0, cy - 2.5), 2, p["hair"])
        c.stroke((cx - rx - 1.0, cy - 2.5), (cx - rx - 1.5, cy + 4.0), 2, p["hair"])
        c.put(cx - rx - 1.0, cy - 3.0, p["hair_light"])

    # Eyes (front one bigger), looking forward; closed for the hurt pose.
    # On a smaller head the eyes sit a little further back, so they stay on the face.
    ex, ey = round(cx + 1 + 1.5 * look.get("head", 0.0)), round(cy)
    if fur:
        ex += 1
    if p["glasses"] and eyes != "shut":
        g = p["glasses"]
        # Frames over the brow and down the outer sides, a bridge, and the arm back to the ear;
        # the lenses stay clear, so the eyes show through.
        for x in range(ex - 1, ex + 5):
            c.put(x, ey - 1, g)
        for y in range(ey, ey + 2):
            c.put(ex - 1, y, g)
            c.put(ex + 4, y, g)
        c.put(ex + 1, ey + 2, g)
        c.put(ex + 2, ey + 2, g)
        for x in range(ex - 4, ex - 1):
            c.put(x, ey, g)
        for y in range(ey, ey + 2):
            c.put(ex, y, p["eye"])
            c.put(ex + 3, y, p["eye"])
        return
    if eyes == "shut":
        c.put(ex, ey + 1, p["eye"]); c.put(ex + 1, ey + 1, p["eye"])
        c.put(ex + 3, ey + 1, p["eye"]); c.put(ex + 4, ey + 1, p["eye"])
    else:
        for y in range(ey, ey + 2):
            c.put(ex, y, p["eye"])
            c.put(ex + 3, y, p["eye"])
        c.put(ex + 3, ey - 1, p["eye"])
    if p["blush"]:
        c.put(ex + 2, ey + 3, p["blush"])
        c.put(ex - 2, ey + 3, p["blush"])


def draw_frame(pose, look):
    p = palette(look)
    c = Canvas()
    dx, dy = pose.get("lean", 0), pose.get("bob", 0)
    # Build: legs and torso lengths, head size and torso width can differ per character
    # (look keys legs, torso, head, wide, arms); the feet always end on the bottom row.
    leg_len = 3.6 + look.get("legs", 0.0)
    arm_len = 3.0 + look.get("arms", 0.0)
    wide = look.get("wide", 0)
    head_r = HEAD["rx"] + look.get("head", 0.0)
    hip_y = 47.7 - 2 * leg_len + pose.get("crouch", 0)
    shoulder = (24 + dx, hip_y - 5.5 - look.get("torso", 0.0) + dy)
    cx = 24.5 + dx + pose.get("head_dx", 0)
    cy = shoulder[1] - 1.6 - head_r + pose.get("head_dy", 0)
    style = look.get("hair_style", "short")
    short_sleeves = look.get("sleeves") == "short"

    def leg(root, thigh, knee, color):
        length = leg_len
        k = add(root, down(thigh), length)
        f = add(k, down(thigh - knee), length)
        c.stroke(root, k, 2, color)
        c.stroke(k, f, 2, color)
        # Shoe: 3 px pointing forward.
        fx, fy = round(f[0]), min(round(f[1]), 47)
        for x in range(fx - 1, fx + 2):
            c.put(x, fy, p["shoes"])

    def arm(root, upper, elbow, color, reach=0.0, skin=None):
        length = arm_len
        e = add(root, down(upper), length + reach)
        h = add(e, down(upper + elbow), length + reach)
        c.stroke(root, e, 2, color)
        c.stroke(e, h, 2, skin if short_sleeves else color)
        c.stroke(h, h, 2, p["hands"])

    # Long hair hangs down the back, behind everything.
    if style == "long":
        length = look.get("hair_length", 11)
        for y in range(round(cy), round(cy) + length):
            w = 4 if y < cy + length - 3 else 3
            back = round(cx - head_r - look.get("cheeks", 0.0)) - 1
            for x in range(back, back + w):
                c.put(x, y, p["hair"])
    # A hood bunched up behind the neck.
    if look.get("hood"):
        c.disc(cx - 4.0, cy + 6.0, 2.4, p["shirt_shade"])
    # A monkey's tail, curling up behind.
    if look.get("tail"):
        tx, ty = 21 - wide + dx * 0.3, hip_y - 1
        c.stroke((tx, ty), (tx - 3, ty - 1), 1, p["hair"])
        c.stroke((tx - 3, ty - 1), (tx - 5, ty - 4), 1, p["hair"])
        c.stroke((tx - 5, ty - 4), (tx - 4, ty - 7), 1, p["hair"])

    # Back limbs (darker), behind everything.
    leg((23 - wide * 0.5 + dx * 0.3, hip_y), pose["bt"], pose["bk"], p["pants_back"])
    arm((22 - wide + dx, shoulder[1] + 0.5), pose["ba"], pose["be"], p["shirt_shade"], skin=p["skin_shade"])

    # Torso: 6 x 7, shaded on the back side, lighter on the front.
    top = int(shoulder[1])
    for y in range(top, int(hip_y) + 1):
        # A belly bulges forward below the chest, rounded at its top and bottom.
        belly = 0
        if top + 2 <= y < int(hip_y):
            ends = y == top + 2 or y == int(hip_y) - 1
            belly = max(look.get("belly", 0) - (1 if ends else 0), 0)
        for x in range(21 - wide, 27 + belly):
            xx = x + round(dx * (1 - (y - shoulder[1]) / 8))
            color = p["shirt_shade"] if x == 21 - wide else p["shirt_light"] if x == 26 and y < shoulder[1] + 3 else p["shirt"]
            if p["inner"] and x in (24, 25) and y < top + 3 and not (x == 24 and y == top + 2):
                color = p["inner"]
            if p["stripe"] and y in (top + 3, top + 5):
                color = p["stripe"]
            if look.get("dots") and (x + 2 * y) % 4 == 0 and x > 21:
                color = look["dots"]
            c.put(xx, y, color)

    # A raised front arm goes behind the head, so it never covers the face.
    raised = pose["fa"] > 2.2
    if raised:
        arm((26 + dx, shoulder[1] + 0.5), pose["fa"], pose["fe"], p["shirt"], reach=pose.get("reach", 0), skin=p["skin"])

    draw_head(c, look, p, cx, cy, pose.get("eyes"))

    # Front limbs.
    leg((25.5 + dx * 0.3, hip_y), pose["ft"], pose["fk"], p["pants"])
    if look.get("skirt"):
        for i, y in enumerate(range(int(hip_y) + 1, int(hip_y) + 4)):
            for x in range(21 - wide - i // 2, 27 + (i + 1) // 2):
                c.put(x + round(dx * 0.3), y, p["shirt_shade"] if x <= 21 - wide - i // 2 else p["shirt"])
    if not raised:
        arm((26 + dx, shoulder[1] + 0.5), pose["fa"], pose["fe"], p["shirt"], reach=pose.get("reach", 0), skin=p["skin"])
    return c.image()


BASE = dict(ft=0.08, fk=0.1, bt=-0.08, bk=0.1, fa=0.25, fe=0.5, ba=-0.2, be=0.5)


def pose(**changes):
    p = dict(BASE)
    p.update(changes)
    return p


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

# Drawing counts and order follow docs/specs/art-guide.md; the strike pose is the drawing shown on
# a move's active frames.
ANIMATIONS = {
    "idle": [pose(), pose(), pose(bob=1), pose(bob=1)],
    "run": [run_pose(i) for i in range(6)],
    "crouch": [pose(crouch=2, ft=0.6, fk=1.1, bt=0.3, bk=0.9, fa=0.4),
               pose(crouch=4, lean=1, ft=1.1, fk=2.1, bt=0.7, bk=1.8, fa=0.7, fe=0.8, ba=0.3)],
    "jump": [pose(crouch=1, ft=0.4, fk=0.9, bt=-0.3, bk=0.9, fa=-0.6, ba=-0.9),
             pose(ft=1.1, fk=1.7, bt=0.3, bk=1.3, fa=1.9, fe=-0.4, ba=-1.2, be=0.5)],
    "fall": [pose(ft=0.35, fk=0.4, bt=-0.25, bk=0.5, fa=1.8, fe=0.5, ba=-1.8, be=-0.5),
             pose(ft=0.3, fk=0.5, bt=-0.3, bk=0.4, fa=2.0, fe=0.4, ba=-2.0, be=-0.4)],
    "helpless": [pose(eyes="shut", fa=2.8, fe=0.2, ba=-2.8, be=-0.2, ft=0.2, fk=0.3, bt=-0.2, bk=0.3),
                 pose(eyes="shut", head_dy=1, fa=2.6, fe=0.4, ba=-2.6, be=-0.4, ft=0.3, fk=0.4, bt=-0.3, bk=0.4)],
    "shield": [pose(crouch=1, fa=1.2, fe=1.5, ba=1.0, be=1.6, ft=0.25, bt=-0.25)],
    "dizzy": [pose(head_dx=1, eyes="shut", fa=0.3, ba=-0.3, ft=0.1, bt=-0.2),
              pose(head_dx=-1, eyes="shut", lean=-1, fa=-0.2, ba=0.2, ft=0.2, bt=-0.1)],
    "hurt": [pose(lean=-2, head_dx=-1, head_dy=-1, eyes="shut", fa=2.6, fe=0.6, ba=-2.6, be=-0.6,
                  ft=-0.5, fk=0.6, bt=0.4, bk=0.6),
             pose(lean=-2, head_dx=-1, eyes="shut", fa=2.2, fe=0.9, ba=-2.8, be=-0.3,
                  ft=-0.3, fk=0.8, bt=0.5, bk=0.4)],
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

# Air attacks: legs tucked like the fall pose, unless the move uses them.
AIR = dict(ft=0.35, fk=0.4, bt=-0.25, bk=0.5)


def air_pose(**changes):
    return pose(**{**AIR, **changes})


ANIMATIONS.update({
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
})

# Dodges and the ledge (docs/specs/art-guide.md).
ANIMATIONS.update({
    "spot_dodge": [pose(crouch=1, lean=-1, fa=0.6, fe=1.4, ba=0.4, be=1.4),
                   pose(crouch=2, lean=-2, head_dx=-1, eyes="shut", fa=1.0, fe=1.8, ba=0.8, be=1.8,
                        ft=0.3, fk=0.7, bt=-0.4, bk=0.7),
                   pose(crouch=1, fa=0.5, fe=0.8, ba=-0.3, be=0.6)],
    "roll": [pose(crouch=3, lean=2, ft=0.9, fk=1.7, bt=0.5, bk=1.5, fa=1.2, fe=1.6, ba=0.9, be=1.6),
             pose(crouch=5, lean=3, head_dy=2, eyes="shut", ft=1.4, fk=2.3, bt=1.1, bk=2.2,
                  fa=1.6, fe=1.8, ba=1.4, be=1.8),
             pose(crouch=5, lean=2, head_dy=2, eyes="shut", ft=1.2, fk=2.2, bt=1.0, bk=2.1,
                  fa=1.0, fe=2.0, ba=1.0, be=2.0),
             pose(crouch=2, lean=-1, ft=0.5, fk=1.0, bt=-0.2, bk=0.8, fa=0.5, fe=1.0, ba=-0.4)],
    "air_dodge": [air_pose(fa=1.2, fe=1.6, ba=1.0, be=1.6, ft=0.8, fk=1.4, bt=0.6, bk=1.4),
                  air_pose(eyes="shut", fa=1.4, fe=1.9, ba=1.2, be=1.9, ft=1.0, fk=1.8, bt=0.8, bk=1.7)],
    "ledge": [pose(fa=2.75, fe=0.1, reach=0.8, ba=2.6, be=0.1, ft=0.2, fk=0.4, bt=-0.1, bk=0.5),
              pose(fa=2.75, fe=0.1, reach=0.8, ba=2.6, be=0.1, ft=0.1, fk=0.6, bt=0.0, bk=0.3)],
    "ledge_climb": [pose(crouch=2, fa=2.4, fe=0.5, ba=2.2, be=0.5, ft=1.0, fk=1.8, bt=0.3, bk=1.0),
                    pose(crouch=4, lean=2, fa=1.2, fe=1.4, ba=1.0, be=1.4, ft=1.3, fk=2.2, bt=0.5, bk=1.6),
                    pose(crouch=1, lean=1, fa=0.5, fe=0.8, ba=-0.3, ft=0.4, fk=0.6, bt=-0.2, bk=0.4)],
})

PROJECTILE = 12
GLOW_OUTER, GLOW_MID, GLOW_CORE = (41, 54, 111), (65, 166, 246), (115, 239, 247)


def projectile_frame(i):
    """A 12x12 energy ball flying right, with a short trail behind it."""
    img = Image.new("RGBA", (PROJECTILE, PROJECTILE), (0, 0, 0, 0))
    cx, cy = 6.5, 6.0
    for y in range(PROJECTILE):
        for x in range(PROJECTILE):
            d = math.hypot((x + 0.5 - cx) / 1.0, (y + 0.5 - cy) / 0.85)
            trail = x < cx and abs(y + 0.5 - cy) < 1.5 and (x + i) % 3 != 0
            if d < 1.8:
                img.putpixel((x, y), GLOW_CORE + (255,))
            elif d < 3.4:
                img.putpixel((x, y), GLOW_MID + (255,))
            elif d < 4.6 or (trail and x > 1):
                img.putpixel((x, y), GLOW_OUTER + (255,))
    return img


# Stock icon, 8x8: the head facing right, with a collar in the shirt shades.
STOCK_ICON = [
    "..hhhh..",
    ".hhHHhh.",
    "hhhhsss.",
    "hhsssese",
    ".hsssss.",
    "..ssss..",
    ".rRRRRr.",
    "rrRRRRrr",
]


def stock_icon(look):
    p = palette(look)
    bald = look.get("hair_style") == "bald"
    colors = {"h": p["skin"] if bald else p["hair"], "H": p["skin_light"] if bald else p["hair_light"],
              "s": p["face"] or p["skin"], "e": p["eye"], "r": p["shirt_shade"], "R": p["shirt"]}
    img = Image.new("RGBA", (8, 8), (0, 0, 0, 0))
    for y, row in enumerate(STOCK_ICON):
        for x, key in enumerate(row):
            if key in colors:
                img.putpixel((x, y), colors[key] + (255,))
    return img


def write_character(look, out):
    out.mkdir(parents=True, exist_ok=True)
    for name, poses in ANIMATIONS.items():
        strip = Image.new("RGBA", (FRAME * len(poses), FRAME), (0, 0, 0, 0))
        for i, pose_ in enumerate(poses):
            strip.paste(draw_frame(pose_, look), (i * FRAME, 0))
        strip.save(out / f"fighter_{name}.png")
    stock_icon(look).save(out / "stock_icon.png")


def write_projectile(out):
    """The side special's projectile, shared by every character."""
    strip = Image.new("RGBA", (PROJECTILE * 3, PROJECTILE), (0, 0, 0, 0))
    for i in range(3):
        strip.paste(projectile_frame(i), (i * PROJECTILE, 0))
    strip.save(out / "projectile.png")


def main(out_dir, ids):
    """Every character (skipping hand-edited ones), or just the ids given (even hand-edited)."""
    out = Path(out_dir)
    out.mkdir(parents=True, exist_ok=True)
    for character_id in ids or [i for i in LOOKS if i not in HAND_EDITED]:
        write_character(LOOKS[character_id], out / character_id)
        print(character_id)
    for character_id in sorted(HAND_EDITED - set(ids)):
        print(character_id, "(hand-edited, left alone)")
    write_projectile(out)


if __name__ == "__main__":
    main(sys.argv[1], sys.argv[2:])
