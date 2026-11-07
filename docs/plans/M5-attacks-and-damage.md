# M5 — Attacks and Damage % Implementation Plan

> **For agentic workers:** executed inline (superpowers:executing-plans); no subagents. Steps use checkbox (`- [ ]`) syntax.

**Goal:** Hit a dummy with jab and the three tilts (on the ground and in the air), see its % rise
and knock it off the stage.

**Architecture:** Moves are `MoveData` resources gathered in a `MoveSet` that `FighterStats`
points at. The fighter gains `ATTACK` (with the current move's id) and `HITSTUN`, a `percent`, and
picks a move from the held direction. The Match collects every hit of a tick (with the knockback
side worked out before anything changes), then applies them; the victim computes its own launch
from the move and its %. Built on the parked `m3-attack` work, reshaped around move data.

**Spec:** [moves](../specs/moves.md), [fighter](../specs/fighter.md), [architecture](../specs/architecture.md#tick-order)

## Global Constraints

As in M3/M4. Move numbers live only in `fighter/moves/default/*.tres`; fighter-wide numbers in
`default_stats.tres`.

## Review Focus

1. Trades: both fighters launched the right way → `test_trade_hits_both_fighters`.
2. A second hit during hitstun restarts it (same state) → `test_a_second_hit_restarts_hitstun`.
3. The tick after a move ends accepts input → `test_can_act_on_the_tick_after_the_move`.
4. Launch from standing leaves the ground at full speed → `test_launch_from_the_ground_uses_air_friction_and_gravity`.
5. Knockback grows with the victim's % *after* the hit's damage → `test_knockback_uses_percent_after_damage`.

---

### Task 1: Move data and stats

- `MoveData` (`Resource`): `startup`, `active`, `recovery` (int); `hitbox_center`, `hitbox_size` (Vector2); `damage`, `base_knockback`, `knockback_growth`, `angle_deg` (float); `direction` (`enum Direction { FACING, AWAY }`). `total_frames() -> int`.
- `MoveSet` (`Resource`): `jab`, `down_tilt`, `up_tilt`, `side_tilt` (`MoveData`; specials added in M6).
- `FighterStats`: `moveset`, `hitstun_per_knockback` 0.06, `min_hitstun` 6, `hitstun_friction` 300.
- [x] Tests (`test_moves.gd`): the four normals load with the spec table's numbers; stats values.
- [x] Fail → implement (`.tres` files in `fighter/moves/default/`) → pass → commit.

### Task 2: Attacking

- `Fighter.State` gains `ATTACK`, `HITSTUN`; `var move: StringName` (`&""` when none), `var percent: float`.
- Actions: attack pressed (from `IDLE`/`RUN`/`CROUCH`/`AIR`, before jump) picks by direction: up → `up_tilt`, down → `down_tilt`, `move_x ≠ 0` → `side_tilt` (on the ground, turns first), else `jab`.
- During `ATTACK`: on the floor slide to a stop; in the air steer and fall; an air attack that lands ends at once (`IDLE`/`RUN`/`CROUCH`); after `total_frames` it ends into whatever fits and the fighter can act that tick.
- `is_hitbox_active()`, `get_hitbox_rect()` (mirrored), `has_hit(i)`, `register_hit(i)`; hurtbox as M4.
- [x] Tests (`test_fighter_attack.gd`): each direction picks its move; side tilt on the ground turns; active frames exactly `startup+1 … startup+active` for each normal; total frames; can act on the next tick; attack wins over jump; no acting/turning during a move; ground move doesn't steer; air move steers and lands out early; hitbox rects mirror (jab facing right/left); a new move forgets who it hit.
- [x] Fail → implement → pass → commit.

### Task 3: Getting hit and damage %

- `Fighter.knockback_side(move: MoveData, victim_center: Vector2) -> int`: `FACING` → facing; `AWAY` → side of the victim's center from this fighter's center (facing when level).
- `Fighter.take_hit(move: MoveData, side: int, attacker_x: float)`: percent += damage (cap 999); speed = base + growth × percent; velocity = (cos a × speed × side, −sin a × speed); `HITSTUN` for `max(min_hitstun, round(speed × hitstun_per_knockback))` (restarts if already stunned); face the attacker; jumps restored; move lost.
- Hitstun movement: airborne (`not on floor or velocity.y < 0`) → `hitstun_friction` + gravity; else ground friction. Ends into `IDLE`/`AIR`; acts that tick.
- `spawn_at` resets `percent` to 0.
- [x] Tests (in `test_fighter_attack.gd`): `test_knockback_uses_percent_after_damage` (jab on 0 % → % 3, speed 120 + 0.8×3); angle and side; AWAY sides; hitstun ticks from speed and the minimum; facing the attacker; jumps restored; move cancelled; restart; launch from the ground; ground friction; lands and stays stunned; ends in air → `AIR`; can act when it ends; spawn resets %.
- [x] Fail → implement → pass → commit.

### Task 4: Dummy and hit resolution

- `match.tscn` gets P2; non-P1 controllers are empty `ScriptedController`s. `Match.step()`: controllers → fighters → `_resolve_hits()` (collect `[attacker, victim, move, side]` for every active hitbox overlapping another fighter's hurtbox not already hit; then `register_hit` + `take_hit`) → respawn → tick.
- [x] Tests (`test_match_hits.gd`, updated `test_match.gd`): P2 is a dummy at (312, 192) facing left; jab hits on its first active frame and not before; out of range misses; one hit per move; knockback follows the attacker's facing; hit from behind turns the victim; `test_trade_hits_both_fighters`; % accumulates over several jabs.
- [x] Fail → implement → pass → commit.

### Task 5: Visuals

- `animation_for(state, velocity_y, move)`: `ATTACK` → the move's name; `HITSTUN` → `hurt`. Hit flash (brighten on alternate pairs of hitstun ticks). Debug view adds the move hitbox (outline during the move, filled when active).
- [x] Tests (in `test_fighter_visuals.gd`): `animation_for` for ATTACK with each move and HITSTUN; each normal's animation shows its strike drawing (index 2) exactly on the move's active frames.
- [x] Fail → implement → pass → headless run with `--hitboxes` clean → mark done → commit.

## Notes from execution

- Tasks 2 and 3 were tested and built together (one test file, one rewrite of `fighter.gd`): the
  attack and hitstun code share the end-of-state and movement logic.
- A test helper named `_input` clashed again with `Node._input()`; tests use `_make_input`.
