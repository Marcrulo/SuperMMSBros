extends GutTest
## The smash-style camera's framing (docs/specs/match-and-stage.md#camera).

## The stages' camera bounds: the blast zone's sides and bottom, the top cut to y −40.
const BOUNDS := Rect2(-72, -40, 624, 344)


func _frame(points: Array[Vector2]) -> Dictionary:
	return MatchCamera.target_framing(points, BOUNDS)


func _view(framing: Dictionary) -> Rect2:
	var view_size := Vector2(480, 270) / float(framing.zoom)
	return Rect2(framing.position - view_size / 2.0, view_size)


func test_frames_both_fighters_and_the_stage_focus() -> void:
	var framing := _frame([Vector2(168, 180), Vector2(312, 180)])
	# Box x 168..312, y 160..180, grown 120/80 → 384 × 180 → zoom min(1.25, 1.5) = 1.25.
	assert_almost_eq(framing.zoom, 1.25, 0.001)
	assert_almost_eq(framing.position.x, 240.0, 0.001)
	assert_almost_eq(framing.position.y, 170.0, 0.001)


func test_a_lone_point_at_the_focus_zooms_in_fully() -> void:
	assert_almost_eq(_frame([Vector2(240, 160)]).zoom, MatchCamera.MAX_ZOOM, 0.001)


func test_zoom_is_clamped() -> void:
	assert_almost_eq(MatchCamera.MIN_ZOOM, 0.77, 0.0001)
	var wide := MatchCamera.target_framing([Vector2(-60, 180), Vector2(540, 180)],
			Rect2(-200, -200, 900, 600))
	assert_almost_eq(wide.zoom, MatchCamera.MIN_ZOOM, 0.001)


func test_never_zooms_out_past_the_camera_bounds() -> void:
	var framing := _frame([Vector2(-60, -30), Vector2(540, 300)])
	assert_almost_eq(framing.zoom, 270.0 / 344.0, 0.001, "the bounds' height fills the view")


func test_view_stays_inside_the_camera_bounds() -> void:
	for corner in [Vector2(-70, -150), Vector2(550, 300), Vector2(-70, 300), Vector2(550, -150),
			Vector2(240, -300)]:
		var view := _view(_frame([corner]))
		assert_true(BOUNDS.encloses(view.grow(-0.001)), "view %s inside for %s" % [view, corner])


func test_a_fighter_high_above_doesnt_drag_the_camera_up() -> void:
	var on_stage := Vector2(168, 180)
	var at_top := _frame([on_stage, Vector2(312, -40)])
	for y in [-80.0, -150.0]:
		var above := _frame([on_stage, Vector2(312, y)])
		assert_almost_eq(above.zoom, at_top.zoom, 0.0001, "same zoom at y %s" % y)
		assert_almost_eq(above.position, at_top.position, Vector2(0.0001, 0.0001), "same view")
	assert_gte(_view(at_top).position.y, -40.001, "the view's top is the cut-off")


func test_the_stage_has_camera_bounds() -> void:
	var stage: Stage = add_child_autofree(preload("res://stage/battlefield.tscn").instantiate())
	assert_eq(stage.camera_bounds, BOUNDS)
	assert_eq(stage.camera_bounds.end, stage.blast_zone.end, "same sides and bottom")
	assert_eq(stage.camera_bounds.position.x, stage.blast_zone.position.x)


func test_match_uses_the_camera() -> void:
	var match_node: Node = add_child_autofree(preload("res://match/match.tscn").instantiate())
	assert_true(match_node.get_node("Camera2D") is MatchCamera)
