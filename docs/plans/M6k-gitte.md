# M6k — Gitte's Scissors and Stances Implementation Plan

> **For agentic workers:** executed inline (superpowers:executing-plans); no subagents. Steps use checkbox (`- [ ]`) syntax.

**Goal:** Gitte carries big scissors on her back, cuts with them in a charged neutral special,
throws a fan of 3 small scissors with side special, and switches stances (+ − ÷ ×) with down
special, each changing her stats; the stance shows on her player card (asked for by the user;
fan spread, moderate numbers, cycle with a short pose resetting on KO, everything scales).

**Architecture:** `StanceData` on her down special's `MoveData.stances`; `Fighter.stance`
(reset in `spawn_at`), `size_scale()` / speed multiplier used by movement, hurtbox, hitbox, body
shape and ledge numbers; `Fighter.boosted(data, special)` applies `×`'s special boost; the Match
applies `+` to projectiles at spawn, `−`'s lifesteal on normal-attack hits, spawns
`projectile_count` projectiles in a fan, and removes all of a KO'd fighter's projectiles.
Visuals draw at the size scale; `PlayerCard` gets a `StanceBadge`. Generator: scissors weapon
(with an opening angle), weapon-specific back placement, Gitte's poses, volley picture.

**Spec:** [moves](../specs/characters/gitte.md#gitte--scissors-and-stances), [HUD](../specs/match-and-stage.md#hud),
[art guide](../specs/art-guide.md#weapons), [fighter](../specs/fighter.md#visuals-fightervisuals)

## Review Focus

1. Stance cycle + reset → `test_down_special_cycles_the_stances`, `test_stance_resets_on_spawn`.
2. Each stance's effect → `test_plus_*`, `test_minus_*`, `test_divide_*`, `test_multiply_*`.
3. Volley fan → `test_volley_throws_three_in_a_fan`.

---

- [x] **Task 1:** spec — moves, HUD, art guide, fighter visuals.
- [x] **Task 2:** tests — `test_gitte.gd`.
- [x] **Task 3:** data + code — StanceData, MoveData, Fighter, Match, visuals, PlayerCard badge.
- [x] **Task 4:** art — scissors, poses, volley picture; regenerate `slot_02`; `--import`; viewer.
- [ ] **Task 5:** user playtest.
