extends GutTest
## The smash-style camera's framing (docs/specs/match-and-stage.md#camera).

const BLAST_ZONE := Rect2(-120, -200, 720, 520)


func _frame(points: Array[Vector2]) -> Dictionary:
	return MatchCamera.target_framing(points, BLAST_ZONE)


func test_frames_both_fighters_and_the_stage_focus() -> void:
	var framing := _frame([Vector2(168, 180), Vector2(312, 180)])
	# Box x 168..312, y 160..180, grown 120/80 → 384 × 180 → zoom min(1.25, 1.5) = 1.25.
	assert_almost_eq(framing.zoom, 1.25, 0.001)
	assert_almost_eq(framing.position.x, 240.0, 0.001)
	assert_almost_eq(framing.position.y, 170.0, 0.001)


func test_a_lone_point_at_the_focus_zooms_in_fully() -> void:
	assert_almost_eq(_frame([Vector2(240, 160)]).zoom, MatchCamera.MAX_ZOOM, 0.001)


func test_zoom_is_clamped() -> void:
	var framing := _frame([Vector2(-100, 180), Vector2(580, 180)])
	assert_almost_eq(framing.zoom, MatchCamera.MIN_ZOOM, 0.001)


func test_view_stays_inside_the_blast_zone() -> void:
	for corner in [Vector2(-110, -190), Vector2(590, 310), Vector2(-110, 310), Vector2(590, -190)]:
		var framing := _frame([corner])
		var zoom: float = framing.zoom
		var center: Vector2 = framing.position
		var view_size := Vector2(480, 270) / zoom
		var view := Rect2(center - view_size / 2.0, view_size)
		assert_true(BLAST_ZONE.encloses(view.grow(-0.001)), "view %s inside for %s" % [view, corner])


func test_match_uses_the_camera() -> void:
	var match_node: Node = add_child_autofree(preload("res://match/match.tscn").instantiate())
	assert_true(match_node.get_node("Camera2D") is MatchCamera)
