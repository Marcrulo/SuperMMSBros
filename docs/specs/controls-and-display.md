# Controls and Display

## Input Map actions

Gameplay and UI code refer only to these action names, never to specific keys or buttons.

| Action | Keyboard | Gamepad |
|---|---|---|
| `move_left` | A | left stick left, d-pad left |
| `move_right` | D | left stick right, d-pad right |
| `up` | W | left stick up, d-pad up |
| `down` | S | left stick down, d-pad down |
| `jump` | Space | A / Cross (bottom face button), Y / Triangle (top face button) |
| `attack` | J | X / Square (left face button) |
| `special` | K | B / Circle (right face button) |
| `shield` | L | right shoulder (RB / R1), left shoulder (LB / L1) |
| `pause` | Esc | Start |

- Keyboard play uses one layout: WASD to move and aim, Space to jump, J attack ("A"), K special
  ("B"), L shield. W does **not** jump, so up + attack is an up tilt, not a jump. The arrow keys are
  left free (e.g. for a second player if local multiplayer is added).
- Stick actions use a dead zone of 0.5 for `up` and `down` and 0.2 for `move_left`/`move_right`.
- Menus use Godot's built-in `ui_*` actions (arrows / d-pad to move focus, Enter / Space / A to
  press), which already support keyboard and gamepad; the game keys are added to them at startup
  (see [menus](menus.md#controls)).

## `KeyboardController`

Builds a `FighterInput` from the Input Map each tick (it is called from `Match.step()` inside the
physics frame, so `is_action_just_pressed` works per tick):

| Field | Source |
|---|---|
| `move_x` | `Input.get_axis("move_left", "move_right")` |
| `jump_pressed` / `jump_held` | `is_action_just_pressed("jump")` / `is_action_pressed("jump")` |
| `up_held` | `is_action_pressed("up")` |
| `down_pressed` / `down_held` | `is_action_just_pressed("down")` / `is_action_pressed("down")` |
| `attack_pressed` | `is_action_just_pressed("attack")` |
| `special_pressed` / `special_held` | `is_action_just_pressed("special")` / `is_action_pressed("special")` |
| `shield_held` | `is_action_pressed("shield")` |

`pause` is handled by the HUD/pause menu, not by the controller.

## Display settings

| Setting (`project.godot`) | Value | Why |
|---|---|---|
| `display/window/size/viewport_width` × `viewport_height` | 480 × 270 | The game's base resolution: one game pixel at zoom 1 |
| `display/window/size/window_width_override` × `window_height_override` | 1440 × 810 | Default window: 3× scale (1080p fullscreen is 4×) |
| `display/window/stretch/mode` | `canvas_items` | Draw at the window's real resolution, so the camera can zoom smoothly |
| `display/window/stretch/aspect` | `keep` | Keep 16:9; black bars if the window is a different shape |
| `display/window/stretch/scale_mode` | `integer` | Whole-number base scale |
| `rendering/textures/canvas_textures/default_texture_filter` | Nearest | Sharp pixels, no smoothing |
| `rendering/2d/snap/snap_2d_transforms_to_pixel` | off | Lets the camera glide smoothly |

The camera zooms between 0.77× and 1.4× (see [match & stage](match-and-stage.md#camera)). At
in-between zooms some game pixels are a screen pixel wider than others; that's the accepted cost
of smooth zoom.
| `physics/common/physics_ticks_per_second` | 60 | One tick = 1/60 s (the default) |

## Text

- A free pixel font (CC0 or OFL license) lives in `assets/fonts/`, with its license file next to
  it. Chosen in M1.
- Pixel fonts are used only at their native size or whole multiples of it.
- The project's default theme uses this font, so all UI picks it up.

## Placeholder palette

Fighter, HUD and debug colors come from the free **Sweetie 16** palette by GrafxKid, so everything
looks consistent before real art exists. Stage colors are in the platform styles (see
[match & stage](match-and-stage.md#platform-look-perspective)).

| Use | Color |
|---|---|
| Clear color behind everything | `#1a1c2c` |
| Outline | `#1a1c2c` |
| P1 shirt (red) | `#b13e53` |
| P2 shirt (blue) | `#3b5dc9` |
| HUD text | `#f4f4f4` |

## Audio

None in v1.
