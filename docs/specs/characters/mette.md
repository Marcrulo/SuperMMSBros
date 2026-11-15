# Mette

Mette's own moves and drawings. The shared rules are in [moves](../moves.md)
and the [art guide](../art-guide.md).

## Mette — potions

Mette is a chemistry and physics teacher. She throws flasks of potion that leave **puddles** on the
floor, and a flask of another colour thrown onto a puddle sets off a **reaction**. Puddles and
reactions affect **everyone, Mette too**. Her neutral, down and side specials are her own; everything else
is the default move set, and her neutral special smashes a flask in front of her. Every number
below is a starting value, tuned in playtesting.

**The potions** (in switching order): 🔴 **red** (acid), 🔵 **blue** (ice), 🟢 **green** (glue). She
holds red at every spawn.

**Down special — pick a potion** (`down_special.tres` with `ability` → `PotionData`): 8 / 0 / 7
(15) frames, on the ground or in the air (no dive). On frame 8 her potion switches to the next
colour: red → blue → green → red. The HUD card shows the colour she holds (see [Look](#look)).
The flask in her hand during the move shows only the new colour, from frame 1.

**Neutral special — flask smash** (`neutral_special.tres`): no charge, 8 / 4 / 14 (26) frames, on
the ground or in the air. She smashes the flask she holds in front of her: hitbox (16, −16),
20×18, launching toward her facing side; what it does depends on her potion (its hit is
`smash_red` / `smash_blue` / `smash_green` in `PotionData`):

| Potion | Effect | Hit |
|---|---|---|
| 🔴 red | **damage** | 12 %, base 70, growth 0.5, angle 40° |
| 🔵 blue | **knockback** | 4 %, base 150, growth 1.8, angle 40° |
| 🟢 green | **stun** | 4 %, base 30, growth 0, angle 40°, then the victim is stunned (dizzy, as after a shield break) for 60 ticks (`smash_stun`) |

- A shield blocks it (no stun). It leaves no puddle. She keeps her potion.
- The stun comes through `Fighter.stun()` ([fighter](../fighter.md#shield)).


**Side special — throw a flask** (`side_special.tres` with `ability` → `PotionData`, the same
resource): 10 / 0 / 14 (24) frames, on the ground or in the air. On frame 10 a flask of the
colour she holds leaves her hand at (12, −18), flying toward her facing side at 230 px/s, 40°
upward, falling with gravity 700 px/s². **One flask at a time:** while hers is in flight, the K
press does nothing (as with the default projectile).

- **It shatters** when it lands on a floor (the main platform or a pass-through platform, coming
  down onto its top), when it touches another fighter, or a shield. Its own thrower can't be hit
  by her flask in flight.
- **Hitting a fighter:** 3 % damage, base 60, growth 0.3, angle 40°, launched in its direction.
- **Splash:** where it shatters, its potion falls onto the floor below (the floor it landed on, or
  the floor under where it hit a fighter or shield, if that is at most 48 px below). With no floor
  that close, it splashes away and nothing happens.
- Out of the blast zone or after 120 ticks it is gone (no splash).

**Puddles:** a splash on the floor makes a puddle of its colour: 40 px wide, its bottom center on
the floor at the splash point; its area is 40 × 6 above the floor. It lasts 480 ticks (8 s). **Up
to 2 puddles** of hers at once: a 3rd removes her oldest (no reaction).

- A splash that lands on a puddle (its point within the puddle's width, on the same floor):
  - **same colour:** the puddle is refilled (its 480 ticks start over); no new puddle.
  - **another colour:** a **reaction** at the puddle's center; the puddle is gone.
- A fighter **stands in** a puddle when it is on the floor (not hanging from a ledge, climbing,
  KO'd or held) and its hurtbox touches the puddle's area. Standing in a puddle:
  - 🔴 **acid:** 1 % damage every 15 ticks it stands in it (4 % a second), only while it can be
    hit. No hitstun.
  - 🔵 **ice:** slippery: its ground acceleration and friction are ×0.1, so it slides.
  - 🟢 **glue:** sticky: its run speed is ×0.4 and its jump speed ×0.7.
- The effects come through the fighter's **ground modifiers** (`Fighter.ground_grip`,
  `ground_speed`, `ground_jump`, see [fighter](../fighter.md#ground-modifiers)), set by the
  puddle for the fighter's next tick.

**Reactions** (each at the puddle's center on the floor; they hit every fighter, Mette too, each
fighter at most once per reaction; a shield blocks them like any hit):

| Colours | Reaction | Area (bottom center on the floor) | Lasts | Hit |
|---|---|---|---|---|
| 🔴 + 🔵 | **steam**: a column that blows fighters upward | 24 × 96 | 40 ticks | 3 %, base 230, growth 0.3, angle 90° |
| 🔴 + 🟢 | **explosion** | 64 × 48 | 6 ticks | 14 %, base 200, growth 1.6, angle 50°, away from its center |
| 🔵 + 🟢 | **elephant toothpaste**: a foam pillar | 32 wide, rising to 56 high | see below | none |

- **The foam pillar** rises out of the floor over 12 ticks, stands for 300 ticks (5 s), then
  shrinks back into the floor over 20 ticks and is gone. Once fully risen, its top is a
  **pass-through platform** (stand on it, jump up through it, drop down through it). While it
  rises, a fighter standing in it is popped up once (vertical speed −320 px/s, no damage, no
  hitstun), so it ends up above the pillar.

Files: `characters/mette/` (`potion_data.gd`, `potion_ability.gd`, `flask.gd`, `puddle.gd`,
`reaction.gd`, `potion_badge.gd`, `potion_look.gd`), `characters/mette/moves/` (`moveset.tres`,
`neutral_special.tres`, `smash_red.tres`, `smash_blue.tres`, `smash_green.tres`, `down_special.tres`, `side_special.tres`, `potions.tres`, `steam_hit.tres`, `explosion_hit.tres`).

## Look

Drawn by the game itself (pixel style, outlined), not by the sprite generator, for now; her body
uses the default poses.

- **Potion colours:** red (220, 52, 52), blue (60, 130, 230), green (90, 190, 70), each with a
  darker and a lighter shade.
- **The flask:** a round-bottomed glass flask (a 7 px bulb and a 2 px neck with a cork), the
  potion filling the bulb; it spins while flying. She **always holds a flask of the colour she
  holds** in her front hand, in every drawing, so it's easy to see which potion is active
  (during the down special, only the new colour, from frame 1). Her hand is empty only from the
  throw to the end of her side special, and from the smash to the end of her neutral special.
  Where her front hand is in each drawing comes from `assets/fighters/slot_10/hands.json`
  (written by the sprite generator: per animation, per drawing, the front fist in game px from
  the feet, facing right); the flask sits upright with its bulb in her fist. The smash
  shows a burst of glass and droplets of her potion's colour in front of her. Her neutral special
  uses the default punch drawings, timed to its frames (wind-up, smash on the active frames, then
  recovery).
- **Puddles:** a flat blob of its colour on the floor, a light rim on top; acid bubbles, ice has a
  white glint, glue has a few drips at its edges.
- **Steam:** grey-white puffs rising up the column, fading out. **Explosion:** an orange-yellow
  ball that grows and fades. **Foam:** a white pillar with a pale blue-green tint, bubbly edges.
- **HUD badge:** on the portrait's bottom-right corner, a small dark square with a flask of the
  colour she holds.
