class_name SelectTile
extends Button
## One tile on a select screen (docs/specs/menus.md): a picture on a square, with a 2 px border
## in the P1 color while highlighted (focused). A locked tile can be highlighted but not chosen.

const HIGHLIGHT := Color("#b13e53")
const SQUARE := Color("#333c57")
const BORDER := 2

## True for a slot that can't be chosen yet.
var locked: bool = false
## The stage this tile stands for (stage select only).
var stage_id: String = ""

var _picture := TextureRect.new()
var _border := Panel.new()


## Makes left/right wrap around in each row of `tiles` (laid out `columns` per row): left from a
## row's first tile goes to its last, right from its last to its first. The focus neighbor
## properties override the direction Godot would pick from the tiles' positions.
static func wrap_rows(tiles: Array[SelectTile], columns: int) -> void:
	for row_start in range(0, tiles.size(), columns):
		var first := tiles[row_start]
		var last := tiles[mini(row_start + columns, tiles.size()) - 1]
		first.focus_neighbor_left = first.get_path_to(last)
		last.focus_neighbor_right = last.get_path_to(first)


## Makes a `size` tile showing `picture` (stretched to fill, inside the border). Its layers, back to
## front: the square, the picture, the highlight border (only while focused).
func setup(tile_size: Vector2, picture: Texture2D,
		filter := CanvasItem.TEXTURE_FILTER_NEAREST) -> void:
	custom_minimum_size = tile_size
	size = tile_size
	focus_mode = Control.FOCUS_ALL
	# The button draws nothing itself; its children are the look.
	for state in ["normal", "hover", "pressed", "disabled", "hover_pressed", "focus"]:
		add_theme_stylebox_override(state, StyleBoxEmpty.new())
	var square := ColorRect.new()
	square.color = SQUARE
	square.size = tile_size
	_picture.texture = picture
	_picture.texture_filter = filter
	_picture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_picture.stretch_mode = TextureRect.STRETCH_SCALE
	_picture.position = Vector2(BORDER, BORDER)
	_picture.size = tile_size - Vector2(BORDER, BORDER) * 2
	var frame := StyleBoxFlat.new()
	frame.draw_center = false
	frame.border_color = HIGHLIGHT
	frame.set_border_width_all(BORDER)
	_border.add_theme_stylebox_override("panel", frame)
	_border.size = tile_size
	_border.visible = false
	for layer: Control in [square, _picture, _border]:
		layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(layer)
	focus_entered.connect(func() -> void: _border.visible = true)
	focus_exited.connect(func() -> void: _border.visible = false)


func get_picture() -> Texture2D:
	return _picture.texture


func get_picture_size() -> Vector2:
	return _picture.size


func get_picture_filter() -> CanvasItem.TextureFilter:
	return _picture.texture_filter


func is_highlighted() -> bool:
	return _border.visible
