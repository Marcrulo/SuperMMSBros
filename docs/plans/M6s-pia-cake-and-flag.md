# M6s — Pia's Cake and German Flag Implementation Plan

> **For agentic workers:** executed inline (superpowers:executing-plans); no subagents. Steps use checkbox (`- [ ]`) syntax.

**Goal:** Pia's Down+B eats cake and heals; Side+B throws a German flag; the belly flop moves to
plain B.

**User choices:** belly flop → neutral special (her charged punch goes); cake = one slice, a
fixed heal, short cooldown; flag = a javelin-like straight throw.
**My calls:** cake 45/0/15 frames, heals 8 % on frame 45, ground only, cooldown 300 ticks from
the heal; flag 260 px/s, 20×8, 6 %, base 100, growth 0.6, 30°.

**Architecture:** belly flop phases renamed `belly_hop` → `belly_dive` → `belly_flop`, driven by
`neutral_special.dive_hit` (the dive's hit), `hop_speed`, `dive_speed`; `belly_flop` uses the
neutral special's data. Cake: `MoveData.heal`, `heal_frame`, `cooldown_frames`;
`Fighter.cake_cooldown`. Flag: Pia's `side_special.tres` + `projectile.png`. Visuals: optional
strip `fighter_belly_flop.png` (only loaded if present), `cake_frame()`, a heal "+" after the
bite. Generator: look flags `belly_flop` (flop poses now in the `belly_flop` strip), `cake`,
`flag`.

**Spec:** [moves](../specs/moves.md#pia--belly-flop-cake-flag),
[art guide](../specs/characters/pia.md#pias-specials), [fighter](../specs/fighter.md)

---

- [x] **Task 1:** spec — moves, art guide, fighter visuals.
- [x] **Task 2:** tests — `tests/test_pia.gd` (rewritten), sprite/visual tests.
- [x] **Task 3:** code — MoveData fields, Fighter phases + cooldown, visuals, sounds.
- [x] **Task 4:** data + art — Pia's move files; generator; viewer. All 536 tests pass (tests that assumed P1 has the default moves now pick Nina, slot_04).
- [ ] **Task 5:** user playtest.

*Round 2 (2026-11-14):* the user swapped them: cake on B (phase `cake`, her `neutral_special`
strip, 4 drawings), belly flop on Down+B (her `down_special` strip; the separate
`fighter_belly_flop.png` strip removed). The flag is just the cloth (no pole), hitbox 12×8. The
code finds the cake / belly flop on whichever special slot holds it (`Fighter.cake_data()`,
`flop_data()`).
