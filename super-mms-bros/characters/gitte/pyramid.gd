class_name Pyramid
extends MatchEntity
## Gitte's pyramid (docs/specs/characters/gitte.md#gitte--scissors-and-stances): rises out of the floor while
## she rides its tip, then sinks back into it and is gone. It isn't solid and has no hitbox of its
## own (the tip's hit is her move's). Owned and advanced by the Match; drawing only reads.

const SINK_SHAKE_TICKS := 2
## Its drawing (docs/specs/characters/gitte.md#gittes-pyramid), drawn at the fighters' 3/4 scale.
const DRAWING := Vector2(168, 128)
const SCALE := 0.75

var data: PyramidData
## The top of the floor it rises out of (its position is (owner's x, floor_y)).
var floor_y: float
## True once its owner's ride has ended (the pop, a hit, a KO): it's sinking.
var sinking := false
## Set once it has sunk: the Match removes it.
var finished := false

## Ticks it has risen, and ticks it has been sinking.
var _rise_age: int = 0
var _sink_age: int = 0
## Its picture: assets/fighters/<owner's character id>/pyramid.png.
var _texture: Texture2D


func setup(owner: int, at: Vector2, pyramid_data: PyramidData, character_id: String) -> void:
	owner_index = owner
	global_position = at
	floor_y = at.y
	data = pyramid_data
	var path := FighterVisuals.SPRITES_DIR + character_id + "/pyramid.png"
	_texture = load(path) as Texture2D if ResourceLoader.exists(path) else null


func behind_fighters() -> bool:
	return true


## One tick: rises while its owner still rides it, else sinks.
func advance(match_: Match) -> void:
	var ride := match_.get_fighter(owner_index).ability(PyramidAbility) as PyramidAbility
	if ride != null and ride.is_riding() and not sinking:
		_rise_age += 1
	else:
		sinking = true
		_sink_age += 1
		if _sink_age >= data.sink_frames:
			finished = true
	queue_redraw()


func is_finished(_match: Match) -> bool:
	return finished


## How high its tip is above the floor now.
func tip_height() -> float:
	var risen := data.tip_height(_rise_age)
	return risen * (1.0 - float(_sink_age) / data.sink_frames)


## The part of the drawing above the floor when the tip is `height` above it: its top rows.
static func drawn_region(height: float) -> Rect2:
	var rows := clampf(height / SCALE, 0.0, DRAWING.y)
	return Rect2(0, 0, DRAWING.x, rows)


func _draw() -> void:
	var height := tip_height()
	if _texture == null or height <= 0.0:
		return
	var shake := 0.0
	if sinking:
		shake = 1.0 if int(_sink_age / float(SINK_SHAKE_TICKS)) % 2 == 0 else -1.0
	var region := drawn_region(height)
	var size := region.size * SCALE
	draw_texture_rect_region(_texture, Rect2(-size.x / 2.0 + shake, -height, size.x, size.y), region)
