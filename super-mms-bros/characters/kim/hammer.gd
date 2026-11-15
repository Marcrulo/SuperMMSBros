class_name Hammer
extends MatchEntity
## Kim's thrown hammer (docs/specs/characters/kim.md#kim--handyman): flies in an arc, spinning,
## and is gone on a hit, a shield, when it lands on the main platform, out of the blast zone, or
## after its lifetime. Added by HammerAbility, advanced by the Match one tick at a time; drawing
## only reads.

const DELTA := 1.0 / 60.0
const WOOD := Color(0.62, 0.4, 0.2)
const IRON := Color(0.7, 0.72, 0.78)
const OUTLINE := Color(0.1, 0.11, 0.17)

## The throw's move data: speed, angle, gravity, lifetime, hitbox size and the hit.
var throw: MoveData
var numbers: HammerData
## 1 = flying right, -1 = flying left.
var direction: int = 1
## Ticks since it appeared.
var age: int = 0
## Set once it landed: the Match removes it.
var landed := false

var _velocity := Vector2.ZERO


func setup(owner: int, flying: int, at: Vector2, move_data: MoveData, hammer_data: HammerData) -> void:
	owner_index = owner
	direction = flying
	global_position = at
	throw = move_data
	numbers = hammer_data
	var angle := deg_to_rad(move_data.projectile_angle_deg)
	_velocity = Vector2(cos(angle) * flying, -sin(angle)) * move_data.projectile_speed


func advance(match_: Match) -> void:
	var before := global_position
	_velocity.y += throw.projectile_gravity * DELTA
	global_position += _velocity * DELTA
	age += 1
	# Lands on the main platform (the pass-through platforms let it through).
	if global_position.y >= match_.get_stage().floor_below(before):
		landed = true
	queue_redraw()


func is_finished(match_: Match) -> bool:
	return landed or age >= throw.projectile_lifetime \
			or not match_.get_stage().blast_zone.has_point(global_position)


func removed_with_owner() -> bool:
	return false


func get_hitbox_rect() -> Rect2:
	return Rect2(global_position - throw.hitbox_size / 2.0, throw.hitbox_size)


func collect_hits(match_: Match, hits: Array[Dictionary]) -> void:
	for victim in match_.get_fighters():
		if victim.player_index == owner_index or not victim.can_be_hit():
			continue
		if get_hitbox_rect().intersects(victim.get_hurtbox_rect()):
			hits.append({
				"victim": victim,
				"move": throw,
				"side": direction,
				"attacker_x": global_position.x,
				"register": func(_victim_index: int) -> void: match_.remove_entity(self),
			})
			return


## The hammer, turned `age` ticks' worth of its spin.
func _draw() -> void:
	var turn := TAU * age / numbers.spin_ticks * direction
	draw_set_transform(Vector2.ZERO, turn, Vector2(direction, 1))
	draw_hammer(self)
	draw_set_transform(Vector2.ZERO)
	if FighterVisuals.show_boxes:
		var box := get_hitbox_rect()
		box.position -= global_position
		draw_rect(box, FighterVisuals.HITBOX_ACTIVE_COLOR)


## A claw hammer centered on its middle, head up, 10 px tall (drawn on `canvas`).
static func draw_hammer(canvas: CanvasItem) -> void:
	canvas.draw_rect(Rect2(-1.5, -5.5, 3, 11), OUTLINE)
	canvas.draw_rect(Rect2(-5.5, -6.5, 11, 5), OUTLINE)
	canvas.draw_rect(Rect2(-0.5, -4.5, 1, 9), WOOD)
	canvas.draw_rect(Rect2(-4.5, -5.5, 9, 3), IRON)
