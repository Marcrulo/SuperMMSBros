class_name PlayerCard
extends Panel
## One fighter's card in the HUD (docs/specs/match-and-stage.md#hud): portrait, name, stocks and
## damage %, framed in the player color. Only reads the fighter; never changes it.

const PERCENT_LOW := Color("#f4f4f4")
const PERCENT_HIGH := Color("#f0524f")
## The % at which the number is fully red.
const PERCENT_RED_AT := 150.0
## Where the head sits in the first idle drawing (art guide frame pixels), per frame size.
const HEAD_REGIONS := {48: Rect2(14, 16, 20, 20), 64: Rect2(23, 20, 20, 20)}
## How long (frames) and how far (px) the number jumps when the fighter is hit.
const BUMP_FRAMES := 6
const BUMP_HEIGHT := 2.0
## Where the first stock icon sits on the card, and the distance to the next.
const STOCKS_AT := Vector2(60, 4)
const STOCK_STEP := 10.0

var player_color: Color
var _fighter: Fighter
var _bump_frames_left: int = 0
var _stock_icons: Array[TextureRect] = []
## Gitte's stance sign, on the portrait's bottom-right corner (only for a fighter with stances).
var _stance_badge: StanceBadge

@onready var _portrait_box := $Portrait as Panel
@onready var _head := $Portrait/Head as TextureRect
@onready var _name := $Name as Label
@onready var _percent := $Percent as Label
@onready var _percent_y := _percent.position.y


## The damage % as shown: a whole number with a percent sign.
static func percent_text(percent: float) -> String:
	return "%d%%" % floori(percent)


## White at 0 %, turning red up to PERCENT_RED_AT and staying red after.
static func percent_color(percent: float) -> Color:
	return PERCENT_LOW.lerp(PERCENT_HIGH, clampf(percent / PERCENT_RED_AT, 0.0, 1.0))


## The head's square in a first idle drawing of this frame size (a bigger canvas holds the 64×64
## frame at its bottom center).
static func head_region(height: int, width: int = 0) -> Rect2:
	var base := 48 if height == 48 else 64
	var region: Rect2 = HEAD_REGIONS[base]
	region.position += Vector2(((width if width > 0 else height) - base) / 2, height - base)
	return region


## The head's square in a character's idle strip.
static func head_region_of(idle: Texture2D) -> Rect2:
	var drawings: int = FighterVisuals.ANIMATIONS["idle"].ticks.size()
	return head_region(FighterVisuals.frame_size(idle), FighterVisuals.frame_width(idle, drawings))


## Shows `fighter` under `player_name`, framed in `color`.
func setup(fighter: Fighter, player_name: String, color: Color) -> void:
	_fighter = fighter
	player_color = color
	_name.text = player_name
	_name.add_theme_color_override("font_color", color.lightened(0.45))
	var frame := (get_theme_stylebox("panel") as StyleBoxFlat).duplicate() as StyleBoxFlat
	frame.border_color = color
	add_theme_stylebox_override("panel", frame)
	var square := (_portrait_box.get_theme_stylebox("panel") as StyleBoxFlat).duplicate() as StyleBoxFlat
	square.bg_color = color.darkened(0.45)
	_portrait_box.add_theme_stylebox_override("panel", square)
	var head := AtlasTexture.new()
	head.atlas = FighterVisuals.textures_for(fighter.character_id)["idle"]
	head.region = head_region_of(head.atlas)
	_head.texture = head
	if _stance_badge != null:
		_stance_badge.queue_free()
		_stance_badge = null
	if fighter.stance_data() != null:
		_stance_badge = StanceBadge.new()
		_stance_badge.border = color
		_stance_badge.position = _portrait_box.position + _portrait_box.size \
				- Vector2(StanceBadge.SIZE, StanceBadge.SIZE) + Vector2(2, 2)
		add_child(_stance_badge)
	for icon in _stock_icons:
		icon.queue_free()
	_stock_icons.clear()
	for i in Match.STOCKS:
		var icon := TextureRect.new()
		icon.texture = FighterVisuals.textures_for(fighter.character_id)["stock_icon"]
		icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		icon.position = STOCKS_AT + Vector2(STOCK_STEP * i, 0)
		add_child(icon)
		_stock_icons.append(icon)
	refresh()


## Reads the fighter's % and stocks into the card.
func refresh() -> void:
	for i in _stock_icons.size():
		_stock_icons[i].visible = i < _fighter.stocks
	_percent.text = percent_text(_fighter.percent)
	_percent.add_theme_color_override("font_color", percent_color(_fighter.percent))
	_percent.position.y = _percent_y + bump_offset()
	if _stance_badge != null and _stance_badge.stance != _fighter.stance:
		_stance_badge.stance = _fighter.stance


## Makes the number jump (the fighter was just hit).
func bump() -> void:
	_bump_frames_left = BUMP_FRAMES


func advance_bump() -> void:
	_bump_frames_left = maxi(_bump_frames_left - 1, 0)


## How far the number is lifted right now.
func bump_offset() -> float:
	return -BUMP_HEIGHT if _bump_frames_left > 0 else 0.0


func has_stance_badge() -> bool:
	return _stance_badge != null


## The stance the badge shows.
func get_shown_stance() -> Fighter.Stance:
	return _stance_badge.stance


func get_name_text() -> String:
	return _name.text


func get_percent_text() -> String:
	return _percent.text


## How many stock icons are showing.
func get_stock_count() -> int:
	return _stock_icons.filter(func(icon: TextureRect) -> bool: return icon.visible).size()


func get_stock_icon() -> Texture2D:
	return _stock_icons[0].texture


func get_portrait() -> AtlasTexture:
	return _head.texture as AtlasTexture


func _process(_delta: float) -> void:
	if _fighter == null:
		return
	advance_bump()
	refresh()
