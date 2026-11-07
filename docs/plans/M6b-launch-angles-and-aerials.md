# M6b — Launch Angles and Aerials Implementation Plan

> **For agentic workers:** executed inline (superpowers:executing-plans); no subagents. Steps use checkbox (`- [ ]`) syntax.

**Goal:** From the first M3–M6 playtest. Every move launches along its own clear angle (Up B and
Down B launch up, jab slightly up, down tilt pops up for combos), the J attacks get separate air
versions, and the Down B dive spikes.

**Architecture:** `MoveData.angle_deg` may be negative (downward). `MoveSet` gains five aerials
(`neutral_air`, `forward_air`, `back_air`, `up_air`, `down_air`) and `down_special_dive`, the
dive's hitbox (active for the whole dive). `Fighter._pick_normal` picks an aerial in `AIR`. In
`take_hit`, a downward launch on a victim standing on the ground bounces upward. Sprites: five new
strips from the generator.

**Spec:** [moves](../specs/moves.md), [fighter](../specs/fighter.md), [art guide](../specs/art-guide.md#animations)

## Global Constraints

As before. Move numbers live in `fighter/moves/default/*.tres`.

## Review Focus

1. In the air, holding away from the facing picks back air, and the fighter doesn't turn →
   `test_air_direction_picks_the_aerial`.
2. A spike on a grounded victim bounces up → `test_downward_launch_on_the_ground_bounces_up`.
3. The dive hits on every dive tick, once per victim → `test_dive_spikes_in_the_match`.

---

- [x] **Task 0:** crouch + jump on a pass-through platform drops through (spec, tests, code).
  Commit.
- [x] **Task 1:** spec — angles per move, aerials, dive hitbox, ground bounce; art guide strips.
- [x] **Task 2:** tests — move table (aerials, dive, new angles), aerial picking, bounce, dive spike
  in the match, sprite strips.
- [x] **Task 3:** data and code — `MoveSet`, `.tres` files, `_pick_normal`, `NORMALS`, dive hitbox,
  bounce. Tests pass.
- [x] **Task 4:** sprites — five aerial strips in `tools/gen_placeholder_sprites.py`, regenerate,
  `FighterVisuals.ANIMATIONS`, `--import`. Tests pass. Commit.
- [ ] **Task 5:** user playtest.
