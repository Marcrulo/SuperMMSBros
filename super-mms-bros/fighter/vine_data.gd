class_name VineData
extends Resource
## The vine up special's tuning (docs/specs/moves.md#fidusen--banana-book-vine).

## Swing: the vine's length (anchor straight above the feet), the angle swung, and in how many ticks.
@export var length: float
@export var swing_degrees: float
@export var swing_frames: int
## Pull: a free ledge whose corner is this close to the center is reached, in this many ticks.
@export var ledge_range: float
@export var pull_frames: int


## The swing's angular speed, rad/s.
func swing_speed() -> float:
	return deg_to_rad(swing_degrees) / (swing_frames / 60.0)
