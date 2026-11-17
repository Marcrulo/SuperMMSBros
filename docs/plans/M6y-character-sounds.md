# M6y — Character sounds

Spec: [sound](../specs/sound.md#character-sounds) (loops, character sounds) and each character's own
spec. Sounds chosen by the user from CC0 Freesound candidates (2026-11-17).

## Step 1 — shared plumbing (on `main`, `shared:` commit)

Tests first (`tests/test_fighter_sounds.gd`, `tests/test_match_hits.gd`), then:

- `MoveData`: `sounds` (`Dictionary[StringName, AudioStream]`), `active_sound`, `hit_sound`.
- `Match`: signal `hit_landed(player_index, move)`, emitted for each landed hit before `fighter_hit`.
- `FighterSounds`:
  - loops generalized (one loop player; `loop_sound()` says what loops for the move in progress,
    and it stops when the move ends; fixes the `charge` hum carrying on after Magnus's rise);
  - a move's `sounds` replace defaults, `active_sound` on its first active frame, `hit_sound` from
    `hit_landed`;
  - ability `"streams"` resolve sound names for that fighter.
- `FighterAbility.sounds()` doc: `"streams"`, `"loop"`.
- `tools/gen_character_sfx.py <name>`: reads `tools/sfx/characters/<name>.py`, downloads, cuts,
  reverses, prepares into `characters/<name>/sounds/`, writes its `CREDITS.txt`.

Then commit, push, and fast-forward the character branches to `main`.

## Step 2 — per character (each on `char/<name>` in its worktree)

Spec line in the character's spec, sound list in `tools/sfx/characters/<name>.py`, generated
files + credits, wiring in its `.tres`/ability, a test, full suite.

| Character | Sound | Where |
|---|---|---|
| Gitte | reversed medium hit | her hits in the `−` stance (`modify_hit` sets `hit_sound`) |
| Gitte | metallic whoosh | side special's volley (`sounds` replaces `zap`) |
| Nina | scream (cut to the volley's length) | `letters` phase start |
| Nina | singing (cut to the song's length) | `song` phase start |
| Henrik | acoustic C chord | `speaker_jam` phase start |
| Stig | choir ("Angel Reveal", cut) | down special's `burst` replaced |
| Kim | metal hit | the thrown hammer's `hit_sound` |
| Kim | flamethrower | torch `active_sound` |
| Kim | axe cut | axe (side tilt) `active_sound` |
| Mette | bottle break | flask smash `active_sound`; the thrown flask shattering |
| Mette | whoosh | the thrown flask leaving her hand |
| Mette | water / slime / acid bubbling | the flask's splash by colour (blue / green / red) |
| Magnus | fire | the fireball appearing |
| Magnus | wind whistle | loops through the Avatar flight |

Not in this milestone: sounds still being searched (Pia, Trine, Fidusen, the rest of the "none"
picks), and Mette's acid puddle showing a hit (its own step).

## Done when

All tests pass headless on each branch and on `main` after the merge, and the user has heard them.
