class_name StanceAbility
extends FighterAbility
## Gitte's stances (docs/specs/characters/gitte.md#gitte--scissors-and-stances): her down special
## switches stance on its frame `startup` (also in the air): + → − → ÷ → × → +, + at every spawn.
## + makes all her hits knock back harder, − tugs opponents toward her with her normals, ÷ makes
## her small and fast, × makes her big with stronger specials.

## In switching order.
enum Stance { PLUS, MINUS, DIVIDE, MULTIPLY }

## Setting it resizes her body.
var stance: Stance = Stance.PLUS:
	set(value):
		stance = value
		if fighter != null:
			fighter.apply_size()


func _numbers() -> StanceData:
	return data as StanceData


func reset() -> void:
	stance = Stance.PLUS


func pick_special(input: FighterInput, choice: StringName) -> StringName:
	if Fighter.special_direction(input) == slot:
		return slot  # Switches stance, also in the air.
	return choice


func move_tick(_input: FighterInput) -> bool:
	if fighter.move != slot:
		return false
	# On its frame `startup` (state_frame counts up at the end of the tick).
	if fighter.state_frame + 1 == (fighter.stats.moveset.get(slot) as MoveData).startup:
		stance = ((stance + 1) % Stance.size()) as Stance
	return true


func size_scale() -> float:
	match stance:
		Stance.DIVIDE:
			return _numbers().small_scale
		Stance.MULTIPLY:
			return _numbers().large_scale
	return 1.0


func speed_scale() -> float:
	return _numbers().small_speed if stance == Stance.DIVIDE else 1.0


## + makes every hit knock back harder; × makes specials hit harder.
func modify_hit(move_data: MoveData, special: bool) -> MoveData:
	var numbers := _numbers()
	if stance == Stance.PLUS:
		var copy := move_data.duplicate() as MoveData
		copy.base_knockback = move_data.base_knockback * numbers.knockback
		copy.knockback_growth = move_data.knockback_growth * numbers.knockback
		return copy
	if stance == Stance.MULTIPLY and special:
		var copy := move_data.duplicate() as MoveData
		copy.damage = move_data.damage * numbers.large_special
		copy.base_knockback = move_data.base_knockback * numbers.large_special
		return copy
	return move_data


## The volley counts as a special.
func modify_projectile(move_data: MoveData) -> MoveData:
	return modify_hit(move_data, true)


## The stance sign on the portrait's bottom-right corner.
func make_card_badge(card: PlayerCard) -> Control:
	var badge := StanceBadge.new()
	badge.ability = self
	badge.border = card.player_color
	var portrait := card.portrait_rect()
	badge.position = portrait.end - Vector2(StanceBadge.SIZE, StanceBadge.SIZE) + Vector2(2, 2)
	return badge
