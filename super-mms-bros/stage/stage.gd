class_name Stage
extends Node2D
## A stage: collision geometry and spawn points (docs/specs/match-and-stage.md#stage-battlefield).
## Spawn points are the Marker2D children P1Spawn, P2Spawn, ...

## Which way each player faces at spawn, by player index: 1 = right, -1 = left.
@export var spawn_facings: Array[int] = [1, -1]


## Where player `player_index` (0 = P1) spawns, in world coordinates.
func get_spawn_position(player_index: int) -> Vector2:
	var marker := get_node("P%dSpawn" % (player_index + 1)) as Marker2D
	return marker.global_position


func get_spawn_facing(player_index: int) -> int:
	return spawn_facings[player_index]
