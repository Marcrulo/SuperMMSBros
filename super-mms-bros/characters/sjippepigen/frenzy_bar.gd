class_name FrenzyBar
extends Control
## Sjippepigen's frenzy meter on her player card (docs/specs/match-and-stage.md#hud): a thin bar that
## fills up as the meter refills, in her rope color, flashing when full (the frenzy is ready).

const SIZE := Vector2(62, 4)
const BACKGROUND := Color("#1a1c2c")
## While full: lit this many frames, then plain as many.
const FLASH_FRAMES := 8

## How full, 0…1.
var value: float = 0.0:
	set(v):
		if v != value:
			value = v
			queue_redraw()
var color := Color.WHITE
var _frames := 0


func _init() -> void:
	size = SIZE
	mouse_filter = Control.MOUSE_FILTER_IGNORE


## The fill's color: lit up in flashes while full.
func fill_color() -> Color:
	if value >= 1.0 and (_frames / FLASH_FRAMES) % 2 == 0:
		return color.lightened(0.6)
	return color


func _process(_delta: float) -> void:
	_frames += 1
	if value >= 1.0:
		queue_redraw()


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), BACKGROUND)
	if value > 0.0:
		draw_rect(Rect2(Vector2(1, 1), Vector2((size.x - 2.0) * value, size.y - 2.0)), fill_color())
