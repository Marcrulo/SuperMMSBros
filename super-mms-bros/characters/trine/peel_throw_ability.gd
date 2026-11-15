class_name PeelThrowAbility
extends FighterAbility
## Trine's banana peel throw (docs/specs/characters/trine.md#trine--banana-peel-throw): her side
## special (the default frames and turn, but no default projectile) tosses a peel (ThrownPeel) on
## its frame `startup`; it arcs, hits like a light projectile, and where it lands it becomes a trap
## peel. One thrown peel of hers in the air at a time.

## True while a thrown peel of hers is still in the air (as of this tick's spawning).
var _out := false


func _numbers() -> PeelThrowData:
	return data as PeelThrowData


func reset() -> void:
	_out = false


func replaces(move: StringName) -> bool:
	return move == &"side_special"


## No new toss while her peel is still in the air.
func pick_special(_input: FighterInput, choice: StringName) -> StringName:
	if choice == &"side_special" and _out:
		return Fighter.NO_MOVE
	return choice


func spawn_entities(match_: Match) -> void:
	_out = not match_.get_entities(ThrownPeel, fighter.player_index).is_empty()
	var move_data := fighter.stats.moveset.get(slot) as MoveData
	if not (fighter.state == Fighter.State.ATTACK and fighter.move == slot
			and fighter.state_frame == move_data.startup):
		return
	var hand := move_data.hitbox_center
	var at := fighter.global_position \
			+ Vector2(hand.x * fighter.facing, hand.y) * fighter.size_scale()
	var peel := ThrownPeel.new()
	match_.add_entity(peel)
	peel.setup(fighter.player_index, fighter.facing, at, fighter.projectile_data(move_data),
			_numbers().trap, fighter.character_id)
	_out = true
