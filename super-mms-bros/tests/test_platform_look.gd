extends GutTest
## The perspective platform drawing (docs/specs/match-and-stage.md#platform-look-perspective).

const STAGE_SCENE := preload("res://stage/battlefield.tscn")
const FIGHTER_SCENE := preload("res://fighter/fighter.tscn")


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
	# The thin platforms' side faces are split between both layers.
	var looks: Array[PlatformLook] = [stage.get_node("PlatformLook") as PlatformLook,
			stage.get_node("PlatformFront") as PlatformLook]
	for look in looks:
		look.follow_camera = false
	for edge in [204.0, 276.0]:
		for k in range(-100, 101):
			for look in looks:
				look.vanish_x = edge + k * 0.001
			await wait_process_frames(1)
	assert_gt(looks[0].skipped_shapes + looks[1].skipped_shapes, 0,
			"collapsed faces were met and skipped")


func test_every_style_draws() -> void:
	var stage: Stage = add_child_autofree(STAGE_SCENE.instantiate())
	for id in ["mms", "fc", "slot_sunset", "lindevej"]:
		stage.apply(StageData.load_stage(id))
		await wait_process_frames(1)
	assert_true(true, "drew without script errors")


## A fighter jumping up through a thin platform passes behind its front face: the platforms' front
## part draws over the fighters, the rest behind them.
func test_thin_platform_fronts_draw_over_the_fighters() -> void:
	var stage: Stage = add_child_autofree(STAGE_SCENE.instantiate())
	var fighter: Node2D = add_child_autofree(FIGHTER_SCENE.instantiate())
	var back := stage.get_node("PlatformLook") as PlatformLook
	var front := stage.get_node("PlatformFront") as PlatformLook
	assert_false(back.front)
	assert_true(front.front)
	assert_lt(back.z_index, fighter.z_index)
	assert_gt(front.z_index, fighter.z_index)
	assert_eq(front.style, back.style)


## A thin platform's end is split at the walk line like its top face: only the part in front of
## the walk line is drawn over the fighters, the part behind it goes behind them.
func test_side_face_splits_at_the_walk_line() -> void:
	var front := Vector2(200, 153)
	var walk := Vector2(204, 150)
	var back := Vector2(208, 146)
	assert_eq(PlatformLook.side_face_edge(PlatformLook.Part.WHOLE, front, walk, back),
			PackedVector2Array([front, back]))
	assert_eq(PlatformLook.side_face_edge(PlatformLook.Part.IN_FRONT, front, walk, back),
			PackedVector2Array([front, walk]), "over the fighters: front corner to walk line")
	assert_eq(PlatformLook.side_face_edge(PlatformLook.Part.BEHIND, front, walk, back),
			PackedVector2Array([walk, back]), "behind the fighters: walk line to back corner")


## Both layers draw a side face (seen from the middle, the thin platforms' inner ends show).
func test_both_layers_draw_the_thin_platforms_ends() -> void:
	var stage: Stage = add_child_autofree(STAGE_SCENE.instantiate())
	for layer_name in ["PlatformLook", "PlatformFront"]:
		var look := stage.get_node(layer_name) as PlatformLook
		look.follow_camera = false
		look.vanish_x = 240.0
		look.side_faces_drawn = 0
		look.queue_redraw()
	await wait_process_frames(2)
	assert_eq((stage.get_node("PlatformLook") as PlatformLook).side_faces_drawn, 2,
			"behind: the back halves of the left and right platforms' inner ends")
	assert_eq((stage.get_node("PlatformFront") as PlatformLook).side_faces_drawn, 2,
			"in front: their front halves")
