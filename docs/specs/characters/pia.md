# Pia

Pia's own moves and drawings. The shared rules are in [moves](../moves.md)
and the [art guide](../art-guide.md).

## Pia — cake, belly flop, flag

Pia's three own specials: **eating cake** (neutral special), the **belly flop** (down special)
and **throwing a German flag** (side special). Her up special and normal attacks are the default.

### Neutral special — cake

She takes out a slice of cake and eats it, healing (phase `cake`; no charging).

- **On the ground only;** in the air the K press does nothing.
- 45 / 0 / 15 (60) frames, no hitbox: she takes the slice out, takes bites and chews; on frame
  45 (`heal_frame`) she's eaten it and her % drops by 8 (`heal`), not below 0; then she pats her
  belly. She can't move, turn or act meanwhile (on the ground she slides to a stop).
- **A hit stops it** like any move; if it comes before frame 45 she doesn't heal.
- **Cooldown:** after a slice she can't eat again for 300 ticks (5 s, `cooldown_frames`,
  counted from the heal; `CakeAbility.cake_cooldown`, 0 at every spawn). Until then the K press does
  nothing.
- **Data:** the special's `MoveData.ability` is a `CakeData` (`cake.tres`: `heal`, `heal_frame`,
  `cooldown_frames`); the `CakeAbility`.
- A green "+" rises above her head when she heals (like Trine's).

### Down special — belly flop

A ground pound done as a belly flop: she throws herself up, turns flat on her belly in the air
and comes down on it, and the impact hits everyone near her on both sides.

- **On the ground: a hop first** (`belly_hop`): she jumps straight up at 240 px/s
  (`hop_speed`; about 46 px high) and can steer in the air as usual (no hitbox). When she stops
  rising, the dive starts.
- **In the air:** the dive starts at once (no hop).
- **The dive** (`belly_dive`): flat on her belly, she drops straight down at 400 px/s
  (`dive_speed`, no steering) until she lands. Her belly hits whoever is under her
  (`dive_hit`): hitbox (0, −7), 36×14, damage 7, base 150, growth 1.1, angle −70°, AWAY — it
  drives the victim down (a victim standing on the ground bounces up instead, like the default
  dive).
- **The flop** (`belly_flop`, on landing, from frame 1; the down special's own data):
  0 / 6 / 22 (28) frames — the impact is on the landing tick itself (no startup), then she lies
  flat and gets up. The shockwave hits on both sides: hitbox (0, −8), 80×16 (40 px each side of
  her feet, up to 16 px high), damage 11 (plus the dive's bonus, below), base 200, growth 1.4, angle 70°, AWAY: up and away from
  her. It can hit someone the belly already hit. A shield blocks both.
- **The longer the dive, the harder the flop:** the flop's damage goes up by 1 for every 5 ticks
  she spent diving, the landing tick included (`dive_ticks_per_damage`; 5 ticks ≈ 33 px at the
  dive speed), up to +10 (`max_dive_damage`, reached after 50 ticks ≈ 333 px, about a drop from
  the top of the screen). After the ground hop the dive lasts about 7 ticks, so a flop from the
  ground does 12; one from the top does 21. Only the flop
  grows, not the belly's hit; the knockback grows with it through the victim's new damage %.
- **Data:** the special's `MoveData.ability` is a `FlopData` (`flop.tres`: `dive_hit`, `hop_speed`,
  `dive_ticks_per_damage`, `max_dive_damage`); the dive speed is the special's own `dive_speed`;
  the `FlopAbility`.
- **Look:** see [art guide](#pias-specials): a dust cloud bursts out on both sides on
  impact.

### Side special — German flag

She throws a German flag — just the cloth, no pole — straight ahead. It works like the
[side special](../moves.md#side-special--projectile) (same frames 10 / 0 / 12, one at a time, straight
ahead, passes through platforms, gone on a hit, a shield, the blast zone or after 120 ticks),
with its own picture and numbers: it appears at (16, −16), flies at 260 px/s, hitbox 12×8,
damage 6, base 100, growth 0.6, angle 30°.

Files: `characters/pia/moves/` (`moveset.tres`, `neutral_special.tres`, `down_special.tres`,
`belly_dive.tres`, `side_special.tres`).

## Look

### Pia's specials

No weapon; her frames stay 64×64. See [moves](#pia--cake-belly-flop-flag).

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
