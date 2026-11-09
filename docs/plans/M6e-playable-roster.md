# M6e — Playable Roster Implementation Plan

> **For agentic workers:** executed inline (superpowers:executing-plans); no subagents. Steps use checkbox (`- [ ]`) syntax.

**Goal:** Every character on the select screen can be played, each with its own generated sprites
(asked for by the user: "I should be able to pick any character now; the default one doesn't
exist anymore").

**Architecture:** Pia's id `default` becomes `slot_01` (`CharacterData.DEFAULT_ID`); all 14
`CharacterData` resources are `playable` with `default_stats.tres`. `tools/gen_fighter_sprites.py`
writes `assets/fighters/<id>/` per character and the shared `assets/fighters/projectile.png`; the
placeholder `assets/fighters/default/` is deleted. `Fighter.character_id` (set by the Match from
`Game.character_id` / `Game.p2_character_id`) picks the strips; `FighterVisuals.textures_for(id)`
caches them per character. The P2 shirt recolor goes away: `CharacterSelect.choose()` gives P2 a
random other playable character, so the two never match.

**Spec:** [menus](../specs/menus.md#characters-and-the-roster), [art guide](../specs/art-guide.md#export),
[fighter](../specs/fighter.md#visuals-fightervisuals)

## Review Focus

1. P2 never gets P1's character → `test_choosing_gives_p2_a_different_character`.
2. Every playable character has every strip → `test_every_character_has_every_strip`.
3. The Match hands each fighter its character → `test_match_gives_each_player_their_character`.

---

- [x] **Task 1:** spec — menus, art guide, fighter visuals, display colors, roadmap.
- [x] **Task 2:** tests — roster all playable, sprites per character, P2's pick, textures per
  character, HUD/select using the character's strips.
- [x] **Task 3:** assets — rename Pia's files to `slot_01`; generator writes per-character folders
  + shared projectile, skips `HAND_EDITED`; generate; delete `default/`; `--import`.
- [x] **Task 4:** code — `CharacterData.DEFAULT_ID`, `Game`, `Fighter.character_id`, `Match`,
  `FighterVisuals`, `PlayerCard`, `CharacterSelect`, `Projectile`. Tests pass (289).
- [x] **Task 5:** user playtest ("looks good").
