# M6t — Split character code out of the shared files

**Goal:** working on one character touches (almost) only that character's own files, so several
character branches can be worked on at once and merged with few conflicts. No gameplay or look
changes: the 535 tests pass unchanged in behaviour, and the generated sprites stay byte-identical.

**Why:** every character feature so far (M6g–M6s) made big edits to the same shared files —
`fighter.gd`, `match.gd`, `fighter_visuals.gd`, `tools/gen_fighter_sprites64.py` and
`docs/specs/moves.md`, mostly by adding to the same lists and `if` chains — so any two character
branches would conflict.

## Design

- **One folder per character:** `super-mms-bros/characters/<name>/` holds its `character.tres`
  (was `fighter/characters/slot_NN.tres`), its move resources (was `fighter/moves/<name>/`), and
  the scripts of the mechanics it brought (data resource, ability, match entity).
- **Abilities** (`fighter/fighter_ability.gd`): a character's special mechanics (ropes, vine,
  pyramid, stances, iPad, grab, hand, peel, cake, belly flop) become `FighterAbility` objects
  that the Fighter, the Match, the visuals and the sounds call through a fixed set of hooks. The
  fighter makes them from its move set: every `AbilityData` resource found on a special (or the
  move set) creates its ability. Shared code never names a character or its moves.
- **Match entities** (`match/match_entity.gd`): hands, peels and pyramids become `MatchEntity`
  nodes in one list, advanced, hit-tested and removed the same way.
- **Specs:** `docs/specs/moves.md` keeps the shared rules; each character's section moves to
  `docs/specs/characters/<name>.md`, and its art notes from `art-guide.md` with it.
- **Sprite generator:** the shared body drawing goes to `tools/sprites/body.py`; each
  character's weapons, props, poses and extra pictures to `tools/sprites/characters/<name>.py`,
  found automatically (no central list). `tools/gen_fighter_sprites64.py` stays the entry point.

## Steps (tests after each; a commit after each)

1. Split the specs (moves.md, art-guide.md) per character.
2. Split the sprite generator; check every character's output is byte-identical to before.
3. Move character files into `characters/<name>/` (paths in `.tres` files and tests updated).
4. Add `FighterAbility`/`AbilityData`/`MatchEntity`; move the mechanics into abilities one at a
   time, running the full suite after each.
5. Visuals, sounds and the HUD card call ability hooks instead of naming mechanics.
6. A guard test: the shared files don't mention character-only moves or mechanics.
7. Update `architecture.md`, `CLAUDE.md` (character-owned files), commit, push, and re-create the
   character branches from the new `main`.

## Execution notes (2026-11-14)

- Done as planned. The mechanic fields on `MoveData` (`vine`, `grab`, `pyramid`, `stances`,
  `peel`, `hand`, `ipad`, `rope_switch`, `rope_frenzy`, `min_charge_frames`, Pia's `dive_hit`,
  `hop_speed`, `heal`, `heal_frame`, `cooldown_frames`) and `MoveSet.ropes` became one generic
  `ability` field each; Pia got `CakeData` / `FlopData`, the rope flags moved into `RopeData`.
- Match signal `hand_landed` became `owner_sound(player_index, sound)`; the `Pyramids` node
  became `BehindFighters`; `FighterVisuals.load_textures()` loads every picture in a character's
  folder; the HUD card shows abilities' badges (`get_badge(type)`).
- Checked beyond the tests: all 196 matchups (14 × 14) played 900 ticks each with the same
  seeded random inputs on the old and the new code gave byte-identical traces of every fighter's
  position, velocity, state, move, frame, %, stocks, facing and shield, and of the projectile and
  entity counts (176 400 ticks; plus a Mads-grabs-a-standing-opponent run for the throw, which
  random play never reaches: 12 600 ticks, identical). The sprite generator's output for every
  character is byte-identical too. 537 tests pass (535 + the 2 guard tests).
