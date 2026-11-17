extends GutTest
## The pause menu (docs/specs/match-and-stage.md#pause): Esc pauses the match and shows CONTINUE,
## RESTART and QUIT; CONTINUE (or Esc again) unpauses, RESTART starts the same match over, QUIT goes
## back to the character select.
## Every test unpauses in after_each: a paused tree would also stop the test runner.

const MATCH_SCENE := preload("res://match/match.tscn")
## The tests save here, never over the player's own settings.
const TEST_SETTINGS := "user://test_settings.cfg"

var _match: Match
var _menu: PauseMenu


func before_each() -> void:
	Game.settings_path = TEST_SETTINGS
	Game.music_muted = false
	Game.sfx_muted = false
	Game.change_scenes = false
	Game.requested_scene = ""
	_match = MATCH_SCENE.instantiate()
	_match.auto_step = false
	add_child_autofree(_match)
	_menu = _match.get_node("PauseMenu") as PauseMenu


func after_each() -> void:
	get_tree().paused = false
	Game.change_scenes = true
	Game.music_muted = false
	Game.sfx_muted = false
	DirAccess.remove_absolute(TEST_SETTINGS)
	Game.settings_path = Game.SETTINGS_PATH


func _press(action: String) -> void:
	var event := InputEventAction.new()
	event.action = action
	event.pressed = true
	_menu._unhandled_input(event)


# --- Opening and closing --------------------------------------------------------------------------


func test_closed_when_the_match_starts() -> void:
	assert_false(_menu.is_open())
	assert_false(_menu.visible)
	assert_false(get_tree().paused)


func test_it_runs_while_paused_and_the_match_doesnt() -> void:
	assert_eq(_menu.process_mode, Node.PROCESS_MODE_ALWAYS)
	get_tree().paused = true
	assert_false(_match.can_process(), "the Match stops ticking")
	assert_true(_menu.can_process(), "the menu still hears keys")


func test_esc_pauses_and_shows_the_menu() -> void:
	_press("pause")
	assert_true(_menu.is_open())
	assert_true(_menu.visible)
	assert_true(get_tree().paused)
	assert_eq(_menu.selected, 0, "CONTINUE is highlighted")


func test_esc_again_continues() -> void:
	_press("pause")
	_press("pause")
	assert_false(_menu.is_open())
	assert_false(_menu.visible)
	assert_false(get_tree().paused)


func test_cancel_continues() -> void:
	_press("pause")
	_press("ui_cancel")
	assert_false(get_tree().paused)


func test_the_choices() -> void:
	var labels := _menu.get_choice_labels()
	assert_eq(labels.size(), 3)
	assert_eq(labels[0].text, "CONTINUE")
	assert_eq(labels[1].text, "RESTART")
	assert_eq(labels[2].text, "QUIT")


# --- Choosing --------------------------------------------


func test_continue_unpauses() -> void:
	_press("pause")
	_press("ui_accept")
	assert_false(_menu.is_open())
	assert_false(get_tree().paused)
	assert_eq(Game.requested_scene, "", "stays in the match")
	assert_eq(Game.last_sfx, "menu_confirm")


func test_restart_starts_the_same_match_over() -> void:
	Game.character_id = "slot_03"
	Game.stage_id = "fc"
	_press("pause")
	_press("ui_down")
	assert_eq(_menu.selected, 1)
	assert_eq(Game.last_sfx, "menu_move")
	_press("ui_accept")
	assert_false(_menu.is_open())
	assert_false(get_tree().paused, "unpaused, so the new match runs")
	assert_eq(Game.requested_scene, Game.MATCH_PATH, "the match scene, loaded again")
	assert_eq(Game.character_id, "slot_03", "same character")
	assert_eq(Game.stage_id, "fc", "same stage")
	assert_eq(Game.last_sfx, "menu_confirm")
	Game.character_id = Game.DEFAULT_CHARACTER
	Game.stage_id = ""


func test_quit_goes_back_to_the_character_select() -> void:
	_press("pause")
	_press("ui_down")
	_press("ui_down")
	assert_eq(_menu.selected, 2)
	_press("ui_accept")
	assert_false(get_tree().paused, "unpaused, so the next screen runs")
	assert_eq(Game.requested_scene, Game.CHARACTER_SELECT_PATH)


func test_the_highlight_doesnt_wrap() -> void:
	_press("pause")
	_press("ui_up")
	assert_eq(_menu.selected, 0)
	for i in 4:
		_press("ui_down")
	assert_eq(_menu.selected, 2)


func test_opening_again_starts_on_continue() -> void:
	_press("pause")
	_press("ui_down")
	_press("pause")
	_press("pause")
	assert_eq(_menu.selected, 0)


func test_menu_keys_do_nothing_while_closed() -> void:
	_press("ui_accept")
	_press("ui_down")
	assert_false(_menu.is_open())
	assert_eq(Game.requested_scene, "")


func test_menu_sounds_play_while_paused() -> void:
	assert_eq(Game.sfx_player("menu_move").process_mode, Node.PROCESS_MODE_ALWAYS)
	assert_eq(Game.sfx_player("menu_confirm").process_mode, Node.PROCESS_MODE_ALWAYS)


# --- Mute -----------------------------------------------------------------------------------------


func _bus_muted(bus: String) -> bool:
	return AudioServer.is_bus_mute(AudioServer.get_bus_index(bus))


func test_mute_buttons_are_small_mouse_buttons() -> void:
	for button: Button in [_menu.music_button(), _menu.sfx_button()]:
		assert_eq(button.focus_mode, Control.FOCUS_NONE, "no keyboard focus: keys stay on the list")
		assert_eq(button.mouse_filter, Control.MOUSE_FILTER_STOP, "clickable")
		assert_lt(button.size.y, 20.0, "small")
	assert_eq(_menu.music_button().text, "", "icons only")
	assert_eq(_menu.music_button().icon, load("res://assets/ui/icon_music.png"))
	assert_eq(_menu.sfx_button().icon, load("res://assets/ui/icon_sfx.png"))
	assert_eq(_menu.music_button().tooltip_text, "Music")
	assert_eq(_menu.sfx_button().tooltip_text, "Sound effects")
	for name in ["Dim", "Panel"]:
		assert_eq((_menu.get_node(name) as Control).mouse_filter, Control.MOUSE_FILTER_IGNORE,
			"%s lets clicks through to the buttons" % name)


func test_clicking_music_mutes_the_music_bus() -> void:
	_press("pause")
	_menu.music_button().pressed.emit()
	assert_true(Game.music_muted)
	assert_true(_bus_muted("Music"))
	assert_false(_bus_muted("SFX"), "sound effects untouched")
	assert_eq(_menu.music_button().icon, load("res://assets/ui/icon_music_off.png"))
	assert_true(_menu.is_open(), "the menu stays open")
	assert_true(get_tree().paused)
	_menu.music_button().pressed.emit()
	assert_false(_bus_muted("Music"), "on again")
	assert_eq(_menu.music_button().icon, load("res://assets/ui/icon_music.png"))


func test_clicking_sfx_mutes_the_sfx_bus() -> void:
	_press("pause")
	_menu.sfx_button().pressed.emit()
	assert_true(Game.sfx_muted)
	assert_true(_bus_muted("SFX"))
	assert_false(_bus_muted("Music"), "music untouched")
	assert_eq(_menu.sfx_button().icon, load("res://assets/ui/icon_sfx_off.png"))


func test_clicking_the_mute_buttons_makes_no_sound() -> void:
	_press("pause")
	Game.last_sfx = ""
	_menu.music_button().pressed.emit()
	_menu.sfx_button().pressed.emit()
	_menu.music_button().pressed.emit()
	_menu.sfx_button().pressed.emit()
	assert_eq(Game.last_sfx, "", "no menu sound on mute / unmute")


func test_buttons_show_the_saved_state_when_opened() -> void:
	Game.music_muted = true
	_press("pause")
	assert_eq(_menu.music_button().icon, load("res://assets/ui/icon_music_off.png"))
	assert_eq(_menu.sfx_button().icon, load("res://assets/ui/icon_sfx.png"))


func test_mute_is_saved_and_loaded() -> void:
	Game.music_muted = true
	Game.sfx_muted = true
	Game.save_settings()
	Game.music_muted = false
	Game.sfx_muted = false
	Game.load_settings()
	assert_true(Game.music_muted)
	assert_true(Game.sfx_muted)
	assert_true(_bus_muted("Music"))
	assert_true(_bus_muted("SFX"))


func test_clicking_saves_at_once() -> void:
	_press("pause")
	_menu.music_button().pressed.emit()
	var config := ConfigFile.new()
	assert_eq(config.load(TEST_SETTINGS), OK)
	assert_true(config.get_value("audio", "music_muted", false))
