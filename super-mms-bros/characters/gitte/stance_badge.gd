class_name StanceBadge
extends Control
## The badge on a player card that shows Gitte's stance (docs/specs/match-and-stage.md#hud): a
## small dark square with the sign (in the stance's color) drawn in lines (the pixel font has no ÷ or ×). Only reads.

const SIZE := 9.0
const BACKGROUND := Color("#1a1c2c")

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


## The sign's color: the stance's.
func sign_color() -> Color:
	return StanceAbility.stance_color(stance)


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), BACKGROUND)
	draw_rect(Rect2(Vector2(0.5, 0.5), size - Vector2.ONE), border, false, 1.0)
	draw_sign(self, stance, Vector2.ZERO, 1.0, sign_color())


## Draws `stance`'s sign on `item` in a 9×9 grid whose top left is `origin`, each grid pixel
## `unit` px big (the badge uses 1; the switch pop-up bigger). The sign is in the 5×5 middle.
static func draw_sign(item: CanvasItem, of: StanceAbility.Stance, origin: Vector2, unit: float,
		color: Color) -> void:
	var px := func(x: int, y: int, w: int, h: int) -> void:
		item.draw_rect(Rect2(origin + Vector2(x, y) * unit, Vector2(w, h) * unit), color)
	match of:
		StanceAbility.Stance.PLUS:
			px.call(2, 4, 5, 1)
			px.call(4, 2, 1, 5)
		StanceAbility.Stance.MINUS:
			px.call(2, 4, 5, 1)
		StanceAbility.Stance.DIVIDE:
			px.call(2, 4, 5, 1)
			px.call(4, 2, 1, 1)
			px.call(4, 6, 1, 1)
		StanceAbility.Stance.MULTIPLY:
			for i in 5:
				px.call(2 + i, 2 + i, 1, 1)
				px.call(6 - i, 2 + i, 1, 1)
