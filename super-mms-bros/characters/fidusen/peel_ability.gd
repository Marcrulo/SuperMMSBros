class_name PeelAbility
extends FighterAbility
## Fidusen's banana peel (docs/specs/characters/fidusen.md#fidusen--banana-book-vine): his down
## special (no dive, also in the air) places a peel (Peel) on its frame `startup`, in front of his
## feet; it falls to the floor and trips the first other fighter on the ground that touches it.
## Past `max_out` peels of his, the oldest goes.


func _numbers() -> PeelData:
	return data as PeelData


func pick_special(input: FighterInput, choice: StringName) -> StringName:
	if Fighter.special_direction(input) == slot:
		return slot  # Places a peel, also in the air.
	return choice


func spawn_entities(match_: Match) -> void:
	var move_data := fighter.stats.moveset.get(slot) as MoveData
	if not (fighter.state == Fighter.State.ATTACK and fighter.move == slot
			and fighter.state_frame == move_data.startup):
		return
	var at := fighter.global_position + Vector2(8.0 * fighter.facing, 0.0)
	var peel := Peel.new()
	match_.add_entity(peel)
	peel.setup(fighter.player_index, at, _numbers(), match_.get_stage().floor_below(at, true),
		fighter.character_id)
	var own := match_.get_entities(Peel, fighter.player_index)
	if own.size() > _numbers().max_out:
		match_.remove_entity(own[0])
