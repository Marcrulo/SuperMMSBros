# M6 — Shield and Specials Implementation Plan

> **For agentic workers:** executed inline (superpowers:executing-plans); no subagents. Steps use checkbox (`- [ ]`) syntax.

**Goal:** Shield, break a shield, and use all four specials, including the projectile and the up
special recovery.

**Architecture:** `MoveData` gains the specials' extra numbers (charge, launch, dive, projectile).
The fighter gains `SHIELD`, `SHIELD_DROP`, `SHIELD_BREAK` and `HELPLESS`, shield health, and the
special phases as move ids: `neutral_special_charge` → `neutral_special` (a charged copy of its
data), `down_special_dive` → `down_special`, `side_special` (asks for a projectile on its startup's
last frame), `up_special` (launch on frame 5, then `HELPLESS`). The Match owns projectiles: it
spawns them after the fighters tick, advances them, and resolves their hits with the moves'.
Shielding victims block instead of taking the hit.

**Spec:** [moves](../specs/moves.md#specials-k), [fighter](../specs/fighter.md#shield), [architecture](../specs/architecture.md#tick-order)

## Global Constraints

As before. Special numbers live in `fighter/moves/default/*.tres`; shield numbers in `default_stats.tres`.

## Review Focus

1. Up special can be used only once per stay in the air → `test_up_special_once_per_air_time`.
2. A second side special while the projectile is out does nothing → `test_one_projectile_at_a_time`.
3. Block stun forbids dropping or jumping out of shield → `test_block_stun_holds_the_shield`.
4. The down special dive turns into the burst on landing, not a normal landing → `test_air_down_special_dives_then_bursts`.
5. Getting hit while charging loses the charge → `test_hit_while_charging_loses_the_charge`.

---

### Task 1: Data

- `MoveData` "Special" group: `charge_frames`, `charge_damage`, `charge_knockback` (neutral); `launch_speed`, `drift_speed` (up); `dive_speed` (down); `projectile_speed`, `projectile_lifetime` (side; the projectile uses the move's hitbox size, damage and knockback, and spawns at `hitbox_center` on frame `startup`).
- `MoveSet` adds `neutral_special`, `down_special`, `side_special`, `up_special` with the spec's numbers. `FighterStats` adds the shield stats and `helpless_air_speed`.
- [x] Tests (`test_moves.gd`): specials' numbers; shield stats. Fail → implement → pass → commit.

### Task 2: Shield

- [x] Tests (`test_fighter_shield.gd`): hold shield → `SHIELD`, slides to a stop; drains per tick; regrows when not shielding (capped); release → `SHIELD_DROP` for 7 ticks → `IDLE`; jump out of shield; `block_hit` costs damage × 1.5, pushes away, no damage %; `test_block_stun_holds_the_shield`; health 0 → `SHIELD_BREAK` for 120 ticks → `IDLE` with 30 health; no shield in the air; attack/special/jump win over shield on the same tick.
- [x] Fail → implement → pass → commit.

### Task 3: Specials

- [x] Tests (`test_fighter_specials.gd`): direction picks the special; neutral: charge counts while held, release punches with charge-scaled damage/knockback, auto-releases at 60, `test_hit_while_charging_loses_the_charge`; down: ground burst active on 11–16, AWAY; `test_air_down_special_dives_then_bursts`; side: asks for a projectile on frame 10 only, turns on the ground, `has_projectile` blocks a new one; up: launch on frame 5 with (move_x × 80, −360), hitbox 5–16, then `HELPLESS` when falling, helpless can't act and steers slowly, lands → `IDLE`, `test_up_special_once_per_air_time`, restored by landing and by a hit.
- [x] Fail → implement → pass → commit.

### Task 4: Projectiles in the Match

- `Projectile` (`Node2D`, `match/projectile.gd`): `owner_index`, `direction`, `age`, `data`; `advance()`; `get_hitbox_rect()`; draws its strip.
- [x] Tests (`test_projectiles.gd`): side special spawns one projectile at (16, −13) from the feet in the facing direction; it moves 4 px per tick; hits the other fighter (damage %, knockback in its direction) and disappears; never hits its owner; disappears after 120 ticks or outside the blast zone; a shield blocks it (shield health drops, projectile gone); `test_one_projectile_at_a_time`; a fighter shielding a melee hit blocks it in the Match.
- [x] Fail → implement → pass → commit.

### Task 5: Visuals

- `animation_for` covers `SHIELD`/`SHIELD_DROP` → `shield`, `SHIELD_BREAK` → `dizzy`, `HELPLESS` → `helpless`, the special move ids. Shield bubble (radius 6–16 px with health), charge glow on the fists, the projectile sprite.
- [x] Tests (`test_fighter_visuals.gd`): `animation_for` for the new states and specials; the strike drawing matches each special's active frames (neutral: drawing 1, down: drawing 2, up: drawing 1).
- [x] Fail → implement → pass → headless runs clean → mark done → commit.

## Notes from execution

- Tasks 2 and 3 were tested and built together (one rewrite of `fighter.gd`).
- Tick order: existing projectiles move first, then new ones are added, so a projectile first moves
  the tick after it appears (spec updated in `architecture.md`).
- Two test fixtures were fixed: the projectile left the blast zone before its lifetime ran out, and
  a shield-health check would have passed on drain alone.
