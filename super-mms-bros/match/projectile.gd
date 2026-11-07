class_name Projectile
extends Node2D
## The side special's projectile (docs/specs/moves.md#side-special--projectile). Owned and
## advanced by the Match, one tick at a time; it has no _process gameplay of its own.

const DELTA := 1.0 / 60.0
const SPRITE := preload("res://assets/fighters/default/projectile.png")
const FRAME := 12
## Ticks per sprite frame.
const FRAME_TICKS := 4

## Player index of the fighter who fired it.
var owner_index: int
## 1 = flying right, -1 = flying left.
var direction: int
## Ticks since it appeared.
var age: int = 0
## The side special's data: speed, lifetime, size, damage and knockback.
var data: MoveData


func setup(owner: int, flying: int, at: Vector2, move_data: MoveData) -> void:
	owner_index = owner
	direction = flying
	global_position = at
	data = move_data


## One tick of flight.
func advance() -> void:
	global_position.x += direction * data.projectile_speed * DELTA
	age += 1
	queue_redraw()


func is_expired(blast_zone: Rect2) -> bool:
	return age >= data.projectile_lifetime or not blast_zone.has_point(global_position)


func get_hitbox_rect() -> Rect2:
	return Rect2(global_position - data.hitbox_size / 2.0, data.hitbox_size)


func _draw() -> void:
	var frame := int(age / float(FRAME_TICKS)) % 3
	draw_set_transform(Vector2.ZERO, 0.0, Vector2(direction, 1))
	draw_texture_rect_region(SPRITE, Rect2(-FRAME / 2.0, -FRAME / 2.0, FRAME, FRAME),
		Rect2(frame * FRAME, 0, FRAME, FRAME))
