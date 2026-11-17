# Sound

Fight sound effects: what makes a sound in a match, where the sounds come from, and how they are
played. Menu sounds and music are in [menus](menus.md#sound) and
[match & stage](match-and-stage.md).

## Intent

A match should sound like a movie fight: a meaty punch when a hit lands, heavier the harder it
launches, with footsteps, jumps, swings and a big knockout boom around it. The menus keep their
retro chiptune sounds; fight sounds are realistic (recorded foley), not beeps.

- **Goals:** every common action is heard; hit strength is audible; a character's own moves can
  have their own sounds (see [Character sounds](#character-sounds)); sounds come from free
  libraries with clear licenses.
- **Non-goals (for now):** a volume settings screen, positional effects beyond left/right panning.
- **Anti-goals:** a sound that changes gameplay in any way (the game must play the same headless);
  the same sample firing identically many times a second (it gets grating, so repeated sounds vary
  slightly); fight sounds drowning out the stage music.

## Events

| Event | When (per tick, from the Match or the fighter's state) | Sound file |
|---|---|---|
| Hit, light | a fighter takes a hit (`Match.fighter_hit`) and is launched at under 200 px/s | `hit_light` |
| Hit, medium | ... launched at 200–400 px/s | `hit_medium` |
| Hit, heavy | ... launched at 400 px/s or more | `hit_heavy` |
| Blocked | a hit lands on a shield (new signal `Match.fighter_blocked`) | `block` |
| Swing | a normal attack (jab, tilts, aerials) starts | `swing` |
| Charged punch | the neutral special's punch starts (Michael: his summon starts) | `swing_heavy` |
| Charging | while the neutral special charges (a loop, see [Loops](#loops)) | `charge` |
| Projectile | the side special's projectile appears | `zap` |
| Hand slam | Michael's hand reaches the floor (`Match.owner_sound`, owner's sounds) | `burst` |
| Burst | the down special's ground burst starts its active frames | `burst` |
| Dive | the down special's air dive starts | `dive` |
| Boost | the up special launches (its frame 5; Gitte: her hop, or her pop off the pyramid's tip) | `boost` |
| Pyramid | Gitte's pyramid starts rising (her move becomes `pyramid_rise`) | `burst` |
| Footstep | in `RUN`, on the two foot plants of the run cycle: `(state_frame - 1) % 30` is 0 or 15; in `DASH`/`SPRINT` the same on the faster cycle, `% 18` is 0 or 9 | `step_1`, `step_2` (alternating) |
| Jump | a ground jump (the fighter leaves the ground going up, not from a hit) | `jump` |
| Double jump | an air jump (`jumps_left` drops in the air) | `double_jump` |
| Land | the fighter touches the ground after being airborne | `land` |
| Shield up | the fighter enters `SHIELD` | `shield_on` |
| Shield break | the fighter enters `SHIELD_BREAK` | `shield_break` |
| Dodge | the fighter enters `SPOT_DODGE`, `ROLL` or `AIR_DODGE` | `dodge` |
| Ledge grab | the fighter enters `LEDGE` | `ledge_grab` |
| KO | a fighter leaves the blast zone (`Match.fighter_ko`) | `ko` |
| Respawn | a KO'd fighter comes back (`Match.fighter_respawned`) | `respawn` |

- One event per tick per kind at most; a hit sound plays for the victim, not the attacker.
- The launch speed is the victim's speed right after `take_hit` (the Match emits `fighter_hit` right
  after it). The thresholds (200 and 400 px/s) are tuning numbers in the sound resource below.

## Playing

- **Presentation only reads.** A `FighterSounds` node on each fighter (next to `FighterVisuals`)
  listens to the Match and compares the fighter's state with the previous tick's to find the events
  above. It never changes the fighter or the Match. The Match gets one new signal, `stepped`,
  emitted at the end of every `step()`, so events are found per tick even when several ticks run in
  one frame; and `fighter_blocked(player_index)` for shield hits.
- **Players:** each fighter has an `AudioStreamPlayer2D` (panned left/right by where the fighter is
  on screen, relative to the camera) with a few voices of polyphony, on the `SFX` bus. Loops have
  their own player so they can be stopped. KO and respawn sounds play unpanned (the fighter is off
  screen).
- **Variation:** each play picks a pitch between 0.95 and 1.05 from a presentation-only random
  generator (never the Match's seeded RNG, which is for gameplay).
- **Resource:** a `FightSounds` resource (`match/fight_sounds.tres`) maps each sound name to its
  `AudioStream` and holds the hit-strength thresholds and the pitch range, so they can be tuned in
  the Inspector. A character's own sounds come on top of it (below).
- A sound whose file is missing is silent, as in the menus.

### Loops

A loop plays from when a move (or an ability's phase) starts until the fighter is no longer in it:
another move, another phase, hitstun, a KO. One loop at a time per fighter; a new one replaces the
old. Which sound loops for the move in progress:

- `neutral_special_charge`: `charge`;
- an ability's phase listed in its `sounds()` under `"loop"` (`{phase: sound}`);
- an ability's phase whose `"start"` sound is `charge` (it was always meant to loop).

## Character sounds

A character's own moves can sound like what they are (a chop, a scream, a choir). Everything here
is character-owned: the sounds live in the character's folder and are plugged in through the move
data and the ability hooks, so the shared code never names a character's sound.

- **On a move** (`MoveData`, so in the character's `moves/*.tres`; set in the Inspector):
  - `sounds` (`{default sound name: AudioStream}`): while this move is in progress, these of the
    default sounds play this stream instead. E.g. a side special's projectile `zap` → a metallic
    whoosh; a down special's `burst` → a choir.
  - `active_sound`: plays when this move's hitbox comes out (its first active frame), on top of
    the defaults (unless `sounds` replaces `burst`, which plays at the same moment).
  - `hit_sound`: what the victim hears when this move's hit lands, instead of the light/medium/heavy
    hit. It works for any hit the Match resolves (normals, specials, projectiles, entities, ability
    hits), so an ability's `modify_hit()` can give a hit its sound too.
  - To find them, `FighterSounds` reads `Fighter.current_move()` each tick; for the hit it reads the
    move from the Match's new signal `hit_landed(player_index, move: MoveData)`, emitted for every
    hit that lands, just before `fighter_hit`. Hits that only emit `fighter_hit` (an ability's own
    damage) keep the default hit sound.
- **On an ability** (`FighterAbility.sounds()`):
  - `"streams"` (`{name: AudioStream}`): its own sound files, by name. Names here can be used
    anywhere a sound name goes for that fighter: `"start"`, `"loop"`, and
    `Match.owner_sound(player_index, name)` from its entities. They take priority over the default
    set, for that fighter only.
  - `"loop"` (`{phase: sound}`): see [Loops](#loops).
- **Files:** `characters/<name>/sounds/<sound>.wav`, prepared like the fight sounds (cut where
  needed, trimmed, loudness-normalized, 44.1 kHz) by `tools/gen_character_sfx.py <name>`, which
  reads the character's list in `tools/sfx/characters/<name>.py` (source, cut, gain, reverse) and
  writes `characters/<name>/sounds/CREDITS.txt` (one per character, so branches don't collide).
  Freesound sounds come from their public high-quality previews (an MP3 of the original).
- What each character's moves sound like is in its own spec (`docs/specs/characters/<name>.md`).

## Files and licenses

- Files: `assets/sfx/fight/<name>.wav`, trimmed, at 44.1 kHz, loudness-normalized with
  `tools/prepare_music.py --sfx` (as the menu sounds), then mixed by ear so hits stand out and
  footsteps sit low.
- **Sources:** free libraries only. CC0 first (Kenney's audio packs, CC0 sounds on freesound.org and
  OpenGameArt); CC BY is fine with a credit. A file whose license is unknown is never committed.
- Every file gets an entry in `assets/sfx/CREDITS.txt`: name, author, source URL, license, changes.
- **Choosing:** candidates are downloaded to a scratch folder first and the user listens to them
  before anything goes into the game.

## Testing

- The event detection is a pure function (previous and current fighter state → events) with unit
  tests for each row of the table, including footstep timing and the hit-strength thresholds.
- Every sound name in the table has a file in `assets/sfx/fight/` and a credit in `CREDITS.txt`.
- Loops, a move's `sounds` / `active_sound` / `hit_sound`, and ability streams each have tests; every
  file in a character's `sounds/` folder has a credit in its `CREDITS.txt`.
- A headless match runs with sounds attached and plays exactly as without them.
