# M6f — Fight Sounds Implementation Plan

> **For agentic workers:** executed inline (superpowers:executing-plans); no subagents. Steps use checkbox (`- [ ]`) syntax.

**Goal:** Matches sound like a movie fight: punches graded by strength, swings, specials,
footsteps, jumps, landings, shields, dodges, ledge grabs, KOs and respawns (asked for by the user:
"default sounds such as hitting, running, jumping"; approved: "Just try putting this into the
game").

**Architecture:** The Match emits two new signals, `stepped` (end of every `step()`) and
`fighter_blocked(player_index)`. A `FighterSounds` node on each fighter (next to `Visuals`) keeps
a snapshot of its fighter, and on every `stepped` turns the difference between the previous and
the current snapshot into sound names (`FighterSounds.events(before, after)`, a pure static
function); hits come from `fighter_hit` (weight from the victim's launch speed), KO/respawn from
the Match's signals. Sounds play on an `AudioStreamPlayer2D` (SFX bus) per fighter; the `charge`
loop has its own player. A `FightSounds` resource (`match/fight_sounds.tres`) maps names to
streams and holds the per-sound volume, the hit thresholds and the pitch range. The files are
CC0 sounds from OpenGameArt, prepared by `tools/gen_fight_sfx.py`.

**Tech Stack:** Godot 4.7, GDScript, GUT; Python + ffmpeg for the files.

**Spec:** [sound](../specs/sound.md)

## Global Constraints

- Presentation only reads: nothing in `FighterSounds` writes to a fighter or the Match.
- Hit weight: launch speed < 200 px/s light, < 400 medium, else heavy.
- Footsteps in `RUN` when `(state_frame - 1) % 30` is 0 (`step_1`) or 15 (`step_2`).
- Pitch varies 0.95–1.05 per play, from a presentation-only RandomNumberGenerator.
- Files: `assets/sfx/fight/<name>.wav`; every file credited in `assets/sfx/CREDITS.txt`.

## Review Focus

1. Several ticks in one frame (tests, `--speed=10`) → still one event per tick: events come from
   `stepped`, never `_process` → `test_events_follow_every_tick`.
2. A fighter hit while jumping isn't heard "jumping" (hitstun launch goes up) →
   `test_a_launch_is_not_a_jump`.
3. A charge interrupted by a hit stops its loop → `test_charge_stops_when_hit`.
4. A match with sounds plays exactly as one without → `test_sounds_do_not_change_the_match`.
5. A missing sound file is silent, not an error → `test_missing_sound_is_silent`.

---

- [x] **Task 1: sound files.** `tools/gen_fight_sfx.py <downloads_dir> <out_dir>`: a table of
  name → (source pack, file in it, trim/fade), each prepared with `prepare_music.prepare_sfx`
  into `assets/sfx/fight/<name>.wav`; credits appended to `CREDITS.txt`. Test
  (`tests/test_sound.gd`): `test_every_fight_sound_exists_and_is_credited` — for every name in
  `FightSounds.NAMES`, the `.wav` loads and `CREDITS.txt` mentions `fight/<name>.wav`.
- [x] **Task 2: Match signals.** `signal stepped`, `signal fighter_blocked(player_index: int)`
  (emitted in `_resolve_hits` where `block_hit` is called). Tests (`tests/test_match_hits.gd`):
  `test_stepped_once_per_step`, `test_blocked_hit_is_announced`.
- [x] **Task 3: events.** `match/fight_sounds.gd` (`class_name FightSounds extends Resource`):
  `const NAMES: Array[StringName]` (the spec's 22 names), `@export var streams:
  Dictionary[StringName, AudioStream]`, `@export var volume_db: Dictionary[StringName, float]`,
  `@export var light_below := 200.0`, `@export var heavy_from := 400.0`, `@export var pitch_min :=
  0.95`, `@export var pitch_max := 1.05`, `func hit_sound(launch_speed: float) -> StringName`.
  `fighter/fighter_sounds.gd` (`class_name FighterSounds extends Node2D`): `static func
  snapshot(fighter: Fighter) -> Dictionary` (state, state_frame, move, jumps_left, velocity,
  on_floor, has_projectile) and `static func events(before: Dictionary, after: Dictionary) ->
  Array[StringName]`. Tests (`tests/test_fighter_sounds.gd`): one per table row (swing for each
  normal, swing_heavy, charge start, zap, burst on frame 11, dive, boost, step_1/step_2 timing,
  jump, double_jump, land, shield_on, shield_break, dodge ×3, ledge_grab), plus
  `test_a_launch_is_not_a_jump`, `test_hit_sound_thresholds` (199 → light, 200 → medium, 400 →
  heavy).
- [x] **Task 4: playing.** `FighterSounds` node added to `fighter/fighter.tscn` as `Sounds`; in
  `_ready` it finds the Match (the fighter's `owner`, else nothing happens), creates its players
  (SFX bus, `max_polyphony = 4`; a separate `charge` player; KO/respawn on a plain
  `AudioStreamPlayer`), connects to `stepped`, `fighter_hit`, `fighter_blocked`, `fighter_ko`,
  `fighter_respawned`. `func play(sound: StringName) -> void` (records `last_played` for tests,
  silent when the stream is missing). Tests: `test_events_follow_every_tick`,
  `test_charge_stops_when_hit`, `test_sounds_do_not_change_the_match`,
  `test_missing_sound_is_silent`, `test_sounds_use_the_sfx_bus`.
- [ ] **Task 5: try it.** Run the whole suite headless; the user plays a match and judges the
  sounds and the mix (volumes in `match/fight_sounds.tres`).
