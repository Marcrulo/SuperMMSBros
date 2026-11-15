# M6x — Pia's Leverkusen banner (up special) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this
> plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Pia's up special becomes a grounded gesture: she holds up a Bayer Leverkusen banner and
every fighter within 100 px is stunned until she lowers it; 3 s cooldown.

**Architecture:** A new `BannerAbility` + `BannerData` in `characters/pia/`, plugged in through the
existing hooks like her cake (`pick_special`, `move_tick`, `phase_*`, `end_step`, `draw`). The
stun reuses `Fighter.stun()`. No shared files change.

**Tech Stack:** Godot 4.7, GDScript, GUT; Python sprite generator (`tools/sprites/characters/pia.py`).

**Spec:** `docs/specs/characters/pia.md#up-special--leverkusen-banner` and `#pias-specials`.

## Global Constraints

- Work only in `../SuperMMSBros-pia` on `char/pia`; only Pia's own files (CLAUDE.md, character
  branches). `tests/test_character_split.gd` must stay green.
- Frame-based: 98 / 0 / 10 frames, `raise_frames` 8, `radius` 100, `cooldown_frames` 180.
- Presentation only reads (the ring and the drawings never change gameplay).

## Review Focus

- Pia hit mid-banner by a projectile still in flight: victims released, cooldown starts.
- A victim launched into hitstun by something else while in range: re-stunned once hitstun ends.
- Pia KO'd / respawned mid-banner: nobody stays stunned, cooldown is 0 after the spawn.
- A victim already dizzy from a shield break: left alone (not shortened or lengthened).
- Up special pressed in the air or during the cooldown: nothing happens, no jump boost.

---

### Task 1: The banner and its stun

**Files:**
- Create: `super-mms-bros/characters/pia/banner_data.gd`, `banner_ability.gd`, `moves/banner.tres`,
  `moves/up_special.tres`
- Modify: `super-mms-bros/characters/pia/moves/moveset.tres` (`up_special` → Pia's own)
- Test: `super-mms-bros/tests/test_pia_banner.gd`

**Interfaces:**
- Produces: `class_name BannerData extends AbilityData` with `@export var raise_frames: int`,
  `radius: float`, `cooldown_frames: int`; `create_ability()` → `BannerAbility.new()`.
- Produces: `class_name BannerAbility extends FighterAbility`, phase `&"banner"`,
  `var banner_cooldown: int`, `func is_up() -> bool` (banner up this frame),
  `static func banner_frame(ticks: int, data: MoveData, raise_frames: int) -> int` (drawing 0–3).

- [ ] **Step 1: Write the failing tests** (`test_pia_banner.gd`, same setup as `test_pia.gd`;
  P2 = slot_09; P1 grounded at (240, 192), P2 at (300, 192) unless said; the up special input =
  `special_pressed`, `special_held`, `up_held`):
  - `test_the_banner_matches_the_spec`: Pia's `up_special` is 98/0/10, its ability a `BannerData`
    with 8 / 100.0 / 180.
  - `test_nobody_else_has_a_banner`: slot_09's up special still launches (default jump boost).
  - `test_the_banner_stuns_someone_near`: P2 is `SHIELD_BREAK` on Pia's frame 10 and frame 98,
    and not on frame 99.
  - `test_nobody_is_stunned_before_it_is_up`: P2 not dizzy on Pia's frames 1–8.
  - `test_she_stays_put`: Pia's x doesn't change and she's in `ATTACK`/`banner` frames 1–108,
    free after.
  - `test_someone_far_away_is_not_stunned`: P2 at (360, 192) (120 px) never dizzy.
  - `test_someone_in_the_air_is_stunned_and_falls`: P2 at (300, 120) is dizzy and its y grows.
  - `test_walking_in_later_is_stunned_until_the_end`: P2 starts at (360, 192) walking left;
    dizzy once within 100 px, free on frame 99.
  - `test_a_shield_does_not_help`: P2 shielding is stunned.
  - `test_no_banner_in_the_air`: Pia at (240, 100) — no `banner`, no `up_special`.
  - `test_no_banner_during_the_cooldown` / `test_the_cooldown_runs_out` (180 ticks after it ends)
    / `test_spawning_clears_the_cooldown`.
  - `test_a_hit_stops_it_and_lets_go`: a projectile hits Pia mid-banner (P2 = a fighter whose
    side special is in flight before the banner, or `_p1.take_hit()` directly); P2 is free within
    2 ticks and `banner_cooldown == 180`.
  - `test_hitstun_then_stun`: P2 put into hitstun in range (`take_hit`) is dizzy once hitstun ends.
  - `test_a_shield_break_is_left_alone`: P2 already `stun(300)` stays dizzy past frame 99.
  - `test_banner_drawings_follow_the_move`: `banner_frame` = 0 for ticks 1–8, 1 for 9–16,
    2 for 17–24, 1 for 25–32 … (switching every 8), 3 for 99–108.
- [ ] **Step 2:** `godot --headless --path super-mms-bros --import` then run
  `godot --headless --path super-mms-bros -s res://addons/gut/gut_cmdln.gd -gselect=test_pia_banner`;
  expect failures (missing classes).
- [ ] **Step 3: Implement.** `pick_special`: up direction → `&"banner"` on the ground with
  cooldown 0, else `NO_MOVE`. `replaces(&"up_special")` → true. `phase_data` = the up special's
  MoveData; `phase_finished` at `total_frames()`. `end_step(match)`: if Pia is in `banner` and up
  (`state_frame` in 9…97 at end of step), stun each other fighter in range that `can_be_hit()`, isn't
  `HITSTUN` and isn't already `SHIELD_BREAK`, with `stun(98 - state_frame)`, and remember it; when
  she has left the phase (finished, hit, KO'd), `stun(1)` every remembered victim still dizzy from
  it if the banner was cut short, clear the list, set `banner_cooldown = cooldown_frames`.
  `before_tick` counts the cooldown down; `reset()` clears both. Exact frame bounds: tune to the
  tests (state_frame after the tick = frame number).
- [ ] **Step 4:** run the file, then the whole suite; all green.
- [ ] **Step 5: Commit** `Pia: Leverkusen banner up special (stun in range, 3 s cooldown)`.

### Task 2: The drawings and the ring

**Files:**
- Modify: `tools/sprites/characters/pia.py` (banner prop + `up_special` strip), its look entry in
  `tools/fighter64_looks.py` (`banner=True`), `characters/pia/banner_ability.gd`
  (`phase_animation` → `"up_special"`, `drawing()` via `banner_frame`, `draw()` the ring)
- Regenerate: `assets/fighters/slot_01/fighter_up_special.png`
- Test: `tests/test_pia_banner.gd`

- [ ] **Step 1: Failing tests:** `test_banner_animation`: `animation_for(ATTACK, 0, &"banner", …)`
  is `"up_special"`; `test_the_banner_strip`: `fighter_up_special.png` is 4 drawings of 64, and
  drawing 2 has red (214, 32, 40)-ish pixels above the head row (the cloth is up high).
- [ ] **Step 2:** run, expect failures.
- [ ] **Step 3:** the prop (`PROPS["banner"]`, on the front fist, pole up, 20×14 cloth: red, white
  disc with black outline and black cross, yellow bottom strip; `wave` 0/1/2 ripples the bottom);
  `BANNER_ANIMATIONS["up_special"]` = raise, hold A, hold B (mouth open), lower — both arms up.
  Regenerate with `python3 tools/gen_fighter_sprites64.py`; re-import.
- [ ] **Step 4:** tests green; sweep all four drawings zoomed (arms, pole through the hands, no
  stray pixels); rebuild + republish the Sprites artifact.
- [ ] **Step 5: Commit** `Pia: banner drawings and range ring`.

### Task 3: Wrap up

- [ ] Full suite green; update `.claude/memory/project-status.md`; commit and push `char/pia`;
  ask the user to playtest (`godot --path ../SuperMMSBros-pia/super-mms-bros`).
