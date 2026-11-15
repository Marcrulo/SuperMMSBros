class_name FireballData
extends AbilityData
## Magnus's fireball (docs/specs/characters/magnus.md#side-special--fireball-fire). Its speed,
## lifetime, size and hit are the side special's own MoveData values; this only marks the move.

## Ticks for one flicker cycle of the drawn flame (presentation only).
@export var flicker_ticks: int = 6


func create_ability() -> FighterAbility:
	return FireballAbility.new()
