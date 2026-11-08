class_name CharacterSelect
extends Control
## Pick your fighter (docs/specs/menus.md#character-select): a 5×2 grid of the roster's slots.
## Each tile shows the character's portrait (or the fighter's head); locked ones can't be chosen.

const TILE := Vector2(74, 74)
const GAP := 8.0
const SILHOUETTE := Color("#29366f")
const QUESTION := Color("#94b0c2")
## Where the title's top goes in the brush font.
const TITLE_TOP := 4.0
## A tile shows a square of the portrait as wide as it, this far down (as a share of the width).
const PORTRAIT_TOP := 6.0 / 221.0

var _tiles: Array[SelectTile] = []
## Off until the screen has opened, so the first highlight makes no sound.
var _sounds_on := false

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
	Game.play_menu_music()
	TitleFont.apply($Title as Label, TITLE_TOP)
	var roster := Game.roster()
	var start := 0
	for i in roster.slots:
		var character := roster.character_in_slot(i)
		var tile := make_tile(character)
		if not tile.locked and character.id == Game.character_id:
			start = i
		tile.focus_entered.connect(_on_tile_focused.bind(i))
		tile.pressed.connect(choose.bind(i))
		_grid.add_child(tile)
		_tiles.append(tile)
	SelectTile.wrap_rows(_tiles, _grid.columns)
	_tiles[start].grab_focus()
	_sounds_on = true


## The tile for `character` (null = an empty slot): its portrait cut to a square, else the
## fighter's head; a locked one without a portrait is a silhouette with a "?".
static func make_tile(character: CharacterData) -> SelectTile:
	var tile := SelectTile.new()
	tile.locked = character == null or not character.playable
	if character != null and character.portrait != null:
		var face := AtlasTexture.new()
		face.atlas = character.portrait
		face.region = portrait_region(character.portrait)
		# Detailed art drawn near its native size (221 px into 70 game px = 210 screen px in the
		# default window): smooth it, with the portraits' mipmaps (pre-shrunk copies, an import
		# setting) for smaller windows.
		tile.setup(TILE, face, CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS)
	elif tile.locked:
		tile.setup(TILE, silhouette(portrait(), SILHOUETTE))
		tile.add_child(_question_mark())
	else:
		tile.setup(TILE, portrait())
	return tile


## The square of `portrait` a tile shows: as wide as the portrait, from near its top (the face).
static func portrait_region(portrait: Texture2D) -> Rect2:
	var width := portrait.get_width()
	return Rect2(0, roundi(width * PORTRAIT_TOP), width, width)


func get_tiles() -> Array[SelectTile]:
	return _tiles


func get_name_text() -> String:
	return _name.text


## Picks slot `index`: an unlocked character goes on to the stage select; a locked slot does nothing.
func choose(index: int) -> void:
	var roster := Game.roster()
	if roster.is_locked(index):
		Game.play_sfx("menu_locked")
		return
	var character := roster.character_in_slot(index)
	Game.play_sfx("menu_confirm")
	Game.character_id = character.id
	Game.go_to(Game.STAGE_SELECT_PATH)


func _on_tile_focused(index: int) -> void:
	if _sounds_on:
		Game.play_sfx("menu_move")
	var character := Game.roster().character_in_slot(index)
	_name.text = character.display_name if character != null else "???"
	_tag.position = tag_position(index)


## Where the "P1" tag goes for slot `index`: just above that tile's top-left corner. Worked out from
## the grid, because the grid places its tiles only after this frame.
func tag_position(index: int) -> Vector2:
	var step := TILE + Vector2(GAP, GAP)
	var cell := Vector2(index % _grid.columns, floori(float(index) / _grid.columns))
	return _grid.position + cell * step + Vector2(0, -9)


static func _question_mark() -> Label:
	var label := Label.new()
	label.name = "QuestionMark"
	label.text = "?"
	label.add_theme_font_size_override("font_size", 16)
	label.add_theme_color_override("font_color", QUESTION)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.size = TILE
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return label
