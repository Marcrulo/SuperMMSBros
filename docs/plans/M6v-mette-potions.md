# M6v — Mette's Potions Implementation Plan

**Goal:** Mette's Down+B switches her potion colour (red → blue → green); her Side+B throws a flask
of that colour that leaves a puddle (acid / ice / glue); a second colour onto a puddle sets off a
reaction (steam / explosion / foam pillar). Puddles and reactions affect everyone, her too.

**Architecture:** `PotionData` (AbilityData on `down_special` and `side_special`, one resource) +
`PotionAbility` (the colour, the switch, the throw, the HUD badge, the flask in her hand) +
`Flask`, `Puddle`, `Reaction` (MatchEntity) + `PotionBadge`. One small shared change: the
fighter's **ground modifiers** (`ground_grip`, `ground_speed`, `ground_jump`, docs/specs/fighter.md),
set by puddles. The foam pillar's top is a one-way `StaticBody2D` on the pass-through platform
layer, owned by its `Reaction`.

**Spec:** [mette](../specs/characters/mette.md), [fighter: ground modifiers](../specs/fighter.md#ground-modifiers)

- [x] **Task 1:** specs.
- [x] **Task 2:** tests — `tests/test_mette.gd`, ground modifiers in `tests/test_fighter_ground_modifiers.gd`.
- [x] **Task 3:** shared: ground modifiers in `fighter/fighter.gd` (`shared:` commit).
- [x] **Task 4:** Mette's code + data; game-drawn look (flask, puddles, reactions, badge).
- [ ] **Task 5:** full suite (639 pass); sprite viewer previews (real game frames); user playtest.
