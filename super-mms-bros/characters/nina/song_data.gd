class_name SongData
extends AbilityData
## Nina's lullaby (docs/specs/characters/nina.md#down-special--lullaby): the tuning that isn't in
## the down special's own MoveData (its frames are that move's startup, active and recovery).

## How far the song reaches from her voice point (px, at normal size).
@export var radius: float
## The song's center, relative to the feet, facing right.
@export var voice: Vector2
## How long a fighter sleeps, in ticks.
@export var sleep_ticks: int
## In the air she sinks at most this fast while singing (px/s).
@export var hover_fall_speed: float


func create_ability() -> FighterAbility:
	return SongAbility.new()
