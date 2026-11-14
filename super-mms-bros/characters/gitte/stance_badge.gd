class_name StanceBadge
extends Control
## The badge on a player card that shows Gitte's stance (docs/specs/match-and-stage.md#hud): a
## small dark square with the sign drawn in lines (the pixel font has no ÷ or ×). Only reads.

const SIZE := 9.0
const BACKGROUND := Color("#1a1c2c")
const SIGN := Color("#f4f4f4")

## The stance shown (refresh() reads it from the ability).
var stance: StanceAbility.Stance = StanceAbility.Stance.PLUS:
	set(value):
		stance = value
		queue_redraw()
var border := Color.WHITE
var ability: StanceAbility


func _init() -> void:
	size = Vector2(SIZE, SIZE)
	mouse_filter = Control.MOUSE_FILTER_IGNORE


## Called by the card every tick.
func refresh() -> void:
	if ability != null and stance != ability.stance:
		stance = ability.stance


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), BACKGROUND)
	draw_rect(Rect2(Vector2(0.5, 0.5), size - Vector2.ONE), border, false, 1.0)
	# The sign in the 5×5 middle (pixels 2…6).
	match stance:
		StanceAbility.Stance.PLUS:
			draw_rect(Rect2(2, 4, 5, 1), SIGN)
			draw_rect(Rect2(4, 2, 1, 5), SIGN)
		StanceAbility.Stance.MINUS:
			draw_rect(Rect2(2, 4, 5, 1), SIGN)
		StanceAbility.Stance.DIVIDE:
			draw_rect(Rect2(2, 4, 5, 1), SIGN)
			draw_rect(Rect2(4, 2, 1, 1), SIGN)
			draw_rect(Rect2(4, 6, 1, 1), SIGN)
		StanceAbility.Stance.MULTIPLY:
			for i in 5:
				draw_rect(Rect2(2 + i, 2 + i, 1, 1), SIGN)
				draw_rect(Rect2(6 - i, 2 + i, 1, 1), SIGN)
