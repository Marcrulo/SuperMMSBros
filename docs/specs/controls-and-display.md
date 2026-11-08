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
| `shield_held` / `shield_pressed` | `is_action_pressed("shield")` / `is_action_just_pressed("shield")` |
| `up_pressed` | `is_action_just_pressed("up")` |
| `side_pressed` | `is_action_just_pressed("move_right")` → 1, else `is_action_just_pressed("move_left")` → −1, else 0 |

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
- **Ink font:** when it's on the machine, **all text** uses **Ink Yugo** by ArtiXLabs
  (`assets/fonts/ink_yugo.otf`), a brush font, so the native-size rule doesn't apply to it. Every
  label is switched as it enters the scene tree: its size × 1.25 (the brush letters are smaller at
  the same size), moved up by half the extra height so it stays centred on its line. Labels show in capitals only (the Label's `uppercase` setting), and names avoid accented
  letters and other signs the brush font draws badly (é, ø, brackets).
- The demo font only has real letters: every digit and sign except `,` and `.` draws as a
  "personal use only" stamp. So a label switches only if its text (when it enters the tree) is
  letters, spaces, commas and full stops; anything with digits or signs (the "P1" tag, the player
  cards, the "?" on locked tiles) keeps the pixel font. Menu hints are written without colons or
  "!" so they can be in the ink font. The select
  screens' titles are 24. Its demo license allows personal use only and forbids redistribution, so
  it is **not committed** (in `.gitignore`); without it all text stays in the pixel font.

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

- **Buses** (`default_bus_layout.tres`): `Master` ← `Music` and `SFX`, all at 0 dB. Music players
  use `Music`, sound effects `SFX`, so each group can get its own volume later.
- **Music:** each stage has a music track that loops for the whole match: `assets/music/<stage
  id>.ogg` (found by its name; a stage without a file is silent). It's played by the Match's
  `Music` node (an `AudioStreamPlayer`), presentation only. The menus have their own looping
  track, `assets/music/menu.ogg` (see [menus](menus.md#sound)).
- **Sound effects:** `assets/sfx/<name>.wav`: some synthesized by `tools/gen_menu_sfx.py` (our
  own), some from outside (credited in `assets/sfx/CREDITS.txt`, or kept out of git when their
  license is unknown). v1 has menu sounds only (see [menus](menus.md#sound)).
- Tracks are prepared with `tools/prepare_music.py`: leading and trailing silence trimmed (so the
  loop has no gap), loudness normalized to −18 LUFS with peaks below −1.5 dBTP, saved as OGG Vorbis
  44.1 kHz stereo. Every track then plays at the same loudness. Sound effects are too short for
  integrated loudness, so `tools/prepare_music.py --sfx` trims their leading and trailing silence
  the same way and sets their **loudest 400 ms window**
  (EBU R128 momentary loudness) to −18 LUFS instead, keeps peaks below −1.5 dBFS, and writes
  16-bit WAV (no compression delay for short sounds).
- The tracks are the user's own copies of existing songs, so they are **not committed** (the repo is
  public): `assets/music/` is in `.gitignore`. The game runs without them.
- **Quitting:** closing the window goes through `Game.quit()`, which frees the current scene and
  waits 0.1 s (real time) before quitting, so the audio engine releases the playing track first.
  Code that ends the game (e.g. M8's `--autoquit`) calls `Game.quit()` too.
