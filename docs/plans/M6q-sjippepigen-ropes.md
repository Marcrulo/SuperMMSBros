# M6q — Sjippepigen's Jump Ropes Implementation Plan

> **For agentic workers:** executed inline (superpowers:executing-plans); no subagents. Steps use checkbox (`- [ ]`) syntax.

**Goal:** Sjippepigen always has three spinning jump ropes that hurt on contact; no attacks; down
special switches the rope length (user's design).

**User choices:** ropes always present and always spinning; contact damages; no attacks except
down special, which toggles the length. Claude's calls (user: "Let's try that. Go"): only the tip
hurts, once per rope turn, small hits, shield blocks, no ropes while stunned, no up special
(no recovery), short = tight and fast (2 %), long = far and slow (3 %, can KO late), drawn by the
game as lines.

**Architecture:** `RopeData` on `MoveData.ropes` (her down special). `Fighter`: `rope_long`,
`rope_tick`, `ropes_active()`, `rope_tip(i)`, `rope_box(i)`, per-rope hit memory; no attacks when
ropes are set. `Match._resolve_hits` collects rope hits. `FighterVisuals._draw_ropes()`.

**Spec:** [moves](../specs/characters/sjippepigen.md#sjippepigen--jump-ropes)

## Review Focus

1. No attacks, only the length switch.
2. Tip hits: once per rope turn; shields block; none while she's stunned.
3. Long ropes reach where short ones don't.

---

- [x] **Task 1:** spec — moves (Sjippepigen).
- [x] **Task 2:** tests — `tests/test_sjippepigen.gd`.
- [x] **Task 3:** code — `RopeData`, `MoveData.ropes`, `Fighter`, `Match`, `FighterVisuals`.
- [x] **Task 4:** data — `fighter/moves/sjippepigen/`, `slot_12.tres`. All 482 tests pass. (The ropes are drawn by the game, so the
  sprites and the viewer don't change; checked with a Python mock-up of `_draw_ropes`.)
- [ ] **Task 5:** user playtest (numbers: radii 18/34, periods 30/48, 2 % / 3 %).
