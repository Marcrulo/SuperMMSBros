class_name FlopAbility
extends FighterAbility
## Pia's belly flop (docs/specs/characters/pia.md#down-special--belly-flop): on the ground a hop
## first (`belly_hop`), then, once she stops rising (or straight away in the air), a dive flat on
## her belly (`belly_dive`, the belly's hit), then the flop on landing (`belly_flop`, her move's
## own hit and frames), which hits harder the longer she dived.

## Her belly-flop dust (dust.png): drawings, and how far out from her feet each side starts.
const DUST_DRAWINGS := 4
const DUST_X := 6.0

## Ticks spent in this dive so far, and the flop's hit with its dive bonus (set on landing).
var _dive_ticks := 0
var _flop_hit: MoveData


func _numbers() -> FlopData:
	return data as FlopData


func _move_data() -> MoveData:
	return fighter.stats.moveset.get(slot) as MoveData


func phases() -> Array[StringName]:
	return [&"belly_hop", &"belly_dive", &"belly_flop"]


func pick_special(input: FighterInput, choice: StringName) -> StringName:
	if Fighter.special_direction(input) != slot:
		return choice
	return &"belly_dive" if fighter.state == Fighter.State.AIR else &"belly_hop"  # A hop first on the ground.


func reset() -> void:
	_dive_ticks = 0
	_flop_hit = null


func on_move_started(move: StringName) -> void:
	if move == &"belly_hop" or move == &"belly_dive":
		_dive_ticks = 0
	if move == &"belly_hop":
		fighter.velocity.y = -_numbers().hop_speed
		fighter.stop_fast_fall()


func move_tick(_input: FighterInput) -> bool:
	if fighter.move != &"belly_hop":
		return false
	if fighter.state_frame > 0 and fighter.velocity.y >= 0.0:
		# Stopped rising: flat on her belly, down she goes.
		fighter.move = &"belly_dive"
		fighter.state_frame = 0
		fighter.clear_hit_victims()
	return true


func phase_data(move: StringName) -> MoveData:
	match move:
		&"belly_dive":
			return _numbers().dive_hit
		&"belly_flop":
			return _flop_hit if _flop_hit != null else _move_data()
	return null


func phase_finished(move: StringName) -> bool:
	return move == &"belly_flop" and fighter.state_frame >= _move_data().total_frames()


func phase_movement(move: StringName, _input: FighterInput) -> bool:
	if move != &"belly_dive":
		return false
	fighter.velocity = Vector2(0.0, _move_data().dive_speed)
	_dive_ticks += 1
	return true


## Her belly lands into the flop, from its first frame.
func on_floor_in_move(_input: FighterInput) -> bool:
	if fighter.move != &"belly_dive":
		return false
	fighter.jumps_left = fighter.stats.max_air_jumps
	fighter.up_special_available = true
	fighter.clear_hit_victims()
	_flop_hit = _flop_with_dive_bonus()
	fighter.move = &"belly_flop"
	fighter.state_frame = 0
	return true


## The flop's own hit, +1 damage per `dive_ticks_per_damage` ticks of diving (capped).
func _flop_with_dive_bonus() -> MoveData:
	var numbers := _numbers()
	var bonus := minf(floorf(float(_dive_ticks) / numbers.dive_ticks_per_damage),
		numbers.max_dive_damage)
	var hit := _move_data().duplicate() as MoveData
	hit.damage += bonus
	return hit


func phase_animation(move: StringName) -> String:
	match move:
		&"belly_hop":
			return "jump"
		&"belly_dive":
			return "down_special_dive"
	return "down_special"


## The dust rolling out along the floor on both sides of her, if she has it.
func draw(visuals: FighterVisuals, _animation: String, _frame: int) -> void:
	if fighter.state != Fighter.State.ATTACK or fighter.move != &"belly_flop":
		return
	var textures := FighterVisuals.textures_for(fighter.character_id)
	if not textures.has("dust"):
		return
	var frame := FighterVisuals.burst_frame(fighter.current_move(), fighter.state_frame)
	if frame < 0:
		return
	var texture: Texture2D = textures["dust"]
	var width := FighterVisuals.frame_width(texture, DUST_DRAWINGS)
	var height := FighterVisuals.frame_size(texture)
	var size := Vector2(width, height) * FighterVisuals.DRAWN_SIZE / 64.0 * fighter.size_scale()
	for side in [1, -1]:
		visuals.draw_set_transform(Vector2.ZERO, 0.0, Vector2(side, 1))
		visuals.draw_texture_rect_region(texture, Rect2(Vector2(DUST_X, -size.y), size),
			Rect2(frame * width, 0, width, height))
	visuals.draw_set_transform(Vector2.ZERO)


func sounds() -> Dictionary:
	return {"start": {&"belly_dive": &"dive", &"belly_hop": &"jump"}, "hit": [&"belly_flop"]}
