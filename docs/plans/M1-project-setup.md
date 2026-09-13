# M1 — Project Setup Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** A Godot project that opens to an empty 320×180 pixel-perfect screen with crisp pixel text, has all Input Map actions, and runs a headless GUT test suite from the terminal.

**Architecture:** Settings are written into `project.godot` by small one-off GDScript tools run headless (then deleted — `project.godot` is the source of truth). GUT is vendored into `addons/gut/`. Each task adds GUT tests that assert the settings from the spec, so later changes that break them are caught.

**Tech Stack:** Godot 4.7.2 (standard build, `godot` on PATH), GDScript, GUT 9.7.1, Press Start 2P font (SIL OFL 1.1).

**Spec:** [`docs/specs/controls-and-display.md`](../specs/controls-and-display.md), [`docs/specs/testing.md`](../specs/testing.md), [`docs/specs/architecture.md`](../specs/architecture.md)

## Global Constraints

- Godot project root: `super-mms-bros/` (`res://`). Run every command from the repo root (`/home/mp/Desktop/SuperMMSBros`).
- Godot version: 4.7.2 standard build; GUT version: 9.7.1 (the release built for Godot 4.7).
- GDScript: official style guide, static typing everywhere, tabs for indentation.
- Resolution 320×180, window 1280×720, stretch `viewport` / `keep` / `integer`, texture filter Nearest, 2D transform snapping on, 60 physics ticks per second.
- Main scene: `res://match/match.tscn`, root node named `Match`.
- Input actions: `move_left`, `move_right`, `jump`, `down`, `attack`, `pause` — every event bound to all devices (`device = -1`).
- Commit `.uid` files that Godot generates next to scripts; never commit `.godot/`.
- Commit messages end with a blank line and `Co-Authored-By: Claude Opus 5 <noreply@anthropic.com>`. Don't push.

## File Structure

| Path | Responsibility |
|---|---|
| `super-mms-bros/addons/gut/` | GUT test framework (vendored, unmodified) |
| `super-mms-bros/.gutconfig.json` | Tells GUT where tests are and to exit when done |
| `super-mms-bros/tests/test_engine_version.gd` | Confirms the suite runs on Godot 4.7 |
| `super-mms-bros/tests/test_project_setup.gd` | Display, rendering, physics, main scene, font settings |
| `super-mms-bros/tests/test_input_map.gd` | Input Map actions, bindings, dead zones |
| `super-mms-bros/match/match.tscn` | Main scene (placeholder: a centered title label; replaced in M2) |
| `super-mms-bros/assets/fonts/PressStart2P-Regular.ttf` + `OFL.txt` | Pixel font and its license |
| `super-mms-bros/project.godot` | Modified by the one-off tools |
| `CLAUDE.md` | Record the test command |

The other folders from the architecture spec (`fighter/`, `controllers/`, `stage/`, `ui/`) are created by the milestones that first put files in them — git can't store empty folders.

---

### Task 1: Install GUT and run the first test

**Files:**
- Create: `super-mms-bros/addons/gut/` (copied from GUT v9.7.1)
- Create: `super-mms-bros/.gutconfig.json`
- Create: `super-mms-bros/tests/test_engine_version.gd`
- Modify: `CLAUDE.md` (the "Test command" line)

**Interfaces:**
- Produces: the test command `godot --headless --path super-mms-bros -s res://addons/gut/gut_cmdln.gd` (exit code 0 = all passed, 1 = failures). Test files are `super-mms-bros/tests/test_*.gd` extending `GutTest`.

- [ ] **Step 1: Write the first test**

Create `super-mms-bros/tests/test_engine_version.gd`:

```gdscript
extends GutTest
## The project targets Godot 4.7 (see CLAUDE.md).


func test_runs_on_godot_4_7() -> void:
	var version := Engine.get_version_info()
	assert_eq(version.major, 4)
	assert_eq(version.minor, 7)
```

- [ ] **Step 2: Run the test command to verify it fails**

Run: `godot --headless --path super-mms-bros -s res://addons/gut/gut_cmdln.gd; echo "exit=$?"`
Expected: an error that the script `res://addons/gut/gut_cmdln.gd` can't be loaded (GUT isn't installed yet), non-zero exit code.

- [ ] **Step 3: Install GUT 9.7.1**

```bash
TMP=$(mktemp -d)
git clone -q --depth 1 --branch v9.7.1 https://github.com/bitwes/Gut "$TMP/gut"
grep 'version="9.7.1"' "$TMP/gut/addons/gut/plugin.cfg"
mkdir -p super-mms-bros/addons
cp -r "$TMP/gut/addons/gut" super-mms-bros/addons/
rm -rf "$TMP"
```

Expected: the `grep` prints `version="9.7.1"`.

Create `super-mms-bros/.gutconfig.json`:

```json
{
	"dirs": ["res://tests/"],
	"include_subdirs": true,
	"should_exit": true,
	"log_level": 1
}
```

- [ ] **Step 4: Import the project and run the test to verify it passes**

```bash
godot --headless --path super-mms-bros --import
godot --headless --path super-mms-bros -s res://addons/gut/gut_cmdln.gd; echo "exit=$?"
```

Expected: the run summary shows `Passing Tests 1`, then `---- All tests passed! ----`, `exit=0`.

- [ ] **Step 5: Record the test command in `CLAUDE.md`**

In `CLAUDE.md`, replace the line

```
Test command: set up in M1 — record it here when it exists.
```

with

````
Run the tests (headless; exit code 0 = all passed):

```bash
godot --headless --path super-mms-bros -s res://addons/gut/gut_cmdln.gd
```
````

- [ ] **Step 6: Commit**

```bash
git add super-mms-bros/addons super-mms-bros/.gutconfig.json super-mms-bros/tests CLAUDE.md
git status --short   # must not list anything under .godot/
git commit -m "Add GUT 9.7.1 test framework and first test

Co-Authored-By: Claude Opus 5 <noreply@anthropic.com>"
```

---

### Task 2: Display settings, main scene and pixel font

**Files:**
- Create: `super-mms-bros/tests/test_project_setup.gd`
- Create: `super-mms-bros/match/match.tscn`
- Create: `super-mms-bros/assets/fonts/PressStart2P-Regular.ttf`, `super-mms-bros/assets/fonts/OFL.txt`
- Create, run, then delete: `super-mms-bros/tools/apply_display_settings.gd`
- Modify: `super-mms-bros/project.godot` (via the tool), `super-mms-bros/assets/fonts/PressStart2P-Regular.ttf.import` (generated, then edited)

**Interfaces:**
- Consumes: the test command from Task 1.
- Produces: main scene `res://match/match.tscn` with root `Match` (`Node2D`); default UI font `res://assets/fonts/PressStart2P-Regular.ttf` (native size 8 px); background clear color `#1a1c2c`.

- [ ] **Step 1: Write the failing tests**

Create `super-mms-bros/tests/test_project_setup.gd`:

```gdscript
extends GutTest
## Display, rendering and font settings from docs/specs/controls-and-display.md.

const FONT_PATH := "res://assets/fonts/PressStart2P-Regular.ttf"


func test_display_settings() -> void:
	assert_eq(ProjectSettings.get_setting("display/window/size/viewport_width"), 320)
	assert_eq(ProjectSettings.get_setting("display/window/size/viewport_height"), 180)
	assert_eq(ProjectSettings.get_setting("display/window/size/window_width_override"), 1280)
	assert_eq(ProjectSettings.get_setting("display/window/size/window_height_override"), 720)
	assert_eq(ProjectSettings.get_setting("display/window/stretch/mode"), "viewport")
	assert_eq(ProjectSettings.get_setting("display/window/stretch/aspect"), "keep")
	assert_eq(ProjectSettings.get_setting("display/window/stretch/scale_mode"), "integer")


func test_pixel_art_rendering() -> void:
	assert_eq(ProjectSettings.get_setting("rendering/textures/canvas_textures/default_texture_filter"), 0,
		"default texture filter should be Nearest")
	assert_true(ProjectSettings.get_setting("rendering/2d/snap/snap_2d_transforms_to_pixel"))
	assert_eq(ProjectSettings.get_setting("rendering/environment/defaults/default_clear_color"),
		Color("#1a1c2c"))


func test_physics_runs_at_60_ticks() -> void:
	assert_eq(ProjectSettings.get_setting("physics/common/physics_ticks_per_second"), 60)


func test_main_scene_loads() -> void:
	var path: String = ProjectSettings.get_setting("application/run/main_scene")
	assert_eq(path, "res://match/match.tscn")
	var scene := load(path) as PackedScene
	assert_not_null(scene, "main scene should load")
	if scene == null:
		return
	var root := scene.instantiate()
	assert_eq(root.name, &"Match")
	root.free()


func test_pixel_font_is_default_and_crisp() -> void:
	assert_eq(ProjectSettings.get_setting("gui/theme/custom_font"), FONT_PATH)
	var font := load(FONT_PATH) as FontFile
	assert_not_null(font, "font should load")
	if font == null:
		return
	assert_eq(font.antialiasing, TextServer.FONT_ANTIALIASING_NONE)
	assert_eq(font.hinting, TextServer.HINTING_NONE)
	assert_eq(font.subpixel_positioning, TextServer.SUBPIXEL_POSITIONING_DISABLED)
```

- [ ] **Step 2: Run the tests to verify they fail**

Run: `godot --headless --path super-mms-bros -s res://addons/gut/gut_cmdln.gd; echo "exit=$?"`
Expected: the run summary shows `Tests 6`, `Passing Tests 2`, `Failing Tests 4` — `test_runs_on_godot_4_7` and `test_physics_runs_at_60_ticks` pass (60 is Godot's default); `test_display_settings`, `test_pixel_art_rendering`, `test_main_scene_loads` and `test_pixel_font_is_default_and_crisp` fail; `exit=1`. Load errors for the missing scene and font are expected.

- [ ] **Step 3: Add the font and the main scene**

```bash
mkdir -p super-mms-bros/assets/fonts super-mms-bros/match
curl -sL -o super-mms-bros/assets/fonts/PressStart2P-Regular.ttf \
  https://raw.githubusercontent.com/google/fonts/main/ofl/pressstart2p/PressStart2P-Regular.ttf
curl -sL -o super-mms-bros/assets/fonts/OFL.txt \
  https://raw.githubusercontent.com/google/fonts/main/ofl/pressstart2p/OFL.txt
file super-mms-bros/assets/fonts/PressStart2P-Regular.ttf
head -3 super-mms-bros/assets/fonts/OFL.txt
```

Expected: `TrueType Font data …`; the license starts with `Copyright 2012 The Press Start 2P Project Authors` and mentions `SIL Open Font License, Version 1.1`.

Create `super-mms-bros/match/match.tscn` (a placeholder — M2 replaces the label with the real match):

```
[gd_scene format=3]

[node name="Match" type="Node2D"]

[node name="TitleLabel" type="Label" parent="."]
offset_right = 320.0
offset_bottom = 180.0
text = "SUPER MMS BROS"
horizontal_alignment = 1
vertical_alignment = 1
```

- [ ] **Step 4: Write and run the display settings tool**

Create `super-mms-bros/tools/apply_display_settings.gd`:

```gdscript
extends SceneTree
## One-off: writes M1 display settings into project.godot, then quits.
## Run: godot --headless --path super-mms-bros -s res://tools/apply_display_settings.gd


func _init() -> void:
	ProjectSettings.set_setting("display/window/size/viewport_width", 320)
	ProjectSettings.set_setting("display/window/size/viewport_height", 180)
	ProjectSettings.set_setting("display/window/size/window_width_override", 1280)
	ProjectSettings.set_setting("display/window/size/window_height_override", 720)
	ProjectSettings.set_setting("display/window/stretch/mode", "viewport")
	ProjectSettings.set_setting("display/window/stretch/aspect", "keep")
	ProjectSettings.set_setting("display/window/stretch/scale_mode", "integer")
	ProjectSettings.set_setting("rendering/textures/canvas_textures/default_texture_filter", 0)
	ProjectSettings.set_setting("rendering/2d/snap/snap_2d_transforms_to_pixel", true)
	ProjectSettings.set_setting("rendering/environment/defaults/default_clear_color", Color("#1a1c2c"))
	ProjectSettings.set_setting("physics/common/physics_ticks_per_second", 60)
	ProjectSettings.set_setting("application/run/main_scene", "res://match/match.tscn")
	ProjectSettings.set_setting("gui/theme/custom_font", "res://assets/fonts/PressStart2P-Regular.ttf")
	ProjectSettings.set_setting("editor_plugins/enabled", PackedStringArray(["res://addons/gut/plugin.cfg"]))

	var err := ProjectSettings.save()
	print("apply_display_settings: save -> ", error_string(err))
	quit(0 if err == OK else 1)
```

Run:

```bash
godot --headless --path super-mms-bros --import
godot --headless --path super-mms-bros -s res://tools/apply_display_settings.gd
git diff super-mms-bros/project.godot
```

Expected: `apply_display_settings: save -> OK`. The diff adds `run/main_scene`, the `[display]` window/stretch keys, `[editor_plugins]`, `[gui] theme/custom_font`, and the `[rendering]` filter/snap/clear-color keys. (Settings already at their default — `stretch/aspect="keep"`, 60 physics ticks — are not written to the file; that's normal.)

- [ ] **Step 5: Make the font import crisp**

The import step created `super-mms-bros/assets/fonts/PressStart2P-Regular.ttf.import` with smoothing on. Turn it off and reimport:

```bash
F=super-mms-bros/assets/fonts/PressStart2P-Regular.ttf.import
sed -i 's/^antialiasing=1$/antialiasing=0/; s/^hinting=3$/hinting=0/; s/^subpixel_positioning=4$/subpixel_positioning=0/' "$F"
grep -E '^(antialiasing|hinting|subpixel_positioning)=' "$F"
godot --headless --path super-mms-bros --import
```

Expected: the `grep` prints `antialiasing=0`, `hinting=0`, `subpixel_positioning=0`.

- [ ] **Step 6: Delete the tool**

```bash
rm -r super-mms-bros/tools
```

- [ ] **Step 7: Run the tests to verify they pass**

Run: `godot --headless --path super-mms-bros -s res://addons/gut/gut_cmdln.gd; echo "exit=$?"`
Expected: the run summary shows `Passing Tests 6`, then `---- All tests passed! ----`, `exit=0`.

Also check the game starts without errors:

Run: `godot --headless --path super-mms-bros --quit-after 30; echo "exit=$?"`
Expected: only the Godot version banner, `exit=0`.

- [ ] **Step 8: Commit**

```bash
git add super-mms-bros/project.godot super-mms-bros/match super-mms-bros/assets super-mms-bros/tests
git status --short   # must not list .godot/ or tools/
git commit -m "Set up 320x180 pixel-perfect display, main scene and pixel font

Co-Authored-By: Claude Opus 5 <noreply@anthropic.com>"
```

---

### Task 3: Input Map

**Files:**
- Create: `super-mms-bros/tests/test_input_map.gd`
- Create, run, then delete: `super-mms-bros/tools/apply_input_map.gd`
- Modify: `super-mms-bros/project.godot` (via the tool)

**Interfaces:**
- Consumes: the test command from Task 1.
- Produces: Input Map actions `move_left`, `move_right`, `jump`, `down`, `attack`, `pause` (used by `KeyboardController` in M2 and the pause menu in M4).

- [ ] **Step 1: Write the failing tests**

Create `super-mms-bros/tests/test_input_map.gd`:

```gdscript
extends GutTest
## Input Map from docs/specs/controls-and-display.md.

const ACTIONS := ["move_left", "move_right", "jump", "down", "attack", "pause"]


func test_actions_exist() -> void:
	for action: String in ACTIONS:
		assert_true(InputMap.has_action(action), "missing action: %s" % action)


func test_keyboard_bindings() -> void:
	_assert_keys("move_left", [KEY_A, KEY_LEFT])
	_assert_keys("move_right", [KEY_D, KEY_RIGHT])
	_assert_keys("jump", [KEY_W, KEY_UP, KEY_SPACE])
	_assert_keys("down", [KEY_S, KEY_DOWN])
	_assert_keys("attack", [KEY_J, KEY_Z])
	_assert_keys("pause", [KEY_ESCAPE])


func test_gamepad_buttons() -> void:
	_assert_buttons("move_left", [JOY_BUTTON_DPAD_LEFT])
	_assert_buttons("move_right", [JOY_BUTTON_DPAD_RIGHT])
	_assert_buttons("jump", [JOY_BUTTON_A])
	_assert_buttons("down", [JOY_BUTTON_DPAD_DOWN])
	_assert_buttons("attack", [JOY_BUTTON_X])
	_assert_buttons("pause", [JOY_BUTTON_START])


func test_gamepad_stick() -> void:
	_assert_axis("move_left", JOY_AXIS_LEFT_X, -1.0)
	_assert_axis("move_right", JOY_AXIS_LEFT_X, 1.0)
	_assert_axis("down", JOY_AXIS_LEFT_Y, 1.0)


func test_deadzones() -> void:
	assert_almost_eq(InputMap.action_get_deadzone("move_left"), 0.2, 0.001)
	assert_almost_eq(InputMap.action_get_deadzone("move_right"), 0.2, 0.001)
	assert_almost_eq(InputMap.action_get_deadzone("down"), 0.5, 0.001)


func test_bindings_work_for_every_device() -> void:
	for action: String in ACTIONS:
		for event: InputEvent in InputMap.action_get_events(action):
			assert_eq(event.device, -1, "%s: %s should listen to all devices" % [action, event])


func _assert_keys(action: String, keys: Array) -> void:
	var found: Array = []
	for event: InputEvent in InputMap.action_get_events(action):
		if event is InputEventKey:
			found.append(event.physical_keycode)
	for key: Key in keys:
		assert_has(found, key, "%s should be bound to %s" % [action, OS.get_keycode_string(key)])


func _assert_buttons(action: String, buttons: Array) -> void:
	var found: Array = []
	for event: InputEvent in InputMap.action_get_events(action):
		if event is InputEventJoypadButton:
			found.append(event.button_index)
	for button: JoyButton in buttons:
		assert_has(found, button, "%s should be bound to joypad button %d" % [action, button])


func _assert_axis(action: String, axis: JoyAxis, value: float) -> void:
	for event: InputEvent in InputMap.action_get_events(action):
		if event is InputEventJoypadMotion and event.axis == axis and is_equal_approx(event.axis_value, value):
			pass_test("%s bound to axis %d (%s)" % [action, axis, value])
			return
	fail_test("%s should be bound to axis %d with value %s" % [action, axis, value])
```

- [ ] **Step 2: Run the tests to verify they fail**

Run: `godot --headless --path super-mms-bros -s res://addons/gut/gut_cmdln.gd; echo "exit=$?"`
Expected: the 6 tests from Tasks 1–2 pass; the tests in `test_input_map.gd` fail (actions missing) — `test_bindings_work_for_every_device` may instead be reported as having no asserts; `exit=1`. Errors from `InputMap` about nonexistent actions are expected at this point.

- [ ] **Step 3: Write and run the Input Map tool**

Create `super-mms-bros/tools/apply_input_map.gd`:

```gdscript
extends SceneTree
## One-off: writes the M1 Input Map into project.godot, then quits.
## Run: godot --headless --path super-mms-bros -s res://tools/apply_input_map.gd


func _init() -> void:
	_set_action("move_left", 0.2, [
		_key(KEY_A), _key(KEY_LEFT),
		_axis(JOY_AXIS_LEFT_X, -1.0), _button(JOY_BUTTON_DPAD_LEFT),
	])
	_set_action("move_right", 0.2, [
		_key(KEY_D), _key(KEY_RIGHT),
		_axis(JOY_AXIS_LEFT_X, 1.0), _button(JOY_BUTTON_DPAD_RIGHT),
	])
	_set_action("jump", 0.5, [
		_key(KEY_W), _key(KEY_UP), _key(KEY_SPACE),
		_button(JOY_BUTTON_A),
	])
	_set_action("down", 0.5, [
		_key(KEY_S), _key(KEY_DOWN),
		_axis(JOY_AXIS_LEFT_Y, 1.0), _button(JOY_BUTTON_DPAD_DOWN),
	])
	_set_action("attack", 0.5, [
		_key(KEY_J), _key(KEY_Z),
		_button(JOY_BUTTON_X),
	])
	_set_action("pause", 0.5, [
		_key(KEY_ESCAPE),
		_button(JOY_BUTTON_START),
	])

	var err := ProjectSettings.save()
	print("apply_input_map: save -> ", error_string(err))
	quit(0 if err == OK else 1)


func _set_action(action: String, deadzone: float, events: Array[InputEvent]) -> void:
	ProjectSettings.set_setting("input/" + action, {"deadzone": deadzone, "events": events})


# Physical keycodes follow key positions, so WASD stays WASD on non-QWERTY layouts.
func _key(physical_keycode: Key) -> InputEventKey:
	var event := InputEventKey.new()
	event.device = -1
	event.physical_keycode = physical_keycode
	return event


func _axis(axis: JoyAxis, value: float) -> InputEventJoypadMotion:
	var event := InputEventJoypadMotion.new()
	event.device = -1
	event.axis = axis
	event.axis_value = value
	return event


func _button(button: JoyButton) -> InputEventJoypadButton:
	var event := InputEventJoypadButton.new()
	event.device = -1
	event.button_index = button
	return event
```

`device = -1` matters: without it Godot ties each event to one specific device (keyboard events get device 16, gamepad events device 0 — only the first gamepad would work).

Run:

```bash
godot --headless --path super-mms-bros -s res://tools/apply_input_map.gd
grep -c '"device":-1' super-mms-bros/project.godot
```

Expected: `apply_input_map: save -> OK`; the count is `21` (one per binding).

- [ ] **Step 4: Delete the tool**

```bash
rm -r super-mms-bros/tools
```

- [ ] **Step 5: Run the tests to verify they pass**

Run: `godot --headless --path super-mms-bros -s res://addons/gut/gut_cmdln.gd; echo "exit=$?"`
Expected: the run summary shows `Passing Tests 12`, then `---- All tests passed! ----`, `exit=0`.

- [ ] **Step 6: Commit**

```bash
git add super-mms-bros/project.godot super-mms-bros/tests
git status --short   # must not list .godot/ or tools/
git commit -m "Add Input Map actions for keyboard and gamepad

Co-Authored-By: Claude Opus 5 <noreply@anthropic.com>"
```

---

### Task 4: Try it with the user

No code. M1 is done when the user has seen it work.

- [ ] **Step 1: The user runs the game**

Ask the user to run `godot --path super-mms-bros` and check:
- a 1280×720 window with a dark blue background and **"SUPER MMS BROS"** in sharp, blocky pixel letters in the center;
- resizing the window keeps the pixels square and sharp, adding black bars instead of stretching.

- [ ] **Step 2: The user opens the editor**

Ask the user to run `godot --path super-mms-bros --editor` and look at:
- **Project → Project Settings → Input Map** (with "Show Built-in Actions" turned off): the six actions and their bindings;
- the **GUT** panel at the bottom: press **Run All** — 12 tests pass;
- **Project → Project Settings → Display → Window**: the 320×180 viewport and stretch settings.

Explain each of these briefly as they look (per `CLAUDE.md`, the user is learning the engine).

- [ ] **Step 3: If the editor changed files, commit them**

Opening the editor can rewrite `project.godot` or `.import` files slightly. Run `git status --short`; if anything changed, run the test command again and commit:

```bash
git add super-mms-bros
git commit -m "Editor housekeeping after first open

Co-Authored-By: Claude Opus 5 <noreply@anthropic.com>"
```
