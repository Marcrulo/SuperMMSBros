"""Generates the placeholder pixel-art fighter strips and projectile (docs/specs/art-guide.md).

Each frame is 48x48, figure facing right, feet on the bottom row centered at x=24, body inside
x 16-31 / y 24-47. Big head (~10 px of the 24 px height). Output: one PNG strip per animation.
Usage: python3 -I tools/gen_placeholder_sprites.py super-mms-bros/assets/fighters/default
"""
import math
import sys
from pathlib import Path

from PIL import Image

FRAME = 48
HEAD = {"rx": 5.3, "ry": 5.0, "cy": 28.5}
OUTLINE = (26, 28, 44)
SKIN, SKIN_SHADE = (240, 195, 155), (205, 150, 115)
HAIR, HAIR_LIGHT = (59, 42, 40), (93, 63, 53)
EYE = (26, 28, 44)
SHIRT, SHIRT_SHADE, SHIRT_LIGHT = (177, 62, 83), (128, 40, 62), (214, 92, 106)
PANTS, PANTS_BACK = (51, 60, 87), (38, 43, 68)
SHOES = (26, 28, 44)


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


def draw_frame(pose):
    c = Canvas()
    dx, dy = pose.get("lean", 0), pose.get("bob", 0)
    hip_y = 40.5 + pose.get("crouch", 0)
    shoulder = (24 + dx, 35 + dy + pose.get("crouch", 0))

    def leg(root, thigh, knee, color, length=3.6):
        k = add(root, down(thigh), length)
        f = add(k, down(thigh - knee), length)
        c.stroke(root, k, 2, color)
        c.stroke(k, f, 2, color)
        # Shoe: 3 px pointing forward.
        fx, fy = round(f[0]), min(round(f[1]), 47)
        for x in range(fx - 1, fx + 2):
            c.put(x, fy, SHOES)

    def arm(root, upper, elbow, color, length=3.0, reach=0.0):
        e = add(root, down(upper), length + reach)
        h = add(e, down(upper + elbow), length + reach)
        c.stroke(root, e, 2, color)
        c.stroke(e, h, 2, color)
        c.stroke(h, h, 2, SKIN)

    # Back limbs (darker), behind everything.
    leg((23 + dx * 0.3, hip_y), pose["bt"], pose["bk"], PANTS_BACK)
    arm((22 + dx, shoulder[1] + 0.5), pose["ba"], pose["be"], SHIRT_SHADE)

    # Torso: 6 x 7, shaded on the back side, lighter on the front.
    for y in range(int(shoulder[1]), int(hip_y) + 1):
        for x in range(21, 27):
            xx = x + round(dx * (1 - (y - shoulder[1]) / 8))
            color = SHIRT_SHADE if x == 21 else SHIRT_LIGHT if x == 26 and y < shoulder[1] + 3 else SHIRT
            c.put(xx, y, color)

    # A raised front arm goes behind the head, so it never covers the face.
    raised = pose["fa"] > 2.2
    if raised:
        arm((26 + dx, shoulder[1] + 0.5), pose["fa"], pose["fe"], SHIRT, reach=pose.get("reach", 0))

    # Head: big, like a chibi figure.
    cx, cy = 24.5 + dx + pose.get("head_dx", 0), HEAD["cy"] + dy + pose.get("crouch", 0) + pose.get("head_dy", 0)
    for y in range(int(cy) - 9, int(cy) + 9):
        for x in range(int(cx) - 9, int(cx) + 10):
            ux, uy = (x + 0.5 - cx) / HEAD["rx"], (y + 0.5 - cy) / HEAD["ry"]
            if ux * ux + uy * uy > 1.0:
                continue
            color = SKIN
            if ux < -0.35 and uy > 0.25:
                color = SKIN_SHADE
            # Hair: the top, and the back of the head down to the ear.
            if uy < -0.3 or (ux < -0.25 and uy < 0.45):
                color = HAIR_LIGHT if (uy < -0.75 and -0.2 < ux < 0.4) else HAIR
            c.put(x, y, color)
    # Eyes (front one bigger), looking forward; closed for the hurt pose.
    ex, ey = round(cx) + 1, round(cy)
    if pose.get("eyes") == "shut":
        c.put(ex, ey + 1, EYE); c.put(ex + 1, ey + 1, EYE)
        c.put(ex + 3, ey + 1, EYE); c.put(ex + 4, ey + 1, EYE)
    else:
        tall = 3 if HEAD["ry"] > 5.5 else 2
        for y in range(ey, ey + tall):
            c.put(ex, y, EYE)
            c.put(ex + 3, y, EYE)
        c.put(ex + 3, ey - 1, EYE)

    # Front limbs.
    leg((25.5 + dx * 0.3, hip_y), pose["ft"], pose["fk"], PANTS)
    if not raised:
        arm((26 + dx, shoulder[1] + 0.5), pose["fa"], pose["fe"], SHIRT, reach=pose.get("reach", 0))
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


def main(out_dir):
    # Brawlhalla-like: a head about 13 px tall, poking 3 px above the 24 px body box.
    HEAD.update(rx=6.4, ry=6.4, cy=27.0)
    out = Path(out_dir)
    out.mkdir(parents=True, exist_ok=True)
    for name, poses in ANIMATIONS.items():
        strip = Image.new("RGBA", (FRAME * len(poses), FRAME), (0, 0, 0, 0))
        for i, p in enumerate(poses):
            strip.paste(draw_frame(p), (i * FRAME, 0))
        strip.save(out / f"fighter_{name}.png")
        print(name, len(poses))
    strip = Image.new("RGBA", (PROJECTILE * 3, PROJECTILE), (0, 0, 0, 0))
    for i in range(3):
        strip.paste(projectile_frame(i), (i * PROJECTILE, 0))
    strip.save(out / "projectile.png")
    print("projectile", 3)


if __name__ == "__main__":
    main(sys.argv[1])
