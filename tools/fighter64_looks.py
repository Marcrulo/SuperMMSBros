"""Every fighter's look at 64x64: colors, and a hand-drawn head with its layers.

The head is a letter grid: each letter is a pixel *role* (skin, eye, hair, ...) and each
character gives the colors (`palette`). Layers on top add hair, beards, glasses, mouths. The body
is drawn by tools/gen_fighter_sprites64.py, which places this head on the neck in every pose.
Grid coordinates: row r, column c. The head hangs from NECK (the middle of the chin line).
"""

OUTLINE = (26, 28, 44)
NECK = (16, 20)

# S s L skin (base, shade, light)   X stubble   W B eye white, iris   T teeth   O outline
HEAD = """
...............sSSSSSSSSS
.............ssSSSSSSLLLSSS
............ssSSSSSSSLLLLSSS
...........sSSSSSSSSSSLLSSSSS
...........sSSSSSSSSSSSSSSSSS
...........sSSSSSSsssSSSsssSS
...........sSsssSSWBSSSSWBSSS
...........sSsSsSSWOSSSSWOSSS
...........sSsXsSSSSSSSSSSssSS
...........sSSssSSSSSSSSSSsSSS
...........sSSSSSSSOSSSSSSSOS
...........sSSSSSSSSOOOOOOOSS
...........sSSSSSSSXOTTTTTOXS
............sSSSSSXXXOOOOOXXS
.............sSSSSXXXXXXXXXS
..............sssSSXXXXXss
..............OOOOOOOOOOOOO
"""

# --- Layers: lists of (row, col, "letters"); ' ' or '.' leaves a pixel alone ----------------


def at(y, x, s):
    """A layer row given in design coordinates (x 12 / y 22 = grid column 0 / row 0)."""
    return (y - 22, x - 12, s)


HAIR = {
    "short": [at(20, 28, "aaaaaaaa"), at(21, 26, "aAAAAZZZZAAa"), at(22, 24, "aAAAAAAZZZZZAAAa"),
              at(23, 23, "aAAAAAAAAZZZZAAAAa"), at(24, 22, "aAAAAAAAAAAAAAAAAAa"),
              at(25, 22, "aAAAAAAAAAAaa"), at(26, 22, "aAAAAAaa"), at(27, 22, "aAAAa.a"),
              at(28, 22, "aAa"), at(29, 22, "aaa"), at(30, 23, "a")],
    "receding": [at(21, 27, "aAAAAAa"), at(22, 25, "aAAAAZZAAAa"), at(23, 23, "aAAAAAAZZAaa"),
                 at(24, 22, "aAAAAAAAaa"), at(25, 22, "aAAAAAa"), at(26, 22, "aAAAAa"),
                 at(27, 22, "aAAAa.a"), at(28, 22, "aAa"), at(29, 22, "aaa"), at(30, 23, "a")],
    "fringe": [at(20, 28, "aaaaaaaa"), at(21, 26, "aAAAAZZZZAAa"), at(22, 24, "aAAAAAAZZZZZAAAa"),
               at(23, 23, "aAAAAAAAAZZZZAAAAa"), at(24, 22, "aAAAAAAAAAAAAAAAAAa"),
               at(25, 22, "aAAAAAAAAAAAAAAAAAa"), at(26, 22, "aAAAAAAAAAAa.aAa.a"),
               at(27, 22, "aAAAAAa"), at(28, 22, "aAa"), at(29, 22, "aaa"), at(30, 23, "a")],
    "bob": [at(19, 28, "aaaaaaaa"), at(20, 26, "aAAAAZZZZAAa"), at(21, 24, "aAAAAAAZZZZZAAAa"),
            at(22, 23, "aAAAAAAAAZZZZAAAAa"), at(23, 22, "aAAAAAAAAAAAAZZAAAAa"),
            at(24, 21, "aAAAAAAAAAAAAAAAAAAAa"), at(25, 21, "aAAAAAAAAAAAAAAAAAAAa"),
            at(26, 21, "aAAAAAAAAAAa..a...a"), at(27, 21, "aAAAAAAa"), at(28, 21, "aAAAAAa"),
            at(29, 21, "aAAAAAa"), at(30, 21, "aAAAAAa"), at(31, 21, "aAAAAAa"),
            at(32, 21, "aAAAAAa"), at(33, 21, "aAAAAa"), at(34, 22, "aaaa")],
    "puff": [at(17, 27, "aaaaaaaaa"), at(18, 24, "aAAAAZZZZZAAAa"),
             at(19, 22, "aAAAAAAZZZZZZAAAAa"), at(20, 21, "aAAAAAAAAZZZZZAAAAAa"),
             at(21, 20, "aAAAAAAAAAAAAZZZAAAAa"), at(22, 20, "aAAAAAAAAAAAAAAAAAAAAa"),
             at(23, 20, "aAAAAAAAAAAAAAAAAAAAAAa"), at(24, 20, "aAAAAAAAAAAAAAAAAAAAAAa"),
             at(25, 20, "aAAAAAAAAAAAAa.aAAAAa"), at(26, 20, "aAAAAAAAAAa"),
             at(27, 20, "aAAAAAAa"), at(28, 20, "aAAAAAa"), at(29, 20, "aAAAAAa"),
             at(30, 20, "aAAAAa"), at(31, 21, "aAAa"), at(32, 22, "aa")],
    "long": [at(19, 28, "aaaaaaaa"), at(20, 26, "aAAAAZZZZAAa"), at(21, 24, "aAAAAAAZZZZZAAAa"),
             at(22, 23, "aAAAAAAAAZZZZAAAAa"), at(23, 22, "aAAAAAAAAAAAZZAAAAAa"),
             at(24, 21, "aAAAAAAAAAAAAAAAAAAAa"), at(25, 21, "aAAAAAAAAAAAAa"),
             at(26, 21, "aAAAAAAAAAa"), at(27, 21, "aAAAAAAa")]
            + [at(y, 21, "aAAAAAa") for y in range(28, 34)]
            + [at(y, 21, "aAAAAa") for y in range(34, 38)],
    "ponytail": [at(20, 28, "aaaaaaa"), at(21, 26, "aAAAZZZAAa"), at(22, 24, "aAAAAAZZZAAAa"),
                 at(23, 23, "aAAAAAAAZZAAAa"), at(24, 22, "aAAAAAAAAAAa"),
                 at(25, 22, "aAAAAAAa"), at(26, 22, "aAAAAa"), at(27, 22, "aAAa"),
                 at(28, 22, "aa"),
                 at(21, 18, "aAAAa"), at(22, 16, "aAAAAAa"), at(23, 15, "aAAZAAa"),
                 at(24, 15, "aAZAAa"), at(25, 15, "aAZAa"), at(26, 15, "aAZAa"),
                 at(27, 15, "aAAa"), at(28, 15, "aAAa"), at(29, 16, "aAa"), at(30, 16, "aAa"),
                 at(31, 17, "aa")],
}


def long_back(length):
    """Long hair hanging down the back, and the far side's hair behind the face."""
    bottom = 34 + length
    rows = [at(y, 19, "aAAAAAAa") for y in range(34, bottom)]
    rows += [at(bottom, 20, "aAAAa"), at(bottom + 1, 21, "aa")]
    rows += [at(y, 41, "aAa") for y in range(24, 24 + length // 2 + 6)]
    return rows


BEARD = {  # R r beard; drawn over skin only, so the mouth shows through
    "full": [(6, 16, "a"), (7, 16, "R"), (8, 15, "RR"), (9, 15, "RR"), (10, 15, "rRR.rRRRRRRr"), (11, 14, "rRRRRR"),
             (11, 27, "RR"), (12, 13, "rRRRRRR"), (12, 26, "RRr"), (13, 12, "rRRRRRRRRRRRRRRRr"),
             (14, 13, "rRRRRRRRRRRRRRr"), (15, 14, "rRRRRRRRRRRr")],
    "full_hang": [(16, 15, "RRRRRRRRRRRR"), (17, 16, "rRRRRRRRRRr"), (18, 18, "rrrrrrr")],
    "short": [(8, 15, "R"), (9, 15, "RR"), (10, 19, "rRRRRRRRr"), (11, 14, "rRRRR"),
              (11, 27, "R"), (12, 13, "rRRRRR"), (12, 27, "Rr"), (13, 12, "rRRRRRRRRRRRRRRRr"),
              (14, 13, "rRRRRRRRRRRRRRr"), (15, 14, "rrRRRRRRRRrr")],
}

SOFT_MOUTH = [(10, 19, "SOSSSSSOS"), (11, 19, "SSOOOOOSS"), (12, 19, "SSSSSSSSS"),
              (13, 21, "SsssS")]
LIPS = [(10, 19, "M.......M"), (11, 20, "MMMMMMM"), (12, 20, "M.....M"), (13, 21, "MMMMM")]
BIG_CHIN = [(15, 14, "sSSSSSSSSSSs"), (16, 13, "OsSSSSSSSSSssO"), (17, 15, "OOOOOOOOOOO")]
FULL_CHEEKS = [(14, 12, "sS"), (15, 13, "sS")]
GLASSES = [(5, 17, "GGGG..GGGG"), (6, 14, "GGGG..GGGG..G"), (6, 23, "G..G"),
           (7, 17, "G..G..G..G"), (8, 17, "GGGG..GGGG")]
BLUSH = [(9, 16, "UU"), (10, 15, "UUU"), (9, 27, "U")]
FRECKLES = [(8, 17, "u.u"), (9, 18, "u"), (8, 26, "u"), (9, 27, "u")]
# Light fur framing the eyes and the muzzle (Y y), and the muzzle (P p): a rounded snout centered
# under the eyes, the nose at its top, the monkey's own mouth (smile, or a grimace when hurt).
MONKEY_FACE = [(4, 18, "yYYYYYYYy"), (5, 17, "YYYYYYYYYYYY"),
               *[(r, 16, "YYYYYYYYYYYYYY") for r in range(6, 13)],
               (13, 16, "yYYYYYYYYYYYy"), (14, 17, "yYYYYYYYYYy"), (15, 18, "yyyyyyyy")]
MONKEY_CLEAR = [(r, 19, "SSSSSSSSS") for r in range(10, 14)]
MONKEY_MUZZLE = [(9, 19, "PPOOOPP"), (10, 18, "PPPPPPPPP"), (11, 18, "PPPPPPPPP"),
                 (12, 18, "pPPPPPPPp"), (13, 19, "ppppppp")]
MONKEY_SMILE = [(11, 19, "O.....O"), (12, 20, "OOOOO")]
MONKEY_GRIMACE = [(11, 20, "OOOOO"), (12, 20, "OTTTO"), (13, 20, "OOOOO")]
MONKEY_EAR = [(6, 9, "aAAa"), (7, 8, "aAYYa"), (8, 8, "aYYYa"), (9, 8, "aAYYa"), (10, 9, "aAa")]
MONKEY_TUFT = [(-2, 18, "a.a"), (-1, 17, "aAaAa")]

SKIN = set("SsLX")


def scale(color, f):
    if f <= 1:
        return tuple(round(c * f) for c in color)
    return tuple(round(c + (255 - c) * (f - 1)) for c in color)


FAIR = (240, 176, 136)
JEANS = (51, 60, 87)
DARK = (40, 42, 54)
WHITE_SHIRT = (232, 236, 240)

CHARACTERS = {
    "slot_01": dict(name="Pia", skin=(232, 160, 122), hair=(150, 52, 26),
                    hair_light=(190, 82, 40), hair_style="bob", blush=(222, 120, 110), mouth="soft", build="heavy",
                    shirt=(132, 78, 182), pants=JEANS),
    "slot_02": dict(name="Gitte", skin=FAIR, hair=(232, 236, 242), hair_shade=(184, 190, 204),
                    hair_light=(255, 255, 255), hair_style="puff", shirt=(226, 48, 120),
                    shirt_shade=(160, 16, 88), inner=(250, 150, 190), lips=(196, 40, 112), pants=DARK),
    "slot_03": dict(name="Trine", skin=FAIR, hair=(160, 168, 176), hair_style="long",
                    hair_length=6, glasses=(20, 20, 28), mouth="soft", big_chin=True, shirt=(84, 96, 106),
                    inner=(150, 160, 168), pants=DARK),
    "slot_04": dict(name="Nina", skin=(248, 180, 140), hair=(168, 30, 18), slim=0.4,
                    hair_light=(214, 64, 34), hair_style="long", hair_length=12,
                    freckles=(204, 120, 90), shirt=(232, 234, 238), shirt_shade=(178, 184, 198),
                    shirt_light=(255, 255, 255),
                    pants=JEANS),
    "slot_05": dict(name="Michael Bech", skin=(240, 128, 112), skin_shade=(196, 92, 84),
                    skin_light=(250, 166, 146), stubble=(214, 104, 94), collar="hood",
                    hair_style="buzz", hair=(178, 104, 86), hair_shade=(160, 90, 76),
                    shirt=(240, 90, 10), shirt_shade=(184, 40, 0), shirt_light=(255, 138, 58),
                    pants=DARK),
    "slot_06": dict(name="Henrik", skin=FAIR, hair=(96, 60, 24), hair_style="short",
                    beard=(128, 96, 56), beard_style="full", shirt=(48, 80, 124),
                    inner=WHITE_SHIRT, pants=DARK),
    "slot_07": dict(name="Stig", skin=FAIR, hair=(84, 56, 34), hair_style="receding",
                    glasses=(20, 20, 28), mouth="soft", shirt=(72, 84, 90), inner=WHITE_SHIRT,
                    pants=(60, 68, 74)),
    "slot_08": dict(name="Casper", skin=(248, 176, 144), hair=(80, 48, 16), hair_style="short",
                    eye=(96, 64, 40), shirt=(30, 30, 36), shirt_light=(64, 64, 72),
                    pants=JEANS),
    "slot_09": dict(name="Kim", skin=FAIR, beard=(128, 88, 48), beard_style="short",
                    shirt=(160, 168, 176), short_sleeves=True, pants=JEANS),
    "slot_10": dict(name="Mette", skin=FAIR, hair=(110, 70, 36), hair_light=(146, 98, 54), slim=0.4,
                    hair_style="long", hair_length=13, shirt=(48, 84, 140),
                    dots=(196, 210, 230), pants=DARK),
    "slot_11": dict(name="Mads", skin=(88, 96, 52), hair=(92, 60, 36), hair_style="short",
                    glasses=(20, 20, 28), eye=(70, 50, 30),
                    camo=[(88, 96, 52), (60, 70, 38), (110, 88, 56), (40, 44, 30)],
                    shirt=(196, 244, 0), shirt_shade=(140, 180, 0), shirt_light=(226, 255, 90),
                    stripe=(170, 178, 200), pants=DARK),
    "slot_12": dict(name="Sjippepigen", skin=(120, 128, 80), skin_shade=(92, 100, 60),
                    hair=(146, 122, 70), hair_light=(182, 160, 100), hair_style="ponytail",
                    eye=(70, 60, 40), eye_white=(226, 230, 208), statue=True, mouth="small", soft_face=True, shirt=(128, 92, 58),
                    legs="skirt", pants=(120, 128, 80), shoes=(88, 64, 40), build="slim", head_trim=([14], [12, 16, 22, 27]),
                    oval_head=(8.8, 17.6, 7.7, 8.6)),
    "slot_13": dict(name="Fidusen", monkey=True, skin=(112, 104, 88), hair=(112, 104, 88),
                    hair_light=(136, 126, 106), face=(232, 218, 176), muzzle=(184, 170, 146),
                    iris=(128, 72, 46), mouth="soft",
                    eye=(14, 10, 10), shirt=(112, 104, 88), shirt_light=(136, 126, 106),
                    pants=(100, 92, 78), hands=(125, 80, 45), shoes=(125, 80, 45),
                    collar="none", belly=True),
    "slot_14": dict(name="Magnus", skin=(240, 166, 130), hair=(96, 60, 34),
                    hair_light=(130, 86, 50), hair_style="fringe", glasses=(20, 20, 28),
                    shirt=(40, 120, 128), pants=JEANS, build="small",
                    head_trim=([2, 14], [12, 21])),
}


def palette(c):
    skin = c["skin"]
    shirt = c["shirt"]
    p = {
        "O": OUTLINE, "S": skin, "s": c.get("skin_shade", scale(skin, 0.8)),
        "L": c.get("skin_light", scale(skin, 1.25)), "X": c.get("stubble", skin),
        "W": (244, 244, 244), "B": c.get("eye", (59, 125, 201)), "T": (250, 246, 236),
        "H": shirt, "h": c.get("shirt_shade", scale(shirt, 0.72)),
        "K": c.get("shirt_light", scale(shirt, 1.22)),
        "D": c.get("pants", DARK), "d": scale(c.get("pants", DARK), 0.72),
        "N": c.get("shoes", (52, 40, 36)), "n": scale(c.get("shoes", (52, 40, 36)), 1.3),
        "J": c.get("hands", skin), "j": scale(c.get("hands", skin), 0.82),
    }
    p["F"], p["f"], p["e"], p["g"] = p["K"], p["H"], p["h"], p["h"]
    if c.get("short_sleeves"):
        p["F"], p["f"], p["e"], p["g"] = p["L"], p["S"], p["s"], p["s"]
    if "hair" in c:
        p["A"] = c["hair"]
        p["a"] = c.get("hair_shade", scale(c["hair"], 0.72))
        p["Z"] = c.get("hair_light", scale(c["hair"], 1.25))
    if "beard" in c:
        p["R"], p["r"] = c["beard"], scale(c["beard"], 0.75)
    if "glasses" in c:
        p["G"] = c["glasses"]
    if "inner" in c:
        p["I"] = c["inner"]
    if "stripe" in c:
        p["V"] = c["stripe"]
    if "dots" in c:
        p["Q"] = c["dots"]
    if "blush" in c:
        p["U"] = c["blush"]
    if "lips" in c:
        p["M"] = c["lips"]
    if "freckles" in c:
        p["u"] = c["freckles"]
    p["m"] = (120, 40, 48)
    if c.get("statue"):
        p["W"] = c.get("eye_white", p["L"])
        p["T"] = p["L"]
    if c.get("monkey"):
        p["Y"], p["y"] = c["face"], scale(c["face"], 0.85)
        p["P"], p["p"] = c["muzzle"], scale(c["muzzle"], 0.85)
        p["W"] = c["iris"]      # red-brown eyes with black pupils
        p["L"] = p["Z"]
    return p


# A softer face: thin high brows, eyes (white, iris, pupil), no nose bump, light on the cheekbones.
SOFT_FACE = [(3, 18, "ss....ss"), (4, 18, "SSSSSSSSS"), (5, 17, "SSSSSSSSSS"),
             (6, 18, "WB....WB"), (7, 18, "WO....WO"), (8, 26, "Ss"), (9, 26, "SS"),
             (9, 16, "L"), (9, 27, "L")]
SOFT_FACE_CUT = [(8, 29), (9, 29)]
SMALL_SMILE = [(10, 19, "SSOSSSOSS"), (11, 19, "SSSOOOSSS"), (12, 19, "SSSSsSSSS"),
               (13, 21, "SSSSS")]

SHUT_EYES = [(6, 18, "SS....SS"), (7, 18, "OO....OO")]
HURT_MOUTH = [(10, 19, "SSSSSSSSS"), (11, 20, "OOOOOOO"), (12, 20, "OTOTOTO"), (13, 20, "OOOOOOO")]


def paint(cells, layer, only=None):
    """Paint (row, col, letters) entries; `only` limits painting to cells holding those letters."""
    for r, c0, s in layer:
        for i, ch in enumerate(s):
            if ch in " .":
                continue
            key = (r, c0 + i)
            if only is not None and cells.get(key) not in only:
                continue
            cells[key] = ch


def build_head(c, face="normal"):
    """The head's cells for a character: (behind, front) dicts of (row, col) -> letter.
    `behind` (long hair down the back) is drawn behind the body. face: normal, shut, hurt."""
    cells = {}
    for r, line in enumerate(HEAD.strip("\n").split("\n")):
        for col, ch in enumerate(line):
            if ch != ".":
                cells[(r, col)] = ch
    if c.get("build") == "heavy":
        paint(cells, FULL_CHEEKS)
    if c.get("big_chin"):
        paint(cells, BIG_CHIN)
    if face == "hurt":
        paint(cells, HURT_MOUTH)
    elif c.get("mouth") == "small":
        paint(cells, SMALL_SMILE)
    elif c.get("mouth") == "soft":
        paint(cells, SOFT_MOUTH)
    if c.get("soft_face"):
        paint(cells, SOFT_FACE)
        for key in SOFT_FACE_CUT:
            cells.pop(key, None)
    if "lips" in c and face != "hurt":
        paint(cells, LIPS)
    if c.get("monkey"):
        paint(cells, MONKEY_CLEAR)
        paint(cells, MONKEY_FACE, only=set("SsLX"))
        paint(cells, MONKEY_MUZZLE)
        paint(cells, MONKEY_GRIMACE if face == "hurt" else MONKEY_SMILE)
        paint(cells, MONKEY_EAR)
        paint(cells, MONKEY_TUFT)
    if face in ("shut", "hurt"):
        shut = [(r, c0, s.replace("S", "Y" if c.get("monkey") else "S")) for r, c0, s in SHUT_EYES]
        paint(cells, shut)
    if "beard" in c:
        paint(cells, BEARD[c["beard_style"]], only=SKIN)
        if c["beard_style"] == "full":
            paint(cells, BEARD["full_hang"])
    if "blush" in c:
        paint(cells, BLUSH, only=SKIN)
    if "freckles" in c:
        paint(cells, FRECKLES, only=SKIN)
    style = c.get("hair_style")
    if style == "buzz":
        # Short, thin hair: the short cut's shape, dotted over the scalp only.
        for r, c0, s in HAIR["short"]:
            for i, ch in enumerate(s):
                key = (r, c0 + i)
                if ch not in " ." and cells.get(key) in SKIN and (key[0] + key[1]) % 2 == 0:
                    cells[key] = "a" if ch == "a" else "A"
    elif style:
        paint(cells, HAIR[style])
    if "glasses" in c:
        paint(cells, GLASSES)
    behind = {}
    if style == "long":
        paint(behind, long_back(c.get("hair_length", 11)))
    if "head_trim" in c:
        cells = trim(cells, *c["head_trim"])
        behind = trim(behind, *c["head_trim"])
    if c.get("jaw_taper"):
        cells = taper_jaw(cells, c["jaw_taper"])
    if c.get("oval_head"):
        cells = oval_head(cells, *c["oval_head"])
    return behind, cells


def oval_head(cells, cy, cx, ry, rx, lean=0.3, jaw=0.45):
    """A smooth, rounded head: the skin becomes an even oval (center row cy, column cx, radii ry,
    rx) with one soft shadow along the back and bottom edge, a highlight on the upper front and a
    simple ear; the features (eyes, mouth) and hair stay. Removes the shared head's carved shading.
    `lean`: the lower half shifts forward (this many width radii at the bottom), so the chin comes
    out; `jaw`: below the middle, the back is cut away by up to this many width radii, so the jaw
    curves up to the ear instead of making a thick neck."""
    feature = set("OWBTMmUuGRrYyPp")
    out = {k: ch for k, ch in cells.items() if ch in "AaZ" or (ch in feature and k[0] < 15)}
    for r in range(int(cy - ry) - 1, int(cy + ry) + 2):
        for col in range(int(cx - rx) - 1, int(cx + rx) + 2):
            v = (r + 0.5 - cy) / ry
            u = (col + 0.5 - cx) / rx - lean * max(v, 0.0)
            d = u * u + v * v
            # Behind the face, only where the head already was (keeps the gap to a ponytail).
            if d > 1.0 or (r, col) in out or (col < cx and (r, col) not in cells):
                continue
            if v > 0.15 and u < -1.0 + jaw * (v - 0.15) / 0.85 * 2:
                continue
            if d > 0.62 and (u < -0.2 or v > 0.45):
                out[(r, col)] = "s"
            elif d < 0.35 and v < -0.45 and u > -0.1:
                out[(r, col)] = "L"
            else:
                out[(r, col)] = "S"
    # The shadow follows the jaw's back edge too.
    for (r, col), ch in list(out.items()):
        if ch == "S" and r > cy and (r, col - 1) not in out:
            out[(r, col)] = "s"
    ex, ey = round(cx - rx * 0.5), round(cy - 0.5)
    for (r, col) in ((ey - 1, ex), (ey - 1, ex + 1), (ey, ex), (ey + 1, ex), (ey + 1, ex + 1)):
        if out.get((r, col)) in ("S", "s", "L"):
            out[(r, col)] = "s"
    return out


def taper_jaw(cells, cuts):
    """A slimmer chin: from the bottom row of the head up, drop this many pixels at the back of
    each row (the jaw curves back up toward the ear). The outline is redrawn around it."""
    bottom = max(r for (r, col), ch in cells.items() if ch not in "AaZ")
    for i, n in enumerate(cuts):
        r = bottom - i
        row = sorted(col for (rr, col), ch in cells.items() if rr == r and ch not in "AaZ")
        for col in row[:n]:
            del cells[(r, col)]
    return cells


def trim(cells, rows, cols):
    """A smaller head: drop these grid rows and columns, closing the gaps toward NECK (rows above
    move down, columns move toward the neck's column), so the head still sits on the neck."""
    nr, nc = NECK
    for gone in sorted(rows, reverse=True):
        cells = {((r + 1) if r < gone else r, col): ch for (r, col), ch in cells.items() if r != gone}
    for gone in cols:
        moved = {}
        for (r, col), ch in cells.items():
            if col == gone:
                continue
            if gone < nc and col < gone:
                col += 1
            elif gone > nc and col > gone:
                col -= 1
            moved[(r, col)] = ch
        cells = moved
    return cells


def camo_color(c, x, y):
    """Face paint: blotches of the camo colors, fixed to the head's grid."""
    blob = ((x // 3) * 7 + (y // 2) * 13 + (x // 3) * (y // 2)) % 5
    return c["camo"][blob % len(c["camo"])]
