# Match and Stage

The rules of a match, its flow from countdown to result, the stages and the camera.

## Match format

- 1v1: P1 (default: human) vs P2 (default: CPU).
- 3 stocks each, damage % (see [moves](moves.md#damage--and-knockback)), no time limit.
- Last fighter with stocks left wins. If both lose their last stock on the same tick, it's a draw.

## Phases

| Phase | What happens |
|---|---|
| `COUNTDOWN` | 180 ticks. HUD shows "3", "2", "1" for 60 ticks each. Controllers are asked for input but fighters receive empty input. |
| `PLAYING` | Normal play. HUD shows "GO!" for the first 60 ticks. |
| `ENDED` | The tick loop stops; fighters freeze where they are. The result screen appears. |

Pausing is not a phase: it stops the whole scene tree (see [Pause](#pause)).

## KOs, stocks and respawn

Checked every tick after hits are resolved (see [architecture](architecture.md)):

1. A fighter not in `KO` whose **center** is outside the stage's blast zone rectangle is KO'd:
   `stocks −= 1`, state `KO`, velocity zero, hidden, collision off. Its projectile disappears. The
   Match emits `fighter_ko(index)`.
2. If that fighter still has stocks, it respawns **60 ticks** later at its own spawn point: facing
   its starting direction, velocity zero, state `IDLE`, **0 %**, jumps and up special restored,
   full shield, collision on, **120 ticks of invulnerability**. The Match emits
   `fighter_respawned(index)`.
3. Invulnerable fighters can't be hit. They can attack normally.

## Win condition

After KOs are processed, count fighters with `stocks > 0` (a KO'd fighter waiting to respawn
counts):

- **One left:** that fighter wins.
- **None left:** draw.
- If `--max-ticks=N` is set and the tick counter reaches N during `PLAYING`: timeout.

The phase becomes `ENDED` and the Match emits `match_ended(result)`, where `result` is one of
`P1_WIN`, `P2_WIN`, `DRAW`, `TIMEOUT`.

## Reset

`Match.reset(seed: int = -1)` returns everything to the start of a match without reloading the
scene:

- tick counter 0, phase `COUNTDOWN`;
- RNG seeded with `seed` (or a new random seed if −1, or the `--seed` value if given); the seed
  is printed;
- every fighter at its spawn point: starting facing, velocity zero, state `IDLE`, 3 stocks, 0 %,
  full shield, jumps restored, no invulnerability, no timers, collision mask restored, visible;
- no projectiles;
- every controller's `reset()` is called;
- the Match emits `match_reset`.

The Match calls `reset()` in `_ready()`. The Restart buttons call it too, and so will AI training
later (one training game = one reset).

## Pause

- The `pause` action (Esc / gamepad Start) during `COUNTDOWN` or `PLAYING` pauses the game with
  `get_tree().paused = true` and shows the pause menu: **Resume**, **Restart**, **Quit**.
- `pause` again or **Resume** unpauses. **Restart** unpauses and calls `reset()`. **Quit** exits.
- The Match is pausable (it stops ticking). The pause menu uses `PROCESS_MODE_WHEN_PAUSED`.

## Result screen

Shown when the match ends. Text depends on the result and on who P1 is:

| Result | P1 is human | P1 is CPU |
|---|---|---|
| `P1_WIN` | "You win!" | "P1 wins" |
| `P2_WIN` | "You lose" | "P2 wins" |
| `DRAW` | "Draw" | "Draw" |
| `TIMEOUT` | "Time out" | "Time out" |

Buttons: **Restart** (focused by default) and **Quit**. Both menus work with keyboard and gamepad
through Godot's UI focus navigation.

With `--autoquit`, the game prints the result line and quits instead of showing this screen (see
[architecture](architecture.md#command-line-options)).

## HUD

- **Damage panels:** one per fighter along the bottom of the screen (P1 left of center, P2 right):
  the damage % in large pixel digits, tinting from white toward red as it rises (white at 0 %, red
  at 150 % and above), with one small stock icon per remaining stock underneath, in the fighter's
  color. A hit makes the number jump briefly.
- **Stage name:** the stage's name in the top-left corner for the first 3 seconds of a match.
- **Countdown:** large text in the center ("3", "2", "1", "GO!").
- **Off-screen arrows:** when a fighter (not `KO`) is fully outside the visible screen, a small
  arrow in its color sits at the nearest screen edge, pointing toward it.
- The HUD is a `CanvasLayer`, so the camera's zoom doesn't affect it. It reads state and listens to
  Match signals (`match_reset`, `countdown_changed(value)`, `fighter_hit(index)`,
  `fighter_ko(index)`, `fighter_respawned(index)`, `match_ended(result)`). It changes nothing in the
  game except through the pause/result buttons.

## Stages

Four stages in v1. They share the Battlefield layout; each has its own name, background, platform
style and light. Each stage is a `StageData` resource in `stage/stages/` (id = file name):

| Id | Name | Background | Platform style | Haze | Light |
|---|---|---|---|---|---|
| `mms` | Marie Mørks Skole | `mms.png` | school brick | cool (0.82, 0.87, 0.93) | white |
| `fc` | Frederiksborgcenteret | `fc.png` | modern | cool | white |
| `slot_day` | Frederiksborg Slot (Dag) | `slot_day.png` | castle | cool | white |
| `slot_sunset` | Frederiksborg Slot (Solnedgang) | `slot_sunset.png` | castle | warm (0.96, 0.80, 0.60) | warm (1.0, 0.85, 0.70) |

`StageData` fields: `id`, `display_name`, `background` (texture), `style` (a `PlatformStyle`
resource), `haze_color`, `light_color`. The stage is chosen with `--stage=<id>` (default `mms`);
a stage-select screen later just lists the resources. The stage's look is presentation only: every
stage plays identically.

### Layout: Battlefield

The world is in game pixels; at zoom 1 the camera shows 480×270. y grows downward. All values are
starting points, tuned in M9.

```
  y
 128                     [=====top=====]
 160       [====left====]               [====right====]
 192   P1 ▶  ███████████████████████████████████████████  ◀ P2
 208         ███████████████████████████████████████████
          x: 96                                          384
```

| Element | Type | Position |
|---|---|---|
| Main platform | solid (`stage_solid`) | x 96–384 (18 fighter widths), top at y 192, 16 px thick |
| Left platform | pass-through (`stage_platform`) | x 132–204, top at y 160 |
| Right platform | pass-through | x 276–348, top at y 160 |
| Top platform | pass-through | x 204–276, top at y 128 |
| P1 spawn | point | (168, 192), facing right |
| P2 spawn | point | (312, 192), facing left |
| Blast zone | rectangle (fighter center must stay inside) | x −120…600, y −200…320 |

- Platforms are 32 px apart vertically, so each one is reachable with a single ground jump (48 px).
- The main platform floats: below and beside it is empty space.
- The blast zone leaves room off every side for recovering and for launches at high %. The camera
  never shows beyond it.

### Stage scene

```
Battlefield            (Node2D, stage/stage.gd)
├── BackgroundLayer    (CanvasLayer, layer −1)
│   └── Background     (Sprite2D + haze shader, slight parallax)
├── Light              (CanvasModulate: the stage's light color)
├── PlatformLook       (Node2D, stage/platform_look.gd: draws every platform)
├── MainPlatform       (StaticBody2D, layer stage_solid) + CollisionShape2D
├── Platforms          (Node2D)
│   ├── Left / Right / Top   (StaticBody2D, layer stage_platform, one-way collision)
├── P1Spawn, P2Spawn   (Marker2D)
```

`stage.gd` exports the blast zone as a `Rect2`, applies a `StageData` (`apply(data)`), and provides
the platform rectangles for the snapshot. Pass-through platforms have a 4 px tall one-way collision
shape at their top edge.

### Platform look (perspective)

The platforms are drawn in code, in perspective, as if seen from slightly above and in front.
Collision is unchanged by any of this.

- **Top face:** recedes toward the camera's center x (the vanishing x). A point `d` pixels toward
  the viewer from the walk line is drawn at `vanish_x + (x − vanish_x) × (1 + 0.011 × d)`, so the
  top face matches the collision exactly along the walk line, is wider in front of it and narrower
  behind it. Depth behind / in front of the walk line: main 8 / 6 px, thin platforms 4 / 3 px — the
  fighter stands about in the middle of the top face.
- **Front face:** as wide as the top face's front edge; a stack of bands (trim, bricks, glass,
  panels…) from the style. Main platform 16 px tall, thin platforms 6 px.
- **Side face:** an end is drawn only if it faces the vanishing x (so panning turns the platforms
  slightly); shaded. Shapes that collapse to no area are skipped.
- **Underside:** the main platform has a dark underside narrowing 12 px downward.
- **Shadows:** each thin platform casts a shadow straight down onto the main platform's top face,
  in the same depth band; the top platform's shadow is fainter.

`PlatformStyle` resources (`stage/styles/`) hold the colors and front-face bands:

| Style | Top face | Front face (main, top to bottom) | Extras |
|---|---|---|---|
| school brick | grey `#8a8f99` | white trim 2, orange-red brick 12, dark band 2 | — |
| modern | light concrete `#b9bcc0` | aluminum 2, blue glass with frames 8, dark line 1, concrete panels 5 | glint in every third pane |
| castle | green copper `#4f8f78` | sandstone 2, red brick 4, sandstone 2, red brick 8 | sandstone corner blocks |

### Background

- One image per stage, **528×297** (the 480×270 screen plus 10% to drift), in
  `assets/stage/backgrounds/`.
- Drawn on a `CanvasLayer` behind the world, so zoom doesn't shrink it; it drifts 6% of the
  camera's movement for a sense of distance.
- A shader tones it down so the stage reads in front: colors at 70% saturation, then mixed 35% toward
  the stage's haze color.

## Camera

A smash-style `Camera2D` (`match/match_camera.gd`). Presentation only: it reads fighter positions
and never changes gameplay.

- Every frame it frames a box around every fighter's center (not `KO`) plus a fixed stage focus
  point (240, 160), grown by 120 px on the sides and 80 px above and below.
- Zoom fits that box in the 480×270 view, clamped between 0.67 (zoomed out: never shows beyond the
  blast zone) and 1.4 (zoomed in).
- Position and zoom glide toward the target (`1 − e^(−4·delta)` per frame); the first frame jumps
  straight there. The view is clamped to stay inside the blast zone.
- The window is rendered at its real resolution (`canvas_items` stretch), so zooming is smooth.
