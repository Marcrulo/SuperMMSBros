class_name StanceAbility
extends FighterAbility
## Gitte's stances (docs/specs/characters/gitte.md#gitte--scissors-and-stances): her down special
## switches stance on its frame `startup` (also in the air): + → − → ÷ → × → +, + at every spawn.
## + makes her projectile hurt more, − heals her by a share of her landed normals, ÷ makes her
## small and fast, × makes her big with stronger specials.

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


## × makes specials hit harder.
func modify_hit(move_data: MoveData, special: bool) -> MoveData:
	if not special or stance != Stance.MULTIPLY:
		return move_data
	var copy := move_data.duplicate() as MoveData
	copy.damage = move_data.damage * _numbers().large_special
	copy.base_knockback = move_data.base_knockback * _numbers().large_special
	return copy


## + makes the projectile hurt more; × (a special) too.
func modify_projectile(move_data: MoveData) -> MoveData:
	var copy := modify_hit(move_data, true)
	if stance == Stance.PLUS:
		copy = copy.duplicate() as MoveData
		copy.damage = move_data.damage * _numbers().projectile_damage
	return copy


func lifesteal() -> float:
	return _numbers().lifesteal if stance == Stance.MINUS else 0.0


## The stance sign on the portrait's bottom-right corner.
func make_card_badge(card: PlayerCard) -> Control:
	var badge := StanceBadge.new()
	badge.ability = self
	badge.border = card.player_color
	var portrait := card.portrait_rect()
	badge.position = portrait.end - Vector2(StanceBadge.SIZE, StanceBadge.SIZE) + Vector2(2, 2)
	return badge
