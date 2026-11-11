extends GutTest
## Sprite drawing logic (docs/specs/fighter.md#visuals-fightervisuals, docs/specs/art-guide.md).
## Tests check what gets picked, never pixels on screen.


func test_frame_index_loops() -> void:
	var idle := [8, 8, 8, 8]
	assert_eq(FighterVisuals.frame_index(idle, true, 1), 0)
	assert_eq(FighterVisuals.frame_index(idle, true, 8), 0)
	assert_eq(FighterVisuals.frame_index(idle, true, 9), 1)
	assert_eq(FighterVisuals.frame_index(idle, true, 32), 3)
	assert_eq(FighterVisuals.frame_index(idle, true, 33), 0, "loops after 32 ticks")


func test_frame_index_holds_the_last_drawing() -> void:
	assert_eq(FighterVisuals.frame_index([4, 4], false, 5), 1)
	assert_eq(FighterVisuals.frame_index([4, 4], false, 100), 1)


func test_frame_index_before_the_first_tick() -> void:
	assert_eq(FighterVisuals.frame_index([8, 8], true, 0), 0)


func test_animation_for_movement_states() -> void:
	assert_eq(FighterVisuals.animation_for(Fighter.State.IDLE, 0.0), "idle")
	assert_eq(FighterVisuals.animation_for(Fighter.State.RUN, 0.0), "run")
	assert_eq(FighterVisuals.animation_for(Fighter.State.CROUCH, 0.0), "crouch")
	assert_eq(FighterVisuals.animation_for(Fighter.State.AIR, -100.0), "jump")
	assert_eq(FighterVisuals.animation_for(Fighter.State.AIR, 50.0), "fall")


func test_every_animation_has_timings_for_its_drawings() -> void:
	for animation: String in FighterVisuals.ANIMATIONS:
		var texture := load("res://assets/fighters/slot_01/fighter_%s.png" % animation) as Texture2D
		var drawings := int(texture.get_width() / texture.get_height())
		assert_eq(FighterVisuals.ANIMATIONS[animation].ticks.size(), drawings, animation)


func test_textures_are_each_characters_own_and_loaded_once() -> void:
	var nina := FighterVisuals.textures_for("slot_04")
	assert_eq((nina["idle"] as Texture2D).resource_path, "res://assets/fighters/slot_04/fighter_idle.png")
	assert_eq((nina["stock_icon"] as Texture2D).resource_path, "res://assets/fighters/slot_04/stock_icon.png")
	assert_same(FighterVisuals.textures_for("slot_04"), nina)
	assert_ne(FighterVisuals.textures_for("slot_05")["idle"], nina["idle"])


func test_animation_for_moves_and_hitstun() -> void:
	for name in [&"jab", &"down_tilt", &"up_tilt", &"side_tilt", &"neutral_air", &"forward_air", &"back_air", &"up_air", &"down_air"]:
		assert_eq(FighterVisuals.animation_for(Fighter.State.ATTACK, 0.0, name), String(name))
	assert_eq(FighterVisuals.animation_for(Fighter.State.HITSTUN, -50.0), "hurt")


## The strike drawing (index 2) must show exactly while the move can hit.
func test_strike_drawing_matches_each_moves_active_frames() -> void:
	var moves := (load("res://fighter/default_stats.tres") as FighterStats).moveset
	for name in ["jab", "down_tilt", "up_tilt", "side_tilt", "neutral_air", "forward_air", "back_air", "up_air", "down_air"]:
		var data := moves.get(name) as MoveData
		var timing: Dictionary = FighterVisuals.ANIMATIONS[name]
		for frame in range(1, data.total_frames() + 1):
			var strike := FighterVisuals.frame_index(timing.ticks, timing.loop, frame) == 2
			assert_eq(strike, data.is_active_frame(frame), "%s frame %d" % [name, frame])


func test_animation_for_dodges_and_ledge() -> void:
	assert_eq(FighterVisuals.animation_for(Fighter.State.SPOT_DODGE, 0.0), "spot_dodge")
	assert_eq(FighterVisuals.animation_for(Fighter.State.ROLL, 0.0), "roll")
	assert_eq(FighterVisuals.animation_for(Fighter.State.AIR_DODGE, 0.0), "air_dodge")
	assert_eq(FighterVisuals.animation_for(Fighter.State.LEDGE, 0.0), "ledge")
	assert_eq(FighterVisuals.animation_for(Fighter.State.LEDGE_CLIMB, 0.0), "ledge_climb")


func test_intangible_fighters_are_drawn_pale() -> void:
	assert_eq(FighterVisuals.tint(false, false), Color.WHITE)
	var pale := FighterVisuals.tint(false, true)
	assert_lt(pale.a, 1.0, "see-through")
	assert_gt(pale.r, 1.0, "brightened")


func test_animation_for_shield_helpless_and_specials() -> void:
	assert_eq(FighterVisuals.animation_for(Fighter.State.SHIELD, 0.0), "shield")
	assert_eq(FighterVisuals.animation_for(Fighter.State.SHIELD_DROP, 0.0), "shield")
	assert_eq(FighterVisuals.animation_for(Fighter.State.SHIELD_BREAK, 0.0), "dizzy")
	assert_eq(FighterVisuals.animation_for(Fighter.State.HELPLESS, 50.0), "helpless")
	for name in ["neutral_special_charge", "neutral_special", "down_special_dive", "down_special", "side_special", "up_special"]:
		assert_eq(FighterVisuals.animation_for(Fighter.State.ATTACK, 0.0, StringName(name)), name)


## Specials' strike drawings: neutral's punch is drawing 1, down's burst drawing 2, up's boost
## drawing 1 (art guide).
func test_strike_drawing_matches_each_specials_active_frames() -> void:
	var moves := (load("res://fighter/default_stats.tres") as FighterStats).moveset
	for case in [["neutral_special", 1], ["down_special", 2], ["up_special", 1]]:
		var data := moves.get(case[0]) as MoveData
		var timing: Dictionary = FighterVisuals.ANIMATIONS[case[0]]
		for frame in range(1, data.total_frames() + 1):
			var strike: bool = FighterVisuals.frame_index(timing.ticks, timing.loop, frame) == case[1]
			assert_eq(strike, data.is_active_frame(frame), "%s frame %d" % [case[0], frame])


func test_ko_is_hidden_and_invulnerability_blinks() -> void:
	assert_true(FighterVisuals.is_hidden(Fighter.State.KO, 0))
	assert_false(FighterVisuals.is_hidden(Fighter.State.IDLE, 0))
	# Hidden 4 ticks, shown 4 ticks, while invulnerable.
	var hidden: Array[bool] = []
	for frames in range(120, 104, -1):
		hidden.append(FighterVisuals.is_hidden(Fighter.State.IDLE, frames))
	assert_eq(hidden, [true, true, true, true, false, false, false, false,
			true, true, true, true, false, false, false, false])


func test_shield_bubble_shrinks_with_health() -> void:
	assert_almost_eq(FighterVisuals.shield_radius(100.0, 100.0), 16.0, 0.001)
	assert_almost_eq(FighterVisuals.shield_radius(0.0, 100.0), 6.0, 0.001)
	assert_almost_eq(FighterVisuals.shield_radius(50.0, 100.0), 11.0, 0.001)


func test_frame_size_is_the_strip_height() -> void:
	assert_eq(FighterVisuals.frame_size(FighterVisuals.textures_for("slot_05")["idle"]), 64)
	var strip_48 := ImageTexture.create_from_image(Image.create(48 * 4, 48, false, Image.FORMAT_RGBA8))
	assert_eq(FighterVisuals.frame_size(strip_48), 48)


func test_every_frame_is_drawn_48_px_with_the_feet_at_the_origin() -> void:
	assert_eq(FighterVisuals.frame_rect(), Rect2(-24, -48, 48, 48),
			"a 48 px frame 1:1, a 64 px frame at 3/4 size")
