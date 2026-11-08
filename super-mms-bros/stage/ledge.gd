class_name Ledge
extends RefCounted
## A corner of the main platform that fighters can hang from (docs/specs/fighter.md#ledge).

## The corner, in world coordinates.
var point: Vector2
## Which way is off the stage from here: -1 = left, 1 = right.
var side: int


func _init(ledge_point: Vector2, outward_side: int) -> void:
	point = ledge_point
	side = outward_side
