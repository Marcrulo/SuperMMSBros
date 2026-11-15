class_name Ladder
extends MatchEntity
## Kim's ladder (docs/specs/characters/kim.md#kim--handyman): stands where he set it up for a
## while, then is gone. Scenery only: no hitbox, nothing climbs or stands on it but him, on his
## way up. Added by LadderAbility, advanced by the Match one tick at a time; drawing only reads.

const WOOD := Color(0.62, 0.4, 0.2)
const WOOD_DARK := Color(0.4, 0.25, 0.14)
const OUTLINE := Color(0.1, 0.11, 0.17)
const RUNG_SPACING := 8.0

var numbers: LadderData
## Ticks since it appeared.
var age: int = 0


## `at`: the foot of the ladder (the middle of its bottom).
func setup(owner: int, at: Vector2, ladder_data: LadderData) -> void:
	owner_index = owner
	global_position = at
	numbers = ladder_data


func behind_fighters() -> bool:
	return true


func advance(_match: Match) -> void:
	age += 1
	queue_redraw()


func is_finished(_match: Match) -> bool:
	return age >= numbers.lifetime


func removed_with_owner() -> bool:
	return true


func _draw() -> void:
	var half := numbers.size.x / 2.0
	var height := numbers.size.y
	for side in [-1.0, 1.0]:
		var x: float = side * half
		draw_rect(Rect2(x - 1.5, -height - 1.0, 3, height + 2.0), OUTLINE)
	var y := -RUNG_SPACING
	while y > -height:
		draw_rect(Rect2(-half, y - 1.5, numbers.size.x, 3), OUTLINE)
		y -= RUNG_SPACING
	for side in [-1.0, 1.0]:
		var x: float = side * half
		draw_rect(Rect2(x - 0.5, -height, 1, height), WOOD)
	y = -RUNG_SPACING
	while y > -height:
		draw_rect(Rect2(-half, y - 0.5, numbers.size.x, 1), WOOD_DARK)
		y -= RUNG_SPACING
