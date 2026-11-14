"""Fidusen's own drawings for the 64 px sprite generator (docs/specs/characters/fidusen.md#look).

Loaded by tools/gen_fighter_sprites64.py; the hooks at the bottom say which looks use it."""
from sprites import body  # noqa: F401
from sprites.body import *  # noqa: F401,F403  (the shared body, poses, drawing)
from sprites.weapons import *  # noqa: F401,F403


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


def applies(c):
    return c.get("peel")


def animations(c):
    return dict(FIDUSEN_ANIMATIONS)


def extra_files(c, out, strips):
    peel_image().save(out / "peel.png")
    book_image().save(out / "projectile.png")
