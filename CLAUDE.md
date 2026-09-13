# Super MMS Bros

A small 2D Smash-Bros-style platform fighter with a pixel-art look, built in Godot 4.7 with
GDScript. v1: you vs one CPU, 1v1, 3 stocks, one fighter, one Battlefield-style stage, placeholder
art.

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
godot --path super-mms-bros                          # run the game
godot --path super-mms-bros --editor                 # open the editor
godot --headless --path super-mms-bros --import      # import new/changed assets (needed before headless runs)
godot --path super-mms-bros -- --p1=cpu              # CPU vs CPU (from M5)
godot --headless --path super-mms-bros -- --p1=cpu --autoquit --speed=10 --max-ticks=36000   # headless end-to-end (from M5)
```

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
