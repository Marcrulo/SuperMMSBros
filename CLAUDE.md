# Super MMS Bros

A small 2D Smash-Bros-style platform fighter with a pixel-art look, built in Godot 4.7 with
GDScript. v1: you vs one CPU, 1v1, 3 stocks, damage %, one big-headed fighter design with a full
Smash-style move set, five themed stages sharing one layout, a zooming camera, generated
placeholder sprites. See `docs/vision.md`.

## Talking to the user

- The user is new to Godot and wants to **learn the engine while we build**. When doing or
  proposing something, briefly explain the Godot concept behind it (nodes, scenes, signals,
  resources, the Input Map, collision layers, etc.) and mention both ways to do it: in the editor
  (GUI) and in code/text files.
- Avoid unexplained jargon; define terms the first time they come up.
- This preference is for conversation only. The `docs/` folder is purely about the game — don't
  put tutorials or learning notes there.

## Where things are

- `super-mms-bros/` — the Godot project (`project.godot` lives here; `res://` = this folder).
- `docs/vision.md` — what the game is, v1 scope, later ideas.
- `docs/roadmap.md` — milestones M1–M6.
- `docs/specs/` — the design, one file per area. **The specs are the source of truth**: read the
  relevant spec before working on an area, and update the spec first if the design changes.
- `docs/plans/` — one implementation plan per milestone.

## Commands

`godot` is on the PATH (`~/.local/bin/godot`, Godot 4.7 standard build). Run from the repo root:

```bash
godot --path super-mms-bros                          # run the game (character select → stage select → match)
godot --path super-mms-bros -- --stage=fc            # skip the menus, straight into a match on that stage
godot --path super-mms-bros --editor                 # open the editor
godot --headless --path super-mms-bros --import      # import new/changed assets and new class_name scripts (needed before headless runs)
godot --path super-mms-bros -- --p1=cpu              # CPU vs CPU (from M8)
godot --headless --path super-mms-bros -- --p1=cpu --autoquit --speed=10 --max-ticks=36000   # headless end-to-end (from M8)
```

Don't run `--import` while the editor is open: two Godot processes writing `.godot/` at once can
corrupt `.godot/uid_cache.bin` (symptom: `Unrecognized UID` / the game can't find its main scene).
Fix: close the editor, delete that file, run `--import`.

Run the tests (headless; exit code 0 = all passed):

```bash
godot --headless --path super-mms-bros -s res://addons/gut/gut_cmdln.gd
```

## Core design rules

Full details in `docs/specs/architecture.md`. In short:

1. **The Match drives every tick** through `Match.step()`, in a fixed order. Fighters, controllers
   and the stage have no gameplay logic in `_process`/`_physics_process` of their own.
2. **Frame-based timing:** 60 ticks per second; durations are counted in ticks, never seconds or
   `Timer` nodes.
3. **Presentation only reads:** visuals, HUD and effects never change gameplay state. The game must
   play the same headless.
4. **Everyone plays through controllers** that return a `FighterInput` per tick.
5. **Deciding controllers (CPU, future trained agent) see only `Match.get_state()`.**
6. **One seeded RNG** owned by the Match. Same seed + same inputs ⇒ same match.

## Code style

- Official Godot GDScript style guide: `snake_case` files/functions/variables, `PascalCase`
  classes and nodes, `CONSTANT_CASE` constants.
- Static typing everywhere; `class_name` on reusable types.
- Tuning numbers go in resources (`FighterStats`, `CpuSettings`), not literals in code.
- Group files by feature (a scene next to its scripts), per the folder layout in the architecture
  spec.

## Workflow

- Each milestone: write its plan in `docs/plans/`, write tests first (GUT, see
  `docs/specs/testing.md`), then implement. A milestone is done when its tests pass headless and
  the user has tried it.
- The user playtests — Claude can't see the game window, so ask the user how things look and feel.
- Git: branch `main`, remote `origin` = github.com/Marcrulo/SuperMMSBros. Commit only when asked
  or when a plan step says so; don't push unless asked.

## Character branches (parallel sessions)

Each character has its own branch, `char/<name>` (lowercase first name, as in
`fighter/moves/<name>/`): `char/pia`, `char/gitte`, `char/trine`, `char/nina`, `char/michael`,
`char/henrik`, `char/stig`, `char/casper`, `char/kim`, `char/mette`, `char/mads`,
`char/sjippepigen`, `char/fidusen`, `char/magnus`. Work that isn't about one character (engine,
stages, menus, CPU, milestones) happens on `main` or its own feature branch.

- **Work on a character only on its branch, in its own worktree.** Several sessions run at once,
  and one folder can only have one branch checked out, so each branch lives in its own folder:
  `git worktree add ../SuperMMSBros-<name> char/<name>` (run from the repo root; skip if the
  folder exists). Work and run every command from that folder. In a new worktree, first link
  the gitignored assets from the main checkout, then import:
  ```bash
  M=../SuperMMSBros/super-mms-bros; W=super-mms-bros
  ln -s "$(realpath $M/assets/music)" $W/assets/music
  for f in fonts/ink_yugo.otf sfx/menu_confirm.wav; do ln -s "$(realpath $M/assets/$f)" $W/assets/$f; done
  godot --headless --path super-mms-bros --import
  ```
- **Stay inside the character.** Character-owned files: `fighter/moves/<name>/`,
  `fighter/characters/slot_NN.tres`, `assets/fighters/slot_NN/` and its portrait,
  `tests/test_<name>*.gd`, `docs/plans/` files for that character, and that character's
  section of `docs/specs/moves.md` / `docs/specs/art-guide.md` / the look entry in
  `tools/fighter64_looks.py`.
- **Shared files** are everything else — mainly `fighter/fighter.gd`, `fighter/fighter_visuals.gd`,
  `fighter/move_data.gd` and other `*_data.gd`, `match/match.gd`, `tools/gen_fighter_sprites64.py`,
  `tests/test_character_moves.gd`, and other characters' sections of the specs. Change them
  only when the feature truly needs it, keep the change small and generic (a hook or a new
  field other characters could use, not a big `if character == ...` block), and never change
  another character's behaviour or look.
- **Mark shared changes** so merging is easy: put them in their own commits whose message starts
  with `shared:` and says what changed and why (e.g. `shared: Fighter gets on_landed() hook for
  Pia's belly flop`). Generated sprites for other characters that change only because the shared
  generator changed also go in a `shared:` commit. Mention every shared change to the user.
- **Merging back:** first `git merge main` into the character branch, fix conflicts, regenerate
  generated files (sprites, sounds) instead of hand-merging them, run the full test suite, then
  merge into `main` (only when the user asks). Merge `main` into the character branch often —
  small conflicts early beat big ones late. List the `shared:` commits for the user before the
  merge into `main`.
