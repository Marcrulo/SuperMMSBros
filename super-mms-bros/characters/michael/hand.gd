class_name Hand
extends MatchEntity
## A summoned hand (docs/specs/characters/michael.md#michael-bech--big-hand): hovers, slams straight down to
## the floor below, stays a moment, then is gone. Added by HandAbility, advanced by the Match one
## tick at a time; drawing only reads.

enum Phase { HOVER, SLAM, IMPACT }

const DELTA := 1.0 / 60.0
## Its drawings (open, flat), each this size, drawn at the fighters' 3/4 scale.
const DRAWING := Vector2(56, 44)
const SCALE := 0.75
const SHADOW := Color(0.0, 0.0, 0.0, 0.3)

## The summoner's facing when it appeared: 1 = right, -1 = left.
var facing: int
var data: HandData
var phase: Phase = Phase.HOVER
## Ticks since it appeared.
var age: int = 0
## The y of the floor it will land on (INF: none, it falls away).
var floor_y: float = INF
## Set once its impact is over: the Match removes it.
var finished := false

## Its picture: assets/fighters/<summoner's character id>/hand.png.
var _texture: Texture2D
var _impact_left: int = 0
## Player indexes hit during this part (hover, or slam + impact); each is hit once per part.
var _victims: Array[int] = []


func setup(owner: int, owner_facing: int, at: Vector2, hand_data: HandData, floor_at: float,
		character_id: String) -> void:
	owner_index = owner
	facing = owner_facing
	global_position = at
	data = hand_data
	floor_y = floor_at
	var path := FighterVisuals.SPRITES_DIR + character_id + "/hand.png"
	_texture = load(path) as Texture2D if ResourceLoader.exists(path) else null


## One tick; on the tick it lands, its owner's sounds play the burst.
func advance(match_: Match) -> void:
	if _step():
		match_.owner_sound.emit(owner_index, &"burst")


func is_finished(match_: Match) -> bool:
	return finished or not match_.get_stage().blast_zone.has_point(global_position)


func removed_with_owner() -> bool:
	return true


## Hits whoever it touches (once per part: hover, or slam + impact).
func collect_hits(match_: Match, hits: Array[Dictionary]) -> void:
	var hitbox := get_hitbox_rect()
	for victim in match_.get_fighters():
		if victim.player_index == owner_index or not victim.can_be_hit() \
				or has_hit(victim.player_index):
			continue
		if hitbox.intersects(victim.get_hurtbox_rect()):
			var dx := victim.get_center().x - global_position.x
			hits.append({
				"victim": victim,
				"move": current_hit(),
				"side": facing if is_zero_approx(dx) else int(signf(dx)),
				"attacker_x": global_position.x,
				"register": register_hit,
			})


## One tick of its own. Returns true on the tick it lands.
func _step() -> bool:
	age += 1
	var landed := false
	match phase:
		Phase.HOVER:
			if age > data.hover_frames:
				phase = Phase.SLAM
				_victims.clear()
				landed = _drop()
		Phase.SLAM:
			landed = _drop()
		Phase.IMPACT:
			_impact_left -= 1
			if _impact_left <= 0:
				finished = true
	queue_redraw()
	return landed


func _drop() -> bool:
	global_position.y += data.slam_speed * DELTA
	if global_position.y >= floor_y:
		global_position.y = floor_y
		phase = Phase.IMPACT
		_impact_left = data.impact_frames
		return true
	return false


## The hit values for the part it's in: a touch while hovering, else the slam.
func current_hit() -> MoveData:
	return data.hover_hit if phase == Phase.HOVER else data.slam_hit


func get_hitbox_rect() -> Rect2:
	return Rect2(global_position - Vector2(data.size.x / 2.0, data.size.y), data.size)


func has_hit(victim_index: int) -> bool:
	return victim_index in _victims


func register_hit(victim_index: int) -> void:
	_victims.append(victim_index)


func _draw() -> void:
	if phase != Phase.IMPACT and floor_y != INF:
		# Where it will land.
		draw_set_transform(Vector2(0, floor_y - global_position.y), 0.0, Vector2(1.0, 0.25))
		draw_circle(Vector2.ZERO, data.size.x / 2.0, SHADOW)
	var bob := float(int(age / 8.0) % 2) if phase == Phase.HOVER else 0.0
	draw_set_transform(Vector2(0, -bob), 0.0, Vector2(facing, 1))
	if _texture != null:
		var frame := 0 if phase == Phase.HOVER else 1
		var size := DRAWING * SCALE
		draw_texture_rect_region(_texture, Rect2(-size.x / 2.0, -size.y, size.x, size.y),
			Rect2(frame * DRAWING.x, 0, DRAWING.x, DRAWING.y))
	draw_set_transform(Vector2.ZERO)
	if FighterVisuals.show_boxes:
		var box := get_hitbox_rect()
		box.position -= global_position
		draw_rect(box, FighterVisuals.HITBOX_ACTIVE_COLOR)
