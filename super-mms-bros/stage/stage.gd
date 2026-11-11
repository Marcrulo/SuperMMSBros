class_name Stage
extends Node2D
## A stage: collision geometry, spawn points and blast zone, dressed by a StageData (docs/specs/match-and-stage.md#stage-battlefield).
## Spawn points are the Marker2D children P1Spawn, P2Spawn, ...

## Which way each player faces at spawn, by player index: 1 = right, -1 = left.
@export var spawn_facings: Array[int] = [1, -1]
## A fighter whose center leaves this rectangle is knocked out (docs/specs/match-and-stage.md).
## It leaves room off every side for recovering; the camera never shows beyond it.
@export var blast_zone: Rect2 = Rect2(-72, -160, 624, 464)

var _ledges: Array[Ledge] = []


## Where player `player_index` (0 = P1) spawns, in world coordinates.
func get_spawn_position(player_index: int) -> Vector2:
	var marker := get_node("P%dSpawn" % (player_index + 1)) as Marker2D
	return marker.global_position


## The grabbable ledges: the main platform's two top corners, left one first.
func get_ledges() -> Array[Ledge]:
	if _ledges.is_empty():
		var shape := $MainPlatform/CollisionShape2D as CollisionShape2D
		var size := (shape.shape as RectangleShape2D).size
		var top_left := shape.global_position - size / 2.0
		_ledges = [Ledge.new(top_left, -1), Ledge.new(top_left + Vector2(size.x, 0.0), 1)]
	return _ledges


## The y of the nearest floor top at or below `point` whose x range holds point.x, else INF: the
## main platform only, or with `platforms` also the pass-through platforms.
func floor_below(point: Vector2, platforms := false) -> float:
	var bodies: Array[Node] = [$MainPlatform]
	if platforms:
		bodies.append_array($Platforms.get_children())
	var best := INF
	for body in bodies:
		var shape := body.get_node("CollisionShape2D") as CollisionShape2D
		var size := (shape.shape as RectangleShape2D).size
		var top_left := shape.global_position - size / 2.0
		if point.x >= top_left.x and point.x <= top_left.x + size.x and top_left.y >= point.y:
			best = minf(best, top_left.y)
	return best


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
	($PlatformFront as PlatformLook).style = data.style
