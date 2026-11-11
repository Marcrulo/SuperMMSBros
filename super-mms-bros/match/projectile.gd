class_name Projectile
extends Node2D
## The side special's projectile (docs/specs/moves.md#side-special--projectile; Michael's
## football: #michael-bech--football). Owned and advanced by the Match, one tick at a time; it has
## no _process gameplay of its own.

const DELTA := 1.0 / 60.0
const SPRITE := preload("res://assets/fighters/projectile.png")
const FRAME := 12
## Ticks per sprite frame.
const FRAME_TICKS := 4
## A character's own picture (64 px style) is drawn at this scale.
const OWN_SCALE := 0.75

## Player index of the fighter who fired it.
var owner_index: int
## 1 = flying right, -1 = flying left.
var direction: int
## Flight angle in degrees: 0 = straight ahead, positive = upward.
var angle_deg: float = 0.0
## Ticks since it appeared.
var age: int = 0
## The side special's data: speed, lifetime, size, damage and knockback.
var data: MoveData

var _velocity := Vector2.ZERO
var _texture: Texture2D = SPRITE
var _scale := 1.0


## The angle (degrees, positive = up) from `origin` to the nearest of `targets` that is on the
## `facing` side, within ±cone_deg and at most `max_range` px away; NAN if there's none.
static func aim_angle(origin: Vector2, facing: int, targets: Array[Vector2], cone_deg: float,
		max_range: float) -> float:
	var best := NAN
	var best_distance := INF
	for target in targets:
		var to := target - origin
		var ahead := to.x * facing
		if ahead <= 0.0:
			continue
		var angle := rad_to_deg(atan2(-to.y, ahead))
		var distance := to.length()
		if absf(angle) <= cone_deg and distance <= max_range and distance < best_distance:
			best = angle
			best_distance = distance
	return best


func setup(owner: int, flying: int, at: Vector2, move_data: MoveData, flight_angle := 0.0,
		character_id := "") -> void:
	owner_index = owner
	direction = flying
	global_position = at
	data = move_data
	angle_deg = flight_angle
	var a := deg_to_rad(flight_angle)
	_velocity = Vector2(cos(a) * flying, -sin(a)) * data.projectile_speed
	var own := FighterVisuals.SPRITES_DIR + character_id + "/projectile.png"
	if character_id != "" and ResourceLoader.exists(own):
		_texture = load(own) as Texture2D
		_scale = OWN_SCALE


## One tick of flight (falling with the move's projectile_gravity, if any).
func advance() -> void:
	_velocity.y += data.projectile_gravity * DELTA
	global_position += _velocity * DELTA
	age += 1
	queue_redraw()


func is_expired(blast_zone: Rect2) -> bool:
	return age >= data.projectile_lifetime or not blast_zone.has_point(global_position)


func get_hitbox_rect() -> Rect2:
	return Rect2(global_position - data.hitbox_size / 2.0, data.hitbox_size)


func _draw() -> void:
	var frame_px := int(_texture.get_height())
	var frame := int(age / float(FRAME_TICKS)) % 3
	var size := frame_px * _scale
	draw_set_transform(Vector2.ZERO, 0.0, Vector2(direction, 1))
	draw_texture_rect_region(_texture, Rect2(-size / 2.0, -size / 2.0, size, size),
		Rect2(frame * frame_px, 0, frame_px, frame_px))
