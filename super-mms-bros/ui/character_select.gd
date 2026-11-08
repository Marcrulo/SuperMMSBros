class_name CharacterSelect
extends Control
## Pick your fighter (docs/specs/menus.md#character-select): a 5×3 grid of the roster's slots.
## Each tile shows the character's portrait (or the fighter's head); locked ones can't be chosen.

const TILE := Vector2(56, 56)
const GAP := 6.0
const SILHOUETTE := Color("#29366f")
## On: every portrait tile shows a silhouette of the face instead (for unlocking characters later).
const SILHOUETTE_PORTRAITS := false
## The name shown for an empty slot (only letters and spaces: the brush font has no "?").
const EMPTY_NAME := "Coming soon"
## Where the title's top goes in the brush font.
const TITLE_TOP := 4.0
## A tile shows a square of the portrait as wide as it, this far down (as a share of the width).
const PORTRAIT_TOP := 6.0 / 221.0
## How close (RGB distance, 0–255 per channel) a portrait pixel must be to the background color to
## count as background when making its silhouette.
const BACKGROUND_DISTANCE := 40
## The corner square averaged for a portrait's background color.
const BACKGROUND_SAMPLE := 8

## Silhouettes already made, by portrait: each is made once.
static var _silhouettes := {}

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
	InkFont.apply_title($Title as Label, TITLE_TOP)
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


## The tile for `character` (null = an empty slot): its portrait's face (or its silhouette, with
## SILHOUETTE_PORTRAITS on), else the fighter's head; a locked one without a portrait is the head's
## silhouette.
static func make_tile(character: CharacterData) -> SelectTile:
	var tile := SelectTile.new()
	tile.locked = character == null or not character.playable
	if character != null and character.portrait != null:
		var face: Texture2D
		if SILHOUETTE_PORTRAITS:
			face = portrait_silhouette(character.portrait)
		else:
			var cut := AtlasTexture.new()
			cut.atlas = character.portrait
			cut.region = portrait_region(character.portrait)
			face = cut
		# Shrunk (221 px into 52 game px = 156 screen px in the default window): smooth it, with
		# mipmaps (pre-shrunk copies, an import setting for the portraits) for clean shrinking.
		tile.setup(TILE, face, CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS)
	elif tile.locked:
		tile.setup(TILE, silhouette(portrait(), SILHOUETTE))
	else:
		tile.setup(TILE, portrait())
	return tile


## The square of `portrait` a tile shows: as wide as the portrait, from near its top (the face).
static func portrait_region(portrait: Texture2D) -> Rect2:
	var width := portrait.get_width()
	return Rect2(0, roundi(width * PORTRAIT_TOP), width, width)


## The face square of `portrait` as a flat `SILHOUETTE` shape on a see-through background. The
## background is whatever a flood fill reaches from the top, left and right edges through pixels
## near the corner's color (the person touches the bottom edge, so the fill never starts there);
## a 3×3 majority pass then smooths away specks and thin leaks.
static func portrait_silhouette(portrait: Texture2D) -> ImageTexture:
	if _silhouettes.has(portrait):
		return _silhouettes[portrait]
	# A copy: the texture may hand out its own image, which must stay as it is.
	var image := portrait.get_image().duplicate() as Image
	image.decompress()
	image.clear_mipmaps()
	image.convert(Image.FORMAT_RGB8)
	image = image.get_region(Rect2i(portrait_region(portrait)))
	var side := image.get_width()
	var data := image.get_data()
	var count := side * side

	# The background color: the average of the top-left corner.
	var background := Vector3.ZERO
	for y in BACKGROUND_SAMPLE:
		for x in BACKGROUND_SAMPLE:
			var i := (y * side + x) * 3
			background += Vector3(data[i], data[i + 1], data[i + 2])
	background /= BACKGROUND_SAMPLE * BACKGROUND_SAMPLE

	# Flood fill (with a stack of pixel indexes) from the top row and the side columns.
	var near := PackedByteArray()
	near.resize(count)
	for p in count:
		var color := Vector3(data[p * 3], data[p * 3 + 1], data[p * 3 + 2])
		near[p] = 1 if color.distance_to(background) < BACKGROUND_DISTANCE else 0
	var filled := PackedByteArray()
	filled.resize(count)
	var stack := PackedInt32Array()
	for x in side:
		stack.append(x)
	for y in side:
		stack.append(y * side)
		stack.append(y * side + side - 1)
	while not stack.is_empty():
		var p := stack[stack.size() - 1]
		stack.remove_at(stack.size() - 1)
		if filled[p] == 1 or near[p] == 0:
			continue
		filled[p] = 1
		var x := p % side
		if x > 0:
			stack.append(p - 1)
		if x < side - 1:
			stack.append(p + 1)
		if p >= side:
			stack.append(p - side)
		if p < count - side:
			stack.append(p + side)

	# Majority of each 3×3 block (edges repeat outward): rows summed, then columns.
	var rows := PackedByteArray()
	rows.resize(count)
	for y in side:
		for x in side:
			var p := y * side + x
			rows[p] = filled[p] + filled[p - 1 if x > 0 else p] + filled[p + 1 if x < side - 1 else p]
	var pixels := PackedByteArray()
	pixels.resize(count * 4)
	var r := roundi(SILHOUETTE.r * 255)
	var g := roundi(SILHOUETTE.g * 255)
	var b := roundi(SILHOUETTE.b * 255)
	for y in side:
		for x in side:
			var p := y * side + x
			var sum: int = rows[p] + rows[p - side if y > 0 else p] \
					+ rows[p + side if y < side - 1 else p]
			if sum < 5:  # mostly person
				pixels[p * 4] = r
				pixels[p * 4 + 1] = g
				pixels[p * 4 + 2] = b
				pixels[p * 4 + 3] = 255
	var shape := Image.create_from_data(side, side, false, Image.FORMAT_RGBA8, pixels)
	shape.generate_mipmaps()
	var texture := ImageTexture.create_from_image(shape)
	_silhouettes[portrait] = texture
	return texture


## The name shown for `character` (null = an empty slot).
static func name_for(character: CharacterData) -> String:
	return character.display_name if character != null else EMPTY_NAME


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
	_name.text = name_for(character)
	_tag.position = tag_position(index)


## Where the "P1" tag goes for slot `index`: just above that tile's top-left corner. Worked out from
## the grid, because the grid places its tiles only after this frame.
func tag_position(index: int) -> Vector2:
	var step := TILE + Vector2(GAP, GAP)
	var cell := Vector2(index % _grid.columns, floori(float(index) / _grid.columns))
	return _grid.position + cell * step + Vector2(0, -9)

