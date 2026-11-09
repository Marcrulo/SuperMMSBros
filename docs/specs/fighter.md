# Fighter

One fighter design in v1 ("default"), used by both players. A fighter is a `CharacterBody2D`
advanced one step per tick by the Match with `fighter.tick(input)` (see
[architecture](architecture.md)). Its attacks are in [moves](moves.md).

## Body

- **Origin:** bottom-center of the body (the feet). Spawn points and positions refer to this point.
- **Body collision shape:** 16×24 px rectangle, centered at (0, −12). Used for walking and landing.
- **Hurtbox (where the fighter can be hit):** 16×27 at (0, −13.5) — the body plus the big head,
  which pokes 3 px above the body box. While crouching: 16×15 at (0, −7.5).
- **Center:** origin + (0, −12). Used for KO checks, the camera and the CPU.
- **Facing:** `1` = right, `−1` = left. Everything directional (hitboxes, sprite, knockback)
  mirrors with it.

## Stats (`FighterStats` resource)

Starting values, tuned in playtesting (M9). Distances in game pixels, speeds in px/s, accelerations
in px/s², durations in ticks (60 per second).

| Stat | Value | Notes |
|---|---|---|
| `run_speed` | 100 | Top ground speed |
| `ground_accel` | 1200 | Toward target speed while holding a direction |
| `ground_friction` | 1200 | Toward 0 with no input, while crouching, shielding, during ground attacks, and on the ground in hitstun |
| `air_speed` | 90 | Top air speed from input |
| `air_accel` | 400 | Air steering |
| `air_friction` | 150 | Toward 0 in the air with no input |
| `gravity` | 600 | |
| `max_fall_speed` | 250 | |
| `fast_fall_speed` | 400 | Falling speed while fast-falling |
| `jump_velocity` | 240 | ≈ 48 px ground jump |
| `double_jump_velocity` | 219 | ≈ 40 px double jump |
| `short_hop_cut` | 0.5 | Upward speed is multiplied by this if jump is released early |
| `max_air_jumps` | 1 | |
| `drop_through_frames` | 10 | How long pass-through platforms are ignored after dropping |
| `drop_double_tap_frames` | 12 | Max ticks between the two down presses of a drop-through |
| `hitstun_per_knockback` | 0.06 | Hitstun ticks per px/s of launch speed |
| `min_hitstun` | 6 | |
| `hitstun_friction` | 300 | Horizontal slowdown in the air during hitstun |
| `shield_max` | 100 | Shield health |
| `shield_drain` | 0.25 | Health lost per tick while shielding |
| `shield_regen` | 0.15 | Health regained per tick while not shielding |
| `shield_damage_scale` | 1.5 | Shield health lost per point of a blocked hit's damage |
| `shield_drop_frames` | 7 | Ticks to lower the shield |
| `shield_break_frames` | 120 | Ticks stunned after the shield breaks |
| `shield_reset_health` | 30 | Shield health after a break |
| `block_pushback` | 60 | Speed a blocked hit pushes the shielder away |
| `helpless_air_speed` | 54 | Top air speed while helpless |
| `spot_dodge_frames` | 20 | Length of a spot dodge |
| `spot_dodge_intangible_start` / `_end` | 3 / 15 | Frames of the spot dodge that can't be hit |
| `roll_frames` | 24 | Length of a roll |
| `roll_intangible_start` / `_end` | 4 / 16 | Frames of the roll that can't be hit |
| `roll_speed` | 100 | Ground speed during a roll (≈ 40 px) |
| `air_dodge_frames` | 30 | Length of an air dodge |
| `air_dodge_intangible_start` / `_end` | 3 / 20 | Frames of the air dodge that can't be hit |
| `air_dodge_speed` | 180 | Starting speed of a directional air dodge |
| `air_dodge_friction` | 360 | How fast the air dodge's speed falls to 0 (no gravity during it) |
| `ledge_grab_box` | Rect2(−16, −32, 32, 20) | Around the feet (mirror-symmetric): a ledge corner inside it can be grabbed |
| `ledge_hang_offset` | (9, 22) | Feet position while hanging, from the corner (x outward) |
| `ledge_max_hang` | 300 | Ticks before the fighter lets go by itself |
| `ledge_intangible_frames` | 40 | Ticks after a grab that can't be hit (when earned, see [Ledge](#ledge)) |
| `ledge_climb_frames` | 20 | Length of the get-up (can't be hit) |
| `ledge_climb_inset` | 12 | Where the get-up ends: this far onto the stage from the corner |
| `ledge_regrab_frames` | 30 | Ticks after leaving a ledge before any ledge can be grabbed again |
| `moveset` | `MoveSet` | The eight moves (see [moves](moves.md)) |

Hitbox *sizes* of moves live in the `MoveData` resources; the body and hurtbox sizes live in the
fighter scene.

## Input

Each tick the fighter receives a `FighterInput`:

| Field | Type | Meaning |
|---|---|---|
| `move_x` | `float` −1…1 | Horizontal direction |
| `up_held` | `bool` | Up is held (aims moves; doesn't jump) |
| `down_held` | `bool` | Down is held |
| `down_pressed` | `bool` | Down went down this tick |
| `jump_pressed` | `bool` | Jump went down this tick |
| `jump_held` | `bool` | Jump is held |
| `attack_pressed` | `bool` | Attack (A) went down this tick |
| `special_pressed` | `bool` | Special (B) went down this tick |
| `special_held` | `bool` | Special is held (charging) |
| `shield_held` | `bool` | Shield is held |
| `shield_pressed` | `bool` | Shield went down this tick (air dodge) |
| `up_pressed` | `bool` | Up went down this tick (ledge get-up) |
| `side_pressed` | `int` −1/0/1 | Left (−1) or right (1) went down this tick (roll, ledge actions) |

Actions trigger on *pressed* (the tick the button goes down); holding a button never repeats an
action. Shield, crouch and charging act while their button is *held*.

## States

| State | Meaning |
|---|---|
| `IDLE` | On the ground, not moving by input |
| `RUN` | On the ground, holding a direction |
| `CROUCH` | On the ground, holding down |
| `AIR` | Airborne (jumping or falling), able to act |
| `ATTACK` | Performing a move (normal or special, ground or air); which one is in `move` |
| `SHIELD` | Shield up |
| `SHIELD_DROP` | Lowering the shield; can't act |
| `SHIELD_BREAK` | Shield broke; stunned |
| `HITSTUN` | Just got hit; can't act |
| `HELPLESS` | Falling after up special; can't act until landing |
| `SPOT_DODGE` | Dodging in place on the ground |
| `ROLL` | Rolling sideways on the ground |
| `AIR_DODGE` | Dodging in the air |
| `LEDGE` | Hanging from a ledge |
| `LEDGE_CLIMB` | Climbing up from a ledge onto the stage |
| `KO` | Knocked out; hidden and inactive until the Match respawns it |

Every fighter also tracks `state_frame`: ticks spent in the current state, starting at 1 on the tick
the state is entered.

### What a fighter that can act does

Checked in this order on each tick; the first that applies happens:

| From `IDLE`, `RUN`, `CROUCH` | From `AIR` |
|---|---|
| attack pressed → ground attack (by direction) | attack pressed → air attack (by direction) |
| special pressed → special (by direction) | special pressed → special (by direction) |
| jump pressed with down held on a pass-through platform → drop through | jump pressed and `jumps_left > 0` → double jump |
| jump pressed → ground jump | |
| shield held and shield health > 0 → `SHIELD` (or straight into a roll / spot dodge if a side / down was pressed this same tick) | shield pressed and the air dodge is available → `AIR_DODGE` |
| | jump released while rising from a ground jump → short hop cut |
| down pressed twice within `drop_double_tap_frames` on a pass-through platform → drop through | |
| down held → `CROUCH` | |
| `move_x ≠ 0` → `RUN` (facing turns) | |
| otherwise → `IDLE` | |

### Other transitions

- `IDLE`/`RUN`/`CROUCH` → `AIR`: jump, drop through a platform, walking off a ledge.
- `AIR` → `IDLE`/`RUN`/`CROUCH`: landing.
- `ATTACK` → `IDLE`/`RUN`/`CROUCH`/`AIR`: after its last frame, whichever fits; an air attack that
  lands ends at once (specials: see [moves](moves.md)).
- `SHIELD` → `SHIELD_DROP` when shield is released → `IDLE` after `shield_drop_frames`.
  `SHIELD` → `AIR` when jump is pressed (jump out of shield, no drop lag).
  `SHIELD` → `SHIELD_BREAK` when shield health reaches 0 → `IDLE` after `shield_break_frames`.
  `SHIELD` → `ROLL` / `SPOT_DODGE` when a side / down is pressed (not during block stun).
- `ROLL`, `SPOT_DODGE` → `IDLE`/`RUN`/`CROUCH` (or `SHIELD` if shield is still held) after their
  last frame; `AIR_DODGE` → `AIR` after its last frame, or on landing.
- `AIR`, `HELPLESS`, `AIR_DODGE`, launched up special → `LEDGE`: grabbing a ledge (set by the
  Match). `LEDGE` → `LEDGE_CLIMB` → `IDLE`; `LEDGE` → `AIR` (let go or ledge jump).
- up special → `HELPLESS` when the fighter stops rising → `IDLE` on landing.
- any state except `KO` → `HITSTUN`: hit while not shielding, invulnerable or intangible.
- `HITSTUN` → `IDLE`/`AIR`: when hitstun runs out.
- any state → `KO`: set by the Match when the fighter leaves the blast zone.

## Movement rules

- **Ground:** with input, horizontal speed moves toward `move_x × run_speed` at `ground_accel`;
  without input it moves toward 0 at `ground_friction`.
- **Air:** with input, horizontal speed moves toward `move_x × air_speed` at `air_accel`; without
  input it moves toward 0 at `air_friction`.
- **Gravity:** every airborne tick, vertical speed increases by `gravity / 60`, capped at
  `max_fall_speed`.
- **Ground jump:** jump pressed → vertical speed = −`jump_velocity`, state `AIR`.
- **Short hop:** if jump is released while still rising from a ground jump, vertical speed is
  multiplied by `short_hop_cut` (once per jump).
- **Double jump:** jump pressed in `AIR` with `jumps_left > 0` → vertical speed =
  −`double_jump_velocity`, horizontal speed = `move_x × air_speed`, `jumps_left −= 1`.
- **Jumps are restored** (`jumps_left = max_air_jumps`) on landing and when hit. Up special is
  allowed again at the same moments.
- **Fast fall:** in `AIR` or during an air attack (not a special), holding down while falling
  (vertical speed ≥ 0) starts a fast fall: vertical speed becomes `fast_fall_speed` and stays
  there (gravity and `max_fall_speed` don't apply). Holding down while still rising does nothing
  until the fighter starts to fall. It doesn't start on the tick the fighter drops through a
  platform (still holding down, it starts the tick after), so a drop-through tap on its own lands
  on the next platform below. A fast fall lasts until landing, a double jump, being hit, an
  up special, or a respawn — releasing down doesn't end it.
- Walking off a ledge does not use up the double jump.
- **Facing** changes only in `IDLE`/`RUN`/`CROUCH`, to the sign of `move_x`, and when a side move
  starts on the ground. It does not change in the air, while attacking, shielding or in hitstun.
  Exception: when hit, the victim turns to face the attacker.
- **Pass-through platforms:** one-way collision, so fighters jump up through them and land on top.
  Pressing down twice within `drop_double_tap_frames` while standing on one, or pressing jump while
  holding down (crouching) on one, removes the `stage_platform` layer from the fighter's collision
  mask for `drop_through_frames` ticks and puts the fighter in `AIR`. In `AIR`, and during an attack while airborne, holding down also removes
  that layer, so a falling fighter passes through every pass-through platform while down is held;
  let go and the next one below catches them again. The main platform is always solid.
- **Fighters don't collide with each other.**

## Crouch

Holding down on the ground (when no other action applies). The fighter slides to a stop at
`ground_friction`, can turn around with left/right but doesn't walk, and uses the crouching
hurtbox. Releasing down stands up at once. Attack while crouching is the down tilt; special is the
down special. Jump while crouching on a pass-through platform drops through it instead of jumping;
on the main platform it's a normal jump.

## Shield

- Holding shield on the ground raises a bubble around the fighter. While it's up, the fighter can't
  move (it slides to a stop) or attack; it can jump out of it.
- **Shield health** (`shield_max`) drains by `shield_drain` per tick while shielding and regrows by
  `shield_regen` per tick otherwise (also while not shielding in the air).
- **A blocked hit** (any hit, from either side, while in `SHIELD`) does no damage and no knockback:
  shield health drops by `damage × shield_damage_scale`, the shielder is pushed away from the
  attacker at `block_pushback` (for a projectile: in its direction), and for
  `max(4, round(damage × 0.8))` ticks the shield can't be lowered or jumped out of (block stun).
  A blocked projectile disappears.
- **Shield break:** at 0 health the fighter enters `SHIELD_BREAK`, stunned for
  `shield_break_frames`; afterwards shield health is `shield_reset_health`.
- No shield in the air.

## Dodges

While a fighter dodges it is **intangible** on the dodge's intangible frames: hits and
projectiles pass through it as if it weren't there (a move that misses this way can still hit it
later, and a projectile flies on).

- **Spot dodge:** in `SHIELD`, pressing down (or pressing down on the tick shield goes up). The
  fighter stays in place (sliding to a stop at `ground_friction`) for `spot_dodge_frames`.
- **Roll:** in `SHIELD`, pressing a side (or on the tick shield goes up). The fighter moves at
  `roll_speed` toward that side for `roll_frames`, and ends facing **away** from the roll (back
  toward where it came from). A roll stops at the edge of whatever it stands on: it never rolls
  off. Holding a side while raising the shield doesn't roll; only a fresh press does.
- Neither works during block stun. After a ground dodge, holding shield goes back to `SHIELD`.
- **Air dodge:** in `AIR`, pressing shield. Once per stay in the air: restored on landing, when
  grabbing a ledge, and when hit. With a direction held (side, up, down, or a diagonal) the speed
  becomes `air_dodge_speed` that way and falls toward 0 at `air_dodge_friction`; with none the
  fighter stops in place. Either way, there is no gravity during the dodge. Afterwards the
  fighter is in `AIR` (it can still double jump). Landing ends it at once. Holding down passes
  through platforms, as in `AIR`.

## Ledge

The main platform's two top corners are **ledges**: (96, 192) facing out to the left and
(384, 192) facing out to the right (see [match & stage](match-and-stage.md#layout-battlefield)).
Pass-through platforms have none.

- **Grabbing** (checked by the Match every tick, after fighters move — see
  [architecture](architecture.md#tick-order)): a fighter grabs a ledge when it is in `AIR`
  (falling), `HELPLESS`, `AIR_DODGE` (falling) or a launched up special (rising or falling), not
  on the floor, not holding down, not within `ledge_regrab_frames` of leaving a ledge, standing
  on the outer side of the corner, and the corner lies inside its `ledge_grab_box`. Only one
  fighter holds a ledge at a time; a held ledge can't be grabbed.
- **On grab:** the fighter snaps so its feet are at the corner + `ledge_hang_offset` (x mirrored
  outward), stops, faces the stage, and gets its double jump, up special and air dodge back. If it
  has touched the ground or been hit since its last grab (or just spawned), it is intangible for
  `ledge_intangible_frames`.
- **Hanging:** no gravity, no movement. After `ledge_max_hang` ticks it lets go.
- **From the ledge** (first that applies):
  - jump pressed → **ledge jump**: vertical speed = −`jump_velocity`, horizontal speed =
    `move_x × air_speed`, state `AIR` (the double jump is kept);
  - up pressed or the stage-side pressed → **get-up**: `LEDGE_CLIMB` for `ledge_climb_frames`,
    intangible throughout, rising to the top of the corner in the first half and moving onto the
    stage in the second; it ends standing `ledge_climb_inset` px in from the corner, `IDLE`;
  - down pressed or the outer side pressed → **let go**: `AIR`, falling from rest.
- Getting hit on the ledge (when not intangible) knocks the fighter off it into `HITSTUN` as usual.

## Helpless

After up special, once the fighter stops rising: it falls with gravity, steers only up to
`helpless_air_speed`, and can't attack, jump, special or shield. It can still pass through
platforms by holding down. Landing returns it to `IDLE`; being hit puts it in `HITSTUN` as usual.

## Getting hit

Resolved by the Match after every fighter and projectile has moved (see
[architecture](architecture.md)). A hit lands when an active hitbox overlaps the victim's hurtbox,
the victim is not `KO`, invulnerable or intangible, and that move or projectile hasn't hit this victim yet. All
hits for a tick are collected first and then applied, so two fighters can trade hits.

When a hit lands on a fighter that isn't shielding, the victim:
- takes the damage and is launched as described in [moves](moves.md#damage--and-knockback);
- enters `HITSTUN` for the computed ticks (a hit during hitstun restarts it);
- turns to face the attacker;
- has its jumps and up special restored;
- loses any move in progress, including a charge.

During `HITSTUN` the fighter ignores input. Gravity applies; horizontal speed moves toward 0 at
`hitstun_friction` in the air and `ground_friction` on the ground. Moving up counts as airborne, so
a grounded fighter that gets launched leaves the ground at full speed. The fighter still lands on
platforms (staying in hitstun).

## Visuals (`FighterVisuals`)

Drawn from the fighter's state; never changes gameplay state.

- **Sprites:** one animation per state or move, from the sprite strips in
  `assets/fighters/<character id>/` (see [art guide](art-guide.md)). Each fighter knows its
  `character_id` (set by the Match). The frame is chosen from
  `state_frame`, so a move's strike pose shows exactly on its active frames. Mirrored when facing
  left.
- **Player color:** every character is drawn in its own colors; no recoloring. The players are told
  apart by their shield bubbles and HUD cards (P1 red, P2 blue), and never share a character.
- **Hit flash:** in hitstun, the sprite brightens on alternate pairs of ticks.
- **Shield:** a translucent bubble in the player's color around the center, its radius shrinking with
  shield health (16 px at full, 6 px near empty).
- **Charge:** the fists glow brighter as the neutral special charges.
- **Invulnerable:** the whole fighter blinks (hidden 4 ticks, shown 4 ticks).
- **Intangible** (dodges, ledge): the sprite is drawn pale and see-through.
- **KO:** hidden.
- **Debug view:** F1 (or `--hitboxes`) draws hurtboxes in blue and move hitboxes in red (solid on
  active frames).
