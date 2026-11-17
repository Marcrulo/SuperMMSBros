extends GutTest
## Battlefield layout and collision layers (docs/specs/match-and-stage.md#stage-battlefield,
## docs/specs/architecture.md#collision-layers).

const STAGE_SCENE := preload("res://stage/battlefield.tscn")

var _stage: Stage


func before_each() -> void:
	_stage = add_child_autofree(STAGE_SCENE.instantiate())


func test_collision_layer_names() -> void:
	var names := ["stage_solid", "stage_platform", "fighter", "hitbox", "hurtbox"]
	for i in names.size():
		assert_eq(ProjectSettings.get_setting("layer_names/2d_physics/layer_%d" % (i + 1)), names[i])


func test_main_platform_is_solid() -> void:
	var body := _stage.get_node("MainPlatform") as StaticBody2D
	assert_eq(_shape_rect(body), Rect2(96, 192, 288, 32), "top 288 wide, 16 + 16 px deep")
	assert_eq(body.collision_layer, _layer_bit(1), "only on layer 1 (stage_solid)")
	assert_false(_shape(body).one_way_collision)


func test_main_platform_underside_slopes_in_below_the_ledges() -> void:
	var shape := _shape(_stage.get_node("MainPlatform") as StaticBody2D)
	var points: Array[Vector2] = []
	for point in (shape.shape as ConvexPolygonShape2D).points:
		points.append(shape.global_position + point)
	assert_eq(points, [
		Vector2(96, 192), Vector2(384, 192), Vector2(384, 208),
		Vector2(364, 224), Vector2(116, 224), Vector2(96, 208),
	] as Array[Vector2], "flat top, straight sides 16 px down, then a wedge 20 px in, 16 down")


func test_ledges_are_the_top_corners() -> void:
	var ledges := _stage.get_ledges()
	assert_eq(ledges[0].point, Vector2(96, 192))
	assert_eq(ledges[0].side, -1)
	assert_eq(ledges[1].point, Vector2(384, 192))
	assert_eq(ledges[1].side, 1)


func test_floor_below_is_the_top() -> void:
	assert_eq(_stage.floor_below(Vector2(240, 100)), 192.0)
	assert_eq(_stage.floor_below(Vector2(90, 100)), INF, "beside the stage")
	assert_eq(_stage.floor_below(Vector2(240, 100), true), 108.0, "the top platform")


func test_pass_through_platforms() -> void:
	var expected := {
		"Left": Rect2(132, 150, 72, 4),
		"Right": Rect2(276, 150, 72, 4),
		"Top": Rect2(204, 108, 72, 4),
	}
	for platform_name: String in expected:
		var body := _stage.get_node("Platforms/" + platform_name) as StaticBody2D
		assert_eq(_shape_rect(body), expected[platform_name], platform_name)
		assert_eq(body.collision_layer, _layer_bit(2), "%s: only on layer 2 (stage_platform)" % platform_name)
		assert_true(_shape(body).one_way_collision, "%s: one-way" % platform_name)


func test_spawn_points() -> void:
	assert_eq(_stage.get_spawn_position(0), Vector2(168, 192))
	assert_eq(_stage.get_spawn_facing(0), 1)
	assert_eq(_stage.get_spawn_position(1), Vector2(312, 192))
	assert_eq(_stage.get_spawn_facing(1), -1)


func _shape(body: StaticBody2D) -> CollisionShape2D:
	return body.get_node("CollisionShape2D") as CollisionShape2D


## The collision shape's bounding rectangle in world coordinates.
func _shape_rect(body: StaticBody2D) -> Rect2:
	var shape := _shape(body)
	var rect := shape.shape.get_rect()
	return Rect2(shape.global_position + rect.position, rect.size)


## Collision layers are stored as bits: layer 1 = 1, layer 2 = 2, layer 3 = 4, ...
func _layer_bit(layer: int) -> int:
	return 1 << (layer - 1)


func test_blast_zone() -> void:
	assert_eq(_stage.blast_zone, Rect2(-72, -160, 624, 464))
