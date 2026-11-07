class_name FighterStats
extends Resource
## Every tuning number for one fighter design (docs/specs/fighter.md#stats).
## Distances in pixels, speeds in px/s, accelerations in px/s², durations in ticks (60 per second).
## The values live in the .tres file (fighter/default_stats.tres), not here.

@export_group("Ground")
## Top ground speed.
@export var run_speed: float
## How fast ground speed moves toward the target while holding a direction.
@export var ground_accel: float
## How fast ground speed moves toward 0 with no input.
@export var ground_friction: float

@export_group("Air")
## Top air speed from input.
@export var air_speed: float
## Air steering.
@export var air_accel: float
## How fast air speed moves toward 0 with no input.
@export var air_friction: float
@export var gravity: float
@export var max_fall_speed: float
## Falling speed while fast-falling (holding down while falling).
@export var fast_fall_speed: float

@export_group("Jumps")
@export var jump_velocity: float
@export var double_jump_velocity: float
## Upward speed is multiplied by this if jump is released early (short hop).
@export var short_hop_cut: float
@export var max_air_jumps: int

@export_group("Platforms")
## How long pass-through platforms are ignored after dropping through one.
@export var drop_through_frames: int
## Max ticks between the two down presses of a drop-through.
@export var drop_double_tap_frames: int

@export_group("Getting hit")
## Hitstun ticks per px/s of launch speed.
@export var hitstun_per_knockback: float
@export var min_hitstun: int
## Horizontal slowdown in the air during hitstun.
@export var hitstun_friction: float

@export_group("Shield")
@export var shield_max: float
## Shield health lost per tick while shielding, and regained per tick otherwise.
@export var shield_drain: float
@export var shield_regen: float
## Shield health lost per point of a blocked hit's damage.
@export var shield_damage_scale: float
## Ticks to lower the shield.
@export var shield_drop_frames: int
## Ticks stunned after the shield breaks, and the shield's health afterwards.
@export var shield_break_frames: int
@export var shield_reset_health: float
## Speed a blocked hit pushes the shielder away.
@export var block_pushback: float

@export_group("Helpless")
## Top air speed while helpless (after up special).
@export var helpless_air_speed: float

@export_group("Moves")
@export var moveset: MoveSet
