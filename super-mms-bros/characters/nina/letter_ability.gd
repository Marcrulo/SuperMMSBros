class_name LetterAbility
extends FighterAbility
## Nina's letter volley (docs/specs/characters/nina.md#nina--existentialism): her side special, on
## the ground or in the air, shoots the letters of a word out of her hands, one every `interval`
## ticks (phase `letters`). She turns toward the held direction at the start and then can't turn,
## but can still walk (on the ground) or steer (in the air).

## The direction held when the special was picked.
var _aim: int = 1
## The index of the next letter to shoot.
var _next: int = 0


func _numbers() -> LetterData:
	return data as LetterData


func _move_data() -> MoveData:
	return fighter.stats.moveset.get(slot) as MoveData


func phases() -> Array[StringName]:
	return [&"letters"]


func reset() -> void:
	_next = 0


func pick_special(input: FighterInput, choice: StringName) -> StringName:
	if Fighter.special_direction(input) != slot:
		return choice
	_aim = 1 if input.move_x > 0.0 else -1
	return &"letters"  # Also in the air; any number of letters can be out.


## Jump: she jumps (a double jump in the air) and the volley goes on. Shield pressed (and it would
## do something): the volley ends and the fighter's normal ground or air actions take that same
## input this tick (shield, roll, spot dodge, air dodge).
func before_tick(input: FighterInput) -> void:
	if not (fighter.state == Fighter.State.ATTACK and fighter.move == &"letters"):
		return
	var on_floor := fighter.is_on_floor()
	var stats := fighter.stats
	if input.jump_pressed:
		if on_floor:
			fighter.velocity.y = -stats.jump_velocity
			fighter.stop_fast_fall()
		elif fighter.jumps_left > 0:
			fighter.velocity.y = -stats.double_jump_velocity
			fighter.velocity.x = input.move_x * stats.air_speed * fighter.speed_scale()
			fighter.jumps_left -= 1
			fighter.stop_fast_fall()
	var shields := input.shield_pressed and (
			(on_floor and input.shield_held and fighter.shield_health > 0.0)
			or (not on_floor and fighter.air_dodge_available))
	if shields:
		fighter.move = Fighter.NO_MOVE
		fighter.set_state(Fighter.State.IDLE if on_floor else Fighter.State.AIR)


func on_move_started(move: StringName) -> void:
	if move == &"letters":
		fighter.facing = _aim
		_next = 0


## Its move's own frames (no hitbox).
func phase_data(_move: StringName) -> MoveData:
	return _move_data()


## Over once the last letter is out and the recovery has passed.
func phase_finished(_move: StringName) -> bool:
	var move_data := _move_data()
	var last := move_data.startup + (_numbers().text.length() - 1) * _numbers().interval
	return fighter.state_frame >= last + move_data.recovery


## She walks on the ground (at `walk_scale` of her run speed); in the air the default steering and
## gravity apply (false).
func phase_movement(_move: StringName, input: FighterInput) -> bool:
	if not (fighter.is_on_floor() and fighter.velocity.y >= 0.0):
		return false
	var stats := fighter.stats
	var top := stats.run_speed * fighter.speed_scale() * _numbers().walk_scale
	var rate := stats.ground_accel if input.move_x != 0.0 else stats.ground_friction
	fighter.velocity.x = move_toward(fighter.velocity.x, input.move_x * top, rate * Fighter.DELTA)
	return true


## The next letter leaves a hand when its frame comes.
func spawn_entities(match_: Match) -> void:
	if not (fighter.state == Fighter.State.ATTACK and fighter.move == &"letters"):
		return
	var numbers := _numbers()
	var move_data := _move_data()
	if _next >= numbers.text.length() \
			or fighter.state_frame < move_data.startup + _next * numbers.interval:
		return
	var hand := move_data.hitbox_center if _next % 2 == 0 else numbers.back_hand
	var at := fighter.global_position \
			+ Vector2(hand.x * fighter.facing, hand.y) * fighter.size_scale()
	var letter := Letter.new()
	match_.add_entity(letter)
	letter.setup(fighter.player_index, fighter.facing, at, numbers.text[_next],
			fighter.projectile_data(move_data))
	_next += 1


# --- Presentation -----------------------------------------------------------------------------


func phase_animation(_move: StringName) -> String:
	return String(slot)


## Wind up, arms out for the whole volley, then the recovery.
func drawing(_animation: String, frame: int) -> int:
	if fighter.move != &"letters":
		return frame
	var move_data := _move_data()
	var last := move_data.startup + (_numbers().text.length() - 1) * _numbers().interval
	var now := fighter.state_frame
	if now < move_data.startup / 2:
		return 0
	if now < move_data.startup:
		return 1
	return 2 if now <= last else 3


## Her own sound as the letters phase starts (docs/specs/sound.md#character-sounds).
func sounds() -> Dictionary:
	var sound := _numbers().sound
	if sound == null:
		return {}
	return {"start": {&"letters": &"nina_scream"}, "streams": {&"nina_scream": sound}}
