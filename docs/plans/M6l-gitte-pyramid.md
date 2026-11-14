# M6l — Gitte's Pyramid Implementation Plan

> **For agentic workers:** executed inline (superpowers:executing-plans); no subagents. Steps use checkbox (`- [ ]`) syntax.

**Goal:** Gitte's up special raises a stepped sandstone pyramid out of the ground under her; it
lifts her up, its tip hits upward, then it sinks back. Only from ground close below her (64 px);
otherwise a weak hop (the user's choices: ground only, tip hits upward, gone right away).

**Architecture:** `MoveData.pyramid` → `PyramidData`. On the up special's last startup frame the
Match (`_start_pyramids`, after `_start_vines`) picks pyramid or hop with `Stage.floor_below`;
pyramid → `Fighter.start_pyramid(floor_y)` (new phase `pyramid_rise`, open-ended, moved with
physics toward the tip; hitbox `tip_hit` placed at the tip) and a `Pyramid` node in a new
`Pyramids` container (between Stage and Fighters, so drawn behind them). `Pyramid.advance(rising)`
rises with its owner's ride and sinks once it ends. Visuals: Gitte's own up special poses;
`pyramid.png` drawn clipped at the floor line.

**Spec:** [moves](../specs/characters/gitte.md#gitte--scissors-and-stances),
[art guide](../specs/characters/gitte.md#gittes-pyramid), [architecture](../specs/architecture.md#tick-order),
[sound](../specs/sound.md), [fighter](../specs/fighter.md#visuals-fightervisuals)

## Review Focus

1. Pyramid vs hop choice → `test_pyramid_from_the_ground`, `test_waits_in_the_air_for_the_tip`,
   `test_too_high_means_a_hop`, `test_off_stage_means_a_hop`, `test_rises_from_a_platform`.
2. The rise and the pop → `test_pyramid_lifts_her_and_pops_her_off`.
3. The tip hit → `test_tip_hits_upward`, `test_multiply_boosts_the_tip`.
4. Sinking → `test_pyramid_sinks_after_the_pop`, `test_a_hit_ends_the_ride`.

---

- [x] **Task 1:** spec — moves, art guide, architecture, sound, fighter visuals.
- [x] **Task 2:** tests — `test_gitte_pyramid.gd` (+ sound, visuals, data tests).
- [x] **Task 3:** data + code — PyramidData, MoveData.pyramid, Fighter phase, Pyramid node, Match.
- [x] **Task 4:** art — pyramid picture, her up special poses; regenerate `slot_02`; `--import`; viewer.
- [ ] **Task 5:** user playtest.
