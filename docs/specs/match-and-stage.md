# Match and Stage

The rules of a match, its flow from countdown to result, the stage layout and the camera.

## Match format

- 1v1: P1 (default: human) vs P2 (default: CPU).
- 3 stocks each. No damage %, no time limit.
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
   `stocks −= 1`, state `KO`, velocity zero, hidden, collision off. The Match emits
   `fighter_ko(index)`.
2. If that fighter still has stocks, it respawns **60 ticks** later at its own spawn point: facing
   its starting direction, velocity zero, state `IDLE`, jumps restored, collision on,
   **120 ticks of invulnerability**. The Match emits `fighter_respawned(index)`.
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
- every fighter at its spawn point: starting facing, velocity zero, state `IDLE`, 3 stocks, jumps
  restored, no invulnerability, no timers, collision mask restored, visible;
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

- **Stock icons:** one small square per remaining stock in the fighter's color. P1 bottom-left,
  P2 bottom-right.
- **Countdown:** large text in the center ("3", "2", "1", "GO!").
- **Off-screen arrows:** when a fighter (not `KO`) is fully outside the visible screen, a small
  arrow in its color sits at the nearest screen edge, pointing toward it.
- The HUD reads state and listens to Match signals (`match_reset`, `countdown_changed(value)`,
  `fighter_ko(index)`, `fighter_respawned(index)`, `match_ended(result)`). It changes nothing in
  the game except through the pause/result buttons.

## Stage: Battlefield

The visible screen is 320×180 and the world uses the same coordinates: (0, 0) is the top-left of
the screen, y grows downward. All values are starting points, tuned in M6.

```
 y
 64                    [====top====]
 96       [===left===]               [===right===]
128   P1 ▶   ███████████████████████████████████   ◀ P2
144          ███████████████████████████████████
          x: 64                                  256
```

| Element | Type | Position |
|---|---|---|
| Main platform | solid (`stage_solid`) | x 64–256 (12 tiles), top at y 128, 16 px thick |
| Left platform | pass-through (`stage_platform`) | x 88–136, top at y 96 |
| Right platform | pass-through | x 184–232, top at y 96 |
| Top platform | pass-through | x 136–184, top at y 64 |
| P1 spawn | point | (112, 128), facing right |
| P2 spawn | point | (208, 128), facing left |
| Blast zone | rectangle (fighter center must stay inside) | x −16…336, y −120…196 |

- The main platform sits on the 16 px tile grid so it can be painted with tiles later.
- Platforms are 32 px apart vertically, so each one is reachable with a single ground jump (48 px).
- The main platform floats: below and beside it is empty space.
- The blast zone sits just outside the screen on the left, right and bottom, so leaving the screen
  there means a KO. It is far above the top, because jumps from the top platform can briefly leave
  the screen.

### Stage scene

```
Battlefield            (Node2D, stage/stage.gd)
├── MainPlatform       (StaticBody2D, layer stage_solid) + CollisionShape2D + visual
├── Platforms          (Node2D)
│   ├── Left / Right / Top   (StaticBody2D, layer stage_platform, one-way collision) + visual
├── P1Spawn, P2Spawn   (Marker2D)
```

`stage.gd` exports the blast zone as a `Rect2` and provides the platform rectangles for the
snapshot.

Pass-through platforms have a 4 px tall one-way collision shape at their top edge.

**Placeholder visuals:** flat dark background; main platform dark gray; pass-through platforms
lighter gray, 4 px tall. Real art later: a `TileMapLayer` with 16×16 tiles for the main platform
and sprites for the pass-through platforms (see [art guide](art-guide.md)).

## Camera

A `Camera2D` fixed at (160, 90), zoom 1, no smoothing or movement. It always shows the whole
stage.
