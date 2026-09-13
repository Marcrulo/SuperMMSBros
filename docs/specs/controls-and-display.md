# Controls and Display

## Input Map actions

Gameplay and UI code refer only to these action names, never to specific keys or buttons.

| Action | Keyboard | Gamepad |
|---|---|---|
| `move_left` | A, ← | left stick left, d-pad left |
| `move_right` | D, → | left stick right, d-pad right |
| `jump` | W, ↑, Space | A / Cross (bottom face button) |
| `down` | S, ↓ | left stick down, d-pad down |
| `attack` | J, Z | X / Square (left face button) |
| `pause` | Esc | Start |

- J suits WASD players; Z suits arrow-key players.
- Stick actions use a dead zone of 0.5 for `down` and 0.2 for `move_left`/`move_right`.
- Menus use Godot's built-in `ui_*` actions (arrows / d-pad to move focus, Enter / Space / A to
  press), which already support keyboard and gamepad.

## `KeyboardController`

Builds a `FighterInput` from the Input Map each tick (it is called from `Match.step()` inside the
physics frame, so `is_action_just_pressed` works per tick):

| Field | Source |
|---|---|
| `move_x` | `Input.get_axis("move_left", "move_right")` |
| `jump_pressed` / `jump_held` | `is_action_just_pressed("jump")` / `is_action_pressed("jump")` |
| `down_pressed` | `is_action_just_pressed("down")` |
| `attack_pressed` | `is_action_just_pressed("attack")` |

`pause` is handled by the HUD/pause menu, not by the controller.

## Display settings

| Setting (`project.godot`) | Value | Why |
|---|---|---|
| `display/window/size/viewport_width` × `viewport_height` | 320 × 180 | The game's native resolution |
| `display/window/size/window_width_override` × `window_height_override` | 1280 × 720 | Default window: 4× scale |
| `display/window/stretch/mode` | `viewport` | Render at 320×180, then scale the finished image |
| `display/window/stretch/aspect` | `keep` | Keep 16:9; black bars if the window is a different shape |
| `display/window/stretch/scale_mode` | `integer` | Only whole-number scaling, so every pixel is the same size |
| `rendering/textures/canvas_textures/default_texture_filter` | Nearest | Sharp pixels, no smoothing |
| `rendering/2d/snap/snap_2d_transforms_to_pixel` | on | Sprites always sit on whole pixels (no shimmer) |
| `physics/common/physics_ticks_per_second` | 60 | One tick = 1/60 s (the default) |

## Text

- A free pixel font (CC0 or OFL license) lives in `assets/fonts/`, with its license file next to
  it. Chosen in M1.
- Pixel fonts are used only at their native size or whole multiples of it.
- The project's default theme uses this font, so all UI picks it up.

## Placeholder palette

Placeholder colors come from the free **Sweetie 16** palette by GrafxKid, so everything already
looks consistent before real art exists:

| Use | Color |
|---|---|
| Background | `#1a1c2c` |
| Main platform | `#333c57` |
| Pass-through platforms | `#566c86` |
| P1 (red) | `#b13e53` |
| P2 (blue) | `#3b5dc9` |
| Eye, fist, hit flash, HUD text | `#f4f4f4` |

## Audio

None in v1.
