class_name HandAbility
extends FighterAbility
## Michael's summon (docs/specs/characters/michael.md#michael-bech--big-hand): his special (no
## charge) summons a big hand on its frame `startup`, one at a time; the hand (Hand) hovers, slams
## down and is gone.

## The hand he summoned last (gone once the Match removed it).
var _hand: Hand


func _numbers() -> HandData:
	return data as HandData


func reset() -> void:
	_hand = null


## His hand is still out.
func has_hand() -> bool:
	return _hand != null and not _hand.removed


func pick_special(input: FighterInput, choice: StringName) -> StringName:
	if Fighter.special_direction(input) == slot:
		return slot if not has_hand() else Fighter.NO_MOVE  # A summon: no charge, one at a time.
	return choice


func spawn_entities(match_: Match) -> void:
	var summon := fighter.stats.moveset.get(slot) as MoveData
	if not (fighter.state == Fighter.State.ATTACK and fighter.move == slot
			and fighter.state_frame == summon.startup):
		return
	var at := fighter.global_position + Vector2(_numbers().offset.x * fighter.facing, _numbers().offset.y)
	_hand = Hand.new()
	match_.add_entity(_hand)
	_hand.setup(fighter.player_index, fighter.facing, at, _numbers(),
		match_.get_stage().floor_below(at), fighter.character_id)
