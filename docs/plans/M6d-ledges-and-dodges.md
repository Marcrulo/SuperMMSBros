# M6d — Ledges and Dodges Implementation Plan

> **For agentic workers:** executed inline (superpowers:executing-plans); no subagents. Steps use checkbox (`- [ ]`) syntax.

**Goal:** Two new mechanics, asked for by the user: grabbing the main platform's ledges (hang,
get up, ledge jump, let go) and dodging (spot dodge and roll out of shield, air dodge).

**Architecture:** `Ledge` (stage/ledge.gd) values from `Stage.get_ledges()` (the main platform's
top corners). `Fighter` gains five states (`SPOT_DODGE`, `ROLL`, `AIR_DODGE`, `LEDGE`,
`LEDGE_CLIMB`), `is_intangible()` (checked by `can_be_hit()`), `can_grab_ledge(ledge)` and
`grab_ledge(ledge)`. The Match grabs ledges right after the fighters tick, skipping ledges held by
another fighter. `FighterInput` gains `shield_pressed`, `up_pressed`, `side_pressed`. Numbers in
`FighterStats` (`default_stats.tres`). Hanging and climbing set the position directly (no
`move_and_slide()` until the climb's last tick, which settles onto the floor).

**Spec:** [fighter](../specs/fighter.md#dodges), [fighter](../specs/fighter.md#ledge),
[architecture](../specs/architecture.md#tick-order), [art guide](../specs/art-guide.md#animations)

## Review Focus

1. A roll never carries the fighter off the stage → `test_roll_stops_at_the_edge`.
2. Hits pass through on intangible frames and land after → `test_spot_dodge_is_intangible_in_the_middle`.
3. Ledge intangibility only once per trip off-stage → `test_ledge_intangibility_must_be_earned_again`.
4. Two fighters can't share a ledge → `test_a_held_ledge_cannot_be_grabbed`.

---

- [x] **Task 1:** spec — dodges, ledge, input fields, tick order, art strips; roadmap row.
- [x] **Task 2:** tests — `test_fighter_dodges.gd`, `test_fighter_ledge.gd`, input map fields,
  sprite strips.
- [x] **Task 3:** code — stats, input, keyboard controller, `Ledge`, stage, fighter, match. Tests pass.
- [x] **Task 4:** sprites — five strips in `tools/gen_placeholder_sprites.py`, regenerate,
  `FighterVisuals` (animations + intangible look), `--import`. Tests pass. Commit.
- [ ] **Task 5:** user playtest.
