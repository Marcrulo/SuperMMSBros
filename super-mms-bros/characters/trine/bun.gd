class_name Bun
extends MatchEntity
## Trine's thrown bun (docs/specs/characters/trine.md#trine--bun-pitch): flies straight ahead at
## its own speed and hits the first other fighter it touches (or is blocked by a shield), then is
## gone. Added by BunAbility, advanced by the Match one tick at a time; drawing only reads.

const DELTA := 1.0 / 60.0
## Its picture (3 drawings, each turned further: it spins) is drawn at this scale.
const SCALE := 0.75
## Ticks per drawing.
const FRAME_TICKS := 3

## 1 = flying right, -1 = flying left.
var direction: int = 1
## Ticks since it appeared.
var age: int = 0
## The throw's values: speed, lifetime, size, damage and knockback (with the charge in them).
var data: MoveData

var _texture: Texture2D


func setup(owner: int, flying: int, at: Vector2, move_data: MoveData, character_id: String) -> void:
	owner_index = owner
	direction = flying
	global_position = at
	data = move_data
	var path := FighterVisuals.SPRITES_DIR + character_id + "/projectile.png"
	_texture = load(path) as Texture2D if ResourceLoader.exists(path) else null


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
			})
			return


func _draw() -> void:
	if _texture != null:
		var px := _texture.get_height()
		var frame := int(age / float(FRAME_TICKS)) % 3
		var size := px * SCALE
		draw_set_transform(Vector2.ZERO, 0.0, Vector2(direction, 1))
		draw_texture_rect_region(_texture, Rect2(-size / 2.0, -size / 2.0, size, size),
			Rect2(frame * px, 0, px, px))
		draw_set_transform(Vector2.ZERO)
	if FighterVisuals.show_boxes:
		var box := get_hitbox_rect()
		box.position -= global_position
		draw_rect(box, FighterVisuals.HITBOX_ACTIVE_COLOR)
