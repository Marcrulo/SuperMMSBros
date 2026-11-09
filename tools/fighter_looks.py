"""Each character's look for tools/gen_fighter_sprites.py: colors taken from their portraits
(assets/fighters/portraits/), a hair style and a few traits. Everyone shares the same body and
poses.

Keys: skin, hair, shirt, pants (base colors; shades are derived), optional shoes, eye, hands,
hair_style (short, receding, fringe, bob, long, bun, ponytail, bald, monkey), hair_length (how
far long hair hangs, in px; default 11), puff (extra hair volume, in head radii), beard, glasses,
lens, blush, inner (shirt under an open jacket), stripe (reflective bands), dots (a dotted
print), sleeves ("short" shows the forearms), hood, skirt, camo (face-paint colors), face and
tail (the monkey). Build: legs, torso (px longer per leg segment / torso), head (head
radius), arms (px per arm segment), wide (torso px wider at the back), belly (px of belly in
front), cheeks (head this much wider than tall); negative for smaller.
"""

## Characters whose strips have been edited by hand: the generator leaves their folders alone
## (unless an id is named on its command line). See docs/specs/art-guide.md#generated-characters.
## slot_05 (Michael Bech) is drawn in the 64 px style by tools/gen_fighter_sprites64.py.
HAND_EDITED: set[str] = {"slot_05"}

FAIR = (240, 176, 136)
JEANS = (51, 60, 87)
DARK = (40, 42, 54)
BLACK_FRAMES = (20, 20, 28)

LOOKS = {
    # Pia: heavier build (same height); short copper-red hair, rosy cheeks, grey top.
    "slot_01": dict(skin=(232, 160, 122), hair=(150, 52, 26), hair_light=(190, 82, 40),
                    hair_style="bob", blush=(222, 120, 110), shirt=(128, 128, 136), pants=JEANS,
                    wide=2, belly=2, cheeks=0.6),
    # Gitte: big white hair, magenta jacket.
    "slot_02": dict(skin=FAIR, hair=(236, 240, 244), hair_light=(255, 255, 255), hair_style="bob",
                    puff=0.12, shirt=(226, 48, 120), shirt_shade=(160, 16, 88), pants=DARK),
    # Trine: shoulder-length grey hair, thick black glasses, grey blazer.
    "slot_03": dict(skin=FAIR, hair=(160, 168, 176), hair_style="long", hair_length=9,
                    glasses=BLACK_FRAMES, shirt=(84, 96, 106), inner=(150, 160, 168), pants=DARK),
    # Nina: long red hair, black top.
    "slot_04": dict(skin=(248, 180, 140), hair=(168, 30, 18), hair_light=(214, 64, 34),
                    hair_style="long", shirt=(36, 32, 40), shirt_light=(70, 62, 74), pants=JEANS),
    # Michael Bech: shaved head, ruddy skin, orange hoodie.
    "slot_05": dict(skin=(240, 128, 112), skin_shade=(196, 92, 84), hair=(240, 128, 112),
                    hair_style="bald", shirt=(240, 90, 10), shirt_shade=(184, 40, 0), hood=True,
                    pants=DARK),
    # Henrik: receding brown hair, full beard, navy blazer over a white shirt.
    "slot_06": dict(skin=FAIR, hair=(96, 60, 24), hair_style="receding", beard=(128, 96, 56),
                    shirt=(48, 80, 124), inner=(232, 236, 240), pants=DARK),
    # Stig: short receding dark-brown hair (a big forehead), dark glasses, grey suit, white shirt.
    "slot_07": dict(skin=FAIR, hair=(84, 56, 34), hair_style="receding",
                    glasses=BLACK_FRAMES, shirt=(72, 84, 90), inner=(232, 236, 240),
                    pants=(60, 68, 74)),
    # Casper: short brown hair, black top.
    "slot_08": dict(skin=(248, 176, 144), hair=(80, 48, 16), shirt=(30, 30, 36),
                    shirt_light=(64, 64, 72), pants=JEANS),
    # Kim: bald, ginger-brown beard, grey t-shirt.
    "slot_09": dict(skin=FAIR, hair=FAIR, hair_style="bald", beard=(128, 88, 48),
                    shirt=(160, 168, 176), sleeves="short", pants=JEANS),
    # Mette: long brown hair, blue patterned top.
    "slot_10": dict(skin=FAIR, hair=(110, 70, 36), hair_light=(146, 98, 54), hair_style="long",
                    shirt=(48, 84, 140), dots=(196, 210, 230), pants=DARK),
    # Mads: camo face paint, dark hair, glasses, hi-vis yellow jacket with reflective bands.
    "slot_11": dict(skin=(88, 96, 52), hair=(32, 28, 26), glasses=BLACK_FRAMES,
                    camo=[(88, 96, 52), (60, 70, 38), (110, 88, 56), (88, 96, 52), (40, 44, 30)],
                    shirt=(196, 244, 0), shirt_shade=(140, 180, 0), stripe=(170, 178, 200),
                    pants=DARK),
    # Sjippepigen: a bronze statue with a green patina, ponytail, a dress.
    "slot_12": dict(skin=(120, 128, 80), skin_shade=(92, 100, 60), hair=(146, 122, 70),
                    hair_light=(182, 160, 100), hair_style="ponytail", eye=(52, 56, 34),
                    shirt=(128, 92, 58), skirt=True, pants=(120, 128, 80), shoes=(88, 64, 40)),
    # Fidusen: a monkey. Grey-brown fur, a beige face, hands and feet.
    "slot_13": dict(skin=(112, 104, 88), hair=(112, 104, 88), hair_light=(136, 126, 106),
                    hair_style="monkey", face=(200, 172, 136), eye=(40, 22, 16),
                    shirt=(112, 104, 88), shirt_light=(136, 126, 106), pants=(100, 92, 78),
                    hands=(200, 172, 136), shoes=(170, 146, 112), tail=True),
    # Magnus: smaller build; brown hair with a fringe, black glasses. Clothes unknown yet:
    # a teal hoodie.
    "slot_14": dict(skin=(240, 166, 130), hair=(96, 60, 34), hair_light=(130, 86, 50),
                    hair_style="fringe", glasses=BLACK_FRAMES, shirt=(40, 120, 128), pants=JEANS,
                    legs=-0.6, torso=-1.0, head=-0.5, arms=-0.4),
}
