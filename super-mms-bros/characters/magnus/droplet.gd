class_name Droplet
extends MatchEntity
## One droplet of Magnus's water gun (docs/specs/characters/magnus.md#neutral-special--water-gun-water):
## flies straight ahead and hits the first other fighter it touches (or is blocked by a shield),
## then is gone. Added by WaterGunAbility, advanced by the Match one tick at a time; drawing only
## reads.

const DELTA := 1.0 / 60.0
const OUTLINE := Color(0.1, 0.11, 0.17)
const WATER := Color(0.25, 0.55, 0.95)
const SHINE := Color(0.78, 0.92, 1.0)

## 1 = flying right, -1 = flying left.
var direction: int = 1
## Ticks since it appeared.
var age: int = 0
## The move's values: speed, lifetime, size, damage and knockback.
var data: MoveData
## Called with the victim when its hit lands (not blocked).
var _on_landed: Callable


func setup(owner: int, flying: int, at: Vector2, move_data: MoveData, on_landed: Callable) -> void:
	owner_index = owner
	direction = flying
	global_position = at
	data = move_data
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


## A small blue drop, pointed at the back, with a light highlight and a dark outline.
func _draw() -> void:
	var f := float(direction)
	draw_circle(Vector2.ZERO, 3.0, OUTLINE)
	draw_colored_polygon(PackedVector2Array([Vector2(-6 * f, 0), Vector2(-1 * f, -3),
		Vector2(-1 * f, 3)]), OUTLINE)
	draw_circle(Vector2.ZERO, 2.0, WATER)
	draw_colored_polygon(PackedVector2Array([Vector2(-5 * f, 0), Vector2(-1 * f, -2),
		Vector2(-1 * f, 2)]), WATER)
	draw_rect(Rect2(0.0 if f > 0 else -1.0, -1.5, 1, 1), SHINE)
	if FighterVisuals.show_boxes:
		var box := get_hitbox_rect()
		box.position -= global_position
		draw_rect(box, FighterVisuals.HITBOX_ACTIVE_COLOR)
