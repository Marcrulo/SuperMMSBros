extends GutTest
## Audio buses, menu music and menu sound effects (docs/specs/menus.md#sound,
## docs/specs/controls-and-display.md#audio).

const CHARACTER_SELECT := preload("res://ui/character_select.tscn")
const STAGE_SELECT := preload("res://ui/stage_select.tscn")
const MATCH_SCENE := preload("res://match/match.tscn")


func before_each() -> void:
	Game.change_scenes = false
	Game.requested_scene = ""
	Game.last_sfx = ""
	Game.character_id = Game.DEFAULT_CHARACTER
	Game.stage_id = ""


func after_each() -> void:
	Game.change_scenes = true
	Game.stage_id = ""
	Game.stop_menu_music()


func test_music_and_sfx_buses() -> void:
	assert_ne(AudioServer.get_bus_index("Music"), -1)
	assert_ne(AudioServer.get_bus_index("SFX"), -1)
	assert_eq(AudioServer.get_bus_send(AudioServer.get_bus_index("SFX")), &"Master")


func test_every_menu_sound_exists() -> void:
	for sound in Game.SOUNDS:
		var path := Game.SFX_DIR + sound + ".wav"
		if not ResourceLoader.exists(path):
			pending("%s isn't on this machine (not every sound is in git)" % sound)
			continue
		assert_not_null(load(path) as AudioStream, sound)


func test_the_committed_sounds_are_there() -> void:
	for sound in ["menu_move", "menu_back", "menu_locked"]:
		assert_true(ResourceLoader.exists(Game.SFX_DIR + sound + ".wav"), sound)


func test_a_missing_sound_is_silent() -> void:
	var player := Game.sfx_player("menu_confirm")
	var stream := player.stream
	player.stream = null
	Game.play_sfx("menu_confirm")
	assert_eq(Game.last_sfx, "menu_confirm")
	assert_false(player.playing)
	player.stream = stream


func test_sound_players_use_the_sfx_bus() -> void:
	assert_eq(Game.sfx_player("menu_move").bus, &"SFX")
	assert_eq(Game.menu_music_player().bus, &"Music")


func test_stage_music_uses_the_music_bus() -> void:
	var match_node: Match = add_child_autofree(MATCH_SCENE.instantiate())
	assert_eq((match_node.get_node("Music") as AudioStreamPlayer).bus, &"Music")


func test_menu_music_plays_on_the_select_screens_and_stops_for_the_match() -> void:
	if not ResourceLoader.exists(MusicLibrary.path("menu")):
		pending("no menu track on this machine")
		return
	add_child_autofree(CHARACTER_SELECT.instantiate())
	assert_true(Game.menu_music_player().playing, "plays on the character select")
	var position := Game.menu_music_player().get_playback_position()
	add_child_autofree(STAGE_SELECT.instantiate())
	assert_true(Game.menu_music_player().playing, "still playing on the stage select")
	assert_gte(Game.menu_music_player().get_playback_position(), position, "didn't restart")
	Game.go_to(Game.MATCH_PATH)
	assert_false(Game.menu_music_player().playing, "stops when the match starts")


func test_menu_music_loops() -> void:
	if not ResourceLoader.exists(MusicLibrary.path("menu")):
		pending("no menu track on this machine")
		return
	assert_true((MusicLibrary.load_looping("menu") as AudioStreamOggVorbis).loop)


func test_opening_a_screen_is_silent() -> void:
	add_child_autofree(CHARACTER_SELECT.instantiate())
	await wait_process_frames(1)
	assert_eq(Game.last_sfx, "", "the first highlight makes no sound")


func test_moving_the_highlight_ticks() -> void:
	var screen: CharacterSelect = add_child_autofree(CHARACTER_SELECT.instantiate())
	await wait_process_frames(1)
	screen.get_tiles()[1].grab_focus()
	assert_eq(Game.last_sfx, "menu_move")


func test_choosing_sounds() -> void:
	var characters: CharacterSelect = add_child_autofree(CHARACTER_SELECT.instantiate())
	await wait_process_frames(1)
	characters.choose(14)
	assert_eq(Game.last_sfx, "menu_locked", "the empty slot buzzes")
	characters.choose(0)
	assert_eq(Game.last_sfx, "menu_confirm", "locking in a character")
	var stages: StageSelect = add_child_autofree(STAGE_SELECT.instantiate())
	await wait_process_frames(1)
	stages.get_tiles()[1].grab_focus()
	assert_eq(Game.last_sfx, "menu_move")
	stages.back()
	assert_eq(Game.last_sfx, "menu_back")
	stages.choose(0)
	assert_eq(Game.last_sfx, "menu_confirm", "locking in a stage")
