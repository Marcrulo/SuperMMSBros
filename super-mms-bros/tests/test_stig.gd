extends GutTest
## Stig's gold cross, used as a sword (docs/specs/moves.md#stig--cross, docs/specs/art-guide.md#weapons):
## swung in the same three moves as Henrik's guitar, with the same poses.

const MATCH_SCENE := preload("res://match/match.tscn")
const STIG := "slot_07"
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
## Held so the roster (and its cached fighter stats) isn't reloaded between calls.
var _roster: Roster


func before_each() -> void:
	_saved_ids = [Game.character_id, Game.p2_character_id]
	_roster = Game.roster()


func after_each() -> void:
	Game.character_id = _saved_ids[0]
	Game.p2_character_id = _saved_ids[1]


func _default_moves() -> MoveSet:
	return (load("res://fighter/default_stats.tres") as FighterStats).moveset


func _stig() -> CharacterData:
	return _roster.find(STIG)


func _reach(move: MoveData) -> float:
	return move.hitbox_center.x + move.hitbox_size.x / 2.0


# --- Moves -----------------------------------------------------------------------------------------


## The same three moves as Henrik swing the weapon; the down special is the cross smash
## (test_stig_smash.gd); everything else is the default.
func test_stig_swings_in_the_same_moves_as_henrik() -> void:
	var moves := _stig().fighter_stats().moveset
	for name in SWUNG:
		assert_ne(moves.get(name), _default_moves().get(name), name + " is his own")
	for name in ["down_special", "down_special_dive"]:
		assert_ne(moves.get(name), _default_moves().get(name), name + ": the cross smash")
	for name in ["down_tilt", "up_tilt", "neutral_air", "forward_air", "back_air", "up_air",
			"down_air", "side_special", "up_special"]:
		assert_eq(moves.get(name), _default_moves().get(name), name + " is the default")


## Same timing and power as Henrik's swings; only the hitboxes differ (fitted to the cross).
func test_stig_moves_match_henriks_but_the_hitboxes() -> void:
	var stig := _stig().fighter_stats().moveset
	var henrik := _roster.find(HENRIK).fighter_stats().moveset
	for name in SWUNG:
		var own := stig.get(name) as MoveData
		var his := henrik.get(name) as MoveData
		assert_eq([own.startup, own.active, own.recovery], [his.startup, his.active, his.recovery],
			name + " frames")
		assert_eq([own.damage, own.base_knockback, own.knockback_growth, own.angle_deg, own.direction],
			[his.damage, his.base_knockback, his.knockback_growth, his.angle_deg, his.direction],
			name + " power")
		assert_eq([own.charge_frames, own.charge_damage, own.charge_knockback],
			[his.charge_frames, his.charge_damage, his.charge_knockback], name + " charge")


func test_stig_hitboxes_match_the_spec() -> void:
	var moves := _stig().fighter_stats().moveset
	var expected := {
		"jab": [Vector2(22, -10), Vector2(22, 12)],
		"side_tilt": [Vector2(29, -16), Vector2(24, 12)],
		"neutral_special": [Vector2(18, -28), Vector2(38, 26)],
	}
	for name: String in expected:
		var move := moves.get(name) as MoveData
		assert_eq([move.hitbox_center, move.hitbox_size], expected[name], name)
	assert_eq(_stig().charge_glow, Vector2(-19, -44))


func test_stig_side_tilt_reaches_further_than_jab() -> void:
	var moves := _stig().fighter_stats().moveset
	assert_gt(_reach(moves.side_tilt), _reach(moves.jab) + 6.0)
	assert_gt(_reach(moves.jab), _reach(_default_moves().jab), "a cross reaches past a fist")
	var swing := moves.neutral_special
	assert_lt(swing.hitbox_center.y - swing.hitbox_size.y / 2.0, -34.0, "overhead: above the head")


func test_match_gives_stig_his_move_set() -> void:
	Game.character_id = STIG
	Game.p2_character_id = "slot_09"
	var match_node: Match = add_child_autofree(MATCH_SCENE.instantiate())
	assert_eq(match_node.get_fighter(0).stats.moveset, _stig().fighter_stats().moveset)


# --- The cross in the sprite ---------------------------------------------------------------


func test_stig_frames_are_a_bigger_canvas() -> void:
	var textures := FighterVisuals.textures_for(STIG)
	for animation: String in DRAWINGS:
		var texture: Texture2D = textures[animation]
		assert_eq(texture.get_size(), Vector2(112 * DRAWINGS[animation], 80), animation)


## Opaque pixels of one drawing, in game pixels relative to the feet (facing right).
func _drawn_points(animation: String, drawing: int) -> Array[Vector2]:
	var texture: Texture2D = FighterVisuals.textures_for(STIG)[animation]
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


## The strike drawing's cross reaches the hitbox's far edge, and nothing is drawn far past it.
func test_hitbox_reaches_where_the_cross_is_drawn() -> void:
	var moves := _stig().fighter_stats().moveset
	for animation in SWUNG:
		var strike := 1 if animation == "neutral_special" else 2
		var move := moves.get(animation) as MoveData
		var furthest := -INF
		for point in _drawn_points(animation, strike):
			furthest = maxf(furthest, point.x)
		assert_almost_eq(furthest, _reach(move), 2.0, animation + " reach")
	var swing := moves.neutral_special
	var highest := INF
	for point in _drawn_points("neutral_special", 1):
		highest = minf(highest, point.y)
	assert_almost_eq(highest, swing.hitbox_center.y - swing.hitbox_size.y / 2.0, 2.0, "swing height")


func test_charge_glow_is_on_the_raised_cross() -> void:
	var glow := FighterVisuals.charge_glow_for(STIG)
	for drawing in 2:
		var near := false
		for point in _drawn_points("neutral_special_charge", drawing):
			near = near or point.distance_to(glow) < 3.0
		assert_true(near, "drawing %d" % drawing)


## The cross is all gold (no steel blade: it's a cross, used as a sword).
func test_the_cross_is_all_gold() -> void:
	var steel: Array[Color] = [Color8(200, 206, 216), Color8(140, 148, 164), Color8(236, 240, 246)]
	var gold := Color8(226, 182, 56)
	for animation: String in ["idle", "side_tilt"]:
		var image: Image = (FighterVisuals.textures_for(STIG)[animation] as Texture2D).get_image()
		var found_gold := false
		for y in image.get_height():
			for x in image.get_width():
				var pixel := image.get_pixel(x, y)
				assert_false(pixel in steel, "%s: no steel at (%d, %d)" % [animation, x, y])
				found_gold = found_gold or pixel == gold
		assert_true(found_gold, animation + ": gold")


## Upright on his back, its foot stays clear of his feet (it never pokes out between his legs).
func test_cross_on_the_back_stays_clear_of_the_feet() -> void:
	var gold: Array[Color] = [Color8(226, 182, 56), Color8(168, 120, 28), Color8(255, 228, 128)]
	for animation: String in ["idle", "run", "jump", "fall"]:
		for drawing in DRAWINGS[animation]:
			var lowest := -INF
			for point in _drawn_points_in(animation, drawing, gold):
				lowest = maxf(lowest, point.y)
			assert_lt(lowest, -5.0, "%s %d" % [animation, drawing])


## Opaque pixels of one drawing in these colors, in game pixels relative to the feet.
func _drawn_points_in(animation: String, drawing: int, colors: Array[Color]) -> Array[Vector2]:
	var texture: Texture2D = FighterVisuals.textures_for(STIG)[animation]
	var image := texture.get_image()
	var width := FighterVisuals.frame_width(texture, DRAWINGS[animation])
	var height := FighterVisuals.frame_size(texture)
	var rect := FighterVisuals.frame_rect(width, height)
	var s := FighterVisuals.pixel_scale(height)
	var points: Array[Vector2] = []
	for y in height:
		for x in width:
			if image.get_pixel(drawing * width + x, y) in colors:
				points.append(rect.position + (Vector2(x, y) + Vector2(0.5, 0.5)) * s)
	return points


## The cross never goes into the floor: it stays above his feet (follow-throughs point it level,
## not down), except where the cross smash puts it on the floor (down special drawings 2 and 3).
func test_cross_never_goes_below_the_feet() -> void:
	var gold: Array[Color] = [Color8(226, 182, 56), Color8(168, 120, 28), Color8(255, 228, 128)]
	for animation: String in DRAWINGS:
		for drawing in DRAWINGS[animation]:
			var smashed: bool = animation == "down_special" and drawing in [2, 3]
			var lowest := -INF
			for point in _drawn_points_in(animation, drawing, gold):
				lowest = maxf(lowest, point.y)
			if smashed:
				assert_gt(lowest, -2.0, "%s %d: on the floor (as low as the shoes)" % [animation, drawing])
			elif lowest > -INF:
				assert_lt(lowest, -2.0, "%s %d" % [animation, drawing])
