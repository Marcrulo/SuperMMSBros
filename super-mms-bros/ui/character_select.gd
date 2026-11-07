class_name CharacterSelect
extends Control
## Pick your fighter (docs/specs/menus.md#character-select): a 5×2 grid of the roster's slots,
## the first one playable, the rest locked silhouettes.

const TILE := Vector2(64, 64)
const GAP := 8.0
const SILHOUETTE := Color("#29366f")
const QUESTION := Color("#94b0c2")

var _tiles: Array[SelectTile] = []

@onready var _grid := $Grid as GridContainer
@onready var _name := $Name as Label
@onready var _tag := $Tag as Label


## The head the player cards use, cut from the idle drawing.
static func portrait() -> AtlasTexture:
	var head := AtlasTexture.new()
	head.atlas = FighterVisuals.textures_for(0)["idle"]
	head.region = PlayerCard.HEAD_REGION
	return head


## `texture` as a flat shape in `color` (every visible pixel painted the same).
static func silhouette(texture: Texture2D, color: Color) -> Texture2D:
	var image := texture.get_image()
	image.decompress()
	for y in image.get_height():
		for x in image.get_width():
			if image.get_pixel(x, y).a > 0.0:
				image.set_pixel(x, y, color)
	return ImageTexture.create_from_image(image)


func _ready() -> void:
	if Game.should_skip_menus(OS.get_cmdline_user_args()):
		Game.go_to(Game.MATCH_PATH)
		return
	var roster := Game.roster()
	var head := portrait()
	var locked_head := silhouette(head, SILHOUETTE)
	var start := 0
	for i in roster.slots:
		var character := roster.character_in_slot(i)
		var tile := SelectTile.new()
		tile.locked = character == null
		tile.setup(TILE, locked_head if tile.locked else head)
		if tile.locked:
			tile.add_child(_question_mark())
		elif character.id == Game.character_id:
			start = i
		tile.focus_entered.connect(_on_tile_focused.bind(i))
		tile.pressed.connect(choose.bind(i))
		_grid.add_child(tile)
		_tiles.append(tile)
	_tiles[start].grab_focus()


func get_tiles() -> Array[SelectTile]:
	return _tiles


func get_name_text() -> String:
	return _name.text


## Picks slot `index`: an unlocked character goes on to the stage select; a locked slot does nothing.
func choose(index: int) -> void:
	var character := Game.roster().character_in_slot(index)
	if character == null:
		return
	Game.character_id = character.id
	Game.go_to(Game.STAGE_SELECT_PATH)


func _on_tile_focused(index: int) -> void:
	var character := Game.roster().character_in_slot(index)
	_name.text = character.display_name if character != null else "???"
	_tag.position = tag_position(index)


## Where the "P1" tag goes for slot `index`: just above that tile's top-left corner. Worked out from
## the grid, because the grid places its tiles only after this frame.
func tag_position(index: int) -> Vector2:
	var step := TILE + Vector2(GAP, GAP)
	var cell := Vector2(index % _grid.columns, floori(float(index) / _grid.columns))
	return _grid.position + cell * step + Vector2(0, -9)


func _question_mark() -> Label:
	var label := Label.new()
	label.text = "?"
	label.add_theme_font_size_override("font_size", 16)
	label.add_theme_color_override("font_color", QUESTION)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.size = TILE
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return label
