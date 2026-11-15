class_name LadderData
extends AbilityData
## Kim's ladder up special (docs/specs/characters/kim.md#kim--handyman): on the move's frame
## `startup` a ladder is set up at his feet, he climbs it straight up, then jumps off.

## The climb: speed (px/s) and how many ticks it lasts.
@export var climb_speed: float
@export var climb_frames: int
## The jump off the top: upward speed, and sideways speed × the held direction (px/s).
@export var jump_speed: float
@export var jump_drift: float
## The ladder standing there: size, and ticks until it's gone.
@export var size: Vector2
@export var lifetime: int


func create_ability() -> FighterAbility:
	return LadderAbility.new()
