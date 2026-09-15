# M2 — Movement on the Stage Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Run, jump, short hop, double jump and drop through platforms on the Battlefield stage with one keyboard/gamepad-controlled fighter, driven tick by tick by the Match.

**Architecture:** Controllers turn input into a `FighterInput` per tick; the `Match` asks each controller and calls `fighter.tick(input)` from its `_physics_process` (tests call `step()` directly). The `Fighter` is a `CharacterBody2D` that computes its velocity from `FighterStats` (a `.tres` resource) and moves with `move_and_slide()` against the stage's `StaticBody2D`s; pass-through platforms are one-way collision shapes on their own collision layer. Visuals only read fighter state.

**Tech Stack:** Godot 4.7.2 (standard build, `godot` on PATH), GDScript, GUT 9.7.1.

**Spec:** [`docs/specs/fighter.md`](../specs/fighter.md), [`docs/specs/match-and-stage.md`](../specs/match-and-stage.md), [`docs/specs/architecture.md`](../specs/architecture.md), [`docs/specs/controls-and-display.md`](../specs/controls-and-display.md), [`docs/specs/testing.md`](../specs/testing.md)

## Global Constraints

- Godot project root: `super-mms-bros/` (`res://`). Run every command from the repo root (`/home/mp/Desktop/SuperMMSBros`).
- Branch: `m2-movement`, created from `main` after M1 is merged.
- Godot 4.7.2 standard build; GUT 9.7.1. Don't run `--import` while the editor is open (it can corrupt `.godot/uid_cache.bin`).
- GDScript: official style guide, static typing everywhere, `class_name` on reusable types, tabs for indentation.
- Tuning numbers live only in `fighter/default_stats.tres`, never as literals in code.
- The Match drives every tick: `Fighter`, controllers and the stage have no gameplay logic in `_process`/`_physics_process`. Durations are counted in ticks (60 per second); speeds are px/s applied with a fixed delta of 1/60 s.
- `Match.step()` and `Fighter.tick()` run only inside a physics frame (`move_and_slide()` takes its time step from the physics engine). Tests get there with `await wait_physics_frames(1)` and then tick synchronously.
- After adding a script with a new `class_name` (or a new scene/resource), run `godot --headless --path super-mms-bros --import` before running the tests; otherwise the new class names are unknown.
- Collision layers: 1 `stage_solid`, 2 `stage_platform`, 3 `fighter`, 4 `hitbox`, 5 `hurtbox`. Fighter bodies are on layer 3 with mask 1 + 2 (fighters don't collide with each other).
- World coordinates = screen coordinates: 320×180, (0, 0) top-left, y down. Fighter origin = feet (bottom-center).
- Placeholder colors (Sweetie 16): main platform `#333c57`, pass-through platforms `#566c86`, P1 `#b13e53`, P2 `#3b5dc9`, eye `#f4f4f4`.
- Commit the `.uid` files Godot generates next to scripts; never commit `.godot/`.
- Commit messages end with a blank line and `Co-Authored-By: Claude Opus 5 <noreply@anthropic.com>`. Don't push.

## File Structure

| Path (under `super-mms-bros/`) | Responsibility |
|---|---|
| `tests/test_test_scripts_load.gd` | Fails if any test script can't load (GUT would silently skip it) |
| `controllers/fighter_input.gd` | `FighterInput`: one tick of input |
| `controllers/controller.gd` | `Controller`: base class, `get_input(state)`, `reset()` |
| `controllers/scripted_controller.gd` | `ScriptedController`: plays back a fixed input list (tests, later the dummy) |
| `controllers/keyboard_controller.gd` | `KeyboardController`: reads the Input Map actions |
| `fighter/fighter_stats.gd` | `FighterStats`: the tuning-number fields |
| `fighter/default_stats.tres` | The one fighter design's values from the spec |
| `fighter/fighter.gd` | `Fighter`: state machine and movement, advanced by `tick(input)` |
| `fighter/fighter_visuals.gd` | `FighterVisuals`: placeholder rectangles drawn from fighter state |
| `fighter/fighter.tscn` | Fighter scene: body, collision shape, visuals |
| `stage/stage.gd` | `Stage`: spawn points and spawn facing |
| `stage/battlefield.tscn` | Battlefield: main platform, three pass-through platforms, spawn markers |
| `match/match.gd` | `Match`: tick loop (`step()`), `reset()`, controllers per fighter |
| `match/match.tscn` | Main scene: Stage, Fighters/P1, Camera2D (replaces the M1 placeholder) |
| `project.godot` | Collision layer names (via a one-off tool) |
| `tests/test_controllers.gd`, `test_fighter_stats.gd`, `test_stage.gd`, `test_fighter_movement.gd`, `test_match.gd` | The M2 tests |
| `CLAUDE.md` (repo root) | Note that new `class_name` scripts need an import |

The test suite has 12 tests at the start of M2 and 52 at the end.

---

### Task 1: Catch test scripts that fail to load

GUT skips a test script that fails to parse (for example, one that uses a class that doesn't exist yet) and still exits with code 0. Every later task starts with exactly that situation, so this guard comes first.

**Files:**
- Create: `super-mms-bros/tests/test_test_scripts_load.gd`
- Create, then delete: `super-mms-bros/tests/test_broken.gd`
- Modify: `CLAUDE.md` (the `--import` line under "Commands")

**Interfaces:**
- Produces: a failing test (`test_every_test_script_loads`, exit code 1) whenever any `res://tests/test_*.gd` can't load. Later tasks' "verify it fails" steps rely on it.

- [ ] **Step 1: Write the guard test**

Create `super-mms-bros/tests/test_test_scripts_load.gd`:

```gdscript
extends GutTest
## GUT skips a test script that fails to load (a typo, or a class the project doesn't have yet)
## and still reports success. This test fails instead, so exit code 0 really means "all passed".

const TESTS_DIR := "res://tests/"


func test_every_test_script_loads() -> void:
	for file in DirAccess.get_files_at(TESTS_DIR):
		if file.begins_with("test_") and file.ends_with(".gd"):
			var script := load(TESTS_DIR + file) as GDScript
			assert_true(script != null and script.can_instantiate(),
				"%s should load; see the SCRIPT ERROR lines above" % file)
```

- [ ] **Step 2: Verify it catches a broken test script**

Create `super-mms-bros/tests/test_broken.gd`:

```gdscript
extends GutTest


func test_broken() -> void:
	var x := NotAClass.new()
```

Run: `godot --headless --path super-mms-bros -s res://addons/gut/gut_cmdln.gd; echo "exit=$?"`
Expected: `SCRIPT ERROR: Parse Error` lines for `test_broken.gd`; the run summary shows `Tests 13`, `Passing Tests 12`, `Failing Tests 1` with the failure `test_broken.gd should load; see the SCRIPT ERROR lines above`; `exit=1`.

- [ ] **Step 3: Delete the broken script and run again**

```bash
rm super-mms-bros/tests/test_broken.gd
godot --headless --path super-mms-bros -s res://addons/gut/gut_cmdln.gd; echo "exit=$?"
```

Expected: `Passing Tests 13`, `---- All tests passed! ----`, `exit=0`.

- [ ] **Step 4: Note the import rule in `CLAUDE.md`**

In `CLAUDE.md`, replace the line

```
godot --headless --path super-mms-bros --import      # import new/changed assets (needed before headless runs)
```

with

```
godot --headless --path super-mms-bros --import      # import new/changed assets and new class_name scripts (needed before headless runs)
```

- [ ] **Step 5: Commit**

```bash
git add super-mms-bros/tests CLAUDE.md
git status --short   # must not list .godot/ or test_broken.gd
git commit -m "Fail the test run when a test script can't load

Co-Authored-By: Claude Opus 5 <noreply@anthropic.com>"
```

---

### Task 2: Fighter input and controllers

**Files:**
- Create: `super-mms-bros/tests/test_controllers.gd`
- Create: `super-mms-bros/controllers/fighter_input.gd`, `controller.gd`, `scripted_controller.gd`, `keyboard_controller.gd`

**Interfaces:**
- Produces:
  - `FighterInput` (`RefCounted`): `move_x: float`, `jump_pressed: bool`, `jump_held: bool`, `down_pressed: bool`, `attack_pressed: bool`; all default to 0/false.
  - `Controller` (`RefCounted`): `get_input(_state: RefCounted) -> FighterInput`, `reset() -> void`. The Match passes `null` as `state` until the snapshot exists (M4).
  - `ScriptedController` (`Controller`): `ScriptedController.new(inputs: Array[FighterInput] = [])`; returns the inputs in order, then empty input; `reset()` starts over.
  - `KeyboardController` (`Controller`): reads the Input Map actions `move_left`, `move_right`, `jump`, `down`, `attack`.

- [ ] **Step 1: Write the failing tests**

Create `super-mms-bros/tests/test_controllers.gd`:

```gdscript
extends GutTest
## FighterInput and controllers (docs/specs/fighter.md#input, docs/specs/controls-and-display.md).


func after_each() -> void:
	for action: String in ["move_left", "move_right", "jump", "down", "attack"]:
		Input.action_release(action)


func test_fighter_input_starts_empty() -> void:
	var input := FighterInput.new()
	assert_eq(input.move_x, 0.0)
	assert_false(input.jump_pressed)
	assert_false(input.jump_held)
	assert_false(input.down_pressed)
	assert_false(input.attack_pressed)


func test_base_controller_returns_empty_input() -> void:
	var input := Controller.new().get_input(null)
	assert_not_null(input)
	assert_eq(input.move_x, 0.0)
	assert_false(input.jump_pressed)


func test_scripted_controller_plays_inputs_in_order_then_nothing() -> void:
	var right := FighterInput.new()
	right.move_x = 1.0
	var jump := FighterInput.new()
	jump.jump_pressed = true
	var controller := ScriptedController.new([right, jump])
	assert_eq(controller.get_input(null).move_x, 1.0)
	assert_true(controller.get_input(null).jump_pressed)
	var after_end := controller.get_input(null)
	assert_eq(after_end.move_x, 0.0)
	assert_false(after_end.jump_pressed)


func test_scripted_controller_reset_starts_over() -> void:
	var right := FighterInput.new()
	right.move_x = 1.0
	var controller := ScriptedController.new([right])
	controller.get_input(null)
	controller.reset()
	assert_eq(controller.get_input(null).move_x, 1.0)


func test_scripted_controller_without_inputs_is_a_dummy() -> void:
	var controller := ScriptedController.new()
	for i in 3:
		var input := controller.get_input(null)
		assert_eq(input.move_x, 0.0)
		assert_false(input.jump_pressed)


func test_keyboard_controller_reads_move_and_held_jump() -> void:
	Input.action_press("move_left")
	Input.action_press("jump")
	var input := KeyboardController.new().get_input(null)
	assert_eq(input.move_x, -1.0)
	assert_true(input.jump_held)


func test_keyboard_controller_pressed_is_true_for_one_tick_only() -> void:
	var controller := KeyboardController.new()
	# A simulated press counts as "just pressed" during the next physics frame. Awaiting the tree's
	# physics_frame signal resumes the test inside exactly that frame (GUT's wait_physics_frames(1)
	# waits one frame longer and would miss it).
	await get_tree().physics_frame
	Input.action_press("jump")
	Input.action_press("down")
	Input.action_press("attack")
	await get_tree().physics_frame
	var first := controller.get_input(null)
	await get_tree().physics_frame
	var second := controller.get_input(null)
	assert_true(first.jump_pressed, "jump pressed on the first tick")
	assert_true(first.down_pressed, "down pressed on the first tick")
	assert_true(first.attack_pressed, "attack pressed on the first tick")
	assert_false(second.jump_pressed, "holding jump doesn't press it again")
	assert_false(second.down_pressed, "holding down doesn't press it again")
	assert_false(second.attack_pressed, "holding attack doesn't press it again")
	assert_true(second.jump_held, "jump is still held")
```

- [ ] **Step 2: Run the tests to verify they fail**

Run: `godot --headless --path super-mms-bros -s res://addons/gut/gut_cmdln.gd; echo "exit=$?"`
Expected: `Parse Error: Identifier "FighterInput" not declared in the current scope` for `test_controllers.gd`; `Tests 13`, `Passing Tests 12`, `Failing Tests 1` (`test_controllers.gd should load`); `exit=1`.

- [ ] **Step 3: Write `FighterInput`**

Create `super-mms-bros/controllers/fighter_input.gd`:

```gdscript
class_name FighterInput
extends RefCounted
## One tick of input for one fighter (docs/specs/fighter.md#input).
## "Pressed" means the button went down this tick; holding it never presses it again.

## Horizontal direction, from -1 (left) to 1 (right).
var move_x: float = 0.0
## Jump went down this tick.
var jump_pressed: bool = false
## Jump is held down.
var jump_held: bool = false
## Down went down this tick.
var down_pressed: bool = false
## Attack went down this tick.
var attack_pressed: bool = false
```

- [ ] **Step 4: Write the `Controller` base class**

Create `super-mms-bros/controllers/controller.gd`:

```gdscript
class_name Controller
extends RefCounted
## Base class for whatever plays a fighter: the keyboard, a test script, later the CPU.
## Each tick the Match asks every fighter's controller for one FighterInput.


## Returns this tick's input. `state` will be the game-state snapshot (Match.get_state(), added in
## M4); until then the Match passes null.
func get_input(_state: RefCounted) -> FighterInput:
	return FighterInput.new()


## Forgets anything remembered from the previous match.
func reset() -> void:
	pass
```

- [ ] **Step 5: Write `ScriptedController`**

Create `super-mms-bros/controllers/scripted_controller.gd`:

```gdscript
class_name ScriptedController
extends Controller
## Plays back a fixed list of inputs, one per tick, then empty input.
## With an empty list it does nothing at all (the training dummy). Used by tests.

var _inputs: Array[FighterInput] = []
var _next: int = 0


func _init(inputs: Array[FighterInput] = []) -> void:
	_inputs = inputs


func get_input(_state: RefCounted) -> FighterInput:
	if _next >= _inputs.size():
		return FighterInput.new()
	var input := _inputs[_next]
	_next += 1
	return input


func reset() -> void:
	_next = 0
```

- [ ] **Step 6: Write `KeyboardController`**

Create `super-mms-bros/controllers/keyboard_controller.gd`:

```gdscript
class_name KeyboardController
extends Controller
## Plays a fighter from the Input Map actions, so keyboard and gamepad both work
## (docs/specs/controls-and-display.md). The Match calls it inside the physics frame, where
## "just pressed" means "went down since the last tick".


func get_input(_state: RefCounted) -> FighterInput:
	var input := FighterInput.new()
	input.move_x = Input.get_axis("move_left", "move_right")
	input.jump_pressed = Input.is_action_just_pressed("jump")
	input.jump_held = Input.is_action_pressed("jump")
	input.down_pressed = Input.is_action_just_pressed("down")
	input.attack_pressed = Input.is_action_just_pressed("attack")
	return input
```

- [ ] **Step 7: Import and run the tests to verify they pass**

```bash
godot --headless --path super-mms-bros --import
godot --headless --path super-mms-bros -s res://addons/gut/gut_cmdln.gd; echo "exit=$?"
```

Expected: `Passing Tests 20`, `---- All tests passed! ----`, `exit=0`. (Without the import, `test_controllers.gd` still fails to load: the new class names aren't registered yet.)

- [ ] **Step 8: Commit**

```bash
git add super-mms-bros/controllers super-mms-bros/tests
git status --short   # must not list .godot/
git commit -m "Add FighterInput and keyboard, scripted and base controllers

Co-Authored-By: Claude Opus 5 <noreply@anthropic.com>"
```

---

### Task 3: `FighterStats` resource

Only the movement stats; the attack and knockback stats from the spec are added in M3.

**Files:**
- Create: `super-mms-bros/tests/test_fighter_stats.gd`
- Create: `super-mms-bros/fighter/fighter_stats.gd`, `super-mms-bros/fighter/default_stats.tres`

**Interfaces:**
- Produces: `FighterStats` (`Resource`) with `run_speed`, `ground_accel`, `ground_friction`, `air_speed`, `air_accel`, `air_friction`, `gravity`, `max_fall_speed`, `jump_velocity`, `double_jump_velocity`, `short_hop_cut` (all `float`), `max_air_jumps`, `drop_through_frames` (`int`). The values live in `res://fighter/default_stats.tres`; the script has no defaults.

- [ ] **Step 1: Write the failing tests**

Create `super-mms-bros/tests/test_fighter_stats.gd`:

```gdscript
extends GutTest
## Starting movement values from docs/specs/fighter.md#stats.

const STATS_PATH := "res://fighter/default_stats.tres"


func test_default_stats_load_as_fighter_stats() -> void:
	assert_true(load(STATS_PATH) is FighterStats)


func test_default_stats_match_the_spec() -> void:
	var stats := load(STATS_PATH) as FighterStats
	assert_not_null(stats, "default stats should load")
	if stats == null:
		return
	assert_eq(stats.run_speed, 100.0)
	assert_eq(stats.ground_accel, 1200.0)
	assert_eq(stats.ground_friction, 1200.0)
	assert_eq(stats.air_speed, 90.0)
	assert_eq(stats.air_accel, 400.0)
	assert_eq(stats.air_friction, 150.0)
	assert_eq(stats.gravity, 600.0)
	assert_eq(stats.max_fall_speed, 250.0)
	assert_eq(stats.jump_velocity, 240.0)
	assert_eq(stats.double_jump_velocity, 219.0)
	assert_eq(stats.short_hop_cut, 0.5)
	assert_eq(stats.max_air_jumps, 1)
	assert_eq(stats.drop_through_frames, 10)
```

- [ ] **Step 2: Run the tests to verify they fail**

Run: `godot --headless --path super-mms-bros -s res://addons/gut/gut_cmdln.gd; echo "exit=$?"`
Expected: parse errors for `test_fighter_stats.gd` (`Could not find type "FighterStats"`); `Tests 20`, `Passing Tests 19`, `Failing Tests 1` (`test_fighter_stats.gd should load`); `exit=1`.

- [ ] **Step 3: Write `FighterStats`**

Create `super-mms-bros/fighter/fighter_stats.gd`:

```gdscript
class_name FighterStats
extends Resource
## Every tuning number for one fighter design (docs/specs/fighter.md#stats).
## Distances in pixels, speeds in px/s, accelerations in px/s², durations in ticks (60 per second).
## The values live in the .tres file (fighter/default_stats.tres), not here.

@export_group("Ground")
## Top ground speed.
@export var run_speed: float
## How fast ground speed moves toward the target while holding a direction.
@export var ground_accel: float
## How fast ground speed moves toward 0 with no input.
@export var ground_friction: float

@export_group("Air")
## Top air speed from input.
@export var air_speed: float
## Air steering.
@export var air_accel: float
## How fast air speed moves toward 0 with no input.
@export var air_friction: float
@export var gravity: float
@export var max_fall_speed: float

@export_group("Jumps")
@export var jump_velocity: float
@export var double_jump_velocity: float
## Upward speed is multiplied by this if jump is released early (short hop).
@export var short_hop_cut: float
@export var max_air_jumps: int

@export_group("Platforms")
## How long pass-through platforms are ignored after dropping through one.
@export var drop_through_frames: int
```

- [ ] **Step 4: Write the default stats**

Create `super-mms-bros/fighter/default_stats.tres`:

```
[gd_resource type="Resource" script_class="FighterStats" format=3]

[ext_resource type="Script" path="res://fighter/fighter_stats.gd" id="1_stats"]

[resource]
script = ExtResource("1_stats")
run_speed = 100.0
ground_accel = 1200.0
ground_friction = 1200.0
air_speed = 90.0
air_accel = 400.0
air_friction = 150.0
gravity = 600.0
max_fall_speed = 250.0
jump_velocity = 240.0
double_jump_velocity = 219.0
short_hop_cut = 0.5
max_air_jumps = 1
drop_through_frames = 10
```

- [ ] **Step 5: Import and run the tests to verify they pass**

```bash
godot --headless --path super-mms-bros --import
godot --headless --path super-mms-bros -s res://addons/gut/gut_cmdln.gd; echo "exit=$?"
```

Expected: `Passing Tests 22`, `---- All tests passed! ----`, `exit=0`.

- [ ] **Step 6: Commit**

```bash
git add super-mms-bros/fighter super-mms-bros/tests
git status --short   # must not list .godot/
git commit -m "Add FighterStats resource with the spec's movement values

Co-Authored-By: Claude Opus 5 <noreply@anthropic.com>"
```

---

### Task 4: Battlefield stage and collision layer names

**Files:**
- Create: `super-mms-bros/tests/test_stage.gd`
- Create: `super-mms-bros/stage/stage.gd`, `super-mms-bros/stage/battlefield.tscn`
- Create, run, then delete: `super-mms-bros/tools/apply_layer_names.gd`
- Modify: `super-mms-bros/project.godot` (via the tool)

**Interfaces:**
- Produces:
  - `res://stage/battlefield.tscn`, root `Battlefield` (`Node2D`, script `Stage`), children `MainPlatform` (`StaticBody2D`, layer 1), `Platforms/Left`, `Platforms/Right`, `Platforms/Top` (`StaticBody2D`, layer 2, one-way `CollisionShape2D`), `P1Spawn`, `P2Spawn` (`Marker2D`). Each body's shape node is named `CollisionShape2D`.
  - `Stage.get_spawn_position(player_index: int) -> Vector2` (global position of `P<n>Spawn`), `Stage.get_spawn_facing(player_index: int) -> int` (from `@export var spawn_facings: Array[int] = [1, -1]`).
  - Layer names in `project.godot`: `layer_names/2d_physics/layer_1..5`.

- [ ] **Step 1: Write the failing tests**

Create `super-mms-bros/tests/test_stage.gd`:

```gdscript
extends GutTest
## Battlefield layout and collision layers (docs/specs/match-and-stage.md#stage-battlefield,
## docs/specs/architecture.md#collision-layers).

const STAGE_SCENE := preload("res://stage/battlefield.tscn")

var _stage: Stage


func before_each() -> void:
	_stage = add_child_autofree(STAGE_SCENE.instantiate())


func test_collision_layer_names() -> void:
	var names := ["stage_solid", "stage_platform", "fighter", "hitbox", "hurtbox"]
	for i in names.size():
		assert_eq(ProjectSettings.get_setting("layer_names/2d_physics/layer_%d" % (i + 1)), names[i])


func test_main_platform_is_solid() -> void:
	var body := _stage.get_node("MainPlatform") as StaticBody2D
	assert_eq(_shape_rect(body), Rect2(64, 128, 192, 16))
	assert_eq(body.collision_layer, _layer_bit(1), "only on layer 1 (stage_solid)")
	assert_false(_shape(body).one_way_collision)


func test_pass_through_platforms() -> void:
	var expected := {
		"Left": Rect2(88, 96, 48, 4),
		"Right": Rect2(184, 96, 48, 4),
		"Top": Rect2(136, 64, 48, 4),
	}
	for platform_name: String in expected:
		var body := _stage.get_node("Platforms/" + platform_name) as StaticBody2D
		assert_eq(_shape_rect(body), expected[platform_name], platform_name)
		assert_eq(body.collision_layer, _layer_bit(2), "%s: only on layer 2 (stage_platform)" % platform_name)
		assert_true(_shape(body).one_way_collision, "%s: one-way" % platform_name)


func test_spawn_points() -> void:
	assert_eq(_stage.get_spawn_position(0), Vector2(112, 128))
	assert_eq(_stage.get_spawn_facing(0), 1)
	assert_eq(_stage.get_spawn_position(1), Vector2(208, 128))
	assert_eq(_stage.get_spawn_facing(1), -1)


func _shape(body: StaticBody2D) -> CollisionShape2D:
	return body.get_node("CollisionShape2D") as CollisionShape2D


## The collision rectangle in world coordinates.
func _shape_rect(body: StaticBody2D) -> Rect2:
	var shape := _shape(body)
	var size := (shape.shape as RectangleShape2D).size
	return Rect2(shape.global_position - size / 2.0, size)


## Collision layers are stored as bits: layer 1 = 1, layer 2 = 2, layer 3 = 4, ...
func _layer_bit(layer: int) -> int:
	return 1 << (layer - 1)
```

- [ ] **Step 2: Run the tests to verify they fail**

Run: `godot --headless --path super-mms-bros -s res://addons/gut/gut_cmdln.gd; echo "exit=$?"`
Expected: parse errors for `test_stage.gd` (`Preload file "res://stage/battlefield.tscn" does not exist`); `Tests 22`, `Passing Tests 21`, `Failing Tests 1`; `exit=1`.

- [ ] **Step 3: Write the `Stage` script**

Create `super-mms-bros/stage/stage.gd`:

```gdscript
class_name Stage
extends Node2D
## A stage: collision geometry and spawn points (docs/specs/match-and-stage.md#stage-battlefield).
## Spawn points are the Marker2D children P1Spawn, P2Spawn, ...

## Which way each player faces at spawn, by player index: 1 = right, -1 = left.
@export var spawn_facings: Array[int] = [1, -1]


## Where player `player_index` (0 = P1) spawns, in world coordinates.
func get_spawn_position(player_index: int) -> Vector2:
	var marker := get_node("P%dSpawn" % (player_index + 1)) as Marker2D
	return marker.global_position


func get_spawn_facing(player_index: int) -> int:
	return spawn_facings[player_index]
```

- [ ] **Step 4: Write the Battlefield scene**

Positions come from the stage table in the spec. A `StaticBody2D` sits at the center of its collision rectangle, except the pass-through platforms: their body sits at the platform's top-center and the 4 px shape is offset 2 px down, so the walkable surface is exactly at the body's y. Collision layers are stored as bit values: `collision_layer = 2` is layer 2; the main platform keeps the default (layer 1). Static bodies need no mask (`collision_mask = 0`). Each platform has its own shape resource so one can be resized in the editor without changing the others. The colors are the spec's hex values as floats (`#333c57`, `#566c86`).

Create `super-mms-bros/stage/battlefield.tscn`:

```
[gd_scene format=3]

[ext_resource type="Script" path="res://stage/stage.gd" id="1_stage"]

[sub_resource type="RectangleShape2D" id="RectangleShape2D_main"]
size = Vector2(192, 16)

[sub_resource type="RectangleShape2D" id="RectangleShape2D_left"]
size = Vector2(48, 4)

[sub_resource type="RectangleShape2D" id="RectangleShape2D_right"]
size = Vector2(48, 4)

[sub_resource type="RectangleShape2D" id="RectangleShape2D_top"]
size = Vector2(48, 4)

[node name="Battlefield" type="Node2D"]
script = ExtResource("1_stage")

[node name="MainPlatform" type="StaticBody2D" parent="."]
position = Vector2(160, 136)
collision_mask = 0

[node name="CollisionShape2D" type="CollisionShape2D" parent="MainPlatform"]
shape = SubResource("RectangleShape2D_main")

[node name="Visual" type="ColorRect" parent="MainPlatform"]
offset_left = -96.0
offset_top = -8.0
offset_right = 96.0
offset_bottom = 8.0
mouse_filter = 2
color = Color(0.2, 0.23529412, 0.34117648, 1)

[node name="Platforms" type="Node2D" parent="."]

[node name="Left" type="StaticBody2D" parent="Platforms"]
position = Vector2(112, 96)
collision_layer = 2
collision_mask = 0

[node name="CollisionShape2D" type="CollisionShape2D" parent="Platforms/Left"]
position = Vector2(0, 2)
shape = SubResource("RectangleShape2D_left")
one_way_collision = true

[node name="Visual" type="ColorRect" parent="Platforms/Left"]
offset_left = -24.0
offset_right = 24.0
offset_bottom = 4.0
mouse_filter = 2
color = Color(0.3372549, 0.42352942, 0.5254902, 1)

[node name="Right" type="StaticBody2D" parent="Platforms"]
position = Vector2(208, 96)
collision_layer = 2
collision_mask = 0

[node name="CollisionShape2D" type="CollisionShape2D" parent="Platforms/Right"]
position = Vector2(0, 2)
shape = SubResource("RectangleShape2D_right")
one_way_collision = true

[node name="Visual" type="ColorRect" parent="Platforms/Right"]
offset_left = -24.0
offset_right = 24.0
offset_bottom = 4.0
mouse_filter = 2
color = Color(0.3372549, 0.42352942, 0.5254902, 1)

[node name="Top" type="StaticBody2D" parent="Platforms"]
position = Vector2(160, 64)
collision_layer = 2
collision_mask = 0

[node name="CollisionShape2D" type="CollisionShape2D" parent="Platforms/Top"]
position = Vector2(0, 2)
shape = SubResource("RectangleShape2D_top")
one_way_collision = true

[node name="Visual" type="ColorRect" parent="Platforms/Top"]
offset_left = -24.0
offset_right = 24.0
offset_bottom = 4.0
mouse_filter = 2
color = Color(0.3372549, 0.42352942, 0.5254902, 1)

[node name="P1Spawn" type="Marker2D" parent="."]
position = Vector2(112, 128)

[node name="P2Spawn" type="Marker2D" parent="."]
position = Vector2(208, 128)
```

- [ ] **Step 5: Import and run the tests**

```bash
godot --headless --path super-mms-bros --import
godot --headless --path super-mms-bros -s res://addons/gut/gut_cmdln.gd; echo "exit=$?"
```

Expected: `Tests 26`, `Passing Tests 25`, `Failing Tests 1`: only `test_collision_layer_names` fails (`[""] expected to equal ["stage_solid"]`, etc.); `exit=1`.

- [ ] **Step 6: Write and run the layer names tool**

Create `super-mms-bros/tools/apply_layer_names.gd`:

```gdscript
extends SceneTree
## One-off: names the 2D physics layers in project.godot, then quits.
## Run: godot --headless --path super-mms-bros -s res://tools/apply_layer_names.gd


func _init() -> void:
	var names := ["stage_solid", "stage_platform", "fighter", "hitbox", "hurtbox"]
	for i in names.size():
		ProjectSettings.set_setting("layer_names/2d_physics/layer_%d" % (i + 1), names[i])

	var err := ProjectSettings.save()
	print("apply_layer_names: save -> ", error_string(err))
	quit(0 if err == OK else 1)
```

Run:

```bash
godot --headless --path super-mms-bros -s res://tools/apply_layer_names.gd
rm -r super-mms-bros/tools
git diff super-mms-bros/project.godot
```

Expected: `apply_layer_names: save -> OK`; the diff adds only a `[layer_names]` section with `2d_physics/layer_1="stage_solid"` … `2d_physics/layer_5="hurtbox"`.

- [ ] **Step 7: Run the tests to verify they pass**

Run: `godot --headless --path super-mms-bros -s res://addons/gut/gut_cmdln.gd; echo "exit=$?"`
Expected: `Passing Tests 26`, `---- All tests passed! ----`, `exit=0`.

- [ ] **Step 8: Commit**

```bash
git add super-mms-bros/stage super-mms-bros/tests super-mms-bros/project.godot
git status --short   # must not list .godot/ or tools/
git commit -m "Add Battlefield stage and name the collision layers

Co-Authored-By: Claude Opus 5 <noreply@anthropic.com>"
```

---

### Task 5: Fighter scene and ground movement

The fighter can stand, run, turn, stop, fall and land. Jumps come in Task 6, pass-through platforms in Task 7, visuals in Task 8.

How a tick works (`Fighter.tick(input)`), in order:
1. **Actions** for the current state (here: on the ground, `move_x` decides `RUN`/`IDLE` and facing).
2. **Steering**: horizontal speed moves toward `move_x × top speed` at the accel, or toward 0 at the friction (ground or air values).
3. **Gravity** when in `AIR`, or when not on the floor (e.g. the first tick after spawning). On the floor, `move_and_slide()` keeps the fighter there by itself (floor snap).
4. `move_and_slide()`.
5. **After the move**: in `AIR` and now on the floor → landed (`IDLE`/`RUN`); on the ground and no longer on the floor → walked off a ledge (`AIR`).
6. `state_frame += 1`. `_set_state()` resets it to 0 on a state change, so it's 1 on the tick a state is entered.

**Files:**
- Create: `super-mms-bros/tests/test_fighter_movement.gd`
- Create: `super-mms-bros/fighter/fighter.gd`, `super-mms-bros/fighter/fighter.tscn`

**Interfaces:**
- Consumes: `FighterInput` (Task 2), `FighterStats` + `default_stats.tres` (Task 3), `battlefield.tscn` (Task 4).
- Produces:
  - `res://fighter/fighter.tscn`: root `Fighter` (`CharacterBody2D`, layer 3, mask 1 + 2, `stats` = `default_stats.tres`), child `BodyShape` (16×24 rectangle at (0, −12)).
  - `Fighter` API: `enum State { IDLE, RUN, AIR }`, `const DELTA := 1.0 / 60.0`, `@export var stats: FighterStats`, `var player_index: int`, `var facing: int` (1/−1), `var state: State`, `var state_frame: int`, `var jumps_left: int`, `func spawn_at(spawn_position: Vector2, spawn_facing: int) -> void`, `func tick(input: FighterInput) -> void`.
  - Test helpers in `test_fighter_movement.gd` used by Tasks 6–7: constants `FLOOR_Y`, `PLATFORM_Y`, `OPEN_SKY`, `UNDER_LEFT_PLATFORM`, `TOLERANCE`; fields `_fighter`, `_stats`; `_start_at(at: Vector2, facing: int = 1)` (async), `_run(input: FighterInput, ticks: int)`, `_idle() -> FighterInput`, `_move(move_x: float) -> FighterInput`.

- [ ] **Step 1: Write the failing tests**

Create `super-mms-bros/tests/test_fighter_movement.gd`:

```gdscript
extends GutTest
## Fighter movement on the Battlefield (docs/specs/fighter.md#movement-rules).
## Every test begins with `await _start_at(...)`: waiting one physics frame registers the stage's
## colliders and resumes the test inside a physics frame, where Fighter.tick() may run.

const STAGE_SCENE := preload("res://stage/battlefield.tscn")
const FIGHTER_SCENE := preload("res://fighter/fighter.tscn")
const FLOOR_Y := 128.0
const PLATFORM_Y := 96.0
## A spot on the main platform with open sky above: no pass-through platform to land on.
const OPEN_SKY := Vector2(76, 128)
## Right below the left pass-through platform.
const UNDER_LEFT_PLATFORM := Vector2(112, 128)
## move_and_slide() keeps a tiny gap (the collision "safe margin") between body and floor.
const TOLERANCE := 0.5

var _fighter: Fighter
var _stats: FighterStats


func before_each() -> void:
	add_child_autofree(STAGE_SCENE.instantiate())
	_fighter = add_child_autofree(FIGHTER_SCENE.instantiate())
	_stats = _fighter.stats


func _start_at(at: Vector2, facing: int = 1) -> void:
	_fighter.spawn_at(at, facing)
	await wait_physics_frames(1)


func _run(input: FighterInput, ticks: int) -> void:
	for i in ticks:
		_fighter.tick(input)


func _idle() -> FighterInput:
	return FighterInput.new()


func _move(move_x: float) -> FighterInput:
	var input := FighterInput.new()
	input.move_x = move_x
	return input


# --- Ground -----------------------------------------------------------------------------------


func test_scene_setup() -> void:
	assert_eq(_fighter.collision_layer, 1 << 2, "body only on layer 3 (fighter)")
	assert_true(_fighter.get_collision_mask_value(1), "collides with stage_solid")
	assert_true(_fighter.get_collision_mask_value(2), "collides with stage_platform")
	assert_false(_fighter.get_collision_mask_value(3), "fighters don't collide with each other")
	var shape := _fighter.get_node("BodyShape") as CollisionShape2D
	assert_eq((shape.shape as RectangleShape2D).size, Vector2(16, 24))
	assert_eq(shape.position, Vector2(0, -12))
	assert_eq(_stats.resource_path, "res://fighter/default_stats.tres")


func test_spawn_at_resets_the_fighter() -> void:
	_fighter.velocity = Vector2(50, 50)
	_fighter.jumps_left = 0
	_fighter.spawn_at(Vector2(208, 128), -1)
	assert_eq(_fighter.position, Vector2(208, 128))
	assert_eq(_fighter.facing, -1)
	assert_eq(_fighter.velocity, Vector2.ZERO)
	assert_eq(_fighter.state, Fighter.State.IDLE)
	assert_eq(_fighter.state_frame, 0)
	assert_eq(_fighter.jumps_left, _stats.max_air_jumps)


func test_stands_on_the_main_platform() -> void:
	await _start_at(UNDER_LEFT_PLATFORM)
	_run(_idle(), 30)
	assert_eq(_fighter.state, Fighter.State.IDLE)
	assert_true(_fighter.is_on_floor())
	assert_almost_eq(_fighter.position.y, FLOOR_Y, TOLERANCE)
	assert_eq(_fighter.position.x, UNDER_LEFT_PLATFORM.x)


func test_runs_up_to_run_speed() -> void:
	await _start_at(UNDER_LEFT_PLATFORM)
	_run(_move(1.0), 1)
	assert_almost_eq(_fighter.velocity.x, _stats.ground_accel / 60.0, 0.001, "one tick of accel")
	_run(_move(1.0), 10)
	assert_eq(_fighter.velocity.x, _stats.run_speed)
	assert_eq(_fighter.state, Fighter.State.RUN)
	assert_eq(_fighter.facing, 1)


func test_friction_stops_the_fighter() -> void:
	await _start_at(UNDER_LEFT_PLATFORM)
	_run(_move(1.0), 10)
	_run(_idle(), 1)
	assert_almost_eq(_fighter.velocity.x, _stats.run_speed - _stats.ground_friction / 60.0, 0.001)
	_run(_idle(), 10)
	assert_eq(_fighter.velocity.x, 0.0)
	assert_eq(_fighter.state, Fighter.State.IDLE)


func test_turns_to_face_the_direction_held_on_the_ground() -> void:
	await _start_at(UNDER_LEFT_PLATFORM, 1)
	_run(_move(-1.0), 1)
	assert_eq(_fighter.facing, -1)
	_run(_move(1.0), 1)
	assert_eq(_fighter.facing, 1)


func test_state_frame_counts_ticks_in_the_current_state() -> void:
	await _start_at(UNDER_LEFT_PLATFORM)
	_run(_idle(), 2)
	assert_eq(_fighter.state_frame, 2, "2 ticks in IDLE")
	_run(_move(1.0), 1)
	assert_eq(_fighter.state, Fighter.State.RUN)
	assert_eq(_fighter.state_frame, 1, "1 on the tick RUN is entered")
	_run(_move(1.0), 2)
	assert_eq(_fighter.state_frame, 3)
	_run(_idle(), 1)
	assert_eq(_fighter.state, Fighter.State.IDLE)
	assert_eq(_fighter.state_frame, 1)
```

- [ ] **Step 2: Run the tests to verify they fail**

Run: `godot --headless --path super-mms-bros -s res://addons/gut/gut_cmdln.gd; echo "exit=$?"`
Expected: parse errors for `test_fighter_movement.gd` (`Preload file "res://fighter/fighter.tscn" does not exist`, `Fighter` not declared); `Tests 26`, `Passing Tests 25`, `Failing Tests 1`; `exit=1`.

- [ ] **Step 3: Write the `Fighter` script**

Create `super-mms-bros/fighter/fighter.gd`:

```gdscript
class_name Fighter
extends CharacterBody2D
## A fighter: body, movement and state machine (docs/specs/fighter.md).
## The Match advances it one tick at a time with tick(); it has no _physics_process of its own.

enum State { IDLE, RUN, AIR }

## One tick of game time, in seconds (the game runs at 60 ticks per second).
const DELTA := 1.0 / 60.0

@export var stats: FighterStats

## 0 for P1, 1 for P2. Set by the Match.
var player_index: int = 0
## 1 = facing right, -1 = facing left.
var facing: int = 1
var state: State = State.IDLE
## Ticks spent in the current state; 1 on the tick the state is entered.
var state_frame: int = 0
var jumps_left: int = 0


## Puts the fighter at a spawn point, standing still: IDLE, jumps restored.
func spawn_at(spawn_position: Vector2, spawn_facing: int) -> void:
	global_position = spawn_position
	facing = spawn_facing
	velocity = Vector2.ZERO
	state = State.IDLE
	state_frame = 0
	jumps_left = stats.max_air_jumps


## Advances the fighter by one tick. Must run inside a physics frame, because move_and_slide()
## takes its time step from the physics engine (which is 1/60 s there).
func tick(input: FighterInput) -> void:
	assert(Engine.is_in_physics_frame(), "Fighter.tick() must run inside a physics frame")
	if state != State.AIR:
		_ground_actions(input)

	if state == State.AIR:
		_steer(input.move_x, stats.air_speed, stats.air_accel, stats.air_friction)
	else:
		_steer(input.move_x, stats.run_speed, stats.ground_accel, stats.ground_friction)
	if state == State.AIR or not is_on_floor():
		velocity.y = minf(velocity.y + stats.gravity * DELTA, stats.max_fall_speed)

	move_and_slide()

	_after_move(input)
	state_frame += 1


## IDLE/RUN: run or stand.
func _ground_actions(input: FighterInput) -> void:
	if input.move_x != 0.0:
		facing = 1 if input.move_x > 0.0 else -1
		_set_state(State.RUN)
	else:
		_set_state(State.IDLE)


## Moves horizontal speed toward `move_x × top_speed` at `accel`, or toward 0 at `friction`.
func _steer(move_x: float, top_speed: float, accel: float, friction: float) -> void:
	if move_x != 0.0:
		velocity.x = move_toward(velocity.x, move_x * top_speed, accel * DELTA)
	else:
		velocity.x = move_toward(velocity.x, 0.0, friction * DELTA)


## Landing and walking off ledges, decided from where move_and_slide() left the fighter.
func _after_move(input: FighterInput) -> void:
	if state == State.AIR:
		if is_on_floor():
			_set_state(State.RUN if input.move_x != 0.0 else State.IDLE)
	elif not is_on_floor():
		_set_state(State.AIR)


func _set_state(new_state: State) -> void:
	if new_state != state:
		state = new_state
		state_frame = 0
```

- [ ] **Step 4: Write the fighter scene**

Create `super-mms-bros/fighter/fighter.tscn` (`collision_layer = 4` is layer 3; `collision_mask = 3` is layers 1 and 2):

```
[gd_scene format=3]

[ext_resource type="Script" path="res://fighter/fighter.gd" id="1_fighter"]
[ext_resource type="Resource" path="res://fighter/default_stats.tres" id="2_stats"]

[sub_resource type="RectangleShape2D" id="RectangleShape2D_body"]
size = Vector2(16, 24)

[node name="Fighter" type="CharacterBody2D"]
collision_layer = 4
collision_mask = 3
script = ExtResource("1_fighter")
stats = ExtResource("2_stats")

[node name="BodyShape" type="CollisionShape2D" parent="."]
position = Vector2(0, -12)
shape = SubResource("RectangleShape2D_body")
```

- [ ] **Step 5: Import and run the tests to verify they pass**

```bash
godot --headless --path super-mms-bros --import
godot --headless --path super-mms-bros -s res://addons/gut/gut_cmdln.gd; echo "exit=$?"
```

Expected: `Passing Tests 33`, `---- All tests passed! ----`, `exit=0`.

- [ ] **Step 6: Commit**

```bash
git add super-mms-bros/fighter super-mms-bros/tests
git status --short   # must not list .godot/
git commit -m "Add fighter scene with ground movement, falling and landing

Co-Authored-By: Claude Opus 5 <noreply@anthropic.com>"
```

---

### Task 6: Jumps — ground jump, short hop, double jump

Numbers to expect, from the stats: a held ground jump rises 46 px (spec: ≈48), a short hop about 14 px, a double jump from the peak about 38 px (spec: ≈40). The tests allow ±3 px around the spec values.

**Files:**
- Modify: `super-mms-bros/tests/test_fighter_movement.gd` (append)
- Modify: `super-mms-bros/fighter/fighter.gd` (full replacement below)

**Interfaces:**
- Consumes: the Task 5 `Fighter` API and test helpers.
- Produces: jump behavior in `Fighter.tick()`; test helpers used by Task 7: `_jump() -> FighterInput` (pressed + held), `_hold_jump() -> FighterInput`, `_run_until_landed(input: FighterInput)`, `_run_until_falling(input: FighterInput) -> float`, `_jump_height(hold_ticks: int) -> float`.

- [ ] **Step 1: Write the failing tests**

Append to the end of `super-mms-bros/tests/test_fighter_movement.gd`:

```gdscript
# --- Jumps ------------------------------------------------------------------------------------


func test_jump_leaves_the_ground() -> void:
	await _start_at(OPEN_SKY)
	_run(_jump(), 1)
	assert_eq(_fighter.state, Fighter.State.AIR)
	assert_lt(_fighter.velocity.y, 0.0, "moving up")
	assert_eq(_fighter.jumps_left, _stats.max_air_jumps, "a ground jump doesn't use the double jump")


func test_ground_jump_rises_about_48_px() -> void:
	await _start_at(OPEN_SKY)
	assert_almost_eq(_jump_height(60), 48.0, 3.0)
	assert_eq(_fighter.state, Fighter.State.IDLE, "landed again")
	assert_almost_eq(_fighter.position.y, FLOOR_Y, TOLERANCE)


func test_short_hop_is_lower_than_a_full_jump() -> void:
	await _start_at(OPEN_SKY)
	var full := _jump_height(60)
	var short := _jump_height(0)
	assert_lt(short, full * 0.5, "short hop (%.1f px) vs full jump (%.1f px)" % [short, full])
	assert_gt(short, 8.0)


func test_double_jump_rises_about_40_px() -> void:
	await _start_at(OPEN_SKY)
	_run(_jump(), 1)
	_run_until_falling(_hold_jump())
	var start_y := _fighter.position.y
	_run(_jump(), 1)
	var highest := _run_until_falling(_hold_jump())
	assert_almost_eq(start_y - highest, 40.0, 3.0)
	assert_eq(_fighter.jumps_left, 0)


func test_only_one_double_jump() -> void:
	await _start_at(OPEN_SKY)
	_run(_jump(), 1)
	_run(_idle(), 1)
	_run(_jump(), 1)
	assert_eq(_fighter.jumps_left, 0)
	_run(_idle(), 1)
	var speed_before := _fighter.velocity.y
	_run(_jump(), 1)
	assert_gt(_fighter.velocity.y, speed_before, "no upward kick: gravity keeps pulling")
	assert_eq(_fighter.jumps_left, 0)


func test_landing_restores_the_double_jump() -> void:
	await _start_at(OPEN_SKY)
	_run(_jump(), 1)
	_run(_idle(), 1)
	_run(_jump(), 1)
	_run_until_landed(_idle())
	assert_eq(_fighter.state, Fighter.State.IDLE)
	assert_eq(_fighter.jumps_left, _stats.max_air_jumps)


func test_walking_off_a_ledge_keeps_the_double_jump() -> void:
	await _start_at(Vector2(244, 128))
	for i in 60:
		_fighter.tick(_move(1.0))
		if _fighter.state == Fighter.State.AIR:
			break
	assert_eq(_fighter.state, Fighter.State.AIR, "walked off the right edge")
	assert_eq(_fighter.jumps_left, _stats.max_air_jumps)
	_run(_jump(), 1)
	assert_lt(_fighter.velocity.y, 0.0, "double jump works")
	assert_eq(_fighter.jumps_left, 0)


func test_facing_does_not_change_in_the_air() -> void:
	await _start_at(Vector2(160, 128), 1)
	_run(_jump(), 1)
	_run(_move(-1.0), 10)
	assert_eq(_fighter.state, Fighter.State.AIR)
	assert_eq(_fighter.facing, 1, "still facing right while drifting left")
	_run_until_landed(_idle())
	_run(_move(-1.0), 1)
	assert_eq(_fighter.facing, -1, "turns once back on the ground")


## The tick jump goes down (it's also held).
func _jump() -> FighterInput:
	var input := FighterInput.new()
	input.jump_pressed = true
	input.jump_held = true
	return input


func _hold_jump() -> FighterInput:
	var input := FighterInput.new()
	input.jump_held = true
	return input


## Ticks with `input` until the fighter is back on the ground (at most 2 seconds).
func _run_until_landed(input: FighterInput) -> void:
	for i in 120:
		_fighter.tick(input)
		if _fighter.state != Fighter.State.AIR:
			return


## Ticks with `input` until the fighter stops rising; returns the highest y reached.
func _run_until_falling(input: FighterInput) -> float:
	var highest := _fighter.position.y
	for i in 120:
		_fighter.tick(input)
		highest = minf(highest, _fighter.position.y)
		if _fighter.velocity.y >= 0.0:
			break
	return highest


## Presses jump, keeps holding it for `hold_ticks` more ticks, then lets go and waits for the
## landing. Returns how many pixels the feet rose.
func _jump_height(hold_ticks: int) -> float:
	var start_y := _fighter.position.y
	var highest := start_y
	_fighter.tick(_jump())
	for i in 120:
		highest = minf(highest, _fighter.position.y)
		if _fighter.state != Fighter.State.AIR:
			break
		_fighter.tick(_hold_jump() if i < hold_ticks else _idle())
	return start_y - highest
```

- [ ] **Step 2: Run the tests to verify they fail**

Run: `godot --headless --path super-mms-bros -s res://addons/gut/gut_cmdln.gd; echo "exit=$?"`
Expected: `Tests 41`, `Passing Tests 34`, `Failing Tests 7`. Failing: `test_jump_leaves_the_ground`, `test_ground_jump_rises_about_48_px`, `test_short_hop_is_lower_than_a_full_jump`, `test_double_jump_rises_about_40_px`, `test_only_one_double_jump`, `test_walking_off_a_ledge_keeps_the_double_jump`, `test_facing_does_not_change_in_the_air`. (`test_landing_restores_the_double_jump` already passes: without jumps the fighter never leaves the ground.) `exit=1`.

- [ ] **Step 3: Add jumps to the fighter**

What changes: a new `_can_short_hop` field (reset in `spawn_at`); `tick()` calls the new `_air_actions()` in `AIR`; `_ground_actions()` starts a ground jump on `jump_pressed`; `_air_actions()` does the double jump (once, sets horizontal speed to `move_x × air_speed`) and the short-hop cut (once, only while rising from a ground jump); landing restores `jumps_left`.

Replace the whole of `super-mms-bros/fighter/fighter.gd` with:

```gdscript
class_name Fighter
extends CharacterBody2D
## A fighter: body, movement and state machine (docs/specs/fighter.md).
## The Match advances it one tick at a time with tick(); it has no _physics_process of its own.

enum State { IDLE, RUN, AIR }

## One tick of game time, in seconds (the game runs at 60 ticks per second).
const DELTA := 1.0 / 60.0

@export var stats: FighterStats

## 0 for P1, 1 for P2. Set by the Match.
var player_index: int = 0
## 1 = facing right, -1 = facing left.
var facing: int = 1
var state: State = State.IDLE
## Ticks spent in the current state; 1 on the tick the state is entered.
var state_frame: int = 0
var jumps_left: int = 0

## True from a ground jump until the fighter stops rising or releases jump.
var _can_short_hop: bool = false


## Puts the fighter at a spawn point, standing still: IDLE, jumps restored.
func spawn_at(spawn_position: Vector2, spawn_facing: int) -> void:
	global_position = spawn_position
	facing = spawn_facing
	velocity = Vector2.ZERO
	state = State.IDLE
	state_frame = 0
	jumps_left = stats.max_air_jumps
	_can_short_hop = false


## Advances the fighter by one tick. Must run inside a physics frame, because move_and_slide()
## takes its time step from the physics engine (which is 1/60 s there).
func tick(input: FighterInput) -> void:
	assert(Engine.is_in_physics_frame(), "Fighter.tick() must run inside a physics frame")
	if state == State.AIR:
		_air_actions(input)
	else:
		_ground_actions(input)

	if state == State.AIR:
		_steer(input.move_x, stats.air_speed, stats.air_accel, stats.air_friction)
	else:
		_steer(input.move_x, stats.run_speed, stats.ground_accel, stats.ground_friction)
	if state == State.AIR or not is_on_floor():
		velocity.y = minf(velocity.y + stats.gravity * DELTA, stats.max_fall_speed)

	move_and_slide()

	_after_move(input)
	state_frame += 1


## IDLE/RUN: jump, or run/stand.
func _ground_actions(input: FighterInput) -> void:
	if input.jump_pressed:
		velocity.y = -stats.jump_velocity
		_can_short_hop = true
		_set_state(State.AIR)
	elif input.move_x != 0.0:
		facing = 1 if input.move_x > 0.0 else -1
		_set_state(State.RUN)
	else:
		_set_state(State.IDLE)


## AIR: double jump, or cut a ground jump short.
func _air_actions(input: FighterInput) -> void:
	if input.jump_pressed and jumps_left > 0:
		velocity.y = -stats.double_jump_velocity
		velocity.x = input.move_x * stats.air_speed
		jumps_left -= 1
		_can_short_hop = false
	elif _can_short_hop:
		if velocity.y >= 0.0:
			_can_short_hop = false
		elif not input.jump_held:
			velocity.y *= stats.short_hop_cut
			_can_short_hop = false


## Moves horizontal speed toward `move_x × top_speed` at `accel`, or toward 0 at `friction`.
func _steer(move_x: float, top_speed: float, accel: float, friction: float) -> void:
	if move_x != 0.0:
		velocity.x = move_toward(velocity.x, move_x * top_speed, accel * DELTA)
	else:
		velocity.x = move_toward(velocity.x, 0.0, friction * DELTA)


## Landing and walking off ledges, decided from where move_and_slide() left the fighter.
func _after_move(input: FighterInput) -> void:
	if state == State.AIR:
		if is_on_floor():
			jumps_left = stats.max_air_jumps
			_can_short_hop = false
			_set_state(State.RUN if input.move_x != 0.0 else State.IDLE)
	elif not is_on_floor():
		# Walked off a ledge: the double jump is still there.
		_set_state(State.AIR)


func _set_state(new_state: State) -> void:
	if new_state != state:
		state = new_state
		state_frame = 0
```

- [ ] **Step 4: Run the tests to verify they pass**

Run: `godot --headless --path super-mms-bros -s res://addons/gut/gut_cmdln.gd; echo "exit=$?"`
Expected: `Passing Tests 41`, `---- All tests passed! ----`, `exit=0`.

- [ ] **Step 5: Commit**

```bash
git add super-mms-bros/fighter super-mms-bros/tests
git commit -m "Add ground jump, short hop and double jump

Co-Authored-By: Claude Opus 5 <noreply@anthropic.com>"
```

---

### Task 7: Pass-through platforms — drop through with down

Jumping up through a platform and landing on it already works (the platforms are one-way and the fighter lands on any floor); this task adds dropping through. `down_pressed` while standing on a pass-through platform turns off collision layer 2 in the fighter's mask for `drop_through_frames` ticks, counting the drop tick. To tell a pass-through platform from the main platform, the fighter briefly sets its mask to layer 2 only and uses `test_move()` to check for a collision 1 px below its feet.

**Files:**
- Modify: `super-mms-bros/tests/test_fighter_movement.gd` (append)
- Modify: `super-mms-bros/fighter/fighter.gd` (full replacement below)

**Interfaces:**
- Consumes: the Task 5–6 `Fighter` API and test helpers (`_run_until_landed`, `_jump`, `_hold_jump`).
- Produces: `Fighter.STAGE_PLATFORM_LAYER := 2`; drop-through in `Fighter.tick()`; `spawn_at()` also restores the platform layer in the mask.

- [ ] **Step 1: Write the failing tests**

Append to the end of `super-mms-bros/tests/test_fighter_movement.gd`:

```gdscript
# --- Pass-through platforms -------------------------------------------------------------------


func test_jumps_up_through_a_platform_and_lands_on_it() -> void:
	await _land_on_left_platform()
	assert_eq(_fighter.state, Fighter.State.IDLE)
	assert_true(_fighter.is_on_floor())
	assert_almost_eq(_fighter.position.y, PLATFORM_Y, TOLERANCE)


func test_down_drops_through_a_platform() -> void:
	await _land_on_left_platform()
	_run(_down(), 1)
	assert_eq(_fighter.state, Fighter.State.AIR)
	assert_false(_fighter.get_collision_mask_value(2), "ignoring pass-through platforms")
	_run_until_landed(_idle())
	assert_eq(_fighter.state, Fighter.State.IDLE)
	assert_almost_eq(_fighter.position.y, FLOOR_Y, TOLERANCE, "landed on the main platform")
	assert_true(_fighter.get_collision_mask_value(2), "pass-through platforms are solid again")


func test_platforms_are_ignored_for_drop_through_frames_ticks() -> void:
	await _land_on_left_platform()
	_run(_down(), 1)
	_run(_idle(), _stats.drop_through_frames - 2)
	assert_false(_fighter.get_collision_mask_value(2), "still ignored after %d ticks" % (_stats.drop_through_frames - 1))
	_run(_idle(), 1)
	assert_true(_fighter.get_collision_mask_value(2), "solid again after %d ticks" % _stats.drop_through_frames)


func test_down_on_the_main_platform_does_nothing() -> void:
	await _start_at(Vector2(160, 128))
	_run(_idle(), 1)
	_run(_down(), 1)
	assert_eq(_fighter.state, Fighter.State.IDLE)
	assert_true(_fighter.get_collision_mask_value(2))
	assert_almost_eq(_fighter.position.y, FLOOR_Y, TOLERANCE)


func _down() -> FighterInput:
	var input := FighterInput.new()
	input.down_pressed = true
	return input


func _land_on_left_platform() -> void:
	await _start_at(UNDER_LEFT_PLATFORM)
	_run(_jump(), 1)
	_run_until_landed(_hold_jump())
```

- [ ] **Step 2: Run the tests to verify they fail**

Run: `godot --headless --path super-mms-bros -s res://addons/gut/gut_cmdln.gd; echo "exit=$?"`
Expected: `Tests 45`, `Passing Tests 43`, `Failing Tests 2`: `test_down_drops_through_a_platform` and `test_platforms_are_ignored_for_drop_through_frames_ticks`; `exit=1`.

- [ ] **Step 3: Add dropping through to the fighter**

What changes: `STAGE_PLATFORM_LAYER` constant and `_drop_through_frames_left` field; `spawn_at()` resets both; `_ground_actions()` drops on `down_pressed` when `_is_on_pass_through_platform()`; `tick()` calls `_count_down_drop_through()` after the move, which turns layer 2 back on when the count reaches 0.

Replace the whole of `super-mms-bros/fighter/fighter.gd` with:

```gdscript
class_name Fighter
extends CharacterBody2D
## A fighter: body, movement and state machine (docs/specs/fighter.md).
## The Match advances it one tick at a time with tick(); it has no _physics_process of its own.

enum State { IDLE, RUN, AIR }

## One tick of game time, in seconds (the game runs at 60 ticks per second).
const DELTA := 1.0 / 60.0
## Collision layer of pass-through platforms (docs/specs/architecture.md#collision-layers).
const STAGE_PLATFORM_LAYER := 2

@export var stats: FighterStats

## 0 for P1, 1 for P2. Set by the Match.
var player_index: int = 0
## 1 = facing right, -1 = facing left.
var facing: int = 1
var state: State = State.IDLE
## Ticks spent in the current state; 1 on the tick the state is entered.
var state_frame: int = 0
var jumps_left: int = 0

## True from a ground jump until the fighter stops rising or releases jump.
var _can_short_hop: bool = false
## Ticks left before pass-through platforms become solid again after dropping through one.
var _drop_through_frames_left: int = 0


## Puts the fighter at a spawn point, standing still: IDLE, jumps restored, platforms solid.
func spawn_at(spawn_position: Vector2, spawn_facing: int) -> void:
	global_position = spawn_position
	facing = spawn_facing
	velocity = Vector2.ZERO
	state = State.IDLE
	state_frame = 0
	jumps_left = stats.max_air_jumps
	_can_short_hop = false
	_drop_through_frames_left = 0
	set_collision_mask_value(STAGE_PLATFORM_LAYER, true)


## Advances the fighter by one tick. Must run inside a physics frame, because move_and_slide()
## takes its time step from the physics engine (which is 1/60 s there).
func tick(input: FighterInput) -> void:
	assert(Engine.is_in_physics_frame(), "Fighter.tick() must run inside a physics frame")
	if state == State.AIR:
		_air_actions(input)
	else:
		_ground_actions(input)

	if state == State.AIR:
		_steer(input.move_x, stats.air_speed, stats.air_accel, stats.air_friction)
	else:
		_steer(input.move_x, stats.run_speed, stats.ground_accel, stats.ground_friction)
	if state == State.AIR or not is_on_floor():
		velocity.y = minf(velocity.y + stats.gravity * DELTA, stats.max_fall_speed)

	move_and_slide()

	_after_move(input)
	_count_down_drop_through()
	state_frame += 1


## IDLE/RUN: jump, drop through a platform, or run/stand.
func _ground_actions(input: FighterInput) -> void:
	if input.jump_pressed:
		velocity.y = -stats.jump_velocity
		_can_short_hop = true
		_set_state(State.AIR)
	elif input.down_pressed and _is_on_pass_through_platform():
		set_collision_mask_value(STAGE_PLATFORM_LAYER, false)
		_drop_through_frames_left = stats.drop_through_frames
		_set_state(State.AIR)
	elif input.move_x != 0.0:
		facing = 1 if input.move_x > 0.0 else -1
		_set_state(State.RUN)
	else:
		_set_state(State.IDLE)


## AIR: double jump, or cut a ground jump short.
func _air_actions(input: FighterInput) -> void:
	if input.jump_pressed and jumps_left > 0:
		velocity.y = -stats.double_jump_velocity
		velocity.x = input.move_x * stats.air_speed
		jumps_left -= 1
		_can_short_hop = false
	elif _can_short_hop:
		if velocity.y >= 0.0:
			_can_short_hop = false
		elif not input.jump_held:
			velocity.y *= stats.short_hop_cut
			_can_short_hop = false


## Moves horizontal speed toward `move_x × top_speed` at `accel`, or toward 0 at `friction`.
func _steer(move_x: float, top_speed: float, accel: float, friction: float) -> void:
	if move_x != 0.0:
		velocity.x = move_toward(velocity.x, move_x * top_speed, accel * DELTA)
	else:
		velocity.x = move_toward(velocity.x, 0.0, friction * DELTA)


## Landing and walking off ledges, decided from where move_and_slide() left the fighter.
func _after_move(input: FighterInput) -> void:
	if state == State.AIR:
		if is_on_floor():
			jumps_left = stats.max_air_jumps
			_can_short_hop = false
			_set_state(State.RUN if input.move_x != 0.0 else State.IDLE)
	elif not is_on_floor():
		# Walked off a ledge: the double jump is still there.
		_set_state(State.AIR)


func _count_down_drop_through() -> void:
	if _drop_through_frames_left > 0:
		_drop_through_frames_left -= 1
		if _drop_through_frames_left == 0:
			set_collision_mask_value(STAGE_PLATFORM_LAYER, true)


## True if the fighter stands on a pass-through platform (not on solid ground).
func _is_on_pass_through_platform() -> bool:
	if not is_on_floor():
		return false
	# Look 1 px down, colliding with pass-through platforms only.
	var saved_mask := collision_mask
	collision_mask = 0
	set_collision_mask_value(STAGE_PLATFORM_LAYER, true)
	var platform_below := test_move(global_transform, Vector2(0, 1))
	collision_mask = saved_mask
	return platform_below


func _set_state(new_state: State) -> void:
	if new_state != state:
		state = new_state
		state_frame = 0
```

- [ ] **Step 4: Run the tests to verify they pass**

Run: `godot --headless --path super-mms-bros -s res://addons/gut/gut_cmdln.gd; echo "exit=$?"`
Expected: `Passing Tests 45`, `---- All tests passed! ----`, `exit=0`.

- [ ] **Step 5: Commit**

```bash
git add super-mms-bros/fighter super-mms-bros/tests
git commit -m "Drop through pass-through platforms with down

Co-Authored-By: Claude Opus 5 <noreply@anthropic.com>"
```

---

### Task 8: Match scene, tick loop and placeholder visuals

Replaces the M1 placeholder main scene with the real match: the Battlefield, one fighter (P1, keyboard/gamepad) and a fixed camera. The tick order is the M2 subset of the spec's: ask every controller for input (P1 first), then tick every fighter (P1 first), then count the tick. The snapshot, phases, hits and KOs are added in M3–M4.

**Files:**
- Create: `super-mms-bros/tests/test_match.gd`
- Create: `super-mms-bros/match/match.gd`, `super-mms-bros/fighter/fighter_visuals.gd`
- Modify: `super-mms-bros/match/match.tscn` (full replacement; keeps its `uid`, which `project.godot` uses to find the main scene), `super-mms-bros/fighter/fighter.tscn` (adds the `Visuals` node)

**Interfaces:**
- Consumes: `Fighter` (Tasks 5–7), `Stage` (Task 4), `KeyboardController`/`ScriptedController` (Task 2).
- Produces: `Match` (`Node2D`): `@export var auto_step: bool = true`, `var tick: int`, `step() -> void`, `reset() -> void`, `get_fighter(player_index: int) -> Fighter`, `get_controller(player_index: int) -> Controller`, `set_controller(player_index: int, controller: Controller) -> void`. Scene nodes `Stage`, `Fighters/P1`, `Camera2D`. `FighterVisuals` (`Node2D`, child `Visuals` of the fighter).

- [ ] **Step 1: Write the failing tests**

Create `super-mms-bros/tests/test_match.gd`:

```gdscript
extends GutTest
## The Match drives every tick (docs/specs/architecture.md#tick-order). M2: one fighter, no rules.

const MATCH_SCENE := preload("res://match/match.tscn")

var _match: Match


## Adds a match to the tree. With `auto_step` off, the test decides when ticks happen.
func _add_match(auto_step: bool) -> void:
	_match = MATCH_SCENE.instantiate()
	_match.auto_step = auto_step
	add_child_autofree(_match)


func test_scene_has_stage_fighter_and_camera() -> void:
	_add_match(false)
	assert_true(_match.get_node("Stage") is Stage)
	assert_eq(_match.get_node("Fighters").get_child_count(), 1, "M2 has one fighter")
	assert_true(_match.get_fighter(0) is Fighter)
	var camera := _match.get_node("Camera2D") as Camera2D
	assert_eq(camera.position, Vector2(160, 90))


func test_p1_starts_at_its_spawn_point() -> void:
	_add_match(false)
	var p1 := _match.get_fighter(0)
	assert_eq(_match.tick, 0)
	assert_eq(p1.player_index, 0)
	assert_eq(p1.position, Vector2(112, 128))
	assert_eq(p1.facing, 1)
	assert_eq(p1.state, Fighter.State.IDLE)


func test_p1_is_played_from_the_keyboard() -> void:
	_add_match(false)
	assert_true(_match.get_controller(0) is KeyboardController)


func test_step_drives_the_fighter_with_its_controller() -> void:
	_add_match(false)
	var right := FighterInput.new()
	right.move_x = 1.0
	var inputs: Array[FighterInput] = []
	for i in 10:
		inputs.append(right)
	_match.set_controller(0, ScriptedController.new(inputs))
	await wait_physics_frames(1)
	for i in 10:
		_match.step()
	assert_eq(_match.tick, 10)
	assert_eq(_match.get_fighter(0).state, Fighter.State.RUN)
	assert_gt(_match.get_fighter(0).position.x, 112.0, "moved right")


func test_without_auto_step_nothing_happens_by_itself() -> void:
	_add_match(false)
	await wait_physics_frames(5)
	assert_eq(_match.tick, 0)


func test_auto_step_ticks_once_per_physics_frame() -> void:
	_add_match(true)
	_match.set_controller(0, ScriptedController.new())
	await wait_physics_frames(5)
	assert_between(_match.tick, 5, 7)


func test_reset_puts_everything_back() -> void:
	_add_match(false)
	var right := FighterInput.new()
	right.move_x = 1.0
	_match.set_controller(0, ScriptedController.new([right, right, right]))
	await wait_physics_frames(1)
	for i in 3:
		_match.step()
	_match.reset()
	var p1 := _match.get_fighter(0)
	assert_eq(_match.tick, 0)
	assert_eq(p1.position, Vector2(112, 128))
	assert_eq(p1.velocity, Vector2.ZERO)
	assert_eq(p1.state, Fighter.State.IDLE)
	_match.step()
	assert_gt(p1.velocity.x, 0.0, "the controller was reset and plays its inputs again")
```

- [ ] **Step 2: Run the tests to verify they fail**

Run: `godot --headless --path super-mms-bros -s res://addons/gut/gut_cmdln.gd; echo "exit=$?"`
Expected: parse errors for `test_match.gd` (`Could not find type "Match"`); `Tests 45`, `Passing Tests 44`, `Failing Tests 1`; `exit=1`.

- [ ] **Step 3: Write the `Match` script**

Create `super-mms-bros/match/match.gd`:

```gdscript
class_name Match
extends Node2D
## Runs a match: owns the tick loop and drives every fighter (docs/specs/architecture.md).
## M2: one keyboard-controlled fighter on the stage. Rules (stocks, KOs, phases) come in M4.

## When on, the Match steps once per physics frame. Tests turn it off and call step() themselves.
@export var auto_step: bool = true

## Ticks since the match started.
var tick: int = 0

var _fighters: Array[Fighter] = []
var _controllers: Array[Controller] = []

@onready var _stage := $Stage as Stage


func _ready() -> void:
	for child in $Fighters.get_children():
		var fighter := child as Fighter
		fighter.player_index = _fighters.size()
		_fighters.append(fighter)
		_controllers.append(KeyboardController.new())
	reset()


func _physics_process(_delta: float) -> void:
	if auto_step:
		step()


## Advances the game by one tick (docs/specs/architecture.md#tick-order).
## Must run inside a physics frame (see Fighter.tick()).
func step() -> void:
	var inputs: Array[FighterInput] = []
	for controller in _controllers:
		inputs.append(controller.get_input(null))
	for i in _fighters.size():
		_fighters[i].tick(inputs[i])
	tick += 1


## Puts everything back to the start of a match, without reloading the scene.
func reset() -> void:
	tick = 0
	for i in _fighters.size():
		_fighters[i].spawn_at(_stage.get_spawn_position(i), _stage.get_spawn_facing(i))
		_controllers[i].reset()


func get_fighter(player_index: int) -> Fighter:
	return _fighters[player_index]


func get_controller(player_index: int) -> Controller:
	return _controllers[player_index]


func set_controller(player_index: int, controller: Controller) -> void:
	_controllers[player_index] = controller
```

- [ ] **Step 4: Replace the main scene**

Replace the whole of `super-mms-bros/match/match.tscn` with (the `uid` in the first line must stay `uid://drv5qoyqdrc1`):

```
[gd_scene format=3 uid="uid://drv5qoyqdrc1"]

[ext_resource type="Script" path="res://match/match.gd" id="1_match"]
[ext_resource type="PackedScene" path="res://stage/battlefield.tscn" id="2_stage"]
[ext_resource type="PackedScene" path="res://fighter/fighter.tscn" id="3_fighter"]

[node name="Match" type="Node2D"]
script = ExtResource("1_match")

[node name="Stage" parent="." instance=ExtResource("2_stage")]

[node name="Fighters" type="Node2D" parent="."]

[node name="P1" parent="Fighters" instance=ExtResource("3_fighter")]

[node name="Camera2D" type="Camera2D" parent="."]
position = Vector2(160, 90)
```

- [ ] **Step 5: Write the placeholder visuals**

Create `super-mms-bros/fighter/fighter_visuals.gd`:

```gdscript
class_name FighterVisuals
extends Node2D
## Draws the parent Fighter as placeholder rectangles (docs/specs/fighter.md#placeholder-visuals).
## Only reads the fighter's state; never changes it.

## Body colors by player index (Sweetie 16 palette, docs/specs/controls-and-display.md).
const PLAYER_COLORS: Array[Color] = [Color("#b13e53"), Color("#3b5dc9")]
const LIGHT_COLOR := Color("#f4f4f4")
const BODY_RECT := Rect2(-8, -24, 16, 24)
const EYE_SIZE := Vector2(3, 3)

@onready var _fighter := get_parent() as Fighter


func _process(_delta: float) -> void:
	queue_redraw()


func _draw() -> void:
	draw_rect(BODY_RECT, PLAYER_COLORS[_fighter.player_index])
	# The eye sits near the top of the body, on the side the fighter faces.
	var eye_x := 3.0 if _fighter.facing == 1 else -6.0
	draw_rect(Rect2(Vector2(eye_x, -21), EYE_SIZE), LIGHT_COLOR)
```

Replace the whole of `super-mms-bros/fighter/fighter.tscn` with (adds the visuals script and the `Visuals` node):

```
[gd_scene format=3]

[ext_resource type="Script" path="res://fighter/fighter.gd" id="1_fighter"]
[ext_resource type="Resource" path="res://fighter/default_stats.tres" id="2_stats"]
[ext_resource type="Script" path="res://fighter/fighter_visuals.gd" id="3_visuals"]

[sub_resource type="RectangleShape2D" id="RectangleShape2D_body"]
size = Vector2(16, 24)

[node name="Fighter" type="CharacterBody2D"]
collision_layer = 4
collision_mask = 3
script = ExtResource("1_fighter")
stats = ExtResource("2_stats")

[node name="BodyShape" type="CollisionShape2D" parent="."]
position = Vector2(0, -12)
shape = SubResource("RectangleShape2D_body")

[node name="Visuals" type="Node2D" parent="."]
script = ExtResource("3_visuals")
```

- [ ] **Step 6: Import and run the tests to verify they pass**

```bash
godot --headless --path super-mms-bros --import
godot --headless --path super-mms-bros -s res://addons/gut/gut_cmdln.gd; echo "exit=$?"
```

Expected: `Passing Tests 52`, `---- All tests passed! ----`, `exit=0`.

- [ ] **Step 7: Run the game headless to check for runtime errors**

Run: `godot --headless --path super-mms-bros --quit-after 120; echo "exit=$?"`
Expected: only the Godot version banner, no `SCRIPT ERROR`, `exit=0`. (`_draw()` runs headless too, so errors in the visuals would show here.)

- [ ] **Step 8: Commit**

```bash
git add super-mms-bros/match super-mms-bros/fighter super-mms-bros/tests
git status --short   # must not list .godot/
git commit -m "Add match scene driving one keyboard-controlled fighter

Co-Authored-By: Claude Opus 5 <noreply@anthropic.com>"
```

---

### Task 9: Try it with the user

No code. M2 is done when the user has played it.

- [ ] **Step 1: The user plays**

Ask the user to run `godot --path super-mms-bros` and try, with keyboard and (if they have one) a gamepad:
- **A/D** (stick/d-pad): run left and right; the eye turns to the direction of travel; the fighter doesn't turn in the air.
- **W or Space** (A/Cross): a held jump; a quick tap for a short hop; a second jump in the air, only once until landing.
- Jump up through the three gray platforms and land on them; **S** (down) on a platform drops through it; on the main platform it does nothing.
- Walk off the edge: the double jump still works; falling off the stage just keeps falling (KOs come in M4). Close the window to quit.
- Optional: **Debug → Visible Collision Shapes** in the editor's menu, then run from the editor, to see the collision boxes.

Ask how it feels (speeds, jump heights, air control). Record requested changes as values for `default_stats.tres`; tuning happens in M6 unless something is badly off.

- [ ] **Step 2: The user looks at the new pieces in the editor**

Ask the user to run `godot --path super-mms-bros --editor` and open:
- `fighter/default_stats.tres` in the Inspector (the grouped stats);
- `fighter/fighter.tscn` (the body shape, collision layer and mask in the Inspector);
- `stage/battlefield.tscn` (platform bodies, the one-way option on the platforms' collision shapes, the spawn markers);
- **Project → Project Settings → Layer Names → 2D Physics** (the five named layers).

Explain each briefly as they look (per `CLAUDE.md`, the user is learning the engine).

- [ ] **Step 3: If the editor changed files, commit them**

Opening the scenes in the editor may add `uid`/`unique_id` attributes to the hand-written `.tscn`/`.tres` files. Close the editor, run `git status --short`; if anything changed, run the test command again and commit:

```bash
git add super-mms-bros
git commit -m "Editor housekeeping after opening the M2 scenes

Co-Authored-By: Claude Opus 5 <noreply@anthropic.com>"
```
