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
## Lasso (0 = none): with no ledge in reach, the nearest hittable opponent this close to the center,
## in front or above (not behind), is caught and reeled in over `reel_frames` to `reel_to` (from the
## feet, facing right), then hit with `grab_hit` (launched forward); then she pops up at `pop_speed`.
@export var grab_range: float
@export var reel_frames: int
@export var reel_to: Vector2
@export var grab_hit: MoveData
@export var pop_speed: float
## With nothing to catch: swing from a vine above (Fidusen), or, if false, a miss: the rope flies
## out (toward `grab_range` at 45° up and forward) and back over `miss_frames` while she falls.
@export var swing: bool = true
@export var miss_frames: int


## The swing's angular speed, rad/s.
func swing_speed() -> float:
	return deg_to_rad(swing_degrees) / (swing_frames / 60.0)
