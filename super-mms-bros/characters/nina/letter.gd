class_name Letter
extends MatchEntity
## One flying letter of Nina's volley (docs/specs/characters/nina.md#nina--existentialism): flies
## straight ahead and hits the first other fighter it touches (or is blocked by a shield), then is
## gone. Added by LetterAbility, advanced by the Match one tick at a time; drawing only reads.

const DELTA := 1.0 / 60.0
const FONT_SIZE := 10

## The letter it shows.
var character: String = ""
## 1 = flying right, -1 = flying left.
var direction: int = 1
## Ticks since it appeared.
var age: int = 0
## Where it appeared (height), for the tests and the look.
var start_y: float = 0.0
## The move's values: speed, lifetime, size, damage and knockback.
var data: MoveData


func setup(owner: int, flying: int, at: Vector2, letter: String, move_data: MoveData) -> void:
	owner_index = owner
	direction = flying
	global_position = at
	start_y = at.y
	character = letter
	data = move_data


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


## The letter in white with a dark outline, centered on the hitbox.
func _draw() -> void:
	var font := ThemeDB.fallback_font
	var size := font.get_string_size(character, HORIZONTAL_ALIGNMENT_LEFT, -1, FONT_SIZE)
	var at := Vector2(-size.x / 2.0, FONT_SIZE * 0.35)
	font.draw_string_outline(get_canvas_item(), at, character, HORIZONTAL_ALIGNMENT_LEFT, -1,
			FONT_SIZE, 3, Color(0.1, 0.11, 0.17))
	font.draw_string(get_canvas_item(), at, character, HORIZONTAL_ALIGNMENT_LEFT, -1, FONT_SIZE,
			Color.WHITE)
