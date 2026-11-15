# Pia

Pia's own moves and drawings. The shared rules are in [moves](../moves.md)
and the [art guide](../art-guide.md).

## Pia — cake, belly flop, flag, banner

Pia's four own specials: **eating cake** (neutral special), the **belly flop** (down special),
**throwing a German flag** (side special) and **holding up a Bayer Leverkusen banner** (up
special). Her normal attacks are the default.

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

### Up special — Leverkusen banner

She holds up a fan scarf of her football club, Bayer Leverkusen, with both hands, and everyone near her is stunned
while she holds it (phase `banner`). It replaces the jump boost, so she has no recovery move: only
her jumps get her back.

- **On the ground only;** in the air the K press does nothing (and so it never uses up
  `up_special_available`).
- 98 / 0 / 10 (108) frames, no hitbox: she raises the banner (frames 1–8, `raise_frames`), holds
  it up (frames 9–98) and lowers it (99–108). She can't move, turn or act meanwhile (on the ground
  she slides to a stop).
- **The stun:** on every tick the banner is up (frames 9–98), every other fighter whose center is
  within 100 px of hers (`radius`) is stunned — dizzy, through `Fighter.stun()`, as after a shield
  break — until the banner goes down: someone stunned on frame *f* is free again on frame 99.
  Someone who comes into range later (walks or falls in) is stunned then, until the same frame.
  In the air they keep falling. A shield doesn't help (it's a gesture, not an attack); nobody who
  can't be hit (`Fighter.can_be_hit()`: dodging, invulnerable after a respawn, KO'd, held) and
  nobody in hitstun is stunned (a fighter in hitstun is, once it ends, if still in range). Someone
  already dizzy from something else is left alone. On frame 98 itself nobody new is stunned (they'd
  be free on the next tick anyway). No damage.
- **A hit stops it** like any move; then everyone it stunned is let go (`stun(1)`: free on the
  tick after next).
- **Cooldown:** after a banner she can't raise it again for 180 ticks (3 s, `cooldown_frames`,
  counted from the tick it ends or is stopped; `BannerAbility.banner_cooldown`, 0 at every spawn).
  Until then the K press does nothing.
- **Data:** the special's `MoveData.ability` is a `BannerData` (`banner.tres`: `raise_frames`,
  `radius`, `cooldown_frames`); the `BannerAbility`.
- **Look:** see [the banner](#pias-specials); a faint red ring on the ground shows the range while
  the banner is up (presentation only).

Files: `characters/pia/moves/` (`moveset.tres`, `neutral_special.tres`, `down_special.tres`,
`belly_dive.tres`, `side_special.tres`, `up_special.tres`).

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

**Leverkusen banner** — a football fan scarf (its own strip `banner`, 4 drawings, shown by the
move's own timing; her `up_special` strip stays the shared one, unused): a long scarf (9 rows: a
black edge, 7 red rows with "BAYER" in white 3×5 letters, a black edge; its last 2 columns at
each end black, with a 3 px red-and-black fringe hanging from each end) stretched between her two
fists, reaching 4 px past each. 1 raising it: both hands at her chest, the scarf hanging below
them (ticks 1–8); 2 and 3 held high: both arms up in a V, the scarf over her head just above her
fists (they show under its edge); 3 pumped higher, arms straighter, eyes shut, beaming —
switching every 8 ticks from tick 9 to 98; 4 lowering it, as 1 (99–108). Facing left the game
draws `banner_left` (already mirrored, the letters readable). No white disc with a cross: at this
size that reads as the wrong flag. The ring (drawn by the game): a 1 px red circle, radius 100, at a third opacity, round
her center, while the banner is up.

**German flag** (`projectile.png`, 3 drawings of 32×32, drawn at ¾): just the cloth, no pole:
16×9, black, red and gold stripes (3 px each), rippling as it flies — each column shifted up or
down a pixel by a wave that moves along it from drawing to drawing, a few columns shaded.
