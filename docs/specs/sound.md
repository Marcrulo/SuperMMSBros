# Sound

Fight sound effects: what makes a sound in a match, where the sounds come from, and how they are
played. Menu sounds and music are in [menus](menus.md#sound) and
[match & stage](match-and-stage.md).

## Intent

A match should sound like a movie fight: a meaty punch when a hit lands, heavier the harder it
launches, with footsteps, jumps, swings and a big knockout boom around it. The menus keep their
retro chiptune sounds; fight sounds are realistic (recorded foley), not beeps.

- **Goals:** every common action is heard; hit strength is audible; sounds come from free libraries
  with clear licenses.
- **Non-goals (for now):** per-character sounds (voices, weapon sounds; they come with the
  per-character moves), a volume settings screen, positional effects beyond left/right panning.
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
| Charged punch | the neutral special's punch starts | `swing_heavy` |
| Charging | while the neutral special charges (loops; stops when the charge ends) | `charge` |
| Projectile | the side special's projectile appears | `zap` |
| Burst | the down special's ground burst starts its active frames | `burst` |
| Dive | the down special's air dive starts | `dive` |
| Boost | the up special launches (its frame 5) | `boost` |
| Footstep | in `RUN`, on the two foot plants of the run cycle: `(state_frame - 1) % 30` is 0 or 15 | `step_1`, `step_2` (alternating) |
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
  on screen, relative to the camera) with a few voices of polyphony, on the `SFX` bus. The `charge`
  loop has its own player so it can be stopped. KO and respawn sounds play unpanned (the fighter is
  off screen).
- **Variation:** each play picks a pitch between 0.95 and 1.05 from a presentation-only random
  generator (never the Match's seeded RNG, which is for gameplay).
- **Resource:** a `FightSounds` resource (`match/fight_sounds.tres`) maps each sound name to its
  `AudioStream` and holds the hit-strength thresholds and the pitch range, so they can be tuned in
  the Inspector. Per-character sound sets can later override it.
- A sound whose file is missing is silent, as in the menus.

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
- A headless match runs with sounds attached and plays exactly as without them.
