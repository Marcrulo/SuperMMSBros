# Testing

## Framework

**GUT** (Godot Unit Test), installed in `super-mms-bros/addons/gut/`. Tests run headless from the
terminal and in the editor's GUT panel.

- Test files: `super-mms-bros/tests/test_<topic>.gd`, each `extends GutTest`.
- The exact command to run the suite is recorded in `CLAUDE.md` once M1 has set it up.
- Headless runs need the project imported first (`godot --headless --path super-mms-bros --import`)
  whenever assets were added or changed.

## How tests drive the game

- Tests build a Match with `ScriptedController`s (fixed input lists) instead of keyboard or CPU
  controllers, set `auto_step = false`, and call `match.step()` directly — so a test controls
  exactly how many ticks pass.
- After adding a scene to the tree, wait one physics frame (`await wait_physics_frames(1)`) before
  stepping, so the physics server has registered the stage's colliders.
- Fighter-level tests may call `fighter.tick(input)` directly on a fighter placed on a stage.
- Tests assert on the `MatchSnapshot` and on fighter state, never on visuals.

## What gets tested

| Area | Examples | Milestone |
|---|---|---|
| Setup | the suite runs; project settings are as specified | M1 |
| Movement | ground jump peaks at ≈48 px; short hop is lower; double jump works once and is restored on landing; walking off a ledge keeps the double jump; dropping through a pass-through platform; facing only changes on the ground | M2 |
| Attack | hitbox active exactly on frames 5–7; total 19 frames; ground attack doesn't steer; air attack ends on landing | M3 |
| Hits | knockback velocity and direction; hitstun length; one hit per attack; trades; jumps restored when hit; invulnerable fighters can't be hit | M3–M4 |
| Match rules | KO when center leaves the blast zone; stocks go down; respawn after 60 ticks with 120 ticks of invulnerability; win; draw; countdown blocks input | M4 |
| Reset & repeatability | `reset()` restores the full start state; same seed + same scripted inputs ⇒ identical snapshots every tick | M4 |
| CPU | uses only the snapshot; reaction delay; recovers when off stage; doesn't walk off the edge; repeatable with a fixed seed | M5 |
| End-to-end | headless CPU vs CPU match with `--autoquit --max-ticks` ends with a winner or draw and exit code 0 | M5 |

Every milestone's plan lists the tests to write first; a milestone is done only when its tests
pass headless.
