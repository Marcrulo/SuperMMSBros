class_name UppercutAbility
extends FighterAbility
## Mads's rising uppercut (docs/specs/characters/mads.md#mads--grappler): no jump boost. On the up
## special's frame `startup` he turns to the held side and rises (`uppercut_rise`) diagonally
## forward with his own gravity and no steering: a clean hit first, a late hit after. When he stops
## rising the default up special takes over again (launched), which makes him HELPLESS.

const RISE := &"uppercut_rise"


func _numbers() -> UppercutData:
	return data as UppercutData


func phases() -> Array[StringName]:
	return [RISE]


func replaces(move: StringName) -> bool:
	return move == &"up_special"


## On the frame `startup`: turn, launch, and start the rise.
func move_tick(input: FighterInput) -> bool:
	if fighter.move == &"up_special" and not fighter.launched \
			and fighter.state_frame == fighter.stats.moveset.up_special.startup:
		if input.move_x != 0.0:
			fighter.facing = 1 if input.move_x > 0.0 else -1
		var u := _numbers()
		fighter.velocity = Vector2(fighter.facing * u.forward_speed, -u.rise_speed)
		fighter.move = RISE
		fighter.state_frame = 0
		fighter.clear_hit_victims()
		return true
	return fighter.move == RISE


## The rise ends when he stops rising (left_floor_in_move / on_floor_in_move), not on a count.
func phase_finished(_move: StringName) -> bool:
	return false


func phase_data(_move: StringName) -> MoveData:
	var u := _numbers()
	return u.clean_hit if fighter.state_frame <= u.clean_frames else u.late_hit


## Straight on, with his own gravity: no steering.
func phase_movement(move: StringName, _input: FighterInput) -> bool:
	if move != RISE:
		return false
	fighter.velocity.y += _numbers().rise_gravity * Fighter.DELTA
	return true


## At the top: back to the launched up special, which turns HELPLESS.
func left_floor_in_move() -> bool:
	_end_rise()
	return false


## Landed during the rise: back to the launched up special, which lands.
func on_floor_in_move(_input: FighterInput) -> bool:
	_end_rise()
	return false


func _end_rise() -> void:
	if fighter.move == RISE and fighter.velocity.y >= 0.0:
		fighter.move = &"up_special"
		fighter.launched = true


func can_be_hit() -> bool:
	if fighter.state != Fighter.State.ATTACK:
		return true
	var startup := fighter.stats.moveset.up_special.startup
	if fighter.move == &"up_special" and not fighter.launched:
		return false
	return not (fighter.move == RISE
		and fighter.state_frame <= _numbers().invulnerable_frames - startup)


# --- Presentation ---------------------------------------------------------------------------------


func phase_animation(_move: StringName) -> String:
	return "up_special"


## Crouched in the startup, the uppercut on the clean hit, the elbow bent after.
func drawing(animation: String, frame: int) -> int:
	if animation != "up_special":
		return frame
	if fighter.move == RISE:
		return 1 if fighter.state_frame <= _numbers().clean_frames else 2
	if fighter.move == &"up_special" and not fighter.launched:
		return 0
	return frame
