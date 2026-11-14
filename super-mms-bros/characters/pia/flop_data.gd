class_name FlopData
extends AbilityData
## Pia's belly flop (docs/specs/characters/pia.md#down-special--belly-flop): on the ground a hop at
## `hop_speed` first, then a dive at its move's `dive_speed` with the belly's hit `dive_hit`, then
## the flop on landing, which is its move's own hit.

@export var dive_hit: MoveData
@export var hop_speed: float


func create_ability() -> FighterAbility:
	return FlopAbility.new()
