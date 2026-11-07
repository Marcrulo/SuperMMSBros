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
		var texture := load("res://assets/fighters/default/fighter_%s.png" % animation) as Texture2D
		var drawings := int(texture.get_width() / 48.0)
		assert_eq(FighterVisuals.ANIMATIONS[animation].ticks.size(), drawings, animation)


func test_p2_wears_blue() -> void:
	var textures := FighterVisuals.load_textures(FighterVisuals.P2_SHIRT_COLORS)
	var image := (textures["idle"] as Texture2D).get_image()
	var colors := {}
	for y in image.get_height():
		for x in image.get_width():
			colors[image.get_pixel(x, y).to_html(false)] = true
	assert_false(colors.has("b13e53"), "no red shirt left")
	assert_true(colors.has("3b5dc9"), "blue shirt")
