# M6j — Fidusen's Specials Implementation Plan

> **For agentic workers:** executed inline (superpowers:executing-plans); no subagents. Steps use checkbox (`- [ ]`) syntax.

**Goal:** Fidusen's down special drops banana peels that trip enemies, his side special throws a
book in an arc, and his up special is a vine: pulled to a nearby ledge, or a swing forward
(asked for by the user: up to 3 peels, slip & lie down, arcing book, let go then helpless).

**Architecture:** new `PeelData` / `VineData` resources hung on `MoveData.peel` / `.vine`;
`MoveData.projectile_angle_deg` / `projectile_gravity` for the book. Fighter: new state `TRIPPED`
(`trip()`), down special without a dive when it places a peel, `wants_peel()`, up special phases
`vine_pull` / `vine_swing` (`wants_vine()`, `start_vine_pull()`, `start_vine_swing()`,
`vine_anchor`). Match: `Peel` nodes (spawn, fall, expire, max 3 per owner, trip check before hits),
vine choice after ledge grabs, books land on floors. `Stage.floor_below(point, platforms)`.
Visuals: tripped rotation, vine line, peel and book pictures, Fidusen's own poses.

**Spec:** [moves](../specs/moves.md#fidusen--banana-book-vine), [fighter](../specs/fighter.md#states),
[match and stage](../specs/match-and-stage.md), [art guide](../specs/art-guide.md#fidusens-peel-and-book)

## Review Focus

1. Peels trip grounded enemies only, max 3 → `test_walking_onto_a_peel_trips`, `test_at_most_three_peels`.
2. Book arcs and lands → `test_book_arcs_and_lands`.
3. Vine pulls to a nearby ledge, else swings and flings → `test_vine_pulls_to_a_nearby_ledge`, `test_vine_swings_forward_and_flings`.

---

- [x] **Task 1:** spec — moves, fighter, match-and-stage, art guide.
- [x] **Task 2:** tests — `test_fidusen.gd`.
- [x] **Task 3:** data + code — resources, Fighter, Peel, Match, Stage, visuals.
- [x] **Task 4:** art — peel, book, poses; regenerate `slot_13`; `--import`; sprite viewer.
- [ ] **Task 5:** user playtest.
