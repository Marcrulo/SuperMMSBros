class_name TorchData
extends AbilityData
## Kim's torch (docs/specs/characters/kim.md#kim--handyman), on his side special: a flamethrower
## whose hitbox is out for the move's active frames and hits again every `hit_interval` ticks.

@export var hit_interval: int = 8
## Burning, once the flame has stopped hitting someone: `burn_damage` every `burn_interval`
## ticks for `burn_ticks` ticks.
@export var burn_ticks: int = 180
@export var burn_interval: int = 30
@export var burn_damage: float = 1.0


func create_ability() -> FighterAbility:
	return TorchAbility.new()
