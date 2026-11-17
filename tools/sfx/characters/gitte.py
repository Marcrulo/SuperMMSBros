"""Gitte's own sounds (docs/specs/characters/gitte.md#sounds), built by tools/gen_character_sfx.py."""
SOUNDS = {
    # Her hits in the − stance: the medium hit, played backwards.
    "reverse_hit": dict(file="super-mms-bros/assets/sfx/fight/hit_medium.wav", reverse=True,
                        title="hit29.mp3.flac (from \"37 hits/punches\")", author="qubodup",
                        page="https://opengameart.org/content/37-hitspunches", license="CC0"),
    # The scissor volley flying out.
    "volley": dict(url="https://cdn.freesound.org/previews/240/240640_4297595-hq.mp3",
                   title="Metallic Whoosh.wav", author="MissCellany",
                   page="https://freesound.org/people/MissCellany/sounds/240640/", license="CC0"),
}
