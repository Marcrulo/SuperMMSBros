class_name FlopData
extends AbilityData
## Pia's belly flop (docs/specs/characters/pia.md#down-special--belly-flop): on the ground a hop at
## `hop_speed` first, then a dive at its move's `dive_speed` with the belly's hit `dive_hit`, then
## the flop on landing, which is its move's own hit, plus 1 damage per `dive_ticks_per_damage`
## ticks of diving, at most `max_dive_damage` more.

@export var dive_hit: MoveData
@export var hop_speed: float
@export var dive_ticks_per_damage: int = 5
@export var max_dive_damage: float = 10.0


func create_ability() -> FighterAbility:
	return FlopAbility.new()
