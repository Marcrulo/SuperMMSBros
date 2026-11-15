class_name Fireball
extends MatchEntity
## Magnus's fireball (docs/specs/characters/magnus.md#side-special--fireball-fire): flies straight
## ahead and hits the first other fighter it touches (or is blocked by a shield), then is gone.
## Added by FireballAbility, advanced by the Match one tick at a time; drawing only reads.

const DELTA := 1.0 / 60.0
const OUTLINE := Color(0.25, 0.06, 0.04)
const RED := Color(0.86, 0.22, 0.1)
const ORANGE := Color(0.98, 0.52, 0.12)
const YELLOW := Color(1.0, 0.88, 0.35)

## 1 = flying right, -1 = flying left.
var direction: int = 1
## Ticks since it appeared.
var age: int = 0
## The move's values: speed, lifetime, size, damage and knockback.
var data: MoveData
var _flicker_ticks: int = 6
var _on_landed: Callable


func setup(owner: int, flying: int, at: Vector2, move_data: MoveData, flicker_ticks: int,
		on_landed: Callable) -> void:
	owner_index = owner
	direction = flying
	global_position = at
	data = move_data
	_flicker_ticks = maxi(flicker_ticks, 1)
	_on_landed = on_landed


func advance(_match: Match) -> void:
	global_position.x += direction * data.projectile_speed * DELTA
	age += 1
	queue_redraw()


func is_finished(match_: Match) -> bool:
	return age >= data.projectile_lifetime \
			or not match_.get_stage().blast_zone.has_point(global_position)


func removed_with_owner() -> bool:
	return true


func get_hitbox_rect() -> Rect2:
	return Rect2(global_position - data.hitbox_size / 2.0, data.hitbox_size)


func collect_hits(match_: Match, hits: Array[Dictionary]) -> void:
	for victim in match_.get_fighters():
		if victim.player_index == owner_index or not victim.can_be_hit():
			continue
		if get_hitbox_rect().intersects(victim.get_hurtbox_rect()):
			hits.append({
				"victim": victim,
				"move": data,
				"side": direction,
				"attacker_x": global_position.x,
				"register": func(_victim_index: int) -> void: match_.remove_entity(self),
				"landed": _on_landed,
			})
			return


## A flickering orange ball with a yellow core and a short tail of flame behind it.
func _draw() -> void:
	var f := float(direction)
	var flick := (age / (_flicker_ticks / 2.0)) as int % 2
	var tail := PackedVector2Array([Vector2(-14 * f - flick * 2 * f, -1 + flick),
		Vector2(-2 * f, -5), Vector2(-2 * f, 5)])
	draw_colored_polygon(tail, RED)
	draw_circle(Vector2.ZERO, 6.0, OUTLINE)
	draw_circle(Vector2.ZERO, 5.0, RED)
	draw_circle(Vector2(f, 0), 4.0 - flick * 0.5, ORANGE)
	draw_circle(Vector2(1.5 * f, -0.5), 2.0, YELLOW)
	if FighterVisuals.show_boxes:
		var box := get_hitbox_rect()
		box.position -= global_position
		draw_rect(box, FighterVisuals.HITBOX_ACTIVE_COLOR)
