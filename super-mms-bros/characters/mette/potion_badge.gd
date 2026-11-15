class_name PotionBadge
extends Control
## The badge on a player card that shows the potion Mette holds
## (docs/specs/characters/mette.md#look): a small dark square with a flask of that colour. Only
## reads.

const SIZE := 13.0
const BACKGROUND := Color("#1a1c2c")

## The potion shown (refresh() reads it from the ability).
var potion: PotionAbility.Potion = PotionAbility.Potion.RED:
	set(value):
		potion = value
		queue_redraw()
var border := Color.WHITE
var ability: PotionAbility


func _init() -> void:
	size = Vector2(SIZE, SIZE)
	mouse_filter = Control.MOUSE_FILTER_IGNORE


## Called by the card every tick.
func refresh() -> void:
	if ability != null and potion != ability.potion:
		potion = ability.potion


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), BACKGROUND)
	draw_rect(Rect2(Vector2(0.5, 0.5), size - Vector2.ONE), border, false, 1.0)
	draw_set_transform(Vector2(SIZE / 2.0, SIZE / 2.0 + 0.5), 0.0, Vector2(0.8, 0.8))
	PotionLook.draw_flask(self, potion)
	draw_set_transform(Vector2.ZERO)
