# M6u — Nina's Letter Volley Implementation Plan

**Goal:** Nina's Side+B shoots the letters of EKSISTENTIALISME from her hands; her facing is locked
but she can walk/steer; usable in the air.

**Architecture:** `LetterData` (AbilityData on `side_special`) + `LetterAbility` (phase `letters`,
picks the special, walks, spawns) + `Letter` (MatchEntity, one flying letter). No shared files.
Tests that used Nina as the "default moves" fighter move to Casper (slot_08).

**Spec:** [nina](../specs/characters/nina.md)

- [x] **Task 1:** spec.
- [x] **Task 2:** tests — `tests/test_nina.gd`.
- [x] **Task 3:** code + data.
- [ ] **Task 4:** full suite (568 pass); user playtest.

*Round 2:* she can jump during the volley (it goes on) and cancel it with shield or a dodge (`LetterAbility.before_tick`).
