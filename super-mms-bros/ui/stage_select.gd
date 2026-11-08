class_name StageSelect
extends Control
## Pick a stage (docs/specs/menus.md#stage-select): a big preview of the highlighted stage and a row
## of thumbnails. Back returns to the character select.

const THUMBNAIL := Vector2(80, 45)
## Where the title's top goes in the brush font (its letters then end just above the preview).
const TITLE_TOP := 2.0

var _tiles: Array[SelectTile] = []
## Off until the screen has opened, so the first highlight makes no sound.
var _sounds_on := false

@onready var _row := $Thumbnails as HBoxContainer
@onready var _preview := $Preview/Picture as TextureRect
@onready var _name := $Name as Label


func _ready() -> void:
	Game.play_menu_music()
	InkFont.apply_title($Title as Label, TITLE_TOP)
	var start := 0
	for i in StageData.ALL_IDS.size():
		var stage := StageData.load_stage(StageData.ALL_IDS[i])
		var tile := SelectTile.new()
		tile.stage_id = stage.id
		tile.setup(THUMBNAIL, stage.background)
		if stage.id == Game.stage_id:
			start = i
		tile.focus_entered.connect(_on_tile_focused.bind(i))
		tile.pressed.connect(choose.bind(i))
		_row.add_child(tile)
		_tiles.append(tile)
	SelectTile.wrap_rows(_tiles, _tiles.size())
	_tiles[start].grab_focus()
	_sounds_on = true


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		back()


func get_tiles() -> Array[SelectTile]:
	return _tiles


func get_preview_texture() -> Texture2D:
	return _preview.texture


func get_name_text() -> String:
	return _name.text


## Plays stage number `index` (in StageData.ALL_IDS order).
func choose(index: int) -> void:
	Game.play_sfx("menu_confirm")
	Game.stage_id = StageData.ALL_IDS[index]
	Game.go_to(Game.MATCH_PATH)


func back() -> void:
	Game.play_sfx("menu_back")
	Game.go_to(Game.CHARACTER_SELECT_PATH)


func _on_tile_focused(index: int) -> void:
	if _sounds_on:
		Game.play_sfx("menu_move")
	var stage := StageData.load_stage(StageData.ALL_IDS[index])
	_preview.texture = stage.background
	_name.text = stage.display_name
