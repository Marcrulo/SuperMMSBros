class_name HammerAbility
extends FighterAbility
## Kim's hammer (docs/specs/characters/kim.md#kim--handyman): his neutral special (no charge,
## also in the air) throws a hammer (Hammer) on its frame `startup`, one at a time.

## The hammer he threw last (gone once the Match removed it).
var _hammer: Hammer


func _numbers() -> HammerData:
	return data as HammerData


func phases() -> Array[StringName]:
	return [&"hammer_throw"]


func reset() -> void:
	_hammer = null


func _hammers_out() -> int:
	return 1 if _hammer != null and not _hammer.removed else 0


func pick_special(input: FighterInput, choice: StringName) -> StringName:
	if Fighter.special_direction(input) != slot:
		return choice
	# A throw: no charge, and not while his hammer is still out.
	return &"hammer_throw" if _hammers_out() < _numbers().max_out else Fighter.NO_MOVE


func spawn_entities(match_: Match) -> void:
	var throw := fighter.stats.moveset.get(slot) as MoveData
	if not (fighter.state == Fighter.State.ATTACK and fighter.move == &"hammer_throw"
			and fighter.state_frame == throw.startup):
		return
	var at := fighter.global_position + Vector2(throw.hitbox_center.x * fighter.facing,
			throw.hitbox_center.y) * fighter.size_scale()
	_hammer = Hammer.new()
	match_.add_entity(_hammer)
	_hammer.setup(fighter.player_index, fighter.facing, at, throw, _numbers())


## The throw has the move's own frames and no hitbox.
func phase_data(_move: StringName) -> MoveData:
	return fighter.stats.moveset.get(slot) as MoveData


func phase_finished(_move: StringName) -> bool:
	return fighter.state_frame >= phase_data(&"hammer_throw").total_frames()


func phase_animation(_move: StringName) -> String:
	return "side_special"


## The hammer in his hand until it leaves it.
func draw(visuals: FighterVisuals, _animation: String, _frame: int) -> void:
	if fighter.state != Fighter.State.ATTACK or fighter.move != &"hammer_throw":
		return
	if fighter.state_frame >= phase_data(&"hammer_throw").startup:
		return
	var hand := Vector2(9.0 * fighter.facing, -20.0)
	visuals.draw_set_transform(hand, -0.6 * fighter.facing, Vector2(fighter.facing, 1.0))
	Hammer.draw_hammer(visuals)
	visuals.draw_set_transform(Vector2.ZERO)
