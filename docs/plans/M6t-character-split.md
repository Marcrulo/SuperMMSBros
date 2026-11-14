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
