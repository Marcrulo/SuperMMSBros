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
	assert_eq(_shape_rect(body), Rect2(64, 128, 192, 16))
	assert_eq(body.collision_layer, _layer_bit(1), "only on layer 1 (stage_solid)")
	assert_false(_shape(body).one_way_collision)


func test_pass_through_platforms() -> void:
	var expected := {
		"Left": Rect2(88, 96, 48, 4),
		"Right": Rect2(184, 96, 48, 4),
		"Top": Rect2(136, 64, 48, 4),
	}
	for platform_name: String in expected:
		var body := _stage.get_node("Platforms/" + platform_name) as StaticBody2D
		assert_eq(_shape_rect(body), expected[platform_name], platform_name)
		assert_eq(body.collision_layer, _layer_bit(2), "%s: only on layer 2 (stage_platform)" % platform_name)
		assert_true(_shape(body).one_way_collision, "%s: one-way" % platform_name)


func test_spawn_points() -> void:
	assert_eq(_stage.get_spawn_position(0), Vector2(112, 128))
	assert_eq(_stage.get_spawn_facing(0), 1)
	assert_eq(_stage.get_spawn_position(1), Vector2(208, 128))
	assert_eq(_stage.get_spawn_facing(1), -1)


func _shape(body: StaticBody2D) -> CollisionShape2D:
	return body.get_node("CollisionShape2D") as CollisionShape2D


## The collision rectangle in world coordinates.
func _shape_rect(body: StaticBody2D) -> Rect2:
	var shape := _shape(body)
	var size := (shape.shape as RectangleShape2D).size
	return Rect2(shape.global_position - size / 2.0, size)


## Collision layers are stored as bits: layer 1 = 1, layer 2 = 2, layer 3 = 4, ...
func _layer_bit(layer: int) -> int:
	return 1 << (layer - 1)
