# M6v — Magnus the Avatar Implementation Plan

**Goal:** Magnus's four specials are the four elements (water gun, fireball, wind burst, earth
smash); landing all four lights his card and starts the Avatar State (freeze, then free flight
with contact hits); he runs the Naruto run.

**Architecture:** All in `characters/magnus/` (no shared files). `WaterGunAbility` + `Droplet`
entity (neutral special, Nina-style stream), `FireballAbility` + `Fireball` entity (side special,
one at a time). Up and down specials are plain `MoveData` (default behaviour, his numbers).
`AvatarAbility` (on `MoveSet.ability`) tracks the lit elements, runs the phases `avatar_rise` /
`avatar_fly`, draws the orbs/rocks/wind and makes the `ElementBadge`. Sprites: his own `run`
strip and `avatar.png` from `tools/sprites/characters/magnus.py`.

**Tech stack:** Godot 4.7 / GDScript, GUT; Python + Pillow for the sprite generator.

**Spec:** [magnus](../specs/characters/magnus.md)

## Global constraints

- Core rules of the architecture spec: Match drives every tick, ticks not seconds, presentation
  only reads, numbers in resources.
- Character-owned files only; `tests/test_character_split.gd` must still pass.

## Review focus

1. A hit blocked by a shield must not light an element (test: fireball into a shield).
2. Respawning after a KO keeps the lit elements; `Match.reset()` clears them (tests).
3. Avatar flight can't carry him out of the blast zone (test: hold left for the whole flight).
4. The fourth element landing mid-move starts the Avatar State only once he's free (test).
5. Getting the elements again after the Avatar State ends works (elements dark again, test).

## How lighting is detected

- Water/Fire: the entity's hit dictionary has `"landed": ability.light.bind(element)` (only
  called on unblocked hits by `Match._resolve_hits`).
- Air/Earth (the Match's own move hits): `AvatarAbility.end_step` — for every opponent that
  `fighter.has_hit()` this tick and didn't the tick before, while the move in progress is
  `up_special` (Air) or `down_special` / `down_special_dive` (Earth), and whose state isn't
  `SHIELD` / `SHIELD_BREAK` → light it.

## Tasks

- [ ] **Task 1: spec** — `docs/specs/characters/magnus.md` (done with the user's OK).
- [ ] **Task 2: tests first** — `tests/test_magnus.gd` (moves, data, water, fire, air, earth)
  and `tests/test_magnus_avatar.gd` (lighting rules, rise, flight, contact hits, end, KO/reset,
  badge). Run: fail (classes missing).
- [ ] **Task 3: moves + abilities** — data `.tres`, `WaterGunData/Ability`, `Droplet`,
  `FireballData/Ability`, `Fireball`, `AvatarData/Ability`, `ElementBadge`; `character.tres`
  gets `moveset`. Run `--import`, then the Magnus tests until they pass.
- [ ] **Task 4: sprites** — `tools/sprites/characters/magnus.py`: Naruto `run` (look flag
  `naruto_run`), `avatar.png` (2 drawings, glowing eyes, flag `avatar`); regenerate slot_14
  only, check every frame, pixel-compare the other ids unchanged; `test_sprites` still passes.
  Rebuild + republish the sprite viewer.
- [ ] **Task 5: full suite** headless, commit, push; user playtest.
