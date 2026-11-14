# M6p — Mads's Over-the-Head Slam Implementation Plan

> **For agentic workers:** executed inline (superpowers:executing-plans); no subagents. Steps use checkbox (`- [ ]`) syntax.

**Goal:** Mads is a grappler; his first command grab (asked for by the user): side special
reaches for the opponent and swings them over his head to the other side, slamming them into
the ground; they bounce up and fly.

**User choices:** command grab style (most of his moves), the slam bounce. Claude's calls (user:
"sounds about right"): grabs go through shields, slow with long end lag on a miss, short reach,
neither fighter hittable during the throw, 12 %, ground only (unanswered; Claude's call), Mads
ends facing the victim.

**Architecture:** new fighter state `HELD` (+ `Fighter.held_by`); `GrabData` resource on
`MoveData.grab`; `Fighter.start_throw()` / `become_held()` / phase `grab_throw`; `Match._resolve_grabs()`
(before `_resolve_hits`, which skips grab boxes) and `Match._advance_throws()` (places the victim
on the arc, slams on `slam_frame`). Visuals: the victim's hurt drawing rotated along the arc; Mads's
own `side_special` drawings picked per phase (`FighterVisuals.grab_frame`).

**Spec:** [moves](../specs/moves.md#mads--grappler), [fighter](../specs/fighter.md#states),
[art guide](../specs/art-guide.md#weapons)

## Review Focus

1. A shield doesn't stop the grab; nothing else about shields changes.
2. The victim ends up behind Mads, launched up and away; Mads turns round.
3. A miss, the air, and other characters' side specials are unchanged.

---

- [x] **Task 1:** spec — moves (Mads), fighter (HELD), art guide.
- [x] **Task 2:** tests — `tests/test_mads_grab.gd`.
- [x] **Task 3:** code — `GrabData`, `MoveData.grab`, `Fighter` (HELD, throw), `Match`, `FighterVisuals`.
- [x] **Task 4:** data + art — `fighter/moves/mads/`, `slot_11.tres`; generator poses; viewer. All 461 tests pass.
- [x] **Round 2 (user):** works in the air (hangs while throwing); the victim stays in his hands
  (`path` fitted to his fists); his own 6-drawing throw strip, turning round on frame 15.
- [ ] **Task 5:** user playtest (numbers to feel out: reach, 24 frames of end lag on a miss, 12 % / 220 / 1.3 at 60°).
