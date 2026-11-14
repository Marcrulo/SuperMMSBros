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
├── BehindFighters     (Node2D container; ability entities drawn behind the fighters)
├── Fighters           (Node2D container)
│   ├── Fighter P1     (fighter/fighter.tscn)
│   └── Fighter P2     (fighter/fighter.tscn)
├── Projectiles        (Node2D container; projectiles and the other ability entities)
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
| `FighterAbility` / `AbilityData` | `RefCounted` / `Resource` | One character mechanic and its tuning (see [Abilities](#abilities)). Each character's are in its folder and its [character spec](characters/). |
| `MatchEntity` | `Node2D` | Something an ability adds to the match (a hand, a peel, a pyramid); advanced by the Match (see [Abilities](#abilities)). |
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
   Then **held fighters**: every fighter holding someone (an ability's throw or reel) moves them
   on (`advance_held`), or lets go if no ability does.
   Then **ledge grabs**: each fighter that can grab a ledge (P1, P2 order) grabs a free one
   whose corner is inside its grab box (see [fighter](fighter.md#ledge)).
   Then every ability's `after_ledges` (a vine up special's choice), P1's abilities first.
5. Advance each existing projectile (in the order they were created) and remove those past their
   lifetime or outside the blast zone. Then add a projectile for every fighter whose side special
   reached its spawn frame this tick (P1, P2 order); a new projectile first moves next tick.
   The same for the entities: advance each (in the order they were added), remove the finished
   ones, then every ability's `spawn_entities` (a pyramid, a hand, a peel), then every entity's
   `interact` (a peel trips someone). Then every ability's `resolve_contacts` (command grabs).
6. Resolve hits: first collect every hit for this tick — move hitboxes, the abilities' own hits
   (`collect_hits`: jump ropes), projectiles and entities against hurtboxes — then apply them all
   (blocked by a shield, or damage + knockback). Two fighters can hit each other on the same tick
   (a trade).
7. Check KOs (fighter center outside the blast zone), stocks, respawns and the win condition.
8. Advance timers (countdown, respawn, invulnerability, every ability's `end_step`) and the tick
   counter.

The order is always the same, which is what makes matches repeatable.

`step()` (and `Fighter.tick()`) must run **inside a physics frame**: `move_and_slide()` takes its time
step from the physics engine, which is exactly 1/60 s there (also with `--speed`, see below). Outside
a physics frame it would use the variable render-frame time and break repeatability. `Fighter.tick()`
asserts this.

## Abilities

Everything one character brings beyond the default move set — a vine, jump ropes, a stance
switch, a command grab, a summoned hand — is a **`FighterAbility`** (`fighter/fighter_ability.gd`),
so that a character's code lives in its own folder and character branches don't clash in shared
files (see the character branches in `CLAUDE.md`).

- **Data:** each mechanic has a data resource extending **`AbilityData`** (`VineData`,
  `RopeData`, …) with its tuning numbers. It sits on the move it belongs to (`MoveData.ability`,
  e.g. the up special's) or on the whole move set (`MoveSet.ability`). `create_ability()` makes
  the ability.
- **Making them:** when a fighter's `stats` is set, it makes one ability per `AbilityData` in its
  move set: its moves top to bottom, then the move set's own. The ability knows its `fighter`, its
  `data` and its `slot` (the move set property it was on, e.g. `&"up_special"`). Every hook is
  called in that order, P1's abilities before P2's.
- **Phases:** an ability can add phases (values of `Fighter.move` while in `ATTACK`, e.g.
  `&"vine_swing"`). While one is in progress the fighter asks its ability about it: its data
  (hitbox and hit), its hitbox, its movement, when it ends.
- **Hooks** (all do nothing by default; `fighter_ability.gd` documents each): on the fighter's
  tick — `reset` (spawn), `before_tick`, `pick_special` (may pick another special, or none),
  `allows_normals`, `replaces` (takes over a default move's behaviour: the up special's boost,
  the side special's projectile, the charge glow), `on_move_started`, `on_charge_released`,
  `move_tick`, `phase_*`, `left_floor_in_move`, `on_floor_in_move`, `places_fighter`/`place`,
  `can_be_hit`, `size_scale`, `speed_scale`, `modify_hit`, `modify_projectile`, `lifesteal`,
  `is_grab_box`, `after_tick`, `on_hit_dealt`; on the Match's step — `advance_held`,
  `after_ledges`, `spawn_entities`, `resolve_contacts`, `collect_hits`, `end_step` (see
  [Tick order](#tick-order)); presentation, only reading — `phase_animation`, `drawing`, `strip`,
  `held_pose`, `draw`, `sounds`, `make_card_badge`.
- **Entities:** what an ability adds to the match (a hand, a peel, a pyramid) is a
  **`MatchEntity`** (`match/match_entity.gd`), added with `Match.add_entity()`. The Match keeps
  them in one list and calls `advance`, `is_finished`, `interact`, `collect_hits`, and removes
  those that go with their owner on a KO.
- **Shared code never names a character's mechanic** (its classes, phases or name);
  `tests/test_character_split.gd` checks this. A mechanic two characters use (the vine) lives
  with the character that brought it and is shared code for the other.

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
| `--seed=N` | random | RNG seed (printed at match start; used by Michael's random football kicks) |
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
├── match/         match.tscn, match.gd, match_camera.gd, projectile.gd, match_entity.gd,
│                  match_snapshot.gd, fighter_snapshot.gd
├── fighter/       fighter.tscn, fighter.gd, fighter_stats.gd, default_stats.tres, fighter_visuals.gd,
│                  fighter_sounds.gd, fighter_ability.gd, ability_data.gd, move_data.gd,
│                  move_set.gd, moves/default/*.tres, character_data.gd, roster.gd, roster.tres
├── characters/    <name>/ for each character: character.tres (its CharacterData), moves/*.tres
│                  (its own moves and ability data), and the scripts of its mechanics (abilities,
│                  their data, entities, HUD badges)
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
`tools/gen_fighter_sprites64.py` (generates every character's sprite strips: the shared body in
`tools/sprites/body.py`, each character's weapon, props and own poses in
`tools/sprites/characters/<name>.py`, the heads and colors in `tools/fighter64_looks.py`).

Group by feature: a scene lives next to its scripts.

## Code style

- Follow the official Godot GDScript style guide: `snake_case` files, functions and variables;
  `PascalCase` for `class_name` and nodes; `CONSTANT_CASE` for constants.
- Static typing everywhere (`var speed: float = 100.0`, typed function signatures, typed arrays).
- Every script that defines a reusable type declares a `class_name`.
- Tuning numbers live in resources (`FighterStats`, `CpuSettings`), not as literals in code.
