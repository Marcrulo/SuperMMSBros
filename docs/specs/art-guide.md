# Art Guide

What to draw, at what size, and how to export it so it drops into the game. v1 ships with
generated placeholder sprites (`tools/gen_placeholder_sprites.py`); this guide is the target for
the hand-drawn art that replaces them. Replacing a PNG with your own drawing in the same format
needs no code changes.

## Tool

**Pixelorama** (free, open source, runs on Linux, made in Godot). Any pixel-art editor works as
long as it exports PNG sprite strips.

## Ground rules

- The game's base resolution is **480×270**. One pixel you draw = one game pixel. Sprites are never
  scaled in the engine (the camera's zoom scales the whole view).
- Use a **limited palette**. Sweetie 16 (the placeholder palette) is a good start; any palette
  works as long as it's used consistently.
- Transparent background; no anti-aliasing against transparency. A 1 px dark outline
  (`#1a1c2c`) around the figure reads well against the busy backgrounds.

## Fighters

### Frame size, alignment and proportions

- Every fighter frame is **48×48 px**.
- The fighter's **feet sit on the bottom row, centered horizontally** (x = 24). That point is the
  fighter's origin in the game.
- **Big head** (Brawlhalla-like): the head is about **13 px tall** and pokes 3 px above the 24 px
  body box. The body box is frame pixels x 16–31, y 24–47; the head reaches up to about y 21.
  The hurtbox covers body and head: x 16–31, y 21–47.
- The extra space is for reach and effects. Draw everything **facing right**; the game mirrors
  sprites for facing left.

### Animations

Each animation matches a fighter state or move (see [fighter](fighter.md) and
[moves](moves.md)). For moves, **the strike pose must show exactly on the active frames**: that's
when the move can hit, and what players read.

| Animation | Used for | Frames | Timing (ticks per drawing) | Loops |
|---|---|---|---|---|
| `idle` | `IDLE` | 4 | 8 each | yes |
| `run` | `RUN` | 6 | 5 each | yes |
| `crouch` | `CROUCH` | 2 | 2, then hold the second | no |
| `jump` | `AIR`, rising | 2 | 4, then hold | no |
| `fall` | `AIR`, falling | 2 | 6 each | yes |
| `helpless` | `HELPLESS` | 2 | 6 each | yes |
| `shield` | `SHIELD`, `SHIELD_DROP` | 1 | hold (the bubble is drawn by the game) | — |
| `dizzy` | `SHIELD_BREAK` | 2 | 10 each | yes |
| `hurt` | `HITSTUN` | 2 | 4 each | yes |
| `jab` | jab (19 ticks) | 5 | 2, 2 · **3** · 6, 6 | no |
| `down_tilt` | down tilt (20) | 5 | 3, 2 · **3** · 6, 6 | no |
| `up_tilt` | up tilt (23) | 5 | 3, 2 · **4** · 7, 7 | no |
| `side_tilt` | side tilt (26) | 5 | 4, 3 · **3** · 8, 8 | no |
| `neutral_special_charge` | neutral special, charging | 2 | 6 each (the game adds a growing glow on the fists) | yes |
| `neutral_special` | the charged punch (25) | 4 | 3 · **4** · 9, 9 | no |
| `down_special_dive` | down special, diving in the air | 1 | hold | — |
| `down_special` | the burst (36) | 5 | 5, 5 · **6** · 10, 10 | no |
| `side_special` | firing the projectile (30) | 4 | 5, 5 · 10, 10 (the projectile appears at the start of drawing 3) | no |
| `up_special` | the boost (startup 4, rising) | 3 | 4 · **12** · hold the last while rising | no |

Bold numbers are the drawings shown on the active frames.

### Projectile

- `projectile.png`: a strip of **3 frames, 12×12 px** each, drawn flying right, center at (6, 6);
  4 ticks per frame, looping. The game's projectile hitbox is 8×6 around the center.

### Player colors

Both players use the same fighter. Pick a few palette shades as the fighter's **"team color"** (in the
placeholder: three shades of red for the shirt) and use them only for the parts that should change
color. The game swaps exactly those shades to blue for P2 when it loads the strips.

### Export

- One PNG **horizontal strip** per animation: frames side by side, 48×48 each, no padding.
- File names: `fighter_<animation>.png`, e.g. `fighter_run.png`.
- Location: `super-mms-bros/assets/fighters/default/` (a new character gets its own folder).

## Stages

- **Backgrounds:** one image per stage, **528×297** (the 480×270 screen plus 10% for parallax
  drift), in `super-mms-bros/assets/stage/backgrounds/`, named after the stage id
  (`mms.png`, `fc.png`, `slot_day.png`, `slot_sunset.png`). Paint at full brightness: the game tones
  backgrounds down with a haze.
- **Platforms:** drawn by the game in code, in perspective, from each stage's platform style (colors
  and front-face bands; see [match & stage](match-and-stage.md#platform-look-perspective)). New
  materials are added as new styles, not as images. Hand-drawn platform art is a later idea.

## HUD

- **Stock icon:** 8×8 px (a tiny fighter head works well).
- **Off-screen arrow:** 8×8 px, pointing right (the game rotates it).
- **Damage digits:** drawn with the game's pixel font.
