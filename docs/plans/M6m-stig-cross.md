# M6m — Stig's Cross Implementation Plan

> **For agentic workers:** executed inline (superpowers:executing-plans); no subagents. Steps use checkbox (`- [ ]`) syntax.

**Goal:** Stig (slot_07) carries a big gold cross, used as a sword, mounted on his back, and swings it in the same moves as Henrik's guitar (user's request: "identical to Henrik in
that regard").

**Architecture:** a new weapon `cross` in the 64 px generator (`cross()`), drawn into
Stig's 112×80 strips. It reuses Henrik's swing poses (`GUITAR_ANIMATIONS`) and has its own back
placement; a weapon flag `choke=False` keeps the hand on the hilt where Henrik chokes up on the
neck. `fighter/moves/stig/` copies Henrik's three moves (same frames, damage, knockback, charge)
with hitboxes fitted to the drawn cross; `slot_07.tres` gets the move set and `charge_glow`.

**Spec:** [moves](../specs/moves.md#stig--cross), [art guide](../specs/art-guide.md#weapons)

## Review Focus

1. Same moves and numbers as Henrik, own hitboxes → `test_stig_moves_match_henriks_but_the_hitboxes`.
2. Hitboxes match the drawn cross → `test_hitbox_reaches_where_the_cross_is_drawn`.
3. All gold, no blade → `test_the_cross_is_all_gold`; on his back clear of his feet → `test_cross_on_the_back_stays_clear_of_the_feet`.

---

- [x] **Task 1:** spec — moves (Stig — cross), art guide (weapons).
- [x] **Task 2:** tests — `tests/test_stig.gd`; `test_sprites.gd` canvas list.
- [x] **Task 3:** art — generator `cross()`, `WEAPONS["cross"]` (back placement,
  `choke=False`); look `weapon="cross", canvas=(112, 80)`; regenerate slot_07; Henrik's and
  Gitte's strips unchanged (checked pixel for pixel); `--import`.
- [x] **Task 4:** data — `fighter/moves/stig/`, `slot_07.tres`. All 423 tests pass.
- [ ] **Task 5:** user playtest.

*Round 1 (replaced):* a sword with a gold cross-shaped hilt and a steel blade; the user wanted it
to be clearly a cross (all gold), used as a sword.

*Round 2:* the cross stood upright on his back; the user wanted it diagonal like Gitte's scissors,
the cross head visible on the left and the foot poking out on the right. A 45° tilt read as an X,
so it first lay flatter (106°), with a shorter top arm; the user wanted it like Gitte's after
all, so it now has her placement and slant (126°: cross head behind the neck, foot past the hip),
with 6 px of beam below the hand so the foot still pokes out.
