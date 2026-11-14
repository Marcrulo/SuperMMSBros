# M6r — Pia's Belly Flop Implementation Plan

> **For agentic workers:** executed inline (superpowers:executing-plans); no subagents. Steps use checkbox (`- [ ]`) syntax.

**Goal:** Pia's down special (asked for by the user): a ground pound done as a belly flop that
damages nearby enemies.

**User choices:** a ground pound; a belly flop; it hurts enemies near her on landing.
**My calls (to check in playtest):** on the ground she hops first (240 px/s, ~48 px), in the
air she flops at once; the belly spikes on the way down (7 %, −70°); the landing shockwave hits
both sides on the landing tick (80×16, 11 %, base 200, growth 1.4, 70° AWAY); 22 frames lying
flat / getting up.

**Architecture:** `MoveData.hop_speed` on her down special; new phase `belly_hop` (in
`Fighter.OPEN_ENDED`, no hitbox): velocity set in `_start_move`, normal air steering + gravity,
turns into `down_special_dive` when it stops rising; the existing dive → land → `down_special`
flow does the rest. `fighter/moves/pia/` (moveset, down_special 0/6/22, down_special_dive).
`CharacterData.moveset` on slot_01. Art: generator look flag `belly_flop` (poses posed upright,
turned 90°, set on the floor row) + `dust.png` drawn by `FighterVisuals._draw_dust()` on both
sides. Sound: the hop plays `jump`; the dive `dive`; the impact `burst` (already).

**Spec:** [moves](../specs/moves.md#pia--belly-flop),
[art guide](../specs/art-guide.md#pias-belly-flop), [fighter](../specs/fighter.md)

## Review Focus

1. The ground version hops, then dives, then flops → `tests/test_pia.gd`.
2. The flop hits both sides on the landing tick; a shield blocks it.
3. Nobody else's down special changes (only Pia's move set points at the new files).

---

- [x] **Task 1:** spec — moves (Pia's down special), art guide, fighter visuals.
- [x] **Task 2:** tests — `tests/test_pia.gd`.
- [x] **Task 3:** code — `MoveData.hop_speed`, `belly_hop` phase, visuals (jump drawings, dust), sound.
- [x] **Task 4:** data + art — Pia's move files; generator poses (body turned 90°, head put back upright) + `dust.png`; viewer shows it. All 524 tests pass (`test_match_hits` dive test now reads P1's own dive damage, since P1 = Pia).
- [ ] **Task 5:** user playtest.
