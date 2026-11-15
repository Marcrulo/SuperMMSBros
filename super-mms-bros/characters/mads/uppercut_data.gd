class_name UppercutData
extends AbilityData
## Mads's rising uppercut up special (docs/specs/characters/mads.md#mads--grappler): on the move's
## frame `startup` he turns to the held side and rises diagonally forward with a clean hit, then a
## late hit, until he stops rising.

## He can't be hit on move frames 1 to this (the startup and the start of the rise).
@export var invulnerable_frames: int
## The rise: upward speed, speed toward the facing side (px/s), and its own gravity (px/s²).
@export var rise_speed: float
@export var forward_speed: float
@export var rise_gravity: float
## Rise frames 1 to this are the clean hit; after them, the late hit.
@export var clean_frames: int
## The hits (their startup/active count rise frames).
@export var clean_hit: MoveData
@export var late_hit: MoveData


func create_ability() -> FighterAbility:
	return UppercutAbility.new()
