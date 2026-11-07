extends Node
## The Game autoload (docs/specs/menus.md): always loaded, so it outlives scene changes. Keeps
## what was chosen in the menus, changes between the screens, and lets the game keys drive menus.

const CHARACTER_SELECT_PATH := "res://ui/character_select.tscn"
const STAGE_SELECT_PATH := "res://ui/stage_select.tscn"
const MATCH_PATH := "res://match/match.tscn"
const ROSTER_PATH := "res://fighter/characters/roster.tres"
const DEFAULT_CHARACTER := "default"
## Menu action ← the game actions whose keys and buttons it also accepts.
const MENU_KEYS := {
	"ui_left": ["move_left"], "ui_right": ["move_right"], "ui_up": ["up"], "ui_down": ["down"],
	"ui_accept": ["attack", "jump"], "ui_cancel": ["shield"],
}

## P1's character, by id.
var character_id: String = DEFAULT_CHARACTER
## The chosen stage's id; empty until one is chosen (the Match then uses the default).
var stage_id: String = ""
## Tests turn this off: go_to() then only records where it would go.
var change_scenes: bool = true
## The last scene go_to() was asked for.
var requested_scene: String = ""


func _ready() -> void:
	for menu_action: String in MENU_KEYS:
		for game_action: String in MENU_KEYS[menu_action]:
			for event in InputMap.action_get_events(game_action):
				InputMap.action_add_event(menu_action, event)


## True when the command line already says which stage to play: then the menus are skipped.
static func should_skip_menus(args: PackedStringArray) -> bool:
	for arg in args:
		if arg.begins_with("--stage="):
			return true
	return false


func roster() -> Roster:
	return load(ROSTER_PATH) as Roster


## The chosen character (the default one if the id is unknown).
func character() -> CharacterData:
	var chosen := roster().find(character_id)
	return chosen if chosen != null else roster().find(DEFAULT_CHARACTER)


## Switches to the scene at `path` (after this frame, so the current one finishes cleanly).
func go_to(path: String) -> void:
	requested_scene = path
	if change_scenes:
		get_tree().change_scene_to_file.call_deferred(path)
