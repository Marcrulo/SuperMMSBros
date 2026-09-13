# Art Guide

What to draw, at what size, and how to export it so it drops into the game. v1 ships with
placeholder rectangles; this guide is the target for the hand-drawn art that replaces them.

## Tool

**Pixelorama** (free, open source, runs on Linux, made in Godot). Any pixel-art editor works as
long as it exports PNG sprite strips.

## Ground rules

- The game renders at **320×180**. One pixel you draw = one pixel in the game. Sprites are never
  scaled in the engine.
- Use a **limited palette**. Sweetie 16 (the placeholder palette) is a good start; any palette
  works as long as it's used consistently.
- Transparent background; no anti-aliasing against transparency.

## Fighters

### Frame size and alignment

- Every fighter frame is **48×48 px**.
- The fighter's **feet sit on the bottom row, centered horizontally** (x = 24). That point is the
  fighter's origin in the game.
- The body should roughly fill the collision box: **16 wide × 24 tall**, i.e. frame pixels
  x 16–31, y 24–47.
- The extra space is for reach: the attack's hitbox covers frame pixels **x 32–45, y 30–39**
  (14×10, in front of the body). Upward space is room for future moves.
- Draw everything **facing right**. The game mirrors sprites for facing left.

### Animations

Each animation matches a fighter state (see [fighter](fighter.md)). Timings are suggestions except
for the attack, which must line up with the attack's frame data.

| Animation | Used in state | Frames | Timing | Loops |
|---|---|---|---|---|
| `idle` | `IDLE` | 4 | 8 ticks each | yes |
| `run` | `RUN` | 6 | 5 ticks each | yes |
| `jump` | `AIR`, rising | 2 | 4 ticks each, hold last | no |
| `fall` | `AIR`, falling | 2 | 6 ticks each | yes |
| `double_jump` | `AIR`, after a double jump (optional; `jump` is used if missing) | 3 | 4 ticks each | no |
| `attack` | `ATTACK` | 6 | see below | no |
| `hurt` | `HITSTUN` | 2 | 4 ticks each | yes |

**Attack (19 ticks in total), suggested 6 drawings:**

| Drawing | Ticks | Attack phase | Pose |
|---|---|---|---|
| 1–2 | 2 + 2 | Startup (ticks 1–4) | Wind-up |
| 3 | 3 | Active (ticks 5–7) | Fully extended — the fist/weapon inside the hitbox area |
| 4–6 | 4 + 4 + 4 | Recovery (ticks 8–19) | Pulling back to neutral |

The one rule that matters: **the strike pose is shown exactly during the active ticks**, so what
players see matches when the attack can hit.

### Player colors

Both players use the same fighter. Pick a few palette shades as the fighter's **"team color"** (for
example 2–3 shades of red for clothing) and use them only for the parts that should change color.
The game can then recolor P2 with a palette-swap shader instead of needing a second set of
drawings.

### Export

- One PNG **horizontal strip** per animation: frames side by side, 48×48 each, no padding.
- File names: `fighter_<animation>.png`, e.g. `fighter_run.png`.
- Location: `super-mms-bros/assets/fighters/default/`.
- In Godot these become a `SpriteFrames` resource on an `AnimatedSprite2D` inside
  `FighterVisuals`.

## Stage

- **Main platform:** **16×16 tiles** painted with a `TileMapLayer`. The platform is 12 tiles wide
  and 1 tile tall (the walkable surface is the top row of pixels). Decorative tiles below it (an
  island underside) go on a separate layer with no collision.
- **Pass-through platforms:** one sprite each, **48×8 px**, walkable surface on the top row.
- **Background:** one **320×180** image (optional; a flat color works).
- Export as PNG to `super-mms-bros/assets/stage/`.

## HUD

- **Stock icon:** 8×8 px (a tiny fighter head works well).
- **Off-screen arrow:** 8×8 px, pointing right (the game rotates it).
