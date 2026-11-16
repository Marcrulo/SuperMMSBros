extends Node
## The Game autoload (docs/specs/menus.md): always loaded, so it outlives scene changes. Keeps
## what was chosen in the menus, changes between the screens, and lets the game keys drive menus.

const CHARACTER_SELECT_PATH := "res://ui/character_select.tscn"
const STAGE_SELECT_PATH := "res://ui/stage_select.tscn"
const MATCH_PATH := "res://match/match.tscn"
const ROSTER_PATH := "res://fighter/roster.tres"
const DEFAULT_CHARACTER := CharacterData.DEFAULT_ID
## P2's character when the menus were skipped.
const DEFAULT_P2_CHARACTER := "slot_02"
## Seconds the audio engine gets to release the music before quitting.
const QUIT_DELAY := 0.1
## Menu sound effects (docs/specs/menus.md#sound): assets/sfx/<name>.wav.
const SFX_DIR := "res://assets/sfx/"
const SOUNDS: Array[String] = ["menu_move", "menu_confirm", "menu_back", "menu_locked"]
const MENU_TRACK := "menu"
## Where the mute choices are saved (docs/specs/match-and-stage.md#pause).
const SETTINGS_PATH := "user://settings.cfg"
## Menu action ← the game actions whose keys and buttons it also accepts.
const MENU_KEYS := {
	"ui_left": ["move_left"], "ui_right": ["move_right"], "ui_up": ["up"], "ui_down": ["down"],
	"ui_accept": ["attack", "jump"], "ui_cancel": ["shield"],
}

## P1's character, by id.
var character_id: String = DEFAULT_CHARACTER
## P2's character, by id: picked at random when P1 chooses (docs/specs/menus.md).
var p2_character_id: String = DEFAULT_P2_CHARACTER
## The chosen stage's id; empty until one is chosen (the Match then uses the default).
var stage_id: String = ""
## Tests turn this off: go_to() then only records where it would go.
var change_scenes: bool = true
## The last scene go_to() was asked for.
var requested_scene: String = ""
## The last sound effect played (for tests).
var last_sfx: String = ""
## Where save_settings()/load_settings() keep the mute choices (tests use their own file).
var settings_path: String = SETTINGS_PATH
## All music (the Music bus) or all sound effects (the SFX bus) muted.
var music_muted: bool = false:
	set(value):
		music_muted = value
		_mute_bus(&"Music", value)
var sfx_muted: bool = false:
	set(value):
		sfx_muted = value
		_mute_bus(&"SFX", value)

## Here, not in a screen, so the menu music carries on across screens and a sound effect finishes
## after its screen is gone.
var _menu_music := AudioStreamPlayer.new()
var _sfx: Dictionary[String, AudioStreamPlayer] = {}


## Here, not in _ready(): the first screen's labels enter the tree before this autoload is ready.
func _enter_tree() -> void:
	# Every label, in every scene, gets the ink font as it enters the tree.
	get_tree().node_added.connect(_on_node_added)
	for label in get_tree().root.find_children("*", "Label", true, false):
		InkFont.apply_to(label as Label)


func _ready() -> void:
	# Closing the window goes through quit() instead of stopping the engine at once.
	get_tree().auto_accept_quit = false
	_menu_music.bus = &"Music"
	add_child(_menu_music)
	for sound in SOUNDS:
		var player := AudioStreamPlayer.new()
		# Not every sound is in git; a missing one stays silent.
		var path := SFX_DIR + sound + ".wav"
		if ResourceLoader.exists(path):
			player.stream = load(path)
		player.bus = &"SFX"
		# The pause menu plays them while the game is paused.
		player.process_mode = Node.PROCESS_MODE_ALWAYS
		add_child(player)
		_sfx[sound] = player
	apply_character_option(OS.get_cmdline_user_args())
	load_settings()
	for menu_action: String in MENU_KEYS:
		for game_action: String in MENU_KEYS[menu_action]:
			for event in InputMap.action_get_events(game_action):
				InputMap.action_add_event(menu_action, event)


func _on_node_added(node: Node) -> void:
	if node is Label:
		InkFont.apply_to(node as Label)


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		quit()


## Quits cleanly: frees the current scene first and gives the audio engine a moment (real time, it
## runs on its own thread) to let go of the music, then stops the game. Quitting mid-track otherwise
## leaves the track "in use" at exit. Shutdown only, so not counted in ticks.
func quit() -> void:
	var tree := get_tree()
	stop_menu_music()
	for player: AudioStreamPlayer in _sfx.values():
		player.stop()
	if tree.current_scene != null:
		tree.current_scene.queue_free()
	await tree.create_timer(QUIT_DELAY).timeout
	tree.quit()


## True when the command line already says which stage to play: then the menus are skipped.
static func should_skip_menus(args: PackedStringArray) -> bool:
	for arg in args:
		if arg.begins_with("--stage="):
			return true
	return false


## `--char=<name>` (docs/specs/architecture.md#command-line-options): P1 plays that character.
func apply_character_option(args: PackedStringArray) -> void:
	var id := character_from_args(args)
	if id != "":
		character_id = id


## The id of the playable character `--char=` names (its first name in any case, or its id), or ""
## for none or an unknown name.
func character_from_args(args: PackedStringArray) -> String:
	for arg in args:
		if not arg.begins_with("--char="):
			continue
		var wanted := arg.trim_prefix("--char=").to_lower()
		for candidate in roster().characters:
			var first_name := candidate.display_name.get_slice(" ", 0).to_lower()
			if candidate.playable and (wanted == first_name or wanted == candidate.id):
				return candidate.id
		push_warning("--char=%s: no playable character by that name" % wanted)
	return ""


## Saves the mute choices.
func save_settings() -> void:
	var config := ConfigFile.new()
	config.set_value("audio", "music_muted", music_muted)
	config.set_value("audio", "sfx_muted", sfx_muted)
	config.save(settings_path)


## Loads the mute choices (both off when nothing was saved yet).
func load_settings() -> void:
	var config := ConfigFile.new()
	config.load(settings_path)
	music_muted = config.get_value("audio", "music_muted", false)
	sfx_muted = config.get_value("audio", "sfx_muted", false)


func _mute_bus(bus: StringName, muted: bool) -> void:
	var index := AudioServer.get_bus_index(bus)
	if index >= 0:
		AudioServer.set_bus_mute(index, muted)


func roster() -> Roster:
	return load(ROSTER_PATH) as Roster


## P1's character (the default one if the id is unknown or not playable).
func character() -> CharacterData:
	return _playable_or_default(character_id)


## P2's character (the default one if the id is unknown or not playable).
func p2_character() -> CharacterData:
	return _playable_or_default(p2_character_id)


func _playable_or_default(id: String) -> CharacterData:
	var chosen := roster().find(id)
	return chosen if chosen != null and chosen.playable else roster().find(DEFAULT_CHARACTER)


## Gives P2 a random playable character other than P1's. The menus' own random pick, not the
## Match's seeded RNG: it happens before the match starts.
func pick_p2_character() -> void:
	var others: Array[String] = []
	for candidate in roster().characters:
		if candidate.playable and candidate.id != character_id:
			others.append(candidate.id)
	p2_character_id = others.pick_random() if not others.is_empty() else character_id


## Plays a menu sound effect (one of SOUNDS), from the start.
func play_sfx(sound: String) -> void:
	last_sfx = sound
	if _sfx[sound].stream != null:
		_sfx[sound].play()


func sfx_player(sound: String) -> AudioStreamPlayer:
	return _sfx[sound]


## Starts the looping menu music, unless it's already playing (it carries on between screens).
func play_menu_music() -> void:
	if _menu_music.playing:
		return
	_menu_music.stream = MusicLibrary.load_looping(MENU_TRACK)
	if _menu_music.stream != null:
		_menu_music.play()


func stop_menu_music() -> void:
	_menu_music.stop()


func menu_music_player() -> AudioStreamPlayer:
	return _menu_music


## Switches to the scene at `path` (after this frame, so the current one finishes cleanly). The
## menu music stops when the match starts.
func go_to(path: String) -> void:
	requested_scene = path
	if path == MATCH_PATH:
		stop_menu_music()
	if change_scenes:
		get_tree().change_scene_to_file.call_deferred(path)
