"""Pia's own drawings for the 64 px sprite generator (docs/specs/characters/pia.md#look).

Loaded by tools/gen_fighter_sprites64.py; the hooks at the bottom say which looks use it."""
from sprites import body  # noqa: F401
from sprites.body import *  # noqa: F401,F403  (the shared body, poses, drawing)
from sprites.weapons import *  # noqa: F401,F403


# --- Pia's belly flop (docs/specs/art-guide.md#pias-belly-flop) ----------------------------------

# Posed upright with `flat=True`: the body (no head) is turned a quarter turn forward (belly down,
# shoulders toward the facing side) and set on the floor row, and the head is put back on upright
# at the front, looking ahead, its chin `chin` px above the floor. Upright "up" becomes forward and
# upright forward becomes down, so arms swung down and back flail up behind her, and knees bent
# back kick the feet up.
FLAT_LEGS = dict(ft=-0.25, fk=1.5, bt=-0.45, bk=1.3)
FLAIL = dict(fa=-1.1, fe=-0.6, ba=-1.4, be=-0.5)
SPLAYED = dict(fa=0.35, fe=0.2, ba=0.15, be=0.2)
# The flop on landing (her down_special strip).
BELLY_FLOP = [
        pose(flat=True, squash=True, face="shut", **FLAIL, ft=-0.1, fk=0.9, bt=-0.2, bk=0.8),
        pose(flat=True, **SPLAYED, ft=-0.15, fk=0.5, bt=-0.3, bk=0.4),
        pose(flat=True, **SPLAYED, ft=-0.15, fk=0.3, bt=-0.3, bk=0.2),
        pose(crouch=5, lean=3, ft=1.5, fk=2.5, bt=1.1, bk=2.3, fa=1.2, fe=0.2, ba=1.0, be=0.2),
        pose(crouch=2, lean=1, ft=0.6, fk=1.1, bt=0.3, bk=0.9, fa=0.5, ba=-0.2)]
BELLY_FLOP_ANIMATIONS = {
    "down_special_dive": [pose(flat=True, chin=2, **FLAIL, **FLAT_LEGS)],
    "down_special": BELLY_FLOP,
}
HEAD_OVERLAP = 3       # px of the head over the turned shoulders
DUST = ((230, 220, 200), (186, 174, 156))   # pale dust, shade
DUST_SIZE = (40, 20)


def flat(body, head, squash=False, chin=0):
    """A flat drawing: `body` (drawn upright without a head) turned a quarter turn clockwise (a
    lossless pixel move) and set on the floor row, `head` (drawn alone) upright at its front, its
    chin `chin` px up; centred. `squash` drops the body's top row (flattened on impact)."""
    w, h = body.size
    turned = body.transpose(Image.ROTATE_270)
    body = turned.crop(turned.getbbox())
    if squash:
        body = body.resize((body.size[0], body.size[1] - 1), Image.NEAREST)
    head = head.crop(head.getbbox())
    width = body.size[0] + head.size[0] - HEAD_OVERLAP
    x0 = w // 2 - width // 2
    out = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    out.alpha_composite(body, (x0, h - body.size[1]))
    out.alpha_composite(head, (x0 + body.size[0] - HEAD_OVERLAP, h - chin - head.size[1]))
    return out


def dust_image():
    """Pia's flop dust, for one side (the game mirrors it for the other): 4 drawings of puffs
    rolling out along the floor and up, growing, then breaking up."""
    (w, h), n = DUST_SIZE, 4
    out = Image.new("RGBA", (w * n, h), (0, 0, 0, 0))
    px = out.load()
    # Per drawing: puffs as (x, radius) sitting on the floor; the last drawing breaks up.
    puffs = [[(3, 3), (8, 2.5)],
             [(5, 4.5), (12, 4), (18, 3)],
             [(8, 5.5), (17, 5), (26, 4), (33, 2.5)],
             [(12, 5), (22, 4.5), (31, 3.5), (37, 2)]]
    for i, row in enumerate(puffs):
        for x in range(w):
            for y in range(h):
                cx, cy = x + 0.5, y + 0.5
                for (pxx, r) in row:
                    py = h - r * 0.9           # resting on the floor
                    d = math.hypot(cx - pxx, (cy - py) * 1.15)
                    if d <= r:
                        if i == 3 and (x + y) % 2:
                            break              # fading
                        shade = (cx - pxx) + (cy - py) > r * 0.6
                        px[i * w + x, y] = (DUST[1] if shade else DUST[0]) + (255,)
                        break
    return out


# --- Pia's cake and flag (docs/specs/characters/pia.md#pias-specials) --------------------------------

SPONGE = ((246, 214, 120), (214, 176, 84))
CREAM = (250, 248, 240)
ICING = ((246, 150, 186), (214, 112, 152))
BERRY = (214, 40, 52)
# The slice, side on (7 wide): icing, cream, sponge, cream, sponge; B = strawberry on top.
CAKE_ROWS = ["..BB...",
             "IIIIIII",
             "CCCCCCC",
             "SSSSSSS",
             "CCCCCCC",
             "SSSSSSs"]
BITE_FIST = (7, 2)     # the fist at her chin for a bite, from the neck point


def cake_slice(fist, neck, look):
    """Pia's slice of cake on her front fist: "low" at her chest, "bitten" with a bite out of its
    front corner, "bite" held up at her mouth."""
    fx, fy = round(fist[0]), round(fist[1])
    x0, y0 = fx - 3, fy - 6
    colors = {"B": BERRY, "I": ICING[0], "C": CREAM, "S": SPONGE[0], "s": SPONGE[1]}
    out = {}
    for y, row in enumerate(CAKE_ROWS):
        for x, ch in enumerate(row):
            if ch == ".":
                continue
            if look == "bitten" and x >= 5 and y <= 3:
                continue                      # the bite out of its front corner
            color = colors[ch]
            if ch == "S" and x == 6:
                color = SPONGE[1]
            if ch == "I" and x == 6:
                color = ICING[1]
            out[(x0 + x, y0 + y)] = color
    return out


FLAG_FRAME = 32
FLAG_COLORS = [(24, 24, 28), (214, 32, 40), (250, 204, 40)]   # black, red, gold


def flag_image():
    """The German flag thrown on its own (no pole), flying right: 16x9 cloth in black, red and
    gold stripes, rippling (each column shifted by a wave that moves along it); 3 drawings of
    32x32."""
    n = FLAG_FRAME
    w, top = 16, 11
    x0 = (n - w) // 2
    out = Image.new("RGBA", (n * 3, n), (0, 0, 0, 0))
    for i in range(3):
        f = Frame()
        px = {}
        for x in range(w):
            dy = round(1.2 * math.sin(x * 0.6 - i * 2.1))
            for stripe, color in enumerate(FLAG_COLORS):
                for k in range(3):
                    shade = (x - 2 * i) % 6 == 0
                    px[(x0 + x, top + stripe * 3 + k + dy)] = \
                        looks.scale(color, 0.82) if shade and stripe else color
        f.part(px)
        frame = Image.new("RGBA", (n, n), (0, 0, 0, 0))
        for (x, y), color in f.px.items():
            if 0 <= x < n and 0 <= y < n:
                frame.putpixel((x, y), color + (255,))
        out.paste(frame, (i * n, 0))
    return out


CAKE_LOW = dict(fa=0.55, fe=1.9)
CAKE_ANIMATIONS = {
    "neutral_special": [pose(cake="low", **CAKE_LOW),
                        pose(cake="bite", face="shut", head_dy=-1, fa=0.35, fe=2.5),
                        pose(cake="bitten", bob=1, **CAKE_LOW),
                        pose(face="shut", head_dy=-1, fa=0.3, fe=1.4, ba=-0.3)],
}


def draw_flat(ps, c, p, heads):
    """A `flat` pose (her belly flop): the body turned to lie on its belly, the head put back on
    upright."""
    turned = draw_frame(dict(ps, headless=True), c, p, heads)
    head = draw_frame(dict(ps, head_only=True), c, p, heads)
    return flat(turned, head, ps.get("squash", False), ps.get("chin", 0))


DRAWERS["flat"] = draw_flat
# Her slice of cake, in her front fist (at her mouth for a bite).
PROPS["cake"] = dict(
    to_mouth=lambda value: value == "bite",
    hand=lambda pose, fist, neck, sipping: cake_slice(fist, neck, pose["cake"]))


def applies(c):
    return c.get("belly_flop") or c.get("cake") or c.get("flag")


def animations(c):
    own = {}
    if c.get("belly_flop"):
        own.update(BELLY_FLOP_ANIMATIONS)
    if c.get("cake"):
        own.update(CAKE_ANIMATIONS)
    return own


def extra_files(c, out, strips):
    if c.get("belly_flop"):
        dust_image().save(out / "dust.png")
    if c.get("flag"):
        flag_image().save(out / "projectile.png")
