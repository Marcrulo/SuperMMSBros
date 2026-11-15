class_name TorchData
extends AbilityData
## Kim's torch (docs/specs/characters/kim.md#kim--handyman), on his side special: a flamethrower
## whose hitbox is out for the move's active frames and hits again every `hit_interval` ticks.

@export var hit_interval: int = 8


func create_ability() -> FighterAbility:
	return TorchAbility.new()
