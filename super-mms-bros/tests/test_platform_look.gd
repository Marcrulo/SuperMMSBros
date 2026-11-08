extends GutTest
## The perspective platform drawing (docs/specs/match-and-stage.md#platform-look-perspective).

const STAGE_SCENE := preload("res://stage/battlefield.tscn")


func test_top_face_matches_the_collision_along_the_walk_line() -> void:
	for vanish in [0.0, 150.0, 240.0, 333.3, 480.0]:
		for x in [96.0, 132.0, 204.0, 384.0]:
			assert_eq(PlatformLook.perspective_x(x, 0.0, vanish), x)


func test_wider_in_front_narrower_behind() -> void:
	assert_almost_eq(PlatformLook.perspective_x(96.0, 6.0, 240.0), 86.496, 0.001)
	assert_almost_eq(PlatformLook.perspective_x(384.0, 6.0, 240.0), 393.504, 0.001)
	assert_almost_eq(PlatformLook.perspective_x(96.0, -8.0, 240.0), 108.672, 0.001)


func test_collapsed_shapes_are_skipped() -> void:
	# A side face from the camera sweep, 0.0004 px wide: Godot can't triangulate it.
	var flat := PackedVector2Array([
		Vector2(204, 163), Vector2(204.0004, 156), Vector2(204.0004, 162), Vector2(204, 169),
	])
	var quad := PackedVector2Array([Vector2(0, 0), Vector2(10, 0), Vector2(10, 5), Vector2(0, 5)])
	assert_false(PlatformLook.is_fillable(flat))
	assert_true(PlatformLook.is_fillable(quad))


## Looking along the thin platforms' ends makes their side faces collapse; those must be skipped
## (before the fix, Godot printed "triangulation failed" for them in a real window).
func test_camera_sweep_along_platform_ends_skips_collapsed_faces() -> void:
	var stage: Stage = add_child_autofree(STAGE_SCENE.instantiate())
	var look := stage.get_node("PlatformLook") as PlatformLook
	look.follow_camera = false
	for edge in [204.0, 276.0]:
		for k in range(-100, 101):
			look.vanish_x = edge + k * 0.001
			await wait_process_frames(1)
	assert_gt(look.skipped_shapes, 0, "collapsed faces were met and skipped")


func test_every_style_draws() -> void:
	var stage: Stage = add_child_autofree(STAGE_SCENE.instantiate())
	for id in ["mms", "fc", "slot_sunset", "lindevej"]:
		stage.apply(StageData.load_stage(id))
		await wait_process_frames(1)
	assert_true(true, "drew without script errors")
