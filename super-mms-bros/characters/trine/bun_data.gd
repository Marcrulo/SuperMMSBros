class_name BunData
extends AbilityData
## Trine's bun pitch (docs/specs/characters/trine.md#trine--bun-pitch): how fast the bun flies
## for no charge and a full charge. Its hit and the windup are the move's own fields.

## The bun's speed in px/s at charge 0 and at full charge.
@export var speed_min: float
@export var speed_max: float


func create_ability() -> FighterAbility:
	return BunAbility.new()
