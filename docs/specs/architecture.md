# Architecture

How the game is put together. Other specs describe *what* each part does; this one describes how
the parts fit and the rules every part follows.

## Core rules

These apply to all code. Breaking one of them needs a spec change first.

1. **The Match drives every tick.** Gameplay advances only inside `Match.step()`, in a fixed order
   (see [Tick order](#tick-order)). Fighters, controllers and the stage have no
   `_physics_process` or `_process` gameplay logic of their own.
2. **Gameplay is frame-based.** The simulation runs at exactly 60 ticks per second. All durations
   (attack phases, hitstun, invulnerability, countdown) are counted in ticks, never in seconds or with
   `Timer` nodes. Speeds and accelerations are in pixels per second, applied with a fixed delta of
   1/60 s.
3. **Presentation only reads.** Visuals, animation, HUD and effects read game state and listen to
   signals. They never change gameplay state. The game plays identically with or without a window.
4. **Everyone plays through controllers.** A fighter never reads the keyboard. Each tick, its
   controller produces a `FighterInput`, and that is the only way to make a fighter act.
5. **Controllers that decide see only the snapshot.** The CPU (and a future trained agent) decide from
   `Match.get_state()` and nothing else.
6. **Randomness comes from one seeded RNG** owned by the Match. Same seed + same inputs ⇒ same match.

Rules 1, 2 and 6 make the game repeatable (needed for tests, AI training and a possible rollback
netcode later). Rule 3 makes headless running safe. Rules 4 and 5 let a keyboard, the CPU, a scripted
test and a future trained agent all be swapped freely.

## Scene tree

```
Match                  (match/match.tscn, match.gd)
├── Stage              (stage/stage.tscn, stage.gd)
├── Fighters           (Node2D container)
│   ├── Fighter P1     (fighter/fighter.tscn)
│   └── Fighter P2     (fighter/fighter.tscn)
├── Camera2D           (fixed, centered on the screen)
└── HUD                (ui/hud.tscn — CanvasLayer)
```

`match/match.tscn` is the project's main scene. Controllers are plain objects (not nodes) created by
the Match and assigned one per fighter.

## Main types

| Type | Kind | Responsibility |
|---|---|---|
| `Match` | `Node2D` | Owns the tick loop (`step()`), rules, phases, RNG, snapshot, `reset()`. Emits signals for the HUD. |
| `Fighter` | `CharacterBody2D` | Movement, state machine, owns its hitbox and hurtbox. Advanced by `tick(input)`. |
| `FighterStats` | `Resource` | All fighter tuning numbers. One `.tres` file per fighter design. |
| `FighterVisuals` | `Node2D` (child of Fighter) | Draws the fighter from its state. Placeholder rectangles now, sprites later. |
| `FighterInput` | `RefCounted` | One tick of input: `move_x`, `jump_pressed`, `jump_held`, `down_pressed`, `attack_pressed`. |
| `Controller` | `RefCounted` (base class) | `get_input(state) -> FighterInput`, `reset()`. |
| `KeyboardController` | `Controller` | Reads Input Map actions (keyboard and gamepad). |
| `CpuController` | `Controller` | Hand-written AI; see [cpu](cpu.md). |
| `ScriptedController` | `Controller` | Plays back a fixed list of inputs; with an empty list it does nothing (the training dummy). Used in tests. |
| `MatchSnapshot` / `FighterSnapshot` | `RefCounted` | Plain read-only copy of the game state; see [Game state snapshot](#game-state-snapshot). |
| `Stage` | `Node2D` | Collision geometry, spawn points, blast zone rectangle. |
| `Hud` | `CanvasLayer` | Stock icons, countdown, off-screen arrows, pause menu, result screen. |

## Tick order

One tick is one call to `Match.step()`. Normally `Match._physics_process()` calls it once per physics
frame; tests (and later AI training) set `Match.auto_step = false` and call `step()` themselves.
Every tick, `step()` does, in this order:

1. If the phase is `ENDED`, do nothing.
2. Build the snapshot for this tick.
3. Ask each fighter's controller for input, P1 then P2. During `COUNTDOWN` the inputs are replaced
   with empty input (controllers are still asked, so the CPU's reaction buffer fills).
4. Advance each fighter one step with `fighter.tick(input)`, P1 then P2.
5. Resolve hits: first collect every hit (hitbox vs hurtbox) for this tick, then apply them all. Two
   fighters can hit each other on the same tick (a trade).
6. Check KOs (fighter center outside the blast zone), stocks, respawns and the win condition.
7. Advance timers (countdown, respawn, invulnerability) and the tick counter.

The order is always the same, which is what makes matches repeatable.

`step()` (and `Fighter.tick()`) must run **inside a physics frame**: `move_and_slide()` takes its time
step from the physics engine, which is exactly 1/60 s there (also with `--speed`, see below). Outside
a physics frame it would use the variable render-frame time and break repeatability. `Fighter.tick()`
asserts this.

## Hit detection

Hitboxes and hurtboxes are `Area2D` nodes with `RectangleShape2D` collision shapes, so they can be
edited in the editor and seen in-game with **Debug → Visible Collision Shapes**. However, the Match
does **not** use Godot's area overlap signals or `get_overlapping_areas()` — those update one physics
step late and in no guaranteed order. Instead, each tick the Match computes the global rectangles of
active hitboxes and hurtboxes and tests them with `Rect2.intersects()`. Areas have `monitoring` and
`monitorable` turned off.

## Game state snapshot

`Match.get_state() -> MatchSnapshot` returns a fresh, read-only copy of the game:

- `tick: int`, `phase: Phase` (`COUNTDOWN`, `PLAYING`, `ENDED`)
- `stage`: platform rectangles (solid and pass-through) and the blast zone `Rect2`
- `fighters: Array[FighterSnapshot]`, each with `index`, `position`, `velocity`, `facing` (−1 or 1),
  `state`, `state_frame` (ticks spent in the current state), `on_floor`, `jumps_left`, `stocks`,
  `invulnerable_frames`

The snapshot never includes controller input or references to nodes.

## Collision layers

| # | Name | Used by |
|---|---|---|
| 1 | `stage_solid` | Main platform |
| 2 | `stage_platform` | Pass-through (one-way) platforms |
| 3 | `fighter` | Fighter bodies |
| 4 | `hitbox` | Attack hitboxes (for editor display only) |
| 5 | `hurtbox` | Fighter hurtboxes (for editor display only) |

Fighters are on layer 3 and collide with layers 1 and 2. They do not collide with each other.
Dropping through a platform temporarily removes layer 2 from the fighter's mask.

## Command-line options

Read from `OS.get_cmdline_user_args()` (arguments after `--`):

| Option | Default | Meaning |
|---|---|---|
| `--p1=human\|cpu` | `human` | Controller for P1 |
| `--p2=human\|cpu` | `cpu` | Controller for P2 |
| `--seed=N` | random | RNG seed (printed at match start) |
| `--autoquit` | off | When the match ends, print the result and quit |
| `--speed=N` | 1 | Run N× faster than real time (sets `Engine.physics_ticks_per_second = 60·N` and `Engine.time_scale = N`, so each tick is still 1/60 s of game time) |
| `--max-ticks=N` | none | End the match as a timeout after N ticks (exit code 1 with `--autoquit`) |

With `--autoquit`, the game prints one line `RESULT: P1_WIN|P2_WIN|DRAW|TIMEOUT ticks=N seed=S` and
quits with exit code 0 (or 1 for `TIMEOUT`).

Examples:
```bash
godot --path super-mms-bros                                   # you vs CPU
godot --path super-mms-bros -- --p1=cpu                       # watch CPU vs CPU
godot --headless --path super-mms-bros -- --p1=cpu --autoquit --speed=10 --max-ticks=36000
```

## Folder layout

```
super-mms-bros/
├── project.godot
├── match/         match.tscn, match.gd, match_snapshot.gd, fighter_snapshot.gd
├── fighter/       fighter.tscn, fighter.gd, fighter_stats.gd, default_stats.tres, fighter_visuals.gd
├── controllers/   controller.gd, fighter_input.gd, keyboard_controller.gd, cpu_controller.gd,
│                  cpu_settings.gd, default_cpu.tres, scripted_controller.gd
├── stage/         battlefield.tscn, stage.gd
├── ui/            hud.tscn, hud.gd, pause_menu.tscn, result_screen.tscn
├── assets/        fonts/ (sprites later)
├── tests/         test_*.gd
└── addons/gut/    test framework
```

Group by feature: a scene lives next to its scripts.

## Code style

- Follow the official Godot GDScript style guide: `snake_case` files, functions and variables;
  `PascalCase` for `class_name` and nodes; `CONSTANT_CASE` for constants.
- Static typing everywhere (`var speed: float = 100.0`, typed function signatures, typed arrays).
- Every script that defines a reusable type declares a `class_name`.
- Tuning numbers live in resources (`FighterStats`, `CpuSettings`), not as literals in code.
