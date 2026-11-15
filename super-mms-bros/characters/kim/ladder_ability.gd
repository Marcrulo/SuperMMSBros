class_name LadderAbility
extends FighterAbility
## Kim's ladder up special (docs/specs/characters/kim.md#kim--handyman): on its frame `startup` a
## ladder (Ladder) is set up at his feet and he climbs it straight up (`ladder_climb`, no gravity),
## then jumps off it like a launched up special.


func _numbers() -> LadderData:
	return data as LadderData


func phases() -> Array[StringName]:
	return [&"ladder_climb"]


func replaces(move: StringName) -> bool:
	return move == &"up_special"  # No jump boost: the ladder is his launch.


## On its frame: the ladder goes up and the climb starts.
func after_ledges(match_: Match) -> void:
	var up := fighter.stats.moveset.up_special
	if not (fighter.state == Fighter.State.ATTACK and fighter.move == &"up_special"
			and not fighter.launched and fighter.state_frame == up.startup):
		return
	var ladder := Ladder.new()
	match_.add_entity(ladder)
	ladder.setup(fighter.player_index, fighter.global_position, _numbers())
	fighter.velocity = Vector2.ZERO
	fighter.move = &"ladder_climb"
	fighter.state_frame = 0
	fighter.clear_hit_victims()


## Up the ladder, and off it at the top.
func move_tick(input: FighterInput) -> bool:
	if fighter.move != &"ladder_climb":
		return false
	var ladder := _numbers()
	if fighter.state_frame >= ladder.climb_frames:
		fighter.velocity = Vector2(input.move_x * ladder.jump_drift, -ladder.jump_speed)
		fighter.move = &"up_special"
		fighter.launched = true
	return true


func phase_movement(move: StringName, _input: FighterInput) -> bool:
	if move != &"ladder_climb":
		return false
	fighter.velocity = Vector2(0.0, -_numbers().climb_speed)  # Straight up, moved with physics.
	return true


func phase_animation(_move: StringName) -> String:
	return "up_special"


func drawing(animation: String, frame: int) -> int:
	if fighter.move == &"ladder_climb":
		return 1  # Reaching up, hand over hand.
	return frame
