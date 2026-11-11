# Moves

The default fighter's move set: four ground attacks, five air attacks, four specials, how damage % turns into
knockback, and the projectile. How a fighter enters and leaves a move is in [fighter](fighter.md).

All numbers are starting values, tuned in playtesting (M9). They live in resources, never in code:
each move is a `MoveData` resource, and a `MoveSet` resource lists the moves of one design
(`fighter/moves/default/*.tres`). `FighterStats.moveset` points at it, so a future character is
a new `FighterStats` + `MoveSet` + sprite folder. A character can also keep the shared stats and
swap only its moves: see [character move sets](#character-move-sets).

## Picking a move

The move is decided on the tick the button goes down, from the direction held on that tick:

| Held | J on the ground | J in the air | K (special, "B") |
|---|---|---|---|
| up (`up_held`) | up tilt | up air | up special |
| down (`down_held`) | down tilt | down air | down special |
| toward the facing side | side tilt | forward air | side special |
| away from the facing side | side tilt (turns first) | back air | side special (turns first, also in the air) |
| nothing | jab | neutral air | neutral special |

Up wins over down, and both win over sideways. A side move on the ground turns the fighter toward
the held direction first; in the air the fighter keeps facing where it faced (so holding back
gives the back air) — except the side special, which turns toward the held direction in the air
too, so it always fires where you hold.

Recovery (the frames after the hit when the fighter can't act) is kept short on every move, so
the fighter is free again soon after the strike.

A normal attack (ground or air) started in the air
ends immediately when the fighter lands (no landing lag). Specials keep going when they land
(neutral special's charge or punch, side special, up special's startup) — except down special's
dive, which turns into the burst, and `HELPLESS`, which ends.

## `MoveData`

| Field | Meaning |
|---|---|
| `startup`, `active`, `recovery` | Frame counts; the tick the move starts is frame 1 |
| `hitbox_center`, `hitbox_size` | Hitbox rectangle relative to the feet, **facing right** (mirrored when facing left) |
| `damage` | % added to the victim |
| `base_knockback`, `knockback_growth` | Launch speed = base + growth × victim's % (after this hit's damage), in px/s |
| `angle_deg` | Launch angle above horizontal; negative launches downward (a spike) |
| `direction` | `FACING`: launched toward the attacker's facing side. `AWAY`: launched away from the attacker's center (for moves that hit both sides or behind) |

Every move has its own clear launch angle; where exactly the hitboxes overlap doesn't change it.

A move hits each fighter at most once.

## Ground attacks (J)

| Move | Frames (startup / active / recovery, total) | Hitbox center, size | Damage | Base, growth | Angle | Direction | Idea |
|---|---|---|---|---|---|---|---|
| Jab | 4 / 3 / 7 (14) | (15, −13), 14×10 | 3 | 120, 0.8 | 30° | FACING | Quick punch, sends slightly up |
| Down tilt | 5 / 3 / 7 (15) | (14, −3), 18×6 | 6 | 100, 0.6 | 80° | FACING | Low kick that pops them a little up, for combos |
| Up tilt | 5 / 4 / 8 (17) | (2, −31), 24×12 | 7 | 160, 1.2 | 90° | AWAY | Swipe over the head, launches straight up |
| Side tilt | 7 / 3 / 10 (20) | (19, −12), 18×8 | 9 | 180, 1.6 | 35° | FACING | Slower kick with reach and power |

On the ground the fighter can't steer during an attack (speed moves toward 0 at
`ground_friction`). In the air it keeps air steering and gravity.

## Air attacks (J in the air)

Hitboxes are relative to the feet, facing right, like the ground attacks.

| Move | Frames (startup / active / recovery, total) | Hitbox center, size | Damage | Base, growth | Angle | Direction | Idea |
|---|---|---|---|---|---|---|---|
| Neutral air | 3 / 6 / 6 (15) | (0, −13), 28×26 | 5 | 110, 0.9 | 45° | AWAY | Spin that hits all around the body |
| Forward air | 5 / 3 / 7 (15) | (16, −14), 16×12 | 7 | 140, 1.2 | 40° | FACING | Punch in front |
| Back air | 6 / 3 / 8 (17) | (−16, −12), 16×12 | 9 | 170, 1.4 | 35° | AWAY | Kick behind, a bit stronger |
| Up air | 4 / 4 / 7 (15) | (2, −32), 24×12 | 6 | 140, 1.0 | 85° | AWAY | Swipe overhead, for juggling |
| Down air | 6 / 3 / 8 (17) | (0, 4), 18×10 | 6 | 110, 0.6 | 75° | AWAY | Stomp under the feet that pops them a little up, a combo starter (not a spike) |

## Specials (K)

### Neutral special — charged punch

1. **Charging:** while K stays held, the fighter charges, up to 60 ticks (`charge_frames`). On the
   ground it slides to a stop; in the air it keeps falling and steering normally. The fists glow
   brighter as the charge grows.
2. **Punch:** releasing K, or reaching the full charge, starts the punch with
   `charge = ticks charged / 60` (0…1): 3 / 4 / 10 (17) frames, hitbox (16, −13), 16×12,
   damage 8 + 14 × charge, base knockback 200 + 200 × charge, growth 2.0, angle 38°, FACING.

Getting hit while charging loses the charge.

### Down special — ground energy burst

- **On the ground:** 10 / 6 / 12 (28) frames. The burst erupts on both sides: hitbox (0, −9),
  56×18, damage 10, base 220, growth 1.5, angle 80°, AWAY.
- **In the air:** the fighter dives straight down at 360 px/s (no steering, no hitbox) until it
  lands, then the ground version starts at frame 1. Diving off the stage is a risk the player takes.
- **The dive spikes:** for the whole dive a hitbox at (0, −4), 20×14 is out: damage 8, base 160,
  growth 1.2, angle −75°, AWAY — it drives the victim down. A victim standing on the ground bounces
  up instead (see the ground bounce below). The burst on landing can hit the same victim again.

### Side special — projectile

- 10 / 0 / 12 (22) frames; the projectile appears on frame 10 at (16, −13), flying toward the
  fighter's facing side. Usable on the ground and in the air (gravity keeps working in the air).
- **One projectile per fighter:** while the fighter's projectile is still out, side special can't be
  started (the K press does nothing).
- **The projectile:** 8×6 px, 240 px/s straight ahead, no gravity. Damage 5, base 90, growth 0.5,
  angle 30°, launches in the projectile's direction. It disappears when it hits a fighter or a
  shield, when it leaves the blast zone, or after 120 ticks. It passes through platforms. It
  can't hit its owner.

### Up special — jump boost

- 4 frames of startup on the ground or in the air. On frame 5 the fighter launches: vertical speed
  −360 px/s, horizontal speed `move_x × 80`. Then normal gravity and air steering (top speed 80).
- Hitbox on frames 5–16: (0, −14), 20×30, damage 6, base 150, growth 0.8, angle 85°, AWAY.
- When the fighter stops rising, it becomes `HELPLESS` (see [fighter](fighter.md#helpless)) until it
  lands or is hit.
- Usable once per stay in the air: landing or being hit allows it again.

## Character move sets

A character whose `CharacterData.moveset` is set plays with that move set instead of the one in
its `FighterStats` (every other stat stays shared). Its own moves keep the default move's frame
counts, so the shared animation timing still fits; only the hitbox and the hit change. Moves it
doesn't change point at the default `.tres` files.

### Henrik — guitar

Henrik carries an acoustic guitar on his back (see [art guide](art-guide.md#weapons)). Three moves swing it;
everything else is the default move set, with the guitar staying on his back.

| Move | Frames | Hitbox center, size | Damage | Base, growth | Angle | Direction | Idea |
|---|---|---|---|---|---|---|---|
| Jab | 4 / 3 / 7 (14) | (18, −10), 20×12 | 3 | 120, 0.8 | 30° | FACING | Light, quick low swing, holding the neck halfway down (choked up); a little more reach than a punch |
| Side tilt | 7 / 3 / 10 (20) | (29, −16), 24×12 | 7 | 160, 1.3 | 35° | FACING | Light swing at arm's length, holding the end of the neck: long reach, a bit weaker than the default kick |
| Neutral special | 3 / 4 / 10 (17), charge 60 | (20, −30), 40×24 | 8 + 14 × charge | 200 + 200 × charge, 2.0 | 45° | FACING | Charged overhead swing: he raises the guitar behind his head while charging, then brings it over his head and down in front, hitting above and in front |

The hitboxes cover where the guitar is drawn in each move's strike drawing (jab reaches 28 px,
side tilt 41, the overhead swing 40 and up to 42 px above the feet). His charge glow is on the
raised guitar's body, `charge_glow` (−21, −45).

Files: `fighter/moves/henrik/` (`moveset.tres` + `jab.tres`, `side_tilt.tres`,
`neutral_special.tres`).

### Michael Bech — football

Michael's side special kicks a football (soccer ball) instead of the default projectile. It
works like the [side special](#side-special--projectile) (same frames 10 / 0 / 12, one projectile
at a time, passes through platforms and floors, disappears on a hit, a shield, the blast zone or
after 120 ticks), with these differences:

- **It flies at an angle**, in a straight line, toward his facing side: angle 0 is straight ahead,
  positive is upward, between −45° and 45° (`MoveData.aim_cone_deg` = 45).
- **Aimed at the nearest enemy he can see:** on the tick the ball appears, every other fighter
  that isn't KO'd and whose center is on his facing side, within the ±45° cone from the ball and
  at most 200 px from it (`MoveData.aim_range`) counts; the ball flies straight at the nearest
  one's center.
- **Otherwise a random angle** between −45° and 45°, from the Match's seeded RNG.
- It appears at (14, −8) from his feet (at his kicking foot), 240 px/s, hitbox 8×8. Damage 6,
  base 110, growth 0.6, angle 30°, launched in the ball's direction (left or right).
- It spins while flying (its own picture: [art guide](art-guide.md#michaels-football)).
- File: `fighter/moves/michael/side_special.tres`.

A projectile's flight angle is 0 for every other side special (straight ahead, as before).

### Gitte — scissors and stances

Gitte carries a large pair of scissors on her back (see [art guide](art-guide.md#weapons)). All
four of her specials are her own; everything else is the default move set.

**Neutral special — scissor cut** (`neutral_special.tres`): charged like the default one (hold K up
to 60 ticks; she holds the scissors out in front, open, while charging), then she snaps them shut:
3 / 4 / 10 (17) frames, hitbox (26, −16), 24×14, damage 8 + 14 × charge, base 200 + 200 × charge,
growth 2.0, angle 38°, FACING. Her charge glow is on the open blades (`charge_glow` (24, −18)).

**Side special — scissor volley** (`side_special.tres`): 10 / 0 / 12 (22) frames; on frame 10 three
small scissors fly out at once from (16, −14), straight, in a fan: 0°, +12° and −12°
(`projectile_count` 3, `projectile_spread_deg` 12), 260 px/s, 90 ticks, hitbox 8×6, each damage 4,
base 90, growth 0.5, angle 30°, launched in their direction. Each can hit once and is gone on a
hit, a shield, the blast zone or its time. No new volley while any of hers is still out. They
spin while flying (her own picture).

**Down special — stance switch** (`down_special.tres` with `stances` → `StanceData`): 15 / 0 / 0
(15) frames, on the ground or in the air (no dive, no hitbox). On frame 8 she switches to the next
stance: `+` → `−` → `÷` → `×` → `+`. She starts every match and every stock in `+`
(`spawn_at()`). The stance shows on her player card ([HUD](match-and-stage.md#hud)).

| Stance | Effect |
|---|---|
| `+` plus | Her projectiles (the volley) do ×1.5 damage (fixed when thrown). |
| `−` minus | Her normal attacks (jab, tilts, aerials; not B moves) heal her: her % drops by 50 % of the damage each hit deals (not below 0; blocked hits don't heal). |
| `÷` divide | Small: size ×0.75 — sprite, body, hurtbox, move hitboxes (center and size), ledge grab box and hang offset all scale from her feet. Faster: run speed and air speed ×1.25. |
| `×` multiply | Large: size ×1.25 (the same things scale). Her specials (neutral, side, up) do ×1.3 damage and ×1.3 base knockback. |

The numbers live in `StanceData` (`projectile_damage` 1.5, `lifesteal` 0.5, `small_scale` 0.75,
`small_speed` 1.25, `large_scale` 1.25, `large_special` 1.3).

**Up special — pyramid** (`up_special.tres` with `pyramid` → `PyramidData`): a sandstone pyramid
rises out of the ground under her and lifts her up. It needs ground: a strong move on the stage, a
poor recovery off it.

- 4 frames of startup (no launch), on the ground or in the air; once per stay in the air like the
  default up special.
- On frame 4 the Match looks for the floor below her feet (the main platform or a pass-through
  platform: `Stage.floor_below(feet − (0, 1), true)`). If its top is at most 64 px below her feet
  (`reach`) → **pyramid**; otherwise (no floor, or too far) → **hop**.
- **Pyramid:** a pyramid appears at her x on that floor and rises out of it: its tip goes from the
  floor top straight up to 96 px above it (`height`) over 18 ticks (`rise_frames`), at a steady
  speed. She stays at her x; her feet are at the tip, or where they were if the tip hasn't reached
  them yet (in the air she waits, not falling, until it does). She's moved with physics, so a
  solid ceiling would stop her. At the top she pops off: vertical speed −180 px/s (`pop_speed`),
  horizontal `move_x × 80` (drift speed), and carries on like a launched up special: air steering,
  gravity, `HELPLESS` once she stops rising, ledges can be grabbed while rising.
- **The tip hits:** while it rises, a hitbox on the tip: center (0, −10) from the tip, 32×28 (the
  pyramid's, so it doesn't change with her stance size); damage 7, base 160, growth 0.8,
  angle 85°, AWAY (from Gitte's center); each fighter once. × boosts it like her other specials.
- **Hop** (no ground in reach): vertical speed −200 px/s (`hop_speed`), no hitbox, then like the
  launched up special (`HELPLESS` once she stops rising).
- **The pyramid goes:** once she pops off — or when the rise ends early because she's hit or
  KO'd — it sinks back into the floor over 20 ticks (`sink_frames`) and is gone. While sinking it
  has no hitbox and nobody stands on it (it isn't solid at any time; it only carries her). It's
  also gone on `Match.reset()`.
- **Data:** `PyramidData`: `reach` 64, `height` 96, `rise_frames` 18, `pop_speed` 180,
  `hop_speed` 200, `sink_frames` 20, `tip_hit` (a `MoveData`: startup 0, active 18, the hitbox and
  hit values). Her own `up_special.tres` keeps the default's 4 startup frames and drift speed 80,
  with no hitbox of its own (active 0).

Files: `fighter/moves/gitte/` (`moveset.tres`, `neutral_special.tres`, `side_special.tres`,
`down_special.tres`, `stances.tres`, `up_special.tres`, `pyramid.tres`, `pyramid_tip_hit.tres`).

### Fidusen — banana, book, vine

Fidusen's down, side and up specials are his own; everything else is the default move set.

**Down special — banana peel** (`down_special.tres` with `peel` → `PeelData`):

- 8 / 0 / 10 (18) frames, on the ground or in the air (no dive). On frame 8 a peel appears at
  (8, 0) from his feet, facing side mirrored. In the air it falls at 300 px/s to the floor below it
  (the main platform or a pass-through platform: `Stage.floor_below(point, true)`); with none, it
  falls out of the blast zone and is gone.
- **Up to 3 peels** of his at a time: a 4th removes his oldest. Each lasts 600 ticks (10 s).
- **Tripping:** a fighter other than Fidusen who is on the ground (a grounded state, not `LEDGE`,
  `LEDGE_CLIMB`, `KO` or `TRIPPED`), can be hit, and whose hurtbox touches a landed peel (12×4,
  bottom center at the peel's position) slips: 3 % damage, no launch (horizontal speed 0), state
  `TRIPPED` for 45 ticks, and the peel is gone. Shields don't protect from it. A peel trips one
  fighter. Jumping over it is safe (airborne fighters don't trip).

**Side special — book** (`side_special.tres`): like the [side special](#side-special--projectile)
(10 / 0 / 12, one at a time), but the book is thrown at 25° upward (`projectile_angle_deg`) at
240 px/s and falls with gravity 700 px/s² (`projectile_gravity`), spinning. It appears at (14, −16);
hitbox 10×8; damage 7, base 120, growth 0.7, angle 40°, launched in its direction. It's gone on a
hit or a shield, when it lands on the main platform (it passes through the pass-through
platforms), out of the blast zone, or after 120 ticks.

**Up special — vine** (`up_special.tres` with `vine` → `VineData`):

- 6 frames of startup (no launch), on the ground or in the air; once per stay in the air like the
  default up special.
- On frame 6 the Match picks: the nearest **ledge** that nobody holds, whose corner is at most
  100 px from his center, that he's beside or below (feet at most 4 px above the corner, not more
  than 4 px on the stage side of it) → **pull**: over 12 ticks he moves in a straight line to the
  ledge's hang position (no physics), then grabs it (as a normal ledge grab).
- Otherwise → **swing**: a vine hangs from an anchor 140 px straight above his feet. He swings
  forward on it (toward his facing side) at a constant 2.09 rad/s: 60° in 30 ticks, his feet at
  `anchor + 140 × (sin φ × facing, cos φ)` (moved with physics, so floors and walls stop him).
  Then he lets go with the swing's speed (140 × 2.09 px/s along the arc's tangent: about
  (146 × facing, −254) px/s) and carries on like a launched up special: air steering, gravity,
  `HELPLESS` once he stops rising, ledges can be grabbed while rising.
- Getting hit ends the vine.

Files: `fighter/moves/fidusen/` (`moveset.tres`, `down_special.tres`, `peel.tres`,
`side_special.tres`, `up_special.tres`, `vine.tres`).

### Michael Bech — big hand

Michael's neutral special summons a giant white-gloved hand that
hovers in front of him for a second, then slams down. Everything else is the default move set.

- **Summon** (`neutral_special`, no charge): 10 / 0 / 7 (17) frames, on the ground or in the air.
  On frame 10 the hand appears. Then Michael is free again (7 frames of recovery); the hand
  carries on by itself.
- **One hand at a time:** while his hand is out, the K press does nothing (like the projectile).
- **Where:** the hand's palm (the bottom center of its hitbox) appears at (60, −50) from his feet,
  facing side mirrored, and stays at that spot however Michael moves.
- **Hover:** 60 ticks (1 second) in place. Touching it hurts a little: hitbox 28×20 above the
  palm, damage 4, base 100, growth 0.4, angle 45°, AWAY (from the hand's center). It hits each
  fighter at most once while hovering.
- **Slam:** then it drops straight down at 600 px/s, through the pass-through platforms, until
  its palm reaches the main platform (`Stage.floor_below()`), and stays there 8 ticks (the
  impact). While dropping and during the
  impact: damage 14, base 280, growth 1.5, angle 90° (straight up), AWAY. It hits each fighter
  at most once during the slam (a fighter hit by the hover can be hit again by the slam).
- With no main platform under it, it keeps falling and disappears when it leaves the blast zone.
- It disappears after the impact, when Michael is KO'd, or on `Match.reset()`. A shield blocks it
  like a projectile hit (the hand keeps going). It can't hit Michael.
- **Data:** the summon is a `MoveData` whose `hand` points at a `HandData` resource (offset, size,
  hover frames, slam speed, impact frames, `hover_hit` and `slam_hit` as `MoveData` for the hit
  values). Files: `fighter/moves/michael/` (`moveset.tres`, `neutral_special.tres`,
  `hand.tres`, `hand_hover_hit.tres`, `hand_slam_hit.tres`).

## Damage % and knockback

When a hit lands on a fighter that isn't shielding:

1. `percent += damage` (capped at 999).
2. `speed = base_knockback + knockback_growth × percent`.
3. Velocity = `(cos(angle) × speed × side, −sin(angle) × speed)`, where `side` is the attacker's
   facing (`FACING`), the side of the victim relative to the attacker's center (`AWAY`; the
   attacker's facing if they're level), or the projectile's direction.
   **Ground bounce:** if the victim is standing on the ground and the velocity points down (a
   spike), its vertical part is flipped: the victim bounces up instead of being driven into the
   floor.
4. Hitstun ticks = `max(min_hitstun, round(speed × hitstun_per_knockback))` (victim's stats:
   `min_hitstun` 6, `hitstun_per_knockback` 0.06 → 300 px/s gives 18 ticks).

`percent` goes back to 0 when the fighter respawns. Shielded hits are in
[fighter](fighter.md#shield).
