extends GutTest
## Mads's lollipop (docs/specs/characters/mads.md#mads--grappler): a crossing guard's stop sign on his back,
## swung in his side tilt; its hitbox fitted to where the sign is drawn.

const MADS := "slot_11"
## Drawings per strip (as in FighterVisuals.ANIMATIONS).
const STRIKE := 2

var _mads: CharacterData


func before_each() -> void:
	_mads = load("res://fighter/characters/%s.tres" % MADS)


func test_the_side_tilt_matches_the_spec() -> void:
	var tilt := _mads.fighter_stats().moveset.side_tilt
	assert_eq([tilt.startup, tilt.active, tilt.recovery], [7, 3, 10])
	assert_eq(tilt.hitbox_center, Vector2(31, -15))
	assert_eq(tilt.hitbox_size, Vector2(22, 14))
	assert_eq([tilt.damage, tilt.base_knockback, tilt.knockback_growth, tilt.angle_deg],
		[7.0, 160.0, 1.3, 35.0])


func test_his_frames_are_a_bigger_canvas() -> void:
	var textures := FighterVisuals.textures_for(MADS)
	for animation: String in FighterVisuals.ANIMATIONS:
		var drawings: int = FighterVisuals.ANIMATIONS[animation].ticks.size()
		assert_eq((textures[animation] as Texture2D).get_size(), Vector2(112 * drawings, 80), animation)


## The strike drawing's sign reaches the hitbox's far edge, and nothing is drawn far past it.
func test_the_hitbox_reaches_where_the_sign_is_drawn() -> void:
	var texture: Texture2D = FighterVisuals.textures_for(MADS)["side_tilt"]
	var image := texture.get_image()
	var width := FighterVisuals.frame_width(texture, 5)
	var height := FighterVisuals.frame_size(texture)
	var rect := FighterVisuals.frame_rect(width, height)
	var s := FighterVisuals.pixel_scale(height)
	var furthest := -INF
	for y in height:
		for x in width:
			if image.get_pixel(STRIKE * width + x, y).a > 0.5:
				furthest = maxf(furthest, rect.position.x + (x + 1) * s)
	var tilt := _mads.fighter_stats().moveset.side_tilt
	assert_almost_eq(furthest, tilt.hitbox_center.x + tilt.hitbox_size.x / 2.0, 2.0)


# --- Down special: the stop smash -----------------------------------------------------------------


## The same move as Stig's cross smash (its own files, so they can be tuned apart).
func test_the_stop_smash_is_stigs_cross_smash() -> void:
	var stig: CharacterData = load("res://fighter/characters/slot_07.tres")
	var ours := _mads.fighter_stats().moveset
	var theirs := stig.fighter_stats().moveset
	for name in ["down_special", "down_special_dive"]:
		var a := ours.get(name) as MoveData
		var b := theirs.get(name) as MoveData
		assert_ne(a, b, name + ": his own file")
		for field in ["startup", "active", "recovery", "hitbox_center", "hitbox_size", "damage",
				"base_knockback", "knockback_growth", "angle_deg", "direction", "dive_speed"]:
			assert_eq(a.get(field), b.get(field), "%s.%s" % [name, field])


func test_he_has_a_red_burst() -> void:
	var textures := FighterVisuals.textures_for(MADS)
	assert_true(textures.has("burst"))
	var image := (textures["burst"] as Texture2D).get_image()
	var red := 0
	for x in image.get_width():
		for y in image.get_height():
			if image.get_pixel(x, y).is_equal_approx(Color8(214, 40, 40)):
				red += 1
	assert_gt(red, 50, "stop-sign red, not Stig's gold")


## The lollipop turns into the red stop sign while he lifts and plants it (drawings 2-4), and is
## the lollipop otherwise.
func test_the_lollipop_turns_into_a_stop_sign() -> void:
	var stop_red := Color8(214, 40, 40)
	var textures := FighterVisuals.textures_for(MADS)
	for animation: String in FighterVisuals.ANIMATIONS:
		var texture: Texture2D = textures[animation]
		var image := texture.get_image()
		var drawings: int = FighterVisuals.ANIMATIONS[animation].ticks.size()
		var width := FighterVisuals.frame_width(texture, drawings)
		for drawing in drawings:
			var red := false
			for y in image.get_height():
				for x in width:
					if image.get_pixel(drawing * width + x, y).is_equal_approx(stop_red):
						red = true
						break
				if red:
					break
			var stop: bool = animation == "down_special" and drawing in [1, 2, 3]
			assert_eq(red, stop, "%s %d" % [animation, drawing])


## Facing left, the game draws his own facing-left strip unmirrored, so STOP isn't mirrored: that
## strip is the usual one mirrored, except the lettering.
func test_stop_reads_right_facing_left() -> void:
	var textures := FighterVisuals.textures_for(MADS)
	assert_true(textures.has("down_special_left"))
	assert_eq(FighterVisuals.strip_for(textures, "down_special", -1), [textures["down_special_left"], 1])
	assert_eq(FighterVisuals.strip_for(textures, "down_special", 1), [textures["down_special"], 1])
	assert_eq(FighterVisuals.strip_for(textures, "idle", -1), [textures["idle"], -1], "others mirror")
	var right := (textures["down_special"] as Texture2D).get_image()
	var left := (textures["down_special_left"] as Texture2D).get_image()
	assert_eq(left.get_size(), right.get_size())
	var width := FighterVisuals.frame_width(textures["down_special"], 5)
	# Drawing 1 (no sign yet) is an exact mirror image.
	var differ := 0
	for y in right.get_height():
		for x in width:
			if right.get_pixel(x, y) != left.get_pixel(width - 1 - x, y):
				differ += 1
	assert_eq(differ, 0, "the lollipop drawing is just mirrored")
	# Drawing 2 (the stop sign) differs from a plain mirror image: the letters.
	differ = 0
	for y in right.get_height():
		for x in width:
			if right.get_pixel(width + x, y) != left.get_pixel(width + width - 1 - x, y):
				differ += 1
	assert_gt(differ, 10, "the lettering is not mirrored")


## Runs FighterVisuals._draw facing left mid-smash (with the facing-left strip).
func test_he_is_drawn_facing_left_mid_smash() -> void:
	var saved := Game.character_id
	Game.character_id = MADS
	var match_node: Match = preload("res://match/match.tscn").instantiate()
	match_node.auto_step = false
	add_child_autofree(match_node)
	var mads := match_node.get_fighter(0)
	var special := FighterInput.new()
	special.special_pressed = true
	special.down_held = true
	mads.spawn_at(Vector2(200, 192), -1)
	match_node.set_controller(0, ScriptedController.new([FighterInput.new(), special]))
	match_node.set_controller(1, ScriptedController.new([]))
	await wait_physics_frames(1)
	for i in 12:
		match_node.step()
	await wait_frames(2)
	assert_eq(mads.move, &"down_special")
	assert_eq(mads.facing, -1)
	Game.character_id = saved
