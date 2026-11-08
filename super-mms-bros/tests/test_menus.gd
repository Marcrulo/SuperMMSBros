extends GutTest
## Character select, stage select and the Game autoload (docs/specs/menus.md).

const CHARACTER_SELECT := preload("res://ui/character_select.tscn")
const STAGE_SELECT := preload("res://ui/stage_select.tscn")
const MATCH_SCENE := preload("res://match/match.tscn")


func before_each() -> void:
	Game.change_scenes = false
	Game.requested_scene = ""
	Game.character_id = Game.DEFAULT_CHARACTER
	Game.stage_id = ""


func after_each() -> void:
	Game.change_scenes = true
	Game.stage_id = ""


# --- Data ----------------------------------------------------------------------------------------


func test_roster_has_10_slots_and_one_character() -> void:
	var roster := Game.roster()
	assert_eq(roster.slots, 10)
	assert_eq(roster.characters.size(), 1)
	assert_eq(roster.characters[0].id, "default")
	assert_null(roster.character_in_slot(1), "slot 2 is locked")
	assert_null(roster.character_in_slot(9))


func test_default_character_uses_the_default_stats() -> void:
	var character := Game.roster().find("default")
	assert_eq(character.display_name, "Default")
	assert_eq(character.stats, load("res://fighter/default_stats.tres"))


func test_stage_order() -> void:
	assert_eq(StageData.ALL_IDS, ["mms", "fc", "slot_sunset", "cafe_station", "lindevej"])


# --- Game autoload ---------------------------------------------------------------------------------


func _key(physical: Key) -> InputEventKey:
	var event := InputEventKey.new()
	event.physical_keycode = physical
	return event


func test_game_keys_work_in_menus() -> void:
	var cases := [[KEY_A, "ui_left"], [KEY_D, "ui_right"], [KEY_W, "ui_up"], [KEY_S, "ui_down"],
			[KEY_J, "ui_accept"], [KEY_SPACE, "ui_accept"], [KEY_L, "ui_cancel"]]
	for case: Array in cases:
		assert_true(InputMap.event_is_action(_key(case[0]), case[1]), "%s → %s" % case)


func test_menus_are_skipped_with_a_stage_option() -> void:
	assert_false(Game.should_skip_menus([]))
	assert_false(Game.should_skip_menus(["--hitboxes"]))
	assert_true(Game.should_skip_menus(["--stage=fc"]))


func test_match_plays_the_chosen_stage() -> void:
	Game.stage_id = "fc"
	var match_node: Match = add_child_autofree(MATCH_SCENE.instantiate())
	var background := match_node.get_node("Stage/BackgroundLayer/Background") as Sprite2D
	assert_eq(background.texture, StageData.load_stage("fc").background)


func test_match_gives_p1_the_chosen_character() -> void:
	var match_node: Match = add_child_autofree(MATCH_SCENE.instantiate())
	assert_eq(match_node.get_fighter(0).stats, Game.roster().find("default").stats)


# --- Character select ------------------------------------------------------------------------------


func _character_select() -> CharacterSelect:
	var screen: CharacterSelect = add_child_autofree(CHARACTER_SELECT.instantiate())
	await wait_process_frames(1)
	return screen


func test_ten_tiles_first_unlocked_rest_locked() -> void:
	var screen: CharacterSelect = await _character_select()
	var tiles := screen.get_tiles()
	assert_eq(tiles.size(), 10)
	assert_false(tiles[0].locked)
	for i in range(1, 10):
		assert_true(tiles[i].locked, "slot %d locked" % (i + 1))


func test_tiles_are_a_5_by_2_grid() -> void:
	var screen: CharacterSelect = await _character_select()
	var tiles := screen.get_tiles()
	assert_eq(tiles[0].get_global_rect(), Rect2(64, 44, 64, 64))
	assert_eq(tiles[4].get_global_rect().position, Vector2(352, 44))
	assert_eq(tiles[5].get_global_rect().position, Vector2(64, 116))


## The tile the arrows move to from `tile` toward `side`.
func _neighbor(tile: Control, side: Side) -> Control:
	return tile.find_valid_focus_neighbor(side)


func test_left_and_right_wrap_within_each_row() -> void:
	var screen: CharacterSelect = await _character_select()
	var tiles := screen.get_tiles()
	assert_eq(_neighbor(tiles[0], SIDE_LEFT), tiles[4], "row 1: left of the first is the last")
	assert_eq(_neighbor(tiles[4], SIDE_RIGHT), tiles[0], "row 1: right of the last is the first")
	assert_eq(_neighbor(tiles[5], SIDE_LEFT), tiles[9], "row 2 wraps within row 2")
	assert_eq(_neighbor(tiles[9], SIDE_RIGHT), tiles[5])
	assert_eq(_neighbor(tiles[2], SIDE_LEFT), tiles[1], "the middle moves normally")
	assert_eq(_neighbor(tiles[2], SIDE_RIGHT), tiles[3])


func test_first_slot_is_highlighted_and_named() -> void:
	var screen: CharacterSelect = await _character_select()
	assert_true(screen.get_tiles()[0].has_focus())
	assert_eq(screen.get_name_text(), "Default")


func test_highlighting_a_locked_slot_shows_question_marks() -> void:
	var screen: CharacterSelect = await _character_select()
	screen.get_tiles()[3].grab_focus()
	assert_eq(screen.get_name_text(), "???")
	assert_true(screen.get_tiles()[3].is_highlighted(), "the border moved")
	assert_eq(screen.get_node("Tag").position, Vector2(64 + 3 * 72, 35), "the P1 tag moved too")
	assert_false(screen.get_tiles()[0].is_highlighted())


func test_tiles_show_the_head_and_locked_ones_a_silhouette() -> void:
	var screen: CharacterSelect = await _character_select()
	var head := screen.get_tiles()[0].get_picture() as AtlasTexture
	assert_eq(head.region, PlayerCard.HEAD_REGION)
	var locked := screen.get_tiles()[1].get_picture().get_image()
	var colors := {}
	for y in locked.get_height():
		for x in locked.get_width():
			if locked.get_pixel(x, y).a > 0.0:
				colors[locked.get_pixel(x, y).to_html()] = true
	assert_eq(colors.keys().size(), 1, "one flat color")
	assert_true(locked.get_size() == Vector2i(20, 20))


func test_choosing_the_character_opens_the_stage_select() -> void:
	var screen: CharacterSelect = await _character_select()
	screen.choose(0)
	assert_eq(Game.character_id, "default")
	assert_eq(Game.requested_scene, Game.STAGE_SELECT_PATH)


func test_choosing_a_locked_slot_does_nothing() -> void:
	var screen: CharacterSelect = await _character_select()
	screen.choose(4)
	assert_eq(Game.requested_scene, "")


# --- Stage select ----------------------------------------------------------------------------------


func _stage_select() -> StageSelect:
	var screen: StageSelect = add_child_autofree(STAGE_SELECT.instantiate())
	await wait_process_frames(1)
	return screen


func test_a_thumbnail_per_stage_in_order() -> void:
	var screen: StageSelect = await _stage_select()
	var tiles := screen.get_tiles()
	assert_eq(tiles.size(), 5)
	for i in 5:
		assert_eq(tiles[i].stage_id, StageData.ALL_IDS[i])
	assert_eq(tiles[0].get_global_rect(), Rect2(24, 190, 80, 45))
	assert_eq(tiles[4].get_global_rect().position, Vector2(376, 190))
	assert_true(tiles[0].has_focus())


func test_stage_row_wraps_around() -> void:
	var screen: StageSelect = await _stage_select()
	var tiles := screen.get_tiles()
	var last := tiles.size() - 1
	assert_eq(_neighbor(tiles[0], SIDE_LEFT), tiles[last])
	assert_eq(_neighbor(tiles[last], SIDE_RIGHT), tiles[0])
	assert_eq(_neighbor(tiles[1], SIDE_LEFT), tiles[0])


func test_highlighted_stage_shows_in_the_preview() -> void:
	var screen: StageSelect = await _stage_select()
	screen.get_tiles()[1].grab_focus()
	var fc := StageData.load_stage("fc")
	assert_eq(screen.get_preview_texture(), fc.background)
	assert_eq(screen.get_name_text(), fc.display_name)


func test_choosing_a_stage_starts_the_match() -> void:
	var screen: StageSelect = await _stage_select()
	screen.choose(2)
	assert_eq(Game.stage_id, "slot_sunset")
	assert_eq(Game.requested_scene, Game.MATCH_PATH)


func test_back_returns_to_the_character_select() -> void:
	var screen: StageSelect = await _stage_select()
	screen.back()
	assert_eq(Game.requested_scene, Game.CHARACTER_SELECT_PATH)
