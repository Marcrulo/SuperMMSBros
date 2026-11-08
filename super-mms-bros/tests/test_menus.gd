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


const ANNOUNCED_NAMES: Array[String] = ["Gitte", "Trine", "Nina", "Michael Bech", "Henrik", "Stig",
		"Casper", "Kim", "Mette"]


func test_roster_has_10_characters_one_playable() -> void:
	var roster := Game.roster()
	assert_eq(roster.slots, 10)
	assert_eq(roster.characters.size(), 10)
	assert_eq(roster.characters[0].id, "default")
	assert_true(roster.characters[0].playable)
	assert_false(roster.is_locked(0))
	for i in range(1, 10):
		var character := roster.character_in_slot(i)
		assert_eq(character.id, "slot_%02d" % (i + 1))
		assert_false(character.playable, character.id)
		assert_eq(character.display_name, ANNOUNCED_NAMES[i - 1])
		assert_eq(character.portrait.resource_path,
				"res://assets/fighters/portraits/slot_%02d.png" % (i + 1))
		assert_true(roster.is_locked(i))
	assert_true(roster.is_locked(10), "past the list")


func test_an_unplayable_character_falls_back_to_the_default() -> void:
	Game.character_id = "slot_05"
	assert_eq(Game.character().id, "default")


func test_default_character_uses_the_default_stats() -> void:
	var character := Game.roster().find("default")
	assert_eq(character.display_name, "Pia")
	assert_eq(character.portrait.resource_path, "res://assets/fighters/portraits/default.png")
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
	assert_eq(tiles[0].get_global_rect(), Rect2(39, 44, 74, 74))
	assert_eq(tiles[4].get_global_rect().position, Vector2(367, 44))
	assert_eq(tiles[5].get_global_rect().position, Vector2(39, 126))


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
	assert_eq(screen.get_name_text(), "Pia")


func test_highlighting_a_locked_slot_shows_its_name() -> void:
	var screen: CharacterSelect = await _character_select()
	screen.get_tiles()[3].grab_focus()
	assert_eq(screen.get_name_text(), "Nina")
	assert_true(screen.get_tiles()[3].is_highlighted(), "the border moved")
	assert_eq(screen.get_node("Tag").position, Vector2(39 + 3 * 82, 35), "the P1 tag moved too")
	assert_false(screen.get_tiles()[0].is_highlighted())


func test_tiles_show_the_head_or_the_portrait() -> void:
	var screen: CharacterSelect = await _character_select()
	for i in range(0, 10):
		var portrait := screen.get_tiles()[i].get_picture() as AtlasTexture
		var expected := Game.roster().character_in_slot(i).portrait
		assert_eq(portrait.atlas, expected, "slot %d" % (i + 1))
		assert_eq(portrait.region, Rect2(0, 6, 221, 221), "slot %d: the face" % (i + 1))
		assert_eq(screen.get_tiles()[i].get_picture_filter(),
				CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS)
		assert_eq(screen.get_tiles()[i].get_picture_size(), Vector2(70, 70))
		assert_false(screen.get_tiles()[i].has_node("QuestionMark"), "no ? over a portrait")


func test_portrait_square_is_the_top_of_the_picture() -> void:
	var pia := load("res://assets/fighters/portraits/default.png") as Texture2D
	assert_eq(CharacterSelect.portrait_region(pia), Rect2(0, 6, 221, 221))
	var small := Image.create(153, 193, false, Image.FORMAT_RGB8)
	assert_eq(CharacterSelect.portrait_region(ImageTexture.create_from_image(small)),
			Rect2(0, 4, 153, 153), "any size works")


func test_an_unlocked_character_without_a_portrait_shows_the_fighter_head() -> void:
	var character := CharacterData.new()
	character.playable = true
	var tile := CharacterSelect.make_tile(character)
	add_child_autofree(tile)
	assert_eq((tile.get_picture() as AtlasTexture).region, PlayerCard.HEAD_REGION)
	assert_eq(tile.get_picture_filter(), CanvasItem.TEXTURE_FILTER_NEAREST)


func test_a_locked_slot_without_a_portrait_is_a_silhouette() -> void:
	var character := CharacterData.new()
	character.id = "mystery"
	var tile := CharacterSelect.make_tile(character)
	add_child_autofree(tile)
	assert_true(tile.locked)
	assert_true(tile.has_node("QuestionMark"))
	var image := tile.get_picture().get_image()
	var colors := {}
	for y in image.get_height():
		for x in image.get_width():
			if image.get_pixel(x, y).a > 0.0:
				colors[image.get_pixel(x, y).to_html()] = true
	assert_eq(colors.keys().size(), 1, "one flat color")


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


func test_title_uses_the_brush_font_when_present() -> void:
	var screen: CharacterSelect = await _character_select()
	var title := screen.get_node("Title") as Label
	if not ResourceLoader.exists(TitleFont.PATH):
		assert_false(title.has_theme_font_override("font"), "pixel font fallback")
		assert_eq(title.position.y, 14.0)
		return
	var font := title.get_theme_font("font")
	assert_eq(font.resource_path, TitleFont.PATH)
	assert_eq(title.get_theme_font_size("font_size"), 24)
	assert_eq(title.position.y, 4.0)
	assert_eq(title.text, "CHOOSE YOUR FIGHTER")


func test_stage_title_uses_the_brush_font_when_present() -> void:
	var screen: StageSelect = await _stage_select()
	var title := screen.get_node("Title") as Label
	assert_eq(title.text, "CHOOSE YOUR STAGE")
	if not ResourceLoader.exists(TitleFont.PATH):
		assert_eq(title.position.y, 10.0, "pixel font fallback")
		return
	assert_eq(title.get_theme_font("font").resource_path, TitleFont.PATH)
	assert_eq(title.get_theme_font_size("font_size"), 24)
	assert_eq(title.position.y, 2.0)


func test_every_portrait_is_221_by_279() -> void:
	for character in Game.roster().characters:
		assert_eq(character.portrait.get_size(), Vector2(221, 279), character.id)


func test_portraits_are_imported_with_mipmaps() -> void:
	for character in Game.roster().characters:
		assert_true(character.portrait.get_image().has_mipmaps(), character.id)
