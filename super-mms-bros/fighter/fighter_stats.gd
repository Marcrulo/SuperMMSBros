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

@export_group("Dodges")
## Spot dodge (in place, from shield): length and the frames that can't be hit.
@export var spot_dodge_frames: int
@export var spot_dodge_intangible_start: int
@export var spot_dodge_intangible_end: int
## Roll (sideways, from shield): length, the frames that can't be hit, and ground speed.
@export var roll_frames: int
@export var roll_intangible_start: int
@export var roll_intangible_end: int
@export var roll_speed: float
## Air dodge: length, the frames that can't be hit, a directional dodge's starting speed and how
## fast that speed falls to 0 (no gravity during the dodge).
@export var air_dodge_frames: int
@export var air_dodge_intangible_start: int
@export var air_dodge_intangible_end: int
@export var air_dodge_speed: float
@export var air_dodge_friction: float

@export_group("Ledge")
## Around the feet (mirror-symmetric): a ledge corner inside it can be grabbed.
@export var ledge_grab_box: Rect2
## Feet position while hanging, from the corner (x points outward, away from the stage).
@export var ledge_hang_offset: Vector2
## Ticks before a hanging fighter lets go by itself.
@export var ledge_max_hang: int
## Ticks after a grab that can't be hit (only if earned: touched ground or got hit since the last).
@export var ledge_intangible_frames: int
## Length of the get-up (can't be hit), and how far onto the stage from the corner it ends.
@export var ledge_climb_frames: int
@export var ledge_climb_inset: float
## Ticks after leaving a ledge before any ledge can be grabbed again.
@export var ledge_regrab_frames: int

@export_group("Moves")
@export var moveset: MoveSet
