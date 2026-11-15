class_name AvatarData
extends AbilityData
## Magnus's elements and Avatar State (docs/specs/characters/magnus.md#avatar-state): on his move
## set's own `ability`.

@export_group("Avatar State")
## Ticks frozen in place before the flight.
@export var rise_frames: int
## Ticks of free flight.
@export var fly_frames: int
## Flying speed (px/s) and how fast he reaches it or slows to a stop (px/s²).
@export var fly_speed: float
@export var fly_accel: float
## He stays this far inside the blast zone while flying (px).
@export var edge_margin: float
## The touch hit during the flight (frames: always active) and how often it can hit the same
## fighter again (ticks).
@export var fly_hit: MoveData
@export var rehit_frames: int

@export_group("Look")
## The element orbs' ring around the middle of his body: radius (px) and ticks per turn.
@export var orbit_radius: float = 22.0
@export var orbit_ticks: int = 60
## Where his eyes are in avatar.png's rise and flight drawings (game px from the feet, facing
## right): the game draws a glow over each.
@export var rise_eyes: PackedVector2Array
@export var fly_eyes: PackedVector2Array


func create_ability() -> FighterAbility:
	return AvatarAbility.new()
