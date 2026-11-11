# M6i — Michael's Football Implementation Plan

> **For agentic workers:** executed inline (superpowers:executing-plans); no subagents. Steps use checkbox (`- [ ]`) syntax.

**Goal:** Michael's side special kicks a football toward his facing side: aimed at the nearest
enemy within a ±45° cone and 200 px, else at a random angle in ±45° (asked for by the user;
straight flight, cone + distance aiming, gone on hit).

**Architecture:** `MoveData.aim_cone_deg` / `aim_range` (0 = straight, as before). `Projectile`
gets a flight angle (`angle_deg`; velocity from it) and an optional per-character picture
(`assets/fighters/<id>/projectile.png`, drawn at ¾). `Projectile.aim_angle()` (static, pure)
picks the target angle or NAN; the Match picks a random angle from its new seeded RNG
(`Match.rng`, seeded at start and in `reset(seed)`, `--seed=N`) when there's none. Michael's
`side_special.tres` + generator: ball picture and his kick pose.

**Spec:** [moves](../specs/moves.md#michael-bech--football), [art guide](../specs/art-guide.md#michaels-football),
[match and stage](../specs/match-and-stage.md#reset)

## Review Focus

1. Aims at the nearest visible enemy → `test_aim_angle_*`, `test_ball_flies_at_the_enemy`.
2. Random within ±45° and repeatable by seed → `test_random_kick_is_seeded`.
3. Others' projectile still flies straight → existing `test_projectiles.gd`.

---

- [x] **Task 1:** spec — moves, art guide, match-and-stage, architecture.
- [x] **Task 2:** tests — `test_michael_football.gd`.
- [x] **Task 3:** data + code — MoveData, Projectile, Match RNG + spawn, Michael's side special.
- [x] **Task 4:** art — ball picture + kick pose; regenerate `slot_05`; `--import`. All tests pass (358). Note: the seed
  is not printed yet (the rest of the RNG/seed work is M7).
- [ ] **Task 5:** user playtest.
