class_name FighterVisuals
extends Node2D
## Draws the parent Fighter as placeholder rectangles (docs/specs/fighter.md#placeholder-visuals).
## Only reads the fighter's state; never changes it.

## Body colors by player index (Sweetie 16 palette, docs/specs/controls-and-display.md).
const PLAYER_COLORS: Array[Color] = [Color("#b13e53"), Color("#3b5dc9")]
const LIGHT_COLOR := Color("#f4f4f4")
const BODY_RECT := Rect2(-8, -24, 16, 24)
const EYE_SIZE := Vector2(3, 3)

@onready var _fighter := get_parent() as Fighter


func _process(_delta: float) -> void:
	queue_redraw()


func _draw() -> void:
	draw_rect(BODY_RECT, PLAYER_COLORS[_fighter.player_index])
	# The eye sits near the top of the body, on the side the fighter faces.
	var eye_x := 3.0 if _fighter.facing == 1 else -6.0
	draw_rect(Rect2(Vector2(eye_x, -21), EYE_SIZE), LIGHT_COLOR)
