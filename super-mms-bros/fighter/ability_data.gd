class_name AbilityData
extends Resource
## The tuning numbers of one character mechanic (docs/specs/architecture.md#abilities): put on a
## move (`MoveData.ability`) or on the whole move set (`MoveSet.ability`), and the fighter makes the
## mechanic's FighterAbility from it.


## A new ability for this data (each data class makes its own kind).
func create_ability() -> FighterAbility:
	return null
