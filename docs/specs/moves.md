# Moves

The default fighter's move set: four ground attacks, five air attacks, four specials, how damage % turns into
knockback, and the projectile. How a fighter enters and leaves a move is in [fighter](fighter.md).

All numbers are starting values, tuned in playtesting (M9). They live in resources, never in code:
each move is a `MoveData` resource, and a `MoveSet` resource lists the moves of one design
(`fighter/moves/default/*.tres`). `FighterStats.moveset` points at it, so a future character is
a new `FighterStats` + `MoveSet` + sprite folder.

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
