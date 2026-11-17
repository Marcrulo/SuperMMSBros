"""Mette's own sounds (docs/specs/characters/mette.md#sounds), built by tools/gen_character_sfx.py."""
SOUNDS = {
    # A flask breaking: the smash, and a thrown flask shattering.
    "glass": dict(url="https://cdn.freesound.org/previews/407/407431_7151065-hq.mp3",
                  title="bottle break.wav", author="DeezSoundzTho",
                  page="https://freesound.org/people/DeezSoundzTho/sounds/407431/", license="CC0"),
    # A flask leaving her hand.
    "throw": dict(url="https://cdn.freesound.org/previews/389/389458_6060491-hq.mp3",
                  title="Whoosh_1.wav", author="lzmraul",
                  page="https://freesound.org/people/lzmraul/sounds/389458/", license="CC0"),
    # Its potion splashing onto the floor, by colour.
    "splash_blue": dict(url="https://cdn.freesound.org/previews/737/737233_71257-hq.mp3",
                        title="Small Water Splash", author="qubodup",
                        page="https://freesound.org/people/qubodup/sounds/737233/", license="CC0"),
    "splash_green": dict(url="https://cdn.freesound.org/previews/433/433839_652422-hq.mp3",
                         title="Slime 28.wav", author="Archos",
                         page="https://freesound.org/people/Archos/sounds/433839/", license="CC0"),
    "splash_red": dict(url="https://cdn.freesound.org/previews/202/202094_3756348-hq.mp3",
                       title="Acid Bubbling.wav", author="spookymodem",
                       page="https://freesound.org/people/spookymodem/sounds/202094/",
                       license="CC0", cut=(0.0, 1.2)),
}
