# M6n — Stig's Cross Smash Implementation Plan

> **For agentic workers:** executed inline (superpowers:executing-plans); no subagents. Steps use checkbox (`- [ ]`) syntax.

**Goal:** Stig's down special (asked for by the user): he kneels and smashes the cross into the
floor, and a burst of light shoots out in front of him, launching opponents nearly sideways.

**User choices:** down + special (replaces his default ground burst); a near-horizontal launch
(round 2; round 1 dazed opponents in place, see below); in the air he drops first (no hitbox on
the way) and smashes on landing.

**Architecture:** `fighter/moves/stig/down_special.tres` (frames 10/6/12 like the default, so the
shared animation timing fits; hitbox (36, −10) 56×20 in front, 9 %, base 180, growth 1.4, 10°,
FACING) and `down_special_dive.tres` (no active frames). Art: kneeling smash poses
(`CROSS_SMASH_ANIMATIONS`, look flag `cross_smash`; pose keys `both_hands` (back fist on the
weapon, `reach_to()`), `grip` (hold the weapon further up/down), `plant` (foot on the floor),
`into_floor`) and `burst.png` (4 drawings, 80×28), drawn by `FighterVisuals._draw_burst()` from
the first active frame (`burst_frame()`, 3 ticks per drawing, 7 px ahead of the feet).

**Spec:** [moves](../specs/characters/stig.md#down-special--cross-smash),
[fighter](../specs/fighter.md#states), [art guide](../specs/art-guide.md#weapons)

## Review Focus

1. The hit: in front only, launched at 10°, blocked by a shield → `tests/test_stig_smash.gd`.
2. The air version drops without a hitbox, then smashes → `test_in_the_air_he_drops_then_smashes_on_landing`.
3. Nobody else's down special changes (only Stig's move set points at the new files).

---

- [x] **Task 1:** spec — moves (Stig's down special), art guide.
- [x] **Task 2:** tests — `tests/test_stig_smash.gd`; `test_stig.gd` (his own down special; the
  cross may touch the floor in the smash).
- [x] **Task 3:** code — `FighterVisuals` (the burst).
- [x] **Task 4:** data + art — Stig's move files; generator poses + `burst.png`; viewer shows it.
  All 434 tests pass.
- [ ] **Task 5:** user playtest (numbers to feel out: knockback 180 / 1.4 at 10°, 12 frames of end lag, reach 64).

*Round 1 (replaced):* he swung the cross down over his head onto the floor; the user wanted it
like Gandalf's staff: both hands round the upright cross, pushed straight down into the ground.

*Round 2:* the user preferred a near-horizontal knockback to the daze (60 ticks dazed in place).
The `DAZED` state and `MoveData.daze_frames` were removed again (no other move used them).
