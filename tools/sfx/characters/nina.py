"""Nina's own sounds (docs/specs/characters/nina.md#sounds), built by tools/gen_character_sfx.py."""
SOUNDS = {
    # The letter volley: she screams them out (cut to the volley's length).
    "scream": dict(url="https://cdn.freesound.org/previews/724/724794_13999124-hq.mp3",
                   title="Robot Woman Screaming Sound Effect", author="Mastersoundboy2005",
                   page="https://freesound.org/people/Mastersoundboy2005/sounds/724794/",
                   license="CC0", cut=(0.2, 1.9)),
    # The lullaby (cut to the song's length).
    "sing": dict(url="https://cdn.freesound.org/previews/315/315856_4557960-hq.mp3",
                 title="female e reverb loop.aiff", author="bevibeldesign",
                 page="https://freesound.org/people/bevibeldesign/sounds/315856/",
                 license="CC0", cut=(0.0, 1.7)),
}
