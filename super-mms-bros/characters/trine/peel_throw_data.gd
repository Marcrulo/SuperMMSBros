class_name PeelThrowData
extends AbilityData
## Trine's banana peel throw (docs/specs/characters/trine.md#trine--banana-peel-throw). The flight
## and the hit in flight are the move's own fields; `trap` is the peel it becomes on landing.

## The trap peel's numbers (Fidusen's Peel): how many, how long, the trip.
@export var trap: PeelData


func create_ability() -> FighterAbility:
	return PeelThrowAbility.new()
