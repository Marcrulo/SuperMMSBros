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
├── Projectiles        (Node2D container; projectiles are added and removed by the Match)
├── Camera2D           (match/match_camera.gd — follows and zooms; presentation only)
└── HUD                (ui/hud.tscn — CanvasLayer)
```

The project's main scene is the character select (`ui/character_select.tscn`, see
[menus](menus.md)), which leads to `match/match.tscn`. The `Game` autoload (`game/game.gd`) keeps the
chosen character and stage between scenes. Controllers are plain objects (not nodes) created by
the Match and assigned one per fighter.

## Main types

| Type | Kind | Responsibility |
|---|---|---|
| `Match` | `Node2D` | Owns the tick loop (`step()`), rules, phases, RNG, snapshot, `reset()`. Emits signals for the HUD. |
| `Fighter` | `CharacterBody2D` | Movement, state machine, moves, damage %, shield; owns its hurtbox. Advanced by `tick(input)`. |
| `FighterStats` | `Resource` | All fighter tuning numbers and its `MoveSet`. One `.tres` file per fighter design. |
| `MoveSet` / `MoveData` | `Resource` | The eight moves of a design and each move's frame data, hitbox and knockback (see [moves](moves.md)). |
| `Projectile` | `Node2D` | The side special's projectile: position, direction, owner, age; advanced by the Match. |
| `FighterVisuals` | `Node2D` (child of Fighter) | Draws the fighter's sprite from its state, plus shield, charge glow and the debug view. |
| `FighterInput` | `RefCounted` | One tick of input (see [fighter](fighter.md#input)). |
| `Controller` | `RefCounted` (base class) | `get_input(state) -> FighterInput`, `reset()`. |
| `KeyboardController` | `Controller` | Reads Input Map actions (keyboard and gamepad). |
| `CpuController` | `Controller` | Hand-written AI; see [cpu](cpu.md). |
| `ScriptedController` | `Controller` | Plays back a fixed list of inputs; with an empty list it does nothing (the training dummy). Used in tests. |
| `MatchSnapshot` / `FighterSnapshot` | `RefCounted` | Plain read-only copy of the game state; see [Game state snapshot](#game-state-snapshot). |
| `Stage` | `Node2D` | Collision geometry, spawn points, ledges, blast zone rectangle; applies a `StageData`. |
| `Ledge` | `RefCounted` | A grabbable corner: `point` and outward `side` (−1 left, 1 right). |
| `StageData` / `PlatformStyle` | `Resource` | A stage's name, background, haze, light and platform style (see [match & stage](match-and-stage.md#stages)). |
| `PlatformLook` | `Node2D` (child of Stage) | Draws the platforms in perspective from the style. Presentation only. |
| `MatchCamera` | `Camera2D` | Frames the fighters and zooms. Presentation only. |
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
   Then **ledge grabs**: each fighter that can grab a ledge (P1, P2 order) grabs a free one
   whose corner is inside its grab box (see [fighter](fighter.md#ledge)).
5. Advance each existing projectile (in the order they were created) and remove those past their
   lifetime or outside the blast zone. Then add a projectile for every fighter whose side special
   reached its spawn frame this tick (P1, P2 order); a new projectile first moves next tick.
6. Resolve hits: first collect every hit for this tick — move hitboxes and projectiles against
   hurtboxes — then apply them all (blocked by a shield, or damage + knockback). Two fighters can
   hit each other on the same tick (a trade).
7. Check KOs (fighter center outside the blast zone), stocks, respawns and the win condition.
8. Advance timers (countdown, respawn, invulnerability) and the tick counter.

The order is always the same, which is what makes matches repeatable.

`step()` (and `Fighter.tick()`) must run **inside a physics frame**: `move_and_slide()` takes its time
step from the physics engine, which is exactly 1/60 s there (also with `--speed`, see below). Outside
a physics frame it would use the variable render-frame time and break repeatability. `Fighter.tick()`
asserts this.

## Hit detection

Hurtboxes are `Area2D` nodes with `RectangleShape2D` collision shapes (standing and crouching), so
they can be edited in the editor. Move hitboxes come from the `MoveData` resources. The Match does
**not** use Godot's area overlap signals or `get_overlapping_areas()` — those update one physics
step late and in no guaranteed order. Instead, each tick the Match computes the global rectangles of
active hitboxes, projectiles and hurtboxes and tests them with `Rect2.intersects()`. Areas have
`monitoring` and `monitorable` turned off. The F1 debug view draws the same rectangles the Match
uses.

## Game state snapshot

`Match.get_state() -> MatchSnapshot` returns a fresh, read-only copy of the game:

- `tick: int`, `phase: Phase` (`COUNTDOWN`, `PLAYING`, `ENDED`)
- `stage`: platform rectangles (solid and pass-through), the ledges (corner and outward side) and
  the blast zone `Rect2`
- `fighters: Array[FighterSnapshot]`, each with `index`, `position`, `velocity`, `facing` (−1 or 1),
  `state`, `move` (the move in progress, or none), `state_frame` (ticks spent in the current
  state), `on_floor`, `jumps_left`, `up_special_available`, `air_dodge_available`, `percent`,
  `shield_health`, `stocks`, `invulnerable_frames`, `intangible`
- `projectiles`: each with `owner`, `position`, `direction`

The snapshot never includes controller input or references to nodes.

## Collision layers

| # | Name | Used by |
|---|---|---|
| 1 | `stage_solid` | Main platform |
| 2 | `stage_platform` | Pass-through (one-way) platforms |
| 3 | `fighter` | Fighter bodies |
| 4 | `hitbox` | Reserved (move hitboxes are data in `MoveData`, not nodes) |
| 5 | `hurtbox` | Fighter hurtboxes (for editor display only) |

Fighters are on layer 3 and collide with layers 1 and 2. They do not collide with each other.
Dropping through a platform temporarily removes layer 2 from the fighter's mask.

## Command-line options

Read from `OS.get_cmdline_user_args()` (arguments after `--`):

| Option | Default | Meaning |
|---|---|---|
| `--stage=<id>` | `mms` | Stage to play (`mms`, `fc`, `slot_sunset`, `cafe_station`, `lindevej`, `cafe_slotsbio`) |
| `--hitboxes` | off | Start with the hitbox debug view on (F1 toggles it) |
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
├── match/         match.tscn, match.gd, match_camera.gd, projectile.gd, match_snapshot.gd,
│                  fighter_snapshot.gd
├── fighter/       fighter.tscn, fighter.gd, fighter_stats.gd, default_stats.tres, fighter_visuals.gd,
│                  move_data.gd, move_set.gd, moves/default/*.tres, character_data.gd, roster.gd,
│                  characters/*.tres
├── controllers/   controller.gd, fighter_input.gd, keyboard_controller.gd, cpu_controller.gd,
│                  cpu_settings.gd, default_cpu.tres, scripted_controller.gd
├── stage/         battlefield.tscn, stage.gd, platform_look.gd, background.gdshader,
│                  stage_data.gd, platform_style.gd, ledge.gd, stages/*.tres, styles/*.tres
├── game/          game.gd (the Game autoload: choices, scene changes, menu keys)
├── ui/            hud.tscn, hud.gd, player_card.tscn, player_card.gd, character_select.tscn,
│                  character_select.gd, stage_select.tscn, stage_select.gd, select_tile.gd,
│                  pause_menu.tscn, result_screen.tscn
├── assets/        fonts/, fighters/default/ (sprite strips), stage/backgrounds/
├── tests/         test_*.gd
└── addons/gut/    test framework
```

Outside the Godot project, `tools/` holds helper scripts that aren't part of the game, such as
`tools/gen_placeholder_sprites.py` (generates the placeholder sprite strips).

Group by feature: a scene lives next to its scripts.

## Code style

- Follow the official Godot GDScript style guide: `snake_case` files, functions and variables;
  `PascalCase` for `class_name` and nodes; `CONSTANT_CASE` for constants.
- Static typing everywhere (`var speed: float = 100.0`, typed function signatures, typed arrays).
- Every script that defines a reusable type declares a `class_name`.
- Tuning numbers live in resources (`FighterStats`, `CpuSettings`), not as literals in code.
