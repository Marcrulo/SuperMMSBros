# Magnus

Magnus's own moves and drawings. The shared rules are in [moves](../moves.md) and the
[art guide](../art-guide.md).

## Magnus — the Avatar

Magnus bends the four elements: each special is one element. Landing a hit with each of the four
lights that element on his player card; with all four lit he goes into the **Avatar State** and
flies around the stage, untouchable. His normal attacks are the default move set. Every number
below is a starting value, tuned in playtesting.

| Special | Element | Idea |
|---|---|---|
| B | Water | Water gun: a short stream of droplets straight ahead |
| Side+B | Fire | Fireball straight ahead, one at a time |
| Up+B | Air | Wind burst: pushes everyone near him away and throws him high up |
| Down+B | Earth | Ground smash: rocks burst up on both sides (in the air he dives first) |

### Neutral special — water gun (Water)

`neutral_special.tres` with `ability` → `WaterGunData`; phase `water_gun`. No charge.

- On the ground or in the air. On the ground he slides to a stop; in the air the usual air
  steering and gravity apply.
- Frames 8 / 0 / 12: the move's `startup`, then 6 droplets (`drops`), one every 4 ticks
  (`interval`): droplet *k* leaves on frame 8 + 4 × *k*; the move ends 12 frames after the last.
- Each droplet leaves his front hand (`hitbox_center` (16, −14)) and flies straight ahead at
  300 px/s (`projectile_speed`) for at most 28 ticks (`projectile_lifetime`, about 140 px).
  Hitbox 8×6, damage 1.5, base 70, growth 0.25, angle 15°, launched in its flying direction: a
  small push that keeps the victim in the stream. Gone on a hit, a shield, the blast zone or its
  time; it flies through the stage. Droplets already out keep flying when he's hit (a KO removes
  them).

### Side special — fireball (Fire)

`side_special.tres` with `ability` → `FireballData`.

- On the ground or in the air, turning toward the held direction first (like the default side
  special). Frames 10 / 0 / 12; the fireball appears on frame 10 at (16, −14).
- It flies straight ahead at 260 px/s for at most 90 ticks; hitbox 12×10, damage 7, base 120,
  growth 0.9, angle 30°, launched in its flying direction. Gone on a hit, a shield, the blast zone
  or its time; it flies through the stage.
- **One fireball at a time:** while his fireball is out, Side+B does nothing.

### Up special — wind burst (Air)

`up_special.tres` (no ability of its own; the `AvatarAbility` watches it): the default up special
(jump boost, then `HELPLESS`, once per stay in the air) with stronger numbers.

- Launch speed 440 px/s (default 360), drift 90.
- The burst: on frames 5–16 a wide hitbox around him, (0, −16), 56×40, damage 4, base 250,
  growth 0.6, angle 40°, AWAY — it blows everyone near him away from him.

### Down special — earth smash (Earth)

`down_special.tres` and `down_special_dive.tres` (no ability of their own): the default down
special (in the air a dive that spikes, then the burst on landing) with his numbers.

- The burst: hitbox (0, −10), 64×20 (wider than the default 56×18), damage 11, base 230, growth
  1.5, angle 80°, AWAY. The dive is the default one.

### The elements on his card

- An element **lights** when a hit of its special **lands** (not blocked by a shield): any
  droplet (Water), the fireball (Fire), the wind burst (Air), the dive or the burst (Earth).
  It stays lit until the Avatar State ends — also when he's KO'd.
- At the start of a match (and at a reset) all four are dark.
- His player card shows four small icons (`ElementBadge`), dark when not lit, in the element's
  color when lit: water (blue drop), fire (orange flame), air (pale swirl), earth (green-brown
  block). During the Avatar State all four flash.

### Avatar State

When all four elements are lit, the next tick he's **free to act** (idle, running, crouching, in
the air, or helpless) he goes into the Avatar State (`AvatarAbility`, on the move set's own
`ability` → `AvatarData`):

1. **Rise** (phase `avatar_rise`, 60 ticks, `rise_frames`): he freezes in place (no movement,
   no gravity) and can't be hit. His eyes glow and the four elements appear around him one by
   one.
2. **Flight** (phase `avatar_fly`, 480 ticks, `fly_frames`): he flies freely, like Super Sonic:
   - No gravity. The held direction (left/right, up, down) sets where he flies: velocity moves
     toward that direction × 300 px/s (`fly_speed`) at 1800 px/s² (`fly_accel`); with nothing
     held he slows to a stop (also at `fly_accel`). Diagonals are as fast as straight lines.
     He faces the way he flies sideways.
   - He can't be hit, and he collides with the stage like anyone (he can't fly into the main
     platform; pass-through platforms let him through from below). He can't leave a box 24 px
     inside the blast zone (`edge_margin`), so he can't KO himself.
   - **Touching hurts:** a hitbox over his whole body, (0, −16), 32×36: damage 8, base 300, growth
     1.2, angle 45°, AWAY (`fly_hit`). It hits the same fighter again every 30 ticks
     (`rehit_frames`).
   - No attacks, specials, shield, jumps or ledge grabs during the flight.
3. **End:** after the flight he falls normally (state AIR) with his double jump, up special and
   air dodge back, and all four elements go dark again.

The four elements circle him during rise and flight: a water drop, a flame, a swirl of air and a
rock, on a ring of radius 22 px around the middle of his body, a full turn every 60 ticks.

### Files

`characters/magnus/moves/` (`moveset.tres`, `neutral_special.tres`, `water_gun.tres`,
`side_special.tres`, `fireball.tres`, `up_special.tres`, `down_special.tres`, `avatar.tres`,
`fly_hit.tres`); scripts `water_gun_data.gd`, `water_gun_ability.gd`, `droplet.gd`,
`fireball_data.gd`, `fireball_ability.gd`, `fireball.gd`, `avatar_data.gd`, `avatar_ability.gd`,
`element_badge.gd`. Tests `tests/test_magnus*.gd`.

## Look

- **Run:** the Naruto run — body leaning far forward, head low and forward, both arms stretched
  straight back behind him, legs taking long strides (his own `run` strip, 6 drawings).
- **Water gun:** his side special drawings (arms thrust forward); the droplets are drawn by the
  game: small blue drops with a light highlight, a dark outline.
- **Fireball:** his side special drawings; the fireball is drawn by the game: a flickering
  orange ball with a yellow core and a short tail.
- **Wind burst:** his up special drawings; while the burst is out pale wind arcs swirl around
  him.
- **Earth smash:** his down special drawings; while the burst is out, brown-grey rocks jut up
  out of the floor on both sides of him (drawn by the game).
- **Avatar State:** his own `avatar.png` strip (2 drawings): drawing 0 for the rise — upright
  and tall, arms spread low at his sides, legs together; drawing 1 for the flight — leaning far
  into the flight, arms back, legs trailing. In both his eyes glow (the whole eye pale cyan-white,
  behind his glasses), and the game draws a glow over each eye (`AvatarData.rise_eyes` /
  `fly_eyes`, game px from his feet, facing right): a soft pale-cyan halo (radius about 3 px)
  with a bright white-cyan core, pulsing a little (a cycle every 20 ticks); during the rise it
  fades in over the first 15 ticks. The four element orbs circle him (drawn by the game), with a faint
  pale-blue glow around him.
