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

@export_group("Jumps")
@export var jump_velocity: float
@export var double_jump_velocity: float
## Upward speed is multiplied by this if jump is released early (short hop).
@export var short_hop_cut: float
@export var max_air_jumps: int

@export_group("Platforms")
## How long pass-through platforms are ignored after dropping through one.
@export var drop_through_frames: int
