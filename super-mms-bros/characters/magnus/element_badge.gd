class_name ElementBadge
extends Control
## Magnus's four elements on his player card (docs/specs/characters/magnus.md#the-elements-on-his-card):
## a 2×2 grid of small icons — water, fire (top), air, earth (bottom) — dark until lit, in the
## element's color when lit, all flashing during the Avatar State. Only reads.

## Where it sits on the card (right of the % number, below the stock icons).
const AT := Vector2(82, 15)
const ICON := 5.0
const GAP := 1.0
const SIZE := Vector2(ICON * 2 + GAP, ICON * 2 + GAP)
const BACKGROUND := Color("#1a1c2c")
const DARK := Color("#3b4054")
## During the Avatar State: lit this many frames, then dimmed as many.
const FLASH_FRAMES := 6

## Which elements are lit (AvatarAbility.Element order).
var lit: Array[bool] = [false, false, false, false]
var ability: AvatarAbility
var _avatar := false
var _frames := 0


func _init() -> void:
	size = SIZE
	mouse_filter = Control.MOUSE_FILTER_IGNORE


## Called by the card every tick.
func refresh() -> void:
	if ability == null:
		return
	lit = ability.lit.duplicate()
	_avatar = ability.in_avatar_state()
	_frames += 1
	queue_redraw()


## The color of element `element`'s icon now.
func icon_color(element: int) -> Color:
	if _avatar:
		var on := (_frames / FLASH_FRAMES) % 2 == 0
		return AvatarAbility.COLORS[element].lightened(0.5 if on else 0.0)
	return AvatarAbility.COLORS[element] if lit[element] else DARK


func _draw() -> void:
	for element in 4:
		var at := Vector2((element % 2) * (ICON + GAP), (element / 2) * (ICON + GAP))
		draw_rect(Rect2(at, Vector2(ICON, ICON)), BACKGROUND)
		var color := icon_color(element)
		var o := at
		match element:
			AvatarAbility.Element.WATER:  # A drop.
				draw_rect(Rect2(o + Vector2(2, 0), Vector2(1, 1)), color)
				draw_rect(Rect2(o + Vector2(1, 1), Vector2(3, 1)), color)
				draw_rect(Rect2(o + Vector2(0, 2), Vector2(5, 2)), color)
				draw_rect(Rect2(o + Vector2(1, 4), Vector2(3, 1)), color)
			AvatarAbility.Element.FIRE:  # A flame.
				draw_rect(Rect2(o + Vector2(2, 0), Vector2(1, 1)), color)
				draw_rect(Rect2(o + Vector2(1, 1), Vector2(2, 1)), color)
				draw_rect(Rect2(o + Vector2(1, 2), Vector2(3, 1)), color)
				draw_rect(Rect2(o + Vector2(0, 3), Vector2(5, 2)), color)
			AvatarAbility.Element.AIR:  # A swirl.
				draw_rect(Rect2(o + Vector2(0, 1), Vector2(4, 1)), color)
				draw_rect(Rect2(o + Vector2(3, 2), Vector2(1, 1)), color)
				draw_rect(Rect2(o + Vector2(1, 3), Vector2(4, 1)), color)
			AvatarAbility.Element.EARTH:  # A block.
				draw_rect(Rect2(o + Vector2(0, 1), Vector2(5, 4)), color)
