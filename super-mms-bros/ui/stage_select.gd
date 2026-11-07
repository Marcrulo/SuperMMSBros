class_name StageSelect
extends Control
## Pick a stage (docs/specs/menus.md#stage-select): a big preview of the highlighted stage and a row
## of thumbnails. Back returns to the character select.

const THUMBNAIL := Vector2(96, 54)

var _tiles: Array[SelectTile] = []

@onready var _row := $Thumbnails as HBoxContainer
@onready var _preview := $Preview/Picture as TextureRect
@onready var _name := $Name as Label


func _ready() -> void:
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
	_tiles[start].grab_focus()


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
	Game.stage_id = StageData.ALL_IDS[index]
	Game.go_to(Game.MATCH_PATH)


func back() -> void:
	Game.go_to(Game.CHARACTER_SELECT_PATH)


func _on_tile_focused(index: int) -> void:
	var stage := StageData.load_stage(StageData.ALL_IDS[index])
	_preview.texture = stage.background
	_name.text = stage.display_name
