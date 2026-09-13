# Fighter

One fighter design in v1, used by both players. A fighter is a `CharacterBody2D` advanced one step
per tick by the Match with `fighter.tick(input)` (see [architecture](architecture.md)).

## Body

- **Origin:** bottom-center of the body (the feet). Spawn points and positions refer to this point.
- **Body collision shape:** 16×24 px rectangle, centered at (0, −12).
- **Hurtbox:** same rectangle as the body.
- **Center:** origin + (0, −12). Used for KO checks and by the CPU.
- **Facing:** `1` = right, `−1` = left. Everything directional (hitbox, eye, knockback) mirrors with it.

## Stats (`FighterStats` resource)

Starting values, tuned in playtesting (M6). Distances in game pixels, speeds in px/s, accelerations
in px/s², durations in ticks (60 per second).

| Stat | Value | Notes |
|---|---|---|
| `run_speed` | 100 | Top ground speed |
| `ground_accel` | 1200 | Toward target speed while holding a direction |
| `ground_friction` | 1200 | Toward 0 with no input, during ground attacks, and on the ground in hitstun |
| `air_speed` | 90 | Top air speed from input |
| `air_accel` | 400 | Air steering |
| `air_friction` | 150 | Toward 0 in the air with no input |
| `gravity` | 600 | |
| `max_fall_speed` | 250 | |
| `jump_velocity` | 240 | ≈ 48 px ground jump |
| `double_jump_velocity` | 219 | ≈ 40 px double jump |
| `short_hop_cut` | 0.5 | Upward speed is multiplied by this if jump is released early |
| `max_air_jumps` | 1 | |
| `drop_through_frames` | 10 | How long pass-through platforms are ignored after dropping |
| `attack_startup` | 4 | Frames before the hitbox appears |
| `attack_active` | 3 | Frames the hitbox is out |
| `attack_recovery` | 12 | Frames after the hitbox, fighter can't act |
| `knockback_speed` | 300 | Launch speed given to the victim |
| `knockback_angle_deg` | 40 | Launch angle above horizontal, away from the attacker |
| `hitstun_frames` | 20 | How long the victim can't act |
| `hitstun_friction` | 300 | Horizontal slowdown in the air during hitstun |

Hitbox and hurtbox *sizes* live in the fighter scene (editable in the editor), not in the stats.

## Input

Each tick the fighter receives a `FighterInput`:

| Field | Type | Meaning |
|---|---|---|
| `move_x` | `float` −1…1 | Horizontal direction |
| `jump_pressed` | `bool` | Jump went down this tick |
| `jump_held` | `bool` | Jump is held |
| `down_pressed` | `bool` | Down went down this tick |
| `attack_pressed` | `bool` | Attack went down this tick |

Actions trigger on *pressed* (the tick the button goes down); holding a button never repeats an
action.

## States

| State | Meaning |
|---|---|
| `IDLE` | On the ground, not moving by input |
| `RUN` | On the ground, holding a direction |
| `AIR` | Airborne (jumping or falling), able to act |
| `ATTACK` | Performing the attack (ground or air) |
| `HITSTUN` | Just got hit; can't act |
| `KO` | Knocked out; hidden and inactive until the Match respawns it |

Every fighter also tracks `state_frame`: ticks spent in the current state, starting at 1 on the tick
the state is entered.

### Transitions

- `IDLE` ↔ `RUN`: on the ground, `move_x ≠ 0` → `RUN`; `move_x = 0` → `IDLE`.
- `IDLE`/`RUN` → `AIR`: jump pressed, drop through a platform, or walking off a ledge.
- `AIR` → `IDLE`/`RUN`: landing.
- `IDLE`/`RUN`/`AIR` → `ATTACK`: attack pressed. Attack takes priority over jump on the same tick.
- `ATTACK` → `IDLE`/`RUN`/`AIR`: after the last recovery frame, whichever fits.
- `ATTACK` → `IDLE`/`RUN`: a fighter who is airborne during an attack and lands ends the attack
  immediately (no landing lag).
- any state except `KO` → `HITSTUN`: hit by an attack while not invulnerable.
- `HITSTUN` → `IDLE`/`AIR`: when hitstun runs out.
- any state → `KO`: set by the Match when the fighter leaves the blast zone.

## Movement rules

- **Ground:** with input, horizontal speed moves toward `move_x × run_speed` at `ground_accel`;
  without input it moves toward 0 at `ground_friction`.
- **Air:** with input, horizontal speed moves toward `move_x × air_speed` at `air_accel`; without
  input it moves toward 0 at `air_friction`.
- **Gravity:** every airborne tick, vertical speed increases by `gravity / 60`, capped at
  `max_fall_speed`.
- **Ground jump:** jump pressed in `IDLE`/`RUN` → vertical speed = −`jump_velocity`, state `AIR`.
- **Short hop:** if jump is released while still rising from a ground jump, vertical speed is
  multiplied by `short_hop_cut` (once per jump).
- **Double jump:** jump pressed in `AIR` with `jumps_left > 0` → vertical speed =
  −`double_jump_velocity`, horizontal speed = `move_x × air_speed`, `jumps_left −= 1`.
- **Jumps are restored** (`jumps_left = max_air_jumps`) on landing and when hit.
- Walking off a ledge does not use up the double jump.
- **Facing** changes only in `IDLE`/`RUN`, to the sign of `move_x`. It does not change in the air,
  while attacking or in hitstun. Exception: when hit, the victim turns to face the attacker.
- **Pass-through platforms:** one-way collision, so fighters jump up through them and land on top.
  `down_pressed` while standing on one removes the `stage_platform` layer from the fighter's
  collision mask for `drop_through_frames` ticks and puts the fighter in `AIR`.
- **Fighters don't collide with each other.**

## The attack

One attack, usable on the ground and in the air. The tick the attack starts is frame 1:

| Frames | Phase | Hitbox |
|---|---|---|
| 1–4 | Startup | off |
| 5–7 | Active | on |
| 8–19 | Recovery | off |

- **Hitbox:** 14×10 px rectangle centered at (15, −13) when facing right (mirrored when facing left).
- **Ground attack:** the fighter can't steer; horizontal speed moves toward 0 at `ground_friction`.
- **Air attack:** the fighter keeps air steering and gravity as normal.
- **One hit per target:** each attack remembers who it hit and can't hit them again.
- The fighter can't act (jump, attack, turn) until the attack ends.

## Getting hit

Resolved by the Match after both fighters have moved (see [architecture](architecture.md)). A hit
lands when the attacker's hitbox is active, it overlaps the victim's hurtbox, the victim is not `KO`
or invulnerable, and this attack hasn't already hit the victim. All hits for a tick are collected
first and then applied, so two fighters can trade hits.

When a hit lands, the victim:
- gets velocity `(cos(angle) × speed × attacker.facing, −sin(angle) × speed)`, using the
  **attacker's** `knockback_speed` and `knockback_angle_deg`;
- enters `HITSTUN` for the attacker's `hitstun_frames`;
- turns to face the attacker;
- has its jumps restored;
- loses any attack in progress (its hitbox turns off).

During `HITSTUN` the fighter ignores input. Gravity applies; horizontal speed moves toward 0 at
`hitstun_friction` in the air and `ground_friction` on the ground. The fighter still lands on
platforms.

Because knockback is fixed in v1, KOs come mostly from being knocked off the side of the stage and
failing to get back, not from being launched straight into the blast zone. `knockback_speed` is the
main knob for match length.

## Placeholder visuals (`FighterVisuals`)

Drawn in `_draw()` from the fighter's state; never changes gameplay state.

- **Body:** 16×24 rectangle, red (P1) or blue (P2).
- **Eye:** 3×3 light square near the top of the body, on the facing side.
- **Fist:** during active frames, a light rectangle where the hitbox is.
- **Hitstun:** body alternates with white every 2 ticks (based on `state_frame`).
- **Invulnerable:** the whole fighter blinks (hidden 4 ticks, shown 4 ticks).
- **KO:** hidden.

When real art arrives, `FighterVisuals` switches to an `AnimatedSprite2D` following the
[art guide](art-guide.md); nothing else changes.
