class_name StanceBadge
extends Control
## The badge on a player card that shows Gitte's stance (docs/specs/match-and-stage.md#hud): a
## small dark square with the sign drawn in lines (the pixel font has no ÷ or ×).

const SIZE := 9.0
const BACKGROUND := Color("#1a1c2c")
const SIGN := Color("#f4f4f4")

var stance: Fighter.Stance = Fighter.Stance.PLUS:
	set(value):
		stance = value
		queue_redraw()
var border := Color.WHITE


func _init() -> void:
	size = Vector2(SIZE, SIZE)
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), BACKGROUND)
	draw_rect(Rect2(Vector2(0.5, 0.5), size - Vector2.ONE), border, false, 1.0)
	# The sign in the 5×5 middle (pixels 2…6).
	match stance:
		Fighter.Stance.PLUS:
			draw_rect(Rect2(2, 4, 5, 1), SIGN)
			draw_rect(Rect2(4, 2, 1, 5), SIGN)
		Fighter.Stance.MINUS:
			draw_rect(Rect2(2, 4, 5, 1), SIGN)
		Fighter.Stance.DIVIDE:
			draw_rect(Rect2(2, 4, 5, 1), SIGN)
			draw_rect(Rect2(4, 2, 1, 1), SIGN)
			draw_rect(Rect2(4, 6, 1, 1), SIGN)
		Fighter.Stance.MULTIPLY:
			for i in 5:
				draw_rect(Rect2(2 + i, 2 + i, 1, 1), SIGN)
				draw_rect(Rect2(6 - i, 2 + i, 1, 1), SIGN)
