class_name ThrownPeel
extends MatchEntity
## Trine's banana peel in flight (docs/specs/characters/trine.md#trine--banana-peel-throw): arcs
## up and falls with gravity, spinning, and hits the first other fighter it touches (or a shield),
## then is gone. Rising it passes through everything; falling onto a floor (the main platform or a
## pass-through platform) it lands and becomes a trap peel (Fidusen's Peel), and past `max_out`
## traps of hers the oldest goes. Added by PeelThrowAbility, advanced by the Match one tick at a
## time; drawing only reads.

const DELTA := 1.0 / 60.0
const SCALE := 0.75
## Turn per tick while flying, radians.
const SPIN := 0.35

## 1 = thrown right, -1 = thrown left.
var direction: int = 1
## Ticks since it appeared.
var age: int = 0
## The throw's values: flight (speed, angle, gravity, lifetime) and the hit in flight.
var data: MoveData
## The trap it becomes.
var trap: PeelData
## Set on the tick it lands (then the Match takes it out; the trap is there instead).
var landed := false

var _velocity := Vector2.ZERO
var _character_id := ""
var _texture: Texture2D


func setup(owner: int, flying: int, at: Vector2, move_data: MoveData, trap_data: PeelData,
		character_id: String) -> void:
	owner_index = owner
	direction = flying
	global_position = at
	data = move_data
	trap = trap_data
	_character_id = character_id
	var a := deg_to_rad(data.projectile_angle_deg)
	_velocity = Vector2(cos(a) * flying, -sin(a)) * data.projectile_speed
	var path := FighterVisuals.SPRITES_DIR + character_id + "/peel.png"
	_texture = load(path) as Texture2D if ResourceLoader.exists(path) else null


## One tick of flight; falling onto a floor, it lands.
func advance(match_: Match) -> void:
	age += 1
	var before := global_position
	_velocity.y += data.projectile_gravity * DELTA
	global_position += _velocity * DELTA
	if _velocity.y > 0.0:
		var floor_y := match_.get_stage().floor_below(Vector2(global_position.x, before.y), true)
		if global_position.y >= floor_y:
			_land(match_, Vector2(global_position.x, floor_y))
	queue_redraw()


func _land(match_: Match, at: Vector2) -> void:
	landed = true
	global_position = at
	var peel := Peel.new()
	match_.add_entity(peel)
	peel.setup(owner_index, at, trap, at.y, _character_id)
	var own := match_.get_entities(Peel, owner_index)
	if own.size() > trap.max_out:
		match_.remove_entity(own[0])


func is_finished(match_: Match) -> bool:
	return landed or age >= data.projectile_lifetime \
			or not match_.get_stage().blast_zone.has_point(global_position)


func removed_with_owner() -> bool:
	return true


func get_hitbox_rect() -> Rect2:
	return Rect2(global_position - data.hitbox_size / 2.0, data.hitbox_size)


func collect_hits(match_: Match, hits: Array[Dictionary]) -> void:
	if landed:
		return
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


## The trap peel's picture, spinning, centered on it.
func _draw() -> void:
	if _texture != null:
		var size := _texture.get_size() * SCALE
		draw_set_transform(Vector2.ZERO, age * SPIN * direction)
		draw_texture_rect(_texture, Rect2(-size / 2.0, size), false)
		draw_set_transform(Vector2.ZERO)
	if FighterVisuals.show_boxes:
		var box := get_hitbox_rect()
		box.position -= global_position
		draw_rect(box, FighterVisuals.HITBOX_ACTIVE_COLOR)
