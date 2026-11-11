# M6h — Michael's Big Hand Implementation Plan

> **For agentic workers:** executed inline (superpowers:executing-plans); no subagents. Steps use checkbox (`- [ ]`) syntax.

**Goal:** Michael Bech's neutral special summons a big hand in front of him that hovers for a
second (hurting a little on touch), then slams to the floor and launches people up (asked for by
the user; Michael is free while it hovers, it stays at a fixed spot, the hover hits too).

**Architecture:** `MoveData.hand` (a `HandData`) turns a neutral special into a summon (no
charge): `Fighter._pick_special` starts `neutral_special` directly (nothing while `has_hand`),
`Fighter.wants_hand()` on its startup frame. The Match owns `Hand` nodes like projectiles:
advances them (hover → slam → impact), spawns new ones, collects their hits (per-phase victim
lists), removes them on finish/KO/reset, emits `hand_landed`. `Stage.floor_below()` finds the
landing y. Michael (`slot_05`) gets `fighter/moves/michael/` via `CharacterData.moveset`. The
generator draws `hand.png` and Michael's own summon pose.

**Spec:** [moves](../specs/moves.md#michael-bech--big-hand), [architecture](../specs/architecture.md#tick-order),
[match and stage](../specs/match-and-stage.md), [art guide](../specs/art-guide.md#michaels-hand),
[sound](../specs/sound.md)

## Review Focus

1. Hover → slam → launches up → `test_slam_launches_straight_up`.
2. One hand at a time, Michael free meanwhile → `test_one_hand_at_a_time`, `test_michael_is_free_while_the_hand_hovers`.
3. Lands on the floor below / falls off → `test_hand_lands_on_the_floor_below`, `test_hand_without_floor_falls_away`.

---

- [x] **Task 1:** spec — moves, architecture, match-and-stage, art guide, sound.
- [x] **Task 2:** tests — `test_michael_hand.gd`.
- [x] **Task 3:** data + code — `HandData`, `MoveData.hand`, Fighter, `Hand`, Match, Stage, sounds.
- [x] **Task 4:** art — hand picture + summon pose; regenerate `slot_05`; `--import`; visuals. All tests pass (348).
- [x] **Task 5:** playtest round 1 → the hand goes through pass-through platforms (lands only on the
  main platform); redrawn as a white glove (56×44, fanned fingers, knuckle creases, thumb).
- [ ] **Task 6:** user playtest.
