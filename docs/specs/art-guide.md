# Art Guide

What to draw, at what size, and how to export it so it drops into the game. v1 ships with
generated sprites (`tools/gen_fighter_sprites.py`); this guide is the target for
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

- Every fighter frame is **48×48 px**, or **64×64 px** for characters already moved to the 64 px
  style (see [64 px style](#64-px-style-trial); all 14 characters are now). Each strip's height is
  its frame size; one character uses one size for all its strips.
- The fighter's **feet sit on the bottom row, centered horizontally** (x = 24 at 48 px, x = 32 at
  64 px). That point is the fighter's origin in the game. Every frame is drawn into the same
  48×48 game pixels: a 48 px frame 1:1, a 64 px frame at ¾ size (one drawn pixel = ¾ game pixel),
  so both styles are the same size in the game.
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
| `spot_dodge` | `SPOT_DODGE` (20) | 3 | 3 · 12 · 5 | no |
| `roll` | `ROLL` (24), tumbling forward | 4 | 6 each | no |
| `air_dodge` | `AIR_DODGE` (30) | 2 | 4, then hold | no |
| `ledge` | `LEDGE`, hanging by the hands, facing the stage | 2 | 12 each | yes |
| `ledge_climb` | `LEDGE_CLIMB` (20) | 3 | 6, 7, 7 | no |
| `jab` | jab (14 ticks) | 5 | 2, 2 · **3** · 4, 3 | no |
| `down_tilt` | down tilt (15) | 5 | 3, 2 · **3** · 4, 3 | no |
| `up_tilt` | up tilt (17) | 5 | 3, 2 · **4** · 4, 4 | no |
| `side_tilt` | side tilt (20) | 5 | 4, 3 · **3** · 5, 5 | no |
| `neutral_air` | neutral air (15) | 5 | 2, 1 · **6** · 3, 3 | no |
| `forward_air` | forward air (15) | 5 | 3, 2 · **3** · 4, 3 | no |
| `back_air` | back air (17), kicking behind | 5 | 3, 3 · **3** · 4, 4 | no |
| `up_air` | up air (15) | 5 | 2, 2 · **4** · 4, 3 | no |
| `down_air` | down air (17), stomping down | 5 | 3, 3 · **3** · 4, 4 | no |
| `neutral_special_charge` | neutral special, charging | 2 | 6 each (the game adds a growing glow on the fists) | yes |
| `neutral_special` | the charged punch (17) | 4 | 3 · **4** · 5, 5 | no |
| `down_special_dive` | down special, diving in the air | 1 | hold | — |
| `down_special` | the burst (28) | 5 | 5, 5 · **6** · 6, 6 | no |
| `side_special` | firing the projectile (22) | 4 | 5, 5 · 6, 6 (the projectile appears at the start of drawing 3) | no |
| `up_special` | the boost (startup 4, rising) | 3 | 4 · **12** · hold the last while rising | no |

Bold numbers are the drawings shown on the active frames.

### Projectile

- `projectile.png`: a strip of **3 frames, 12×12 px** each, drawn flying right, center at (6, 6);
  4 ticks per frame, looping. The game's projectile hitbox is 8×6 around the center.

### Player colors

Every character is drawn in its own colors; the game never recolors the strips. The two players
never play the same character (see [menus](menus.md#characters-and-the-roster)).

### Export

- One PNG **horizontal strip** per animation: frames side by side, 48×48 (or 64×64) each, no
  padding.
- File names: `fighter_<animation>.png`, e.g. `fighter_run.png`.
- Location: one folder per character, named after its id: `super-mms-bros/assets/fighters/<id>/`
  (e.g. `slot_01/`), holding its strips and `stock_icon.png`. The projectile is shared by everyone:
  `super-mms-bros/assets/fighters/projectile.png`.

### Generated characters

`tools/gen_fighter_sprites.py <out_dir> [ids…]` draws every character on the same body and poses;
each character's look (colors sampled from its portrait, hair style, traits such as glasses or a
beard) is in `tools/fighter_looks.py`, keyed by character id, and its strips go to
`<out_dir>/<id>/` (and the shared projectile to `<out_dir>/projectile.png`). The generated looks
are a base to fine-tune by hand: once a character's strips are edited by hand, add its id to
`HAND_EDITED` in `tools/fighter_looks.py`, and the generator leaves that folder alone (unless the id
is named on the command line).

### 64 px style (trial)

A bigger, more detailed style; every character uses it.

- **Frames 64×64**, feet on the bottom row centered at x = 32. The standing figure is about 42 px
  tall: a hand-drawn head about 17 px tall (18 wide) on a 15 px wide torso, the shoulders 17 px.
- **Look:** a 1 px `#1a1c2c` outline around every body part (so an arm in front of the torso
  reads), three tones per material (base, shade on the back/lower side, light on the front/upper
  side). The idle is a boxing guard.
- **Faces:** normal, eyes shut (helpless, dodges, dizzy, rolls) and a wince with gritted teeth
  (hurt). A raised arm comes up beside the head, never over the face.
- **Drawn at ¾ size** in the game (into 48×48 game pixels), so gameplay sizes (body box,
  hurtbox, hitboxes) and the stages stay as they are. The trade-off: a fighter's pixels are
  finer than the stage's. (The alternative, kept for later: scale the world and the camera by
  4/3 and draw 64 px frames 1:1.)
- **Tools:** `tools/fighter64_looks.py` holds each character's colors and hand-drawn head (a
  letter grid plus layers: hair, beard, glasses, mouth); `tools/gen_fighter_sprites64.py
  <out_dir> [ids…]` draws the bodies from poses and writes the strips plus a preview sheet;
  `tools/preview_fighter_gif.py <strips_dir> <out.gif>` animates a character's strips at game
  timing. Every character is in `HAND_EDITED` (`tools/fighter_looks.py`), so the old 48 px
  generator leaves their folders alone.

### Weapons

A character can carry a weapon (Henrik: an acoustic guitar). It's drawn into the character's
strips like any body part, by the 64 px generator from the poses, so it follows the body.

- **Bigger canvas:** a swung weapon reaches past a 64×64 frame, so such a character's frames are
  bigger (Henrik: **112×80**). The body is the same size and in the same place relative to the
  feet: the 64×64 frame sits at the bottom center of the canvas (Henrik: 24 px of extra room on
  each side, 16 px above). The game draws any frame size at ¾, feet at the origin. A character's
  frames all share one size; the frame width is the strip width divided by the drawings.
- **Henrik's guitar:** acoustic, natural wood top with a dark sound hole, a brown neck and
  headstock, about 35 px long. On his back it's slung close: the body pressed against his back,
  the neck rising behind his head on the back side. In jab, side tilt and the neutral special his own poses swing it (held
  by the neck); in every other animation it stays on his back.
- His move hitboxes are fitted to where the guitar is drawn in the strike drawing (see
  [moves](moves.md#henrik--guitar)).
- **Gitte's scissors:** a large pair, about 30 px long: two steel blades (light grey, shaded) on a
  pivot screw, two big red handle loops (about 8 px across, with a visible hole) so they read as
  scissors even small. Her frames are a 112×80 canvas too. On her back they hang closed, diagonally like
  a sword in a back sheath: the handles stick out behind her neck (both loops clearly visible), the
  blades slant down and forward behind her body, and just the tip pokes out in front of her hip. In her neutral special she holds
  them out in front: open while charging (the blades about 40° apart), snapped shut in the strike
  drawing. Her stance switch (`down_special`, 5 drawings) is her own pose: hands crossed in front,
  then flung out wide. Her volley's picture (`projectile.png`): a small pair of scissors, 3
  drawings of 16×16 turned 120° further each.
- **Stances ÷ and ×** draw her frames at ×0.75 / ×1.25 of the usual ¾ size, feet at the origin.

### Gitte's pyramid

`assets/fighters/slot_02/pyramid.png`, one drawing, 168×128, drawn at ¾ (126×96 game px) by the
64 px generator: a **stepped pyramid of sandstone blocks**, not a plain triangle. 8 courses
(rows) of 16 px, each 10 px narrower on both sides than the one below it, with a single capstone
block on top (28 px wide; its top row is the tip she stands on). Every course is a row of
rectangular blocks (about 20–30 px wide, joints staggered from the course below like brickwork),
each block a slightly different sand tone with grainy speckles (lighter and darker pixels), a
light top edge, a darker bottom edge, a 1 px dark-sand joint between blocks, and chipped
(missing) corner pixels so they read as rough-cut stone. The step tops catch the light. The usual
dark outline goes around the whole pyramid. The colors are fixed (sand, not per character).

In the game the drawing's bottom center sits on the floor top, and only the part above the floor
is drawn: rising, it comes up out of the floor, and sinking, it goes back down into it, shaking
1 px left and right every 2 ticks. Drawn behind the fighters, in front of the stage.

Her own **up special** pose (3 drawings): a crouch with the front hand out low over the ground
(calling the pyramid up), then standing with her fist raised forward and up (riding the tip; shown
for the whole rise), then the same with the legs tucked (the pop). Her back arm stays hidden
behind her body in this view, so the poses read through the front arm.

### Fidusen's peel and book

Drawn by the 64 px generator in the same style (outline, three tones), at ¾ in the game:

- `assets/fighters/slot_13/peel.png`: a banana peel lying on the floor, 16×8, one drawing:
  yellow with brown tips, three floppy flaps; its bottom center is the peel's position.
- `assets/fighters/slot_13/projectile.png`: a book, 3 drawings of 16×16 turned 120° further each
  (it spins): a red cover with white page edges.
- His own **down special** pose (5 drawings: bend, drop, crouch, rise, stand) and **side special**
  pose (4 drawings: wind back, throw over the shoulder, follow-through, stand).

### Sjippepigen's arms

Sjippepigen has **3 pairs of arms** (`arm_pairs=3` in `tools/fighter64_looks.py`). The main pair
is drawn as usual (sleeves of her dress); the two extra pairs are bare (her bronze-green skin),
start just below the shoulders (1.5 px lower per pair) and copy the main arms' pose, evenly
fanned from the main arm toward a limit: out toward the horizontal, or down toward hanging when
the main arm is already out in front; a raised main arm's extras step back down to the
horizontal. An extra arm (and its forearm) never points above the horizontal unless the main arm
is raised, so no arm goes up on its own. Visual only: her hurtbox and moves are the
default ones.

### Michael's football

`assets/fighters/slot_05/projectile.png` (a character's own projectile picture; without one, the
shared `assets/fighters/projectile.png` is used): a black-and-white football, 16×16 per drawing,
3 drawings side by side, each turned a little further (it spins, 4 ticks per drawing, toward its
flight direction). In the 64 px style (outline, shading), drawn at ¾ (12 game px), centered on the
ball's position.

Michael's kick (`side_special`, 4 drawings) is his own: kicking leg back, swinging through,
leg up high in front (the follow-through), back to standing.

### Michael's hand

`assets/fighters/slot_05/hand.png`: his summoned hand, a giant **white glove** drawn by the 64 px
generator (white with grey shading, a rolled cuff, the same outline as the bodies), seen from the
side, palm down, fingers pointing forward, cuff at the back. Two drawings side by side, 56×44
each: **open** (hovering: fingers close together, fanning out slightly, knuckle creases, the
thumb hanging below) and **flat** (slamming: fingers together, palm flat on the bottom row). The palm's bottom center
is at the bottom center of the drawing; drawn at ¾ like the fighters, mirrored to Michael's
facing. While hovering it bobs 1 px every 8 ticks, and a shadow (a dark ellipse) on the floor
below it shows where it will land.

Michael's summon pose (`neutral_special`, 4 drawings) is his own: arm thrown forward and up,
palm open.

## Stages

- **Backgrounds:** one image per stage, **528×297** (the 480×270 screen plus 10% for parallax
  drift), in `super-mms-bros/assets/stage/backgrounds/`, named after the stage id
  (`mms.png`, `fc.png`, `slot_sunset.png`, `cafe_station.png`, `lindevej.png`, `cafe_slotsbio.png`). Paint at full brightness: the game tones
  backgrounds down with a haze.
- **Platforms:** drawn by the game in code, in perspective, from each stage's platform style (colors
  and front-face bands; see [match & stage](match-and-stage.md#platform-look-perspective)). New
  materials are added as new styles, not as images. Hand-drawn platform art is a later idea.

## HUD

- **Stock icon:** `stock_icon.png`, 8×8 px, one per character: a tiny head with a shirt collar in
  the character's own colors.
- **Off-screen arrow:** 8×8 px, pointing right (the game rotates it).
- **Damage digits:** drawn with the game's pixel font.
