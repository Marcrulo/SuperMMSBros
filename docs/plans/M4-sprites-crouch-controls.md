# M4 — Sprites, Crouch and New Controls Implementation Plan

> **For agentic workers:** executed inline (superpowers:executing-plans); no subagents. Steps use checkbox (`- [ ]`) syntax.

**Goal:** Move a big-headed sprite fighter with the new key layout, crouch, and drop through
platforms with a double tap.

**Architecture:** New Input Map actions feed new `FighterInput` fields. The fighter gains `CROUCH`,
a hurtbox (`Area2D` with standing and crouching shapes) and a double-tap drop. Generated sprite
strips (the spike's generator, extended to every animation in the art guide) are drawn by a
sprite-based `FighterVisuals` that picks the animation from the state and the frame from
`state_frame`.

**Spec:** [fighter](../specs/fighter.md), [controls & display](../specs/controls-and-display.md), [art guide](../specs/art-guide.md)

## Global Constraints

As in M3. Tuning numbers in `default_stats.tres`; hurtbox sizes in `fighter.tscn`.

## Review Focus

1. W must no longer jump (up + attack would jump) → `test_keyboard_bindings` (W only on `up`).
2. A single down press on a platform must not drop; two within 12 ticks must; two far apart must not → drop tests.
3. Crouch on a thin platform must not fall through by itself → `test_crouching_on_a_platform_stays_on_it`.
4. Landing while holding down → `CROUCH`, not `IDLE` → `test_landing_with_down_held_crouches`.
5. Animation frame for every animation at its last tick and past it (non-looping holds the last drawing) → `test_frame_index`.

---

### Task 1: Input Map, `FighterInput`, `KeyboardController`

- [x] Tests (`test_input_map.gd`, `test_controllers.gd`): actions `up`, `special`, `shield` exist; keys `up` W, `jump` Space only, `special` K, `shield` L; gamepad `jump` A and Y, `special` B, `shield` RB and LB, `up` d-pad up and stick up (dead zone 0.5); `FighterInput` has `up_held`, `special_pressed`, `special_held`, `shield_held`, all false by default; the keyboard controller reads them (held stays true, pressed is one tick).
- [x] Run: fail. Change `project.godot`'s `[input]` section; add the fields and reads. Run: pass. Commit.

### Task 2: Crouch, hurtbox and double-tap drop

- `FighterStats.drop_double_tap_frames: int` = 12. `Fighter.State` gains `CROUCH`.
- `fighter.tscn`: `Hurtbox` (`Area2D`, layer 5, mask 0, monitoring/monitorable off) with `Standing` (16×27 at (0, −13.5)) and `Crouching` (16×15 at (0, −7.5)) shapes. `Fighter.get_hurtbox_rect() -> Rect2`: the crouching shape in `CROUCH`, else standing.
- Ground actions (this milestone's part of the spec's order): jump → double-tap drop → down held → `CROUCH` → run → idle. A down press remembers its tick; a second press within `drop_double_tap_frames` on a pass-through platform drops. Landing with down held → `CROUCH`. In `CROUCH`: slide to a stop, facing follows `move_x`, no walking.
- [x] Tests (`test_fighter_crouch.gd`, updated drop tests in `test_fighter_movement.gd`): hold down → `CROUCH` with the crouching hurtbox; release → `IDLE`/`RUN`; crouching slides to a stop and turns without moving; one press doesn't drop, two presses 5 ticks apart drop, two presses 20 ticks apart don't; `test_crouching_on_a_platform_stays_on_it`; `test_landing_with_down_held_crouches`; standing hurtbox rect `Rect2(pos + (−8, −27), (16, 27))`.
- [x] Run: fail. Implement. Run: pass. Commit.

### Task 3: Placeholder sprites

- `tools/gen_placeholder_sprites.py <out_dir>`: the spike generator (big head), extended with every animation in the art guide (frame counts as listed) and `projectile.png` (3 × 12×12).
- [x] Generate into `super-mms-bros/assets/fighters/default/`; import. Test (`test_sprites.gd`): every animation file exists, is 48 px tall and `frames × 48` wide (frame counts from the art guide table); `projectile.png` is 36×12.
- [x] Commit.

### Task 4: Sprite-based `FighterVisuals`

- Animation table as in the art guide: name → drawing durations and loop. `static func frame_index(durations: Array, loop: bool, ticks: int) -> int`; `static func animation_for(state, velocity_y) -> String` (moves come in M5/M6).
- Draws the frame at (−24, −48), mirrored by facing; P2's three shirt shades swapped to blue at load; hit flash and the F1 / `--hitboxes` debug view (hurtbox now; hitboxes in M5).
- [x] Tests (`test_fighter_visuals.gd`): `frame_index` for idle (8,8,8,8 looping: tick 1 → 0, 8 → 0, 9 → 1, 33 → 0) and jump (4, 4 non-looping: tick 100 → 1); `animation_for` for IDLE, RUN, CROUCH, AIR rising/falling; the P2 texture has no P1 shirt color and has `#3b5dc9`.
- [x] Run: fail. Implement. Run: pass. Headless run clean. Mark the plan done; commit.

## Notes from execution

- `test_sprites.gd` was written after generating the strips: it checks the generated files' format
  against the art guide rather than driving the generator.
- Raised front arms are drawn behind the head in the generator, so they never cover the face.
