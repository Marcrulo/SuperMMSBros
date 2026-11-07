# Moves

The default fighter's move set: four normal attacks, four specials, how damage % turns into
knockback, and the projectile. How a fighter enters and leaves a move is in [fighter](fighter.md).

All numbers are starting values, tuned in playtesting (M9). They live in resources, never in code:
each move is a `MoveData` resource, and a `MoveSet` resource lists the eight moves of one design
(`fighter/moves/default/*.tres`). `FighterStats.moveset` points at it, so a future character is
a new `FighterStats` + `MoveSet` + sprite folder.

## Picking a move

The move is decided on the tick the button goes down, from the direction held on that tick:

| Held | J (attack, "A") | K (special, "B") |
|---|---|---|
| up (`up_held`) | up tilt | up special |
| down (`down_held`) | down tilt | down special |
| left or right (`move_x ≠ 0`) | side tilt | side special |
| nothing | jab | neutral special |

Up wins over down, and both win over sideways. A side move on the ground turns the fighter toward
the held direction first; in the air the fighter keeps facing where it faced.

The same moves work in the air (no separate aerials in v1). A normal attack started in the air
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
| `angle_deg` | Launch angle above horizontal |
| `direction` | `FACING`: launched toward the attacker's facing side. `AWAY`: launched away from the attacker's center (for moves that hit both sides) |

A move hits each fighter at most once.

## Normal attacks (J)

| Move | Frames (startup / active / recovery, total) | Hitbox center, size | Damage | Base, growth | Angle | Direction | Idea |
|---|---|---|---|---|---|---|---|
| Jab | 4 / 3 / 12 (19) | (15, −13), 14×10 | 3 | 120, 0.8 | 40° | FACING | Quick punch |
| Down tilt | 5 / 3 / 12 (20) | (14, −3), 18×6 | 6 | 130, 1.0 | 75° | FACING | Low kick along the ground that pops up |
| Up tilt | 5 / 4 / 14 (23) | (2, −31), 24×12 | 7 | 160, 1.2 | 90° | AWAY | Swipe over the head, launches straight up |
| Side tilt | 7 / 3 / 16 (26) | (19, −12), 18×8 | 9 | 180, 1.6 | 35° | FACING | Slower kick with reach and power |

On the ground the fighter can't steer during an attack (speed moves toward 0 at
`ground_friction`). In the air it keeps air steering and gravity.

## Specials (K)

### Neutral special — charged punch

1. **Charging:** while K stays held, the fighter charges, up to 60 ticks (`charge_frames`). On the
   ground it slides to a stop; in the air it keeps falling and steering normally. The fists glow
   brighter as the charge grows.
2. **Punch:** releasing K, or reaching the full charge, starts the punch with
   `charge = ticks charged / 60` (0…1): 3 / 4 / 18 (25) frames, hitbox (16, −13), 16×12,
   damage 8 + 14 × charge, base knockback 200 + 200 × charge, growth 2.0, angle 38°, FACING.

Getting hit while charging loses the charge.

### Down special — ground energy burst

- **On the ground:** 10 / 6 / 20 (36) frames. The burst erupts on both sides: hitbox (0, −9),
  56×18, damage 10, base 220, growth 1.5, angle 80°, AWAY.
- **In the air:** the fighter dives straight down at 360 px/s (no steering, no hitbox) until it
  lands, then the ground version starts at frame 1. Diving off the stage is a risk the player takes.

### Side special — projectile

- 10 / 0 / 20 (30) frames; the projectile appears on frame 10 at (16, −13), flying toward the
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
4. Hitstun ticks = `max(min_hitstun, round(speed × hitstun_per_knockback))` (victim's stats:
   `min_hitstun` 6, `hitstun_per_knockback` 0.06 → 300 px/s gives 18 ticks).

`percent` goes back to 0 when the fighter respawns. Shielded hits are in
[fighter](fighter.md#shield).
