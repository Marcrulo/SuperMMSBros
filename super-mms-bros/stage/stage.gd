class_name Stage
extends Node2D
## A stage: collision geometry, spawn points and blast zone, dressed by a StageData (docs/specs/match-and-stage.md#stage-battlefield).
## Spawn points are the Marker2D children P1Spawn, P2Spawn, ...

## Which way each player faces at spawn, by player index: 1 = right, -1 = left.
@export var spawn_facings: Array[int] = [1, -1]
## A fighter whose center leaves this rectangle is knocked out (docs/specs/match-and-stage.md).
## It leaves room off every side for recovering; the camera never shows beyond it.
@export var blast_zone: Rect2 = Rect2(-72, -160, 624, 464)


## Where player `player_index` (0 = P1) spawns, in world coordinates.
func get_spawn_position(player_index: int) -> Vector2:
	var marker := get_node("P%dSpawn" % (player_index + 1)) as Marker2D
	return marker.global_position


func get_spawn_facing(player_index: int) -> int:
	return spawn_facings[player_index]


## Dresses the stage as `data`: background, haze, light and platform style. Presentation only:
## the layout and collision are the same on every stage.
func apply(data: StageData) -> void:
	var background := $BackgroundLayer/Background as Sprite2D
	background.texture = data.background
	(background.material as ShaderMaterial).set_shader_parameter("haze_color", data.haze_color)
	($Light as CanvasModulate).color = data.light_color
	($PlatformLook as PlatformLook).style = data.style
