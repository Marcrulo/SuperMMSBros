class_name PyramidData
extends Resource
## Gitte's pyramid up special's tuning (docs/specs/characters/gitte.md#gitte--scissors-and-stances).

## A floor at most this far below her feet (px) raises a pyramid; otherwise she hops.
@export var reach: float
## How far above the floor the tip ends up (px), and in how many ticks it gets there.
@export var height: float
@export var rise_frames: int
## Upward speed when she pops off the tip (px/s).
@export var pop_speed: float
## Upward speed of the hop when there's no floor in reach (px/s).
@export var hop_speed: float
## Ticks the pyramid takes to sink back into the floor.
@export var sink_frames: int
## The tip's hit (startup 0, active = rise_frames); its hitbox center is from the tip.
@export var tip_hit: MoveData


## How high the tip is above the floor after `frames` ticks of rising.
func tip_height(frames: int) -> float:
	return height * clampf(float(frames) / rise_frames, 0.0, 1.0)
