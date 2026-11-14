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

A character can carry a weapon (Henrik: an acoustic guitar; Stig: a gold cross). It's drawn into the character's
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
- **Stig's cross:** a solid gold Latin cross, not a sword: a long beam about 39 px and a crossbar
  16 px wide near the top (the arm above it shorter than the side arms, so it reads as a Latin
  cross even when only the top shows), both beams about 4 px thick with square ends, bevelled (lit
  edges up and right, shaded down and left). He holds it 6 px up from the foot of the long beam
  and swings it like a sword (Henrik's poses, no choking up), so the crossbar is out at the far
  end. It never points below level, so in the follow-throughs it's held out forward instead of
  down into the floor. Frames 112×80 like Henrik's. On his back it hangs diagonally like Gitte's
  scissors, at the same slant: the cross head sticks out behind his neck at head height (left),
  the long beam slants down behind his body, and its foot pokes out just in front of his hip
  (right).
- **Stig's cross smash** (his `down_special`, 5 drawings), like a wizard driving his staff into
  the ground: the cross held upright in front of him in **both hands** (the back fist drawn over
  the beam just above the front one), well clear of his face; lifted higher; then (the strike
  drawing and the next) pushed straight down, its foot on the floor about 13 px ahead, as he drops
  to one knee; then getting up, still holding it upright. **The light** (`burst.png`, 4 drawings
  of 80×28, drawn at ¾ on the floor with its left edge 7 px ahead of his feet, so it starts at the
  cross's foot; 3 ticks each from the first active frame): a white flash where the cross hits,
  with short rays; then warm light fanning out forward along the floor up to ~26° (white core on
  the floor, pale yellow glow and three rays, a gold rim, a dithered far end), with a few
  twinkles; then the same breaking up as it fades. Colors: white (255, 255, 236), pale
  (255, 238, 150), gold (246, 196, 72).
- **Trine's iPad and coffee** (her `down_special`, 5 drawings; no weapon otherwise, frames stay
  64×64). **The iPad** stands on the floor in front of her feet on a kickstand, leaning back away
  from her, its screen turned to her, so we see its back: a 6×11 aluminium slab (lit top right,
  shaded bottom left), a dark camera dot near the top, a 1 px line of pale blue screen light along
  the edge facing her, the kickstand a thin line down behind it. **The screen's light** tints her
  face and hair blue (90, 175, 255), strongest near the screen and fading out over ~28 px
  (outlines untouched), a little stronger in the watching drawings. **The mug:** white, 4×5 with
  a shaded side and bottom and a handle toward her, in her front hand; at her chest it shows the
  coffee on top and a 2-pixel wisp of steam (the wisp shifts between the two watching drawings);
  for a sip it's tipped up to her lips (rim at her mouth, foot down and forward, a 7×6 tilted
  shape), her fist under its foot and her arm raised in front of her face, eyes closed. Her back hand rests on the floor behind
  her. Drawings: 1 bending down (mug in hand); 2 seated, legs out in front, watching, mug at her
  chest; 3 the same, the steam and light shifted, leaning a pixel; 4 sipping (head up a pixel, eyes closed);
  5 getting up (like 1). Sitting down shows 1 then 2 (5 ticks each). While she watches: 2 and 3
  alternate every 15 ticks for 30 ticks, then 4 for 30 ticks (a sip), round after round (a sip
  every second, half the time). Getting
  up shows 5.
  The heal "+" (presentation only): green (99, 199, 77) with a dark outline, 5×5 px, rising
  12 px above her head and fading over 20 ticks after each heal.
- **Sjippepigen's idle** is skipping on the spot (her ropes always spin): 4 drawings, landing
  (knees bent), a hop (her feet 4 px off the floor, toes down), landing, a hop with the other foot
  leading; her hands down by her hips, where the rope handles are. Her **run** skips along the
  same way: the run's strides with a hop in each (landing, 5 px up, coming down), hands by her hips.
- **Mads's lollipop:** a school crossing guard's stop sign: a white pole (about 2 px thick,
  shaded) with a round sign on top, about 15 px across, yellow-green (214, 226, 74), lit top left
  and shaded bottom right, with a white rim; about 36 px from the foot of the pole to the far edge
  of the sign. He holds it 4 px up from the foot of the pole. On his back it slants like Stig's
  cross (the sign up behind his head). Only his side tilt swings it (Henrik's side tilt poses, never
  pointing below level). His frames are 112×80 like the other weapon carriers.
- **Mads's stop smash** (his `down_special`, 5 drawings, Stig's cross smash poses with the
  lollipop): drawing 1 the lollipop held upright in both hands; 2 lifted, and it has turned into a
  **stop sign**: a red octagon (214, 40, 40), shaded bottom right (166, 26, 30), 21 px across with
  a white rim and **STOP** in white 3×5 pixel letters (1 px apart; the game draws each art pixel
  about 2 screen pixels wide, so they stay readable); 3 and 4 planted, its pole 10 px longer so the
  sign stands above his head; 5 getting up, the lollipop again. His burst (`burst.png`, as Stig's)
  is in stop-sign colors: white core, pale red glow (255, 156, 146), red rim.
  **Facing left:** the game mirrors drawings for facing left, which would mirror the lettering, so
  Mads has a second strip, `fighter_down_special_left.png`: the down special already mirrored but
  with STOP (and the sign's shading) the right way round. Any character may have such a
  `<animation>_left` strip; facing left the game draws it as it is instead of mirroring the usual
  one.
- **Mads's slam** (no weapon, frames stay 64×64). The reach (his `side_special`, 4 drawings):
  reaching forward with both arms out, leaning in (drawings 1–3, so the reach and a miss look the
  same); 4 straightening up. **The throw** has its own strip, `fighter_grab_throw.png` (6
  drawings, only for grapplers): 1 the catch, arms out in front (throw ticks 1–3); 2 lifting, both
  arms up in front (4–8); 3 overhead, leaning back, both arms up beside his head (9–14); 4 turned
  round (he now faces the other way), arms overhead, leaning toward the victim (15–18); 5 the slam,
  bent forward, both arms driven down in front (19–30); 6 straightening up (31–40). The victim's
  `path` (see [moves](moves.md#mads--grappler)) is fitted to his front fist in these drawings. The
  victim is drawn in their own `hurt` drawing behind him (`z_index` −1), turned round the middle of
  their body (π × t, head first over him), upright again once thrown.
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

### Pia's specials

No weapon; her frames stay 64×64. See [moves](moves.md#pia--cake-belly-flop-flag).

**Cake** (her `neutral_special` strip, 4 drawings, shown by the move's own timing, not the shared
one): a slice of layer cake (7×6, side on: pink icing with a red strawberry on top, white cream,
yellow sponge, cream, sponge) in her front hand. 1 taking it out, held at her chest (ticks 1–10);
2 a bite, the slice at her mouth, eyes shut (11–19 and 29–37); 3 chewing, the slice lowered, a
bite out of its front corner (20–28 and 38–45); 4 happy, eyes shut, slice gone, hand on her belly
(46–60).

**Belly flop** (her down special):

- **The hop** uses her usual `jump` drawings.
- **The dive** (`down_special_dive`, 1 drawing): flat on her belly in the air, shoulders toward
  the facing side, her head upright at the front looking ahead, one arm flailing up behind it,
  knees bent so her feet kick up behind her.
- **The flop** (`down_special`, 5 drawings, the shared timing): 1 the impact, flat on the floor,
  squashed a pixel, arm flailing, eyes shut; 2 and 3 lying flat, arms back along her body, her
  chin on the floor; 4 pushing herself up, crouched low and leaning forward; 5 crouching, getting
  up.
- The flat drawings are posed upright without the head, turned 90° (a quarter turn moves every
  pixel onto the grid, so the art isn't distorted) and set down with the lowest pixel on the
  floor row; then the head is drawn on upright at the front (3 px over the shoulders), so the
  face never turns sideways.
- **The dust** (`dust.png`, 4 drawings of 40×20, drawn at ¾ on both sides of her, mirrored, from
  6 px out from her feet; 3 ticks each from the first active frame, so on impact): puffs of
  pale dust (230, 220, 200) shaded (186, 174, 156) rolling out along the floor and up, growing,
  then breaking up and fading. Presentation only.

**German flag** (`projectile.png`, 3 drawings of 32×32, drawn at ¾): just the cloth, no pole:
16×9, black, red and gold stripes (3 px each), rippling as it flies — each column shifted up or
down a pixel by a wave that moves along it from drawing to drawing, a few columns shaded.

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
