extends GutTest
## Character select, stage select and the Game autoload (docs/specs/menus.md).

const CHARACTER_SELECT := preload("res://ui/character_select.tscn")
const STAGE_SELECT := preload("res://ui/stage_select.tscn")
const MATCH_SCENE := preload("res://match/match.tscn")


func before_each() -> void:
	Game.change_scenes = false
	Game.requested_scene = ""
	Game.character_id = Game.DEFAULT_CHARACTER
	Game.p2_character_id = Game.DEFAULT_P2_CHARACTER
	Game.stage_id = ""


func after_each() -> void:
	Game.change_scenes = true
	Game.stage_id = ""


# --- Data ----------------------------------------------------------------------------------------


const NAMES: Array[String] = ["Pia", "Gitte", "Trine", "Nina", "Michael Bech", "Henrik", "Stig",
		"Casper", "Kim", "Mette", "Mads", "Sjippepigen", "Fidusen",
		"Magnus"]


func test_roster_has_15_slots_14_playable_characters() -> void:
	var roster := Game.roster()
	assert_eq(roster.slots, 15)
	assert_eq(roster.characters.size(), 14)
	for i in range(0, 14):
		var character := roster.character_in_slot(i)
		assert_eq(character.id, "slot_%02d" % (i + 1))
		assert_true(character.playable, character.id)
		assert_eq(character.display_name, NAMES[i])
		assert_eq(character.portrait.resource_path,
				"res://assets/fighters/portraits/slot_%02d.png" % (i + 1))
		assert_eq(character.stats, load("res://fighter/default_stats.tres"), character.id)
		assert_false(roster.is_locked(i))
	for i in [14]:
		assert_null(roster.character_in_slot(i), "slot %d is empty" % (i + 1))
		assert_true(roster.is_locked(i), "past the list")


func test_an_unknown_character_falls_back_to_the_default() -> void:
	Game.character_id = "nobody"
	assert_eq(Game.character().id, "slot_01")
	Game.p2_character_id = "nobody"
	assert_eq(Game.p2_character().id, "slot_01")


func test_the_default_characters_are_pia_and_gitte() -> void:
	assert_eq(Game.DEFAULT_CHARACTER, "slot_01")
	assert_eq(CharacterData.DEFAULT_ID, "slot_01")
	assert_eq(Game.DEFAULT_P2_CHARACTER, "slot_02")
	assert_eq(Game.roster().find("slot_01").display_name, "Pia")


func test_stage_order() -> void:
	assert_eq(StageData.ALL_IDS, ["mms", "fc", "slot_sunset", "cafe_station", "lindevej", "cafe_slotsbio"])


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


func test_match_gives_each_player_their_character() -> void:
	Game.character_id = "slot_04"
	Game.p2_character_id = "slot_09"
	var match_node: Match = add_child_autofree(MATCH_SCENE.instantiate())
	assert_eq(match_node.get_fighter(0).character_id, "slot_04")
	assert_eq(match_node.get_fighter(1).character_id, "slot_09")
	assert_eq(match_node.get_fighter(0).stats, Game.roster().find("slot_04").stats)
	assert_eq(match_node.get_fighter(1).stats, Game.roster().find("slot_09").stats)


# --- Character select ------------------------------------------------------------------------------


func _character_select() -> CharacterSelect:
	var screen: CharacterSelect = add_child_autofree(CHARACTER_SELECT.instantiate())
	await wait_process_frames(1)
	return screen


func test_fourteen_tiles_unlocked_the_last_locked() -> void:
	var screen: CharacterSelect = await _character_select()
	var tiles := screen.get_tiles()
	assert_eq(tiles.size(), 15)
	for i in range(0, 14):
		assert_false(tiles[i].locked, "slot %d unlocked" % (i + 1))
	assert_true(tiles[14].locked, "slot 15 is empty")


func test_tiles_are_a_5_by_3_grid() -> void:
	var screen: CharacterSelect = await _character_select()
	var tiles := screen.get_tiles()
	assert_eq(tiles[0].get_global_rect(), Rect2(88, 42, 56, 56))
	assert_eq(tiles[4].get_global_rect().position, Vector2(336, 42), "row 1 ends at x 392")
	assert_eq(tiles[5].get_global_rect().position, Vector2(88, 104))
	assert_eq(tiles[14].get_global_rect(), Rect2(336, 166, 56, 56), "the grid ends at y 222")


func test_name_sits_below_the_grid() -> void:
	var screen: CharacterSelect = await _character_select()
	# The ink font, when present, moves a 16 px label up 2 px to stay centred on its line.
	var expected := 226.0 if InkFont.present() else 228.0
	assert_eq((screen.get_node("Name") as Label).position.y, expected)


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
	assert_eq(_neighbor(tiles[10], SIDE_LEFT), tiles[14], "row 3 too")
	assert_eq(_neighbor(tiles[2], SIDE_LEFT), tiles[1], "the middle moves normally")
	assert_eq(_neighbor(tiles[2], SIDE_RIGHT), tiles[3])


func test_first_slot_is_highlighted_and_named() -> void:
	var screen: CharacterSelect = await _character_select()
	assert_true(screen.get_tiles()[0].has_focus())
	assert_eq(screen.get_name_text(), "Pia")


func test_highlighting_a_slot_shows_its_name() -> void:
	var screen: CharacterSelect = await _character_select()
	screen.get_tiles()[3].grab_focus()
	assert_eq(screen.get_name_text(), "Nina")
	assert_true(screen.get_tiles()[3].is_highlighted(), "the border moved")
	assert_eq(screen.get_node("Tag").position, Vector2(88 + 3 * 62, 33), "the P1 tag moved too")
	assert_false(screen.get_tiles()[0].is_highlighted())


func test_an_empty_slot_is_named_in_words_the_brush_font_draws() -> void:
	assert_eq(CharacterSelect.name_for(null), "Coming soon")
	assert_true(InkFont.can_draw(CharacterSelect.name_for(null)))
	assert_eq(CharacterSelect.name_for(Game.roster().character_in_slot(11)), "Sjippepigen")


func test_magnus_is_slot_14_and_the_last_is_coming_soon() -> void:
	var screen: CharacterSelect = await _character_select()
	screen.get_tiles()[13].grab_focus()
	assert_eq(screen.get_name_text(), "Magnus")
	assert_false(screen.get_tiles()[13].locked)
	screen.get_tiles()[14].grab_focus()
	assert_eq(screen.get_name_text(), "Coming soon")
	assert_true(screen.get_tiles()[14].locked)


func test_tiles_show_the_portraits_faces() -> void:
	var screen: CharacterSelect = await _character_select()
	for i in range(0, 14):
		var tile := screen.get_tiles()[i]
		var face := tile.get_picture() as AtlasTexture
		assert_eq(face.atlas, Game.roster().character_in_slot(i).portrait, "slot %d" % (i + 1))
		assert_eq(face.region, Rect2(0, 6, 221, 221), "slot %d: the face" % (i + 1))
		assert_eq(tile.get_picture_filter(), CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS)
		assert_eq(tile.get_picture_size(), Vector2(52, 52))


## Silhouette portraits are off for now, but every portrait must still make a clean one.
func test_every_portrait_makes_a_clean_silhouette() -> void:
	for i in range(0, 14):
		var portrait := Game.roster().character_in_slot(i).portrait
		var image := CharacterSelect.portrait_silhouette(portrait).get_image()
		assert_eq(image.get_size(), Vector2i(221, 221), "slot %d: the face square" % (i + 1))
		assert_true(image.has_mipmaps(), "slot %d: mipmaps" % (i + 1))
		var counts := _silhouette_counts(image)
		assert_eq(counts.other, 0, "slot %d: only flat color or see-through" % (i + 1))
		# The person covers a real share of the square, the background another (Magnus's close-up
		# face covers about 92%).
		assert_between(counts.flat, 221 * 221 / 4, 221 * 221 * 95 / 100, "slot %d" % (i + 1))
		assert_eq(image.get_pixel(0, 0).a, 0.0, "slot %d: the corner is background" % (i + 1))
		assert_eq(image.get_pixel(110, 200), CharacterSelect.SILHOUETTE,
				"slot %d: the bottom middle is the person" % (i + 1))


func test_a_portrait_silhouette_is_made_once() -> void:
	var pia := load("res://assets/fighters/portraits/slot_01.png") as Texture2D
	assert_same(CharacterSelect.portrait_silhouette(pia),
			CharacterSelect.portrait_silhouette(pia))


func test_portrait_silhouette_keeps_the_person_and_drops_the_background() -> void:
	# A navy square with a lighter "person" blob touching the bottom edge.
	var image := Image.create(30, 38, false, Image.FORMAT_RGB8)
	image.fill(Color8(21, 23, 43))
	image.fill_rect(Rect2i(10, 12, 10, 26), Color8(200, 150, 120))
	image.set_pixel(3, 20, Color8(200, 200, 200))  # a lone speck in the background
	var silhouette := CharacterSelect.portrait_silhouette(ImageTexture.create_from_image(image))
	var result := silhouette.get_image()
	result.clear_mipmaps()
	assert_eq(result.get_size(), Vector2i(30, 30))
	assert_eq(result.get_pixel(15, 20), CharacterSelect.SILHOUETTE, "the person")
	assert_eq(result.get_pixel(2, 2).a, 0.0, "the background")
	assert_eq(result.get_pixel(3, 19).a, 0.0, "the speck is cleaned up")


func _silhouette_counts(image: Image) -> Dictionary:
	var counts := {flat = 0, other = 0}
	var top := image.duplicate() as Image
	top.clear_mipmaps()
	for y in top.get_height():
		for x in top.get_width():
			var color := top.get_pixel(x, y)
			if color == CharacterSelect.SILHOUETTE:
				counts.flat += 1
			elif color.a != 0.0:
				counts.other += 1
	return counts


func test_portrait_square_is_the_top_of_the_picture() -> void:
	var pia := load("res://assets/fighters/portraits/slot_01.png") as Texture2D
	assert_eq(CharacterSelect.portrait_region(pia), Rect2(0, 6, 221, 221))
	var small := Image.create(153, 193, false, Image.FORMAT_RGB8)
	assert_eq(CharacterSelect.portrait_region(ImageTexture.create_from_image(small)),
			Rect2(0, 4, 153, 153), "any size works")


func test_an_unlocked_character_without_a_portrait_shows_the_fighter_head() -> void:
	var character := CharacterData.new()
	character.id = "slot_06"
	character.playable = true
	var tile := CharacterSelect.make_tile(character)
	add_child_autofree(tile)
	assert_eq((tile.get_picture() as AtlasTexture).region, PlayerCard.HEAD_REGION)
	assert_eq((tile.get_picture() as AtlasTexture).atlas, FighterVisuals.textures_for("slot_06")["idle"],
			"its own head")
	assert_eq(tile.get_picture_filter(), CanvasItem.TEXTURE_FILTER_NEAREST)


func test_a_locked_slot_without_a_portrait_is_a_silhouette() -> void:
	var character := CharacterData.new()
	character.id = "mystery"
	var tile := CharacterSelect.make_tile(character)
	add_child_autofree(tile)
	assert_true(tile.locked)
	assert_eq(tile.get_child_count(), 3, "just the square, the picture and the border: no ?")
	var image := tile.get_picture().get_image()
	var colors := {}
	for y in image.get_height():
		for x in image.get_width():
			if image.get_pixel(x, y).a > 0.0:
				colors[image.get_pixel(x, y).to_html()] = true
	assert_eq(colors.keys().size(), 1, "one flat color")


func test_choosing_the_character_opens_the_stage_select() -> void:
	var screen: CharacterSelect = await _character_select()
	screen.choose(4)
	assert_eq(Game.character_id, "slot_05")
	assert_eq(Game.requested_scene, Game.STAGE_SELECT_PATH)


func test_choosing_gives_p2_a_different_character() -> void:
	var screen: CharacterSelect = await _character_select()
	var seen := {}
	for i in 60:
		screen.choose(i % 14)
		var p2 := Game.p2_character()
		assert_ne(p2.id, Game.character_id, "P2 never gets P1's character")
		assert_true(p2.playable)
		seen[p2.id] = true
	assert_gt(seen.size(), 5, "P2's pick varies")


func test_choosing_a_locked_slot_does_nothing() -> void:
	var screen: CharacterSelect = await _character_select()
	screen.choose(14)
	assert_eq(Game.requested_scene, "")


# --- Stage select ----------------------------------------------------------------------------------


func _stage_select() -> StageSelect:
	var screen: StageSelect = add_child_autofree(STAGE_SELECT.instantiate())
	await wait_process_frames(1)
	return screen


func test_a_thumbnail_per_stage_in_order() -> void:
	var screen: StageSelect = await _stage_select()
	var tiles := screen.get_tiles()
	assert_eq(tiles.size(), 6)
	for i in 6:
		assert_eq(tiles[i].stage_id, StageData.ALL_IDS[i])
	assert_eq(tiles[0].get_global_rect(), Rect2(28, 190, 64, 36))
	assert_eq(tiles[5].get_global_rect().position, Vector2(388, 190))
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
	if not ResourceLoader.exists(InkFont.PATH):
		assert_false(title.has_theme_font_override("font"), "pixel font fallback")
		assert_eq(title.position.y, 14.0)
		return
	var font := title.get_theme_font("font")
	assert_eq(font.resource_path, InkFont.PATH)
	assert_eq(title.get_theme_font_size("font_size"), 24)
	assert_eq(title.position.y, 4.0)
	assert_eq(title.text, "CHOOSE YOUR FIGHTER")


func test_stage_title_uses_the_brush_font_when_present() -> void:
	var screen: StageSelect = await _stage_select()
	var title := screen.get_node("Title") as Label
	assert_eq(title.text, "CHOOSE YOUR STAGE")
	if not ResourceLoader.exists(InkFont.PATH):
		assert_eq(title.position.y, 10.0, "pixel font fallback")
		return
	assert_eq(title.get_theme_font("font").resource_path, InkFont.PATH)
	assert_eq(title.get_theme_font_size("font_size"), 24)
	assert_eq(title.position.y, 2.0)


func test_every_label_switches_to_the_ink_font_when_present() -> void:
	var label := Label.new()
	label.add_theme_font_size_override("font_size", 8)
	label.position = Vector2(0, 100)
	add_child_autofree(label)
	if not ResourceLoader.exists(InkFont.PATH):
		assert_false(label.has_theme_font_override("font"), "pixel font fallback")
		assert_eq(label.position.y, 100.0)
		return
	assert_eq(label.get_theme_font("font").resource_path, InkFont.PATH)
	assert_eq(label.get_theme_font_size("font_size"), 10)
	assert_true(label.uppercase, "capitals only")
	assert_eq(label.position.y, 99.0, "moved up half the extra height")


func test_a_label_with_digits_or_signs_keeps_the_pixel_font() -> void:
	for text in ["P1", "0%", "?", "MOVE: WASD"]:
		var label := Label.new()
		label.text = text
		add_child_autofree(label)
		assert_false(label.has_theme_font_override("font"), text)


func test_the_ink_font_draws_only_letters_and_plain_punctuation() -> void:
	assert_true(InkFont.can_draw("Frederiksborg Castle Sunset"))
	assert_true(InkFont.can_draw("Hi, there."))
	assert_true(InkFont.can_draw(""))
	for text in ["P1", "50%", "???", "J/SPACE", "Café", "Mørk", "FIGHT!"]:
		assert_false(InkFont.can_draw(text), text)


func test_a_vertically_centred_label_keeps_its_place() -> void:
	var label := Label.new()
	label.add_theme_font_size_override("font_size", 16)
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.position = Vector2(0, 100)
	add_child_autofree(label)
	if not ResourceLoader.exists(InkFont.PATH):
		return
	assert_eq(label.get_theme_font_size("font_size"), 20)
	assert_eq(label.position.y, 100.0)


func test_every_portrait_is_221_by_279() -> void:
	for character in Game.roster().characters:
		assert_eq(character.portrait.get_size(), Vector2(221, 279), character.id)


func test_portraits_are_imported_with_mipmaps() -> void:
	for character in Game.roster().characters:
		assert_true(character.portrait.get_image().has_mipmaps(), character.id)
