# M6w — Kim's Burning Implementation Plan

**Goal:** Kim's torch (side special) sets its victims burning: once the flame stops hitting them,
they take 1 % every 30 ticks for 180 ticks (3 s). Doesn't stack (a new burn restarts the 3 s).

**Architecture:** `TorchAbility` notes who the flame lands on (`end_step`) and lights a `Burn`
(MatchEntity, `characters/kim/burn.gd`) in `spawn_entities` once the flame has stopped hitting
them. `Burn.ignite()` refreshes an existing burn on that fighter instead of adding one. Numbers on
`TorchData`. No shared files.

**Spec:** [kim](../specs/characters/kim.md#kim--handyman)

- [x] **Task 1:** spec.
- [x] **Task 2:** tests — `tests/test_kim.gd` (burning section).
- [x] **Task 3:** code + data.
- [ ] **Task 4:** full suite; user playtest.
