extends GutTest
## Character move sets and weapons drawn into the sprite (docs/specs/moves.md#character-move-sets,
## docs/specs/art-guide.md#weapons): Henrik and his guitar.

const MATCH_SCENE := preload("res://match/match.tscn")
const HENRIK := "slot_06"
const SWUNG: Array[String] = ["jab", "side_tilt", "neutral_special"]
## Drawings per animation (art guide).
const DRAWINGS := {
	"idle": 4, "run": 6, "crouch": 2, "jump": 2, "fall": 2, "helpless": 2, "shield": 1,
	"dizzy": 2, "hurt": 2, "jab": 5, "down_tilt": 5, "up_tilt": 5, "side_tilt": 5,
	"neutral_special_charge": 2, "neutral_special": 4, "down_special_dive": 1,
	"down_special": 5, "side_special": 4, "up_special": 3,
	"neutral_air": 5, "forward_air": 5, "back_air": 5, "up_air": 5, "down_air": 5,
	"spot_dodge": 3, "roll": 4, "air_dodge": 2, "ledge": 2, "ledge_climb": 3,
}

var _saved_ids: Array[String] = []


func before_each() -> void:
	_saved_ids = [Game.character_id, Game.p2_character_id]


func after_each() -> void:
	Game.character_id = _saved_ids[0]
	Game.p2_character_id = _saved_ids[1]


func _default_moves() -> MoveSet:
	return (load("res://fighter/default_stats.tres") as FighterStats).moveset


func _henrik() -> CharacterData:
	return Game.roster().find(HENRIK)


# --- Move sets -------------------------------------------------------------------------------------


func test_henrik_has_his_own_moves() -> void:
	var moves := _henrik().fighter_stats().moveset
	assert_ne(moves, _default_moves(), "Henrik's own move set")
	for name in SWUNG:
		assert_ne(moves.get(name), _default_moves().get(name), name + " is his own")
	for name in ["down_tilt", "up_tilt", "neutral_air", "forward_air", "back_air", "up_air",
			"down_air", "down_special", "down_special_dive", "side_special", "up_special"]:
		assert_eq(moves.get(name), _default_moves().get(name), name + " is the default")


func test_henrik_keeps_the_shared_stats() -> void:
	var henrik := _henrik()
	var stats := henrik.fighter_stats()
	var shared := henrik.stats
	assert_eq(stats.run_speed, shared.run_speed)
	assert_eq(stats.shield_max, shared.shield_max)
	assert_eq(stats.ledge_grab_box, shared.ledge_grab_box)
	assert_same(henrik.fighter_stats(), stats, "made once")
	assert_eq(shared.moveset, _default_moves(), "the shared stats are left alone")


func test_others_use_the_shared_stats_as_they_are() -> void:
	for character in Game.roster().characters:
		if character.moveset == null:
			assert_same(character.fighter_stats(), character.stats, character.id)


## His moves keep the default frame counts, so the shared animation timing still fits.
func test_henrik_moves_keep_the_default_frames() -> void:
	var moves := _henrik().fighter_stats().moveset
	for name in SWUNG:
		var own := moves.get(name) as MoveData
		var default := _default_moves().get(name) as MoveData
		assert_eq([own.startup, own.active, own.recovery],
			[default.startup, default.active, default.recovery], name)


func test_henrik_moves_match_the_spec() -> void:
	var moves := _henrik().fighter_stats().moveset
	# name: [center, size, damage, base, growth, angle]
	var expected := {
		"jab": [Vector2(18, -10), Vector2(20, 12), 3.0, 120.0, 0.8, 30.0],
		"side_tilt": [Vector2(29, -16), Vector2(24, 12), 7.0, 160.0, 1.3, 35.0],
		"neutral_special": [Vector2(20, -30), Vector2(40, 24), 8.0, 200.0, 2.0, 45.0],
	}
	for name: String in expected:
		var move := moves.get(name) as MoveData
		var e: Array = expected[name]
		assert_eq(move.hitbox_center, e[0], name + " center")
		assert_eq(move.hitbox_size, e[1], name + " size")
		assert_eq(move.damage, e[2], name + " damage")
		assert_eq(move.base_knockback, e[3], name + " base")
		assert_almost_eq(move.knockback_growth, e[4], 0.0001, name + " growth")
		assert_eq(move.angle_deg, e[5], name + " angle")
		assert_eq(move.direction, MoveData.Direction.FACING, name + " direction")
	var swing := moves.neutral_special
	assert_eq([swing.charge_frames, swing.charge_damage, swing.charge_knockback], [60, 14.0, 200.0])


func _reach(move: MoveData) -> float:
	return move.hitbox_center.x + move.hitbox_size.x / 2.0


func test_henrik_side_tilt_reaches_further_than_jab() -> void:
	var moves := _henrik().fighter_stats().moveset
	assert_gt(_reach(moves.side_tilt), _reach(moves.jab) + 8.0)
	assert_gt(_reach(moves.side_tilt), _reach(_default_moves().side_tilt), "further than the kick")
	assert_gt(_reach(moves.jab), _reach(_default_moves().jab), "a guitar reaches past a fist")
	assert_lt(moves.side_tilt.damage, _default_moves().side_tilt.damage, "but lighter")


func test_henrik_overhead_swing_hits_above_his_head() -> void:
	var swing := _henrik().fighter_stats().moveset.neutral_special
	var top := swing.hitbox_center.y - swing.hitbox_size.y / 2.0
	assert_lt(top, -34.0, "above the head")
	assert_gt(_reach(swing), 24.0, "and in front")


func test_match_gives_henrik_his_move_set() -> void:
	Game.character_id = HENRIK
	Game.p2_character_id = "slot_09"
	var match_node: Match = add_child_autofree(MATCH_SCENE.instantiate())
	assert_eq(match_node.get_fighter(0).stats.moveset, _henrik().fighter_stats().moveset)
	assert_eq(match_node.get_fighter(1).stats.moveset, _default_moves())


# --- The guitar in the sprite ------------------------------------------------------------------


func test_henrik_frames_are_a_bigger_canvas() -> void:
	var textures := FighterVisuals.textures_for(HENRIK)
	for animation: String in DRAWINGS:
		var texture: Texture2D = textures[animation]
		assert_eq(texture.get_size(), Vector2(112 * DRAWINGS[animation], 80), animation)


## Opaque pixels of one drawing, in game pixels relative to the feet (facing right).
func _drawn_points(animation: String, drawing: int) -> Array[Vector2]:
	var texture: Texture2D = FighterVisuals.textures_for(HENRIK)[animation]
	var image := texture.get_image()
	var width := FighterVisuals.frame_width(texture, DRAWINGS[animation])
	var height := FighterVisuals.frame_size(texture)
	var rect := FighterVisuals.frame_rect(width, height)
	var s := FighterVisuals.pixel_scale(height)
	var points: Array[Vector2] = []
	for y in height:
		for x in width:
			if image.get_pixel(drawing * width + x, y).a > 0.5:
				points.append(rect.position + (Vector2(x, y) + Vector2(0.5, 0.5)) * s)
	return points


## The strike drawing's guitar reaches the hitbox's far edge, and nothing is drawn far past it.
func test_hitbox_reaches_where_the_guitar_is_drawn() -> void:
	var moves := _henrik().fighter_stats().moveset
	for animation in SWUNG:
		var strike := 1 if animation == "neutral_special" else 2
		var move := moves.get(animation) as MoveData
		var hitbox := Rect2(move.hitbox_center - move.hitbox_size / 2.0, move.hitbox_size)
		var furthest := -INF
		for point in _drawn_points(animation, strike):
			furthest = maxf(furthest, point.x)
		assert_almost_eq(furthest, hitbox.end.x, 2.0, animation + " reach")
	var swing := moves.neutral_special
	var highest := INF
	for point in _drawn_points("neutral_special", 1):
		highest = minf(highest, point.y)
	assert_almost_eq(highest, swing.hitbox_center.y - swing.hitbox_size.y / 2.0, 2.0, "swing height")


func test_charge_glow_is_on_the_raised_guitar() -> void:
	var glow := FighterVisuals.charge_glow_for(HENRIK)
	assert_eq(glow, _henrik().charge_glow)
	assert_eq(FighterVisuals.charge_glow_for("slot_01"), FighterVisuals.FIST, "the fists by default")
	for drawing in 2:
		var near := false
		for point in _drawn_points("neutral_special_charge", drawing):
			near = near or point.distance_to(glow) < 3.0
		assert_true(near, "drawing %d" % drawing)


func test_frames_of_any_size_are_drawn_at_three_quarters_feet_at_the_origin() -> void:
	assert_eq(FighterVisuals.frame_rect(112, 80), Rect2(-42, -60, 84, 60))
	assert_eq(FighterVisuals.frame_rect(), Rect2(-24, -48, 48, 48))
	assert_eq(FighterVisuals.frame_rect(48, 48), Rect2(-24, -48, 48, 48))


func test_head_region_in_a_bigger_canvas() -> void:
	assert_eq(PlayerCard.head_region(80, 112), Rect2(47, 36, 20, 20))
	assert_eq(PlayerCard.head_region_of(FighterVisuals.textures_for(HENRIK)["idle"]),
		Rect2(47, 36, 20, 20))
	assert_eq(PlayerCard.head_region_of(FighterVisuals.textures_for("slot_05")["idle"]),
		PlayerCard.head_region(64))
