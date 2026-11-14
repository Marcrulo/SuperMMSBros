class_name HandData
extends Resource
## A summoned hand's tuning (docs/specs/characters/michael.md#michael-bech--big-hand): where it appears, how
## long it hovers, how fast it slams, and what its touches and its slam do.

## Where the palm (the bottom center of the hitbox) appears, from the summoner's feet, facing right.
@export var offset: Vector2
## Hitbox size; the box sits on the palm (from palm.y - size.y to palm.y).
@export var size: Vector2
## Ticks it hovers in place before slamming.
@export var hover_frames: int
## Slamming speed, straight down, in px/s.
@export var slam_speed: float
## Ticks it stays on the floor after landing (its hitbox still out).
@export var impact_frames: int
## The hit while hovering, and while slamming and on impact (damage and knockback values).
@export var hover_hit: MoveData
@export var slam_hit: MoveData
