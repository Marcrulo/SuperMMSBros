class_name PeelData
extends Resource
## A banana peel's tuning (docs/specs/characters/fidusen.md#fidusen--banana-book-vine).

## Peels of one fighter out at once; another removes the oldest.
@export var max_out: int
## Ticks a peel stays before it's gone.
@export var lifetime: int
## Its trip area (bottom center at the peel's position).
@export var size: Vector2
## Falling speed while dropping to the floor, px/s.
@export var fall_speed: float
## % added to the fighter who slips, and the ticks they lie on the floor.
@export var damage: float
@export var trip_frames: int
