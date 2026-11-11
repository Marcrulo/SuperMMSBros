# M6g — Henrik's Guitar Implementation Plan

> **For agentic workers:** executed inline (superpowers:executing-plans); no subagents. Steps use checkbox (`- [ ]`) syntax.

**Goal:** The first character-specific moves (asked for by the user): Henrik carries a guitar on
his back and swings it in his jab (light), side tilt (light, long reach) and neutral special
(charged overhead swing).

**Architecture:** `CharacterData.moveset` (optional) replaces the move set from the shared
`FighterStats`; `CharacterData.fighter_stats()` returns the stats with it applied, and the Match
uses that. Henrik's moves are in `fighter/moves/henrik/` (same frame counts as the defaults, so
the shared animation timing fits). The acoustic guitar is drawn into Henrik's strips by the 64 px
generator (user's choice, round 2: "changing the sprite to include a guitar"); his frames are a
112×80 canvas (user picked the bigger canvas over keeping 64×64) so the swing fits.
`FighterVisuals` draws any frame size (width = strip width / drawings) at ¾, feet at the origin;
`PlayerCard.head_region_of()` finds the head in a bigger canvas; `CharacterData.charge_glow` puts
the charge glow on the guitar. Hitboxes are fitted to the drawn guitar.

*Round 1 (replaced):* the guitar was a separate picture placed per drawing from a generated
`weapon.json`; the user preferred it in the sprite.

**Spec:** [moves](../specs/moves.md#character-move-sets), [menus](../specs/menus.md#characters-and-the-roster),
[art guide](../specs/art-guide.md#weapons), [fighter](../specs/fighter.md#visuals-fightervisuals)

## Review Focus

1. Henrik plays with his moves, nobody else does → `test_henrik_has_his_own_moves`,
   `test_match_gives_henrik_his_move_set`.
2. Side tilt reaches further than the jab → `test_henrik_side_tilt_reaches_further_than_jab`.
3. Hitboxes match the drawn guitar → `test_hitbox_reaches_where_the_guitar_is_drawn`.

---

- [x] **Task 1:** spec — moves (character move sets, Henrik), menus (`CharacterData.moveset`),
  art guide (weapons), fighter visuals.
- [x] **Task 2:** tests — Henrik's move data, `fighter_stats()`, the Match's stats, canvas size,
  hitboxes vs the drawing, charge glow; existing sprite/HUD tests for non-square frames.
- [x] **Task 3:** data — `fighter/moves/henrik/`, `CharacterData.moveset` + `charge_glow`,
  `slot_06.tres`.
- [x] **Task 4:** art — generator: acoustic guitar drawn into the frames, `canvas`, Henrik's guitar
  poses (`GUITAR_ANIMATIONS`, `held(angle, front, choke)`); regenerate `slot_06`; `--import`.
- [x] **Task 5:** code — `CharacterData.fighter_stats()`, Match, `FighterVisuals` frame sizes and
  charge glow, `PlayerCard.head_region_of()`. All tests pass.
- [ ] **Task 6:** user playtest.
