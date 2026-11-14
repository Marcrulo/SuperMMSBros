# M6o — Trine's iPad Break Implementation Plan

> **For agentic workers:** executed inline (superpowers:executing-plans); no subagents. Steps use checkbox (`- [ ]`) syntax.

**Goal:** Trine's down special (asked for by the user): she sits down and watches her iPad, which
heals her slowly.

**User choices:** down + special replaces her default ground burst; holding down keeps her
watching; a hit cancels it. Claude's calls (user said "try that"): ground only (nothing in the
air), 1 % every 10 ticks, at most 300 ticks (30 %), no acting while sitting, 10 frames to sit and
12 to get up, a green "+" floating up per heal.

**Architecture:** `IpadData` resource (`watch_frames`, `heal_every`, `heal`) on
`MoveData.ipad`. `Fighter` phases: `down_special` (sitting down) → `ipad_watch` (open-ended,
heals, ends when down is released or at `watch_frames`) → `ipad_stand` (the move's recovery
frames) → free. `FighterVisuals` picks the strip's drawing per phase and draws the "+".
Art: new seated poses in `tools/gen_fighter_sprites64.py` behind a look flag `ipad`.

**Spec:** [moves](../specs/moves.md#trine--ipad-break), [art guide](../specs/art-guide.md#weapons)

## Review Focus

1. Healing rate and cap, never below 0 → `tests/test_trine_ipad.gd`.
2. Releasing down / a hit ends it; nothing happens in the air.
3. Nobody else's down special changes.

---

- [x] **Task 1:** spec — moves (Trine's down special), art guide.
- [x] **Task 2:** tests — `tests/test_trine_ipad.gd`.
- [x] **Task 3:** code — `IpadData`, `MoveData.ipad`, `Fighter` phases, `FighterVisuals`.
- [x] **Task 4:** data + art — `fighter/moves/trine/`, `slot_03.tres`; generator poses; sprite
  viewer artifact rebuilt. All 448 tests pass.
- [ ] **Task 5:** user playtest (look approved: iPad on a stand, coffee sips every second) (numbers to feel out: 6 %/s, 5 s cap, 12 frames to get up).
