class_name GrabTable
extends MatchEntity
## The table of Mads's slam (docs/specs/characters/mads.md#mads--grappler): stands behind him from
## the start of the move, and breaks apart when the victim is slammed into it. No hitbox; drawing only reads.

const DELTA := 1.0 / 60.0
const GRAVITY := 900.0
const WOOD := Color("9a6a3a")
const EDGE := Color("5c3a1c")

var data: GrabData
## Ticks since it broke (-1: still whole).
var broken_age: int = -1


func setup(owner: int, spot: Vector2, grab: GrabData) -> void:
	owner_index = owner
	data = grab
	global_position = spot


func behind_fighters() -> bool:
	return true


func is_broken() -> bool:
	return broken_age >= 0


func break_apart() -> void:
	if not is_broken():
		broken_age = 0


func advance(_match: Match) -> void:
	if is_broken():
		broken_age += 1
	queue_redraw()


func is_finished(_match: Match) -> bool:
	return broken_age >= data.table_break_ticks


func removed_with_owner() -> bool:
	return true


## Where each of the six pieces is (relative to the spot) and how far it turned, `ticks` after the
## break: [top left, top right, four legs] as [offset, angle] pairs.
static func piece_pose(index: int, ticks: int) -> Array:
	var vx: Array[float] = [-70.0, 70.0, -110.0, -40.0, 40.0, 110.0]
	var vy: Array[float] = [-150.0, -150.0, -110.0, -190.0, -190.0, -110.0]
	var spin: Array[float] = [-6.0, 6.0, -9.0, -5.0, 5.0, 9.0]
	var t := float(ticks) * DELTA
	return [Vector2(vx[index] * t, vy[index] * t + 0.5 * GRAVITY * t * t), spin[index] * t]


func _draw() -> void:
	var size := data.table_size
	var top_h := size.y * 0.3
	var leg_h := size.y - top_h
	if not is_broken():
		draw_rect(Rect2(-size.x / 2.0, -size.y, size.x, top_h), WOOD)
		draw_rect(Rect2(-size.x / 2.0, -size.y, size.x, top_h), EDGE, false, 1.0)
		for x in [-size.x / 2.0 + 2.0, size.x / 2.0 - 4.0]:
			draw_rect(Rect2(x, -leg_h, 2.0, leg_h), EDGE)
		return
	var fade := 1.0 - float(broken_age) / data.table_break_ticks
	for i in 6:
		var pose := piece_pose(i, broken_age)
		var piece := Rect2(-size.x / 4.0, -top_h / 2.0, size.x / 2.0, top_h) if i < 2 \
				else Rect2(-1.0, -leg_h / 2.0, 2.0, leg_h)
		var origin := Vector2(((i * 2 - 1) * size.x / 4.0) if i < 2 else 0.0, -size.y / 2.0)
		draw_set_transform(origin + pose[0], pose[1])
		draw_rect(piece, Color(WOOD, fade))
		draw_rect(piece, Color(EDGE, fade), false, 1.0)
	draw_set_transform(Vector2.ZERO, 0.0)
