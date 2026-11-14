class_name IpadData
extends AbilityData
## Trine's iPad break (docs/specs/characters/trine.md#trine--ipad-break): how long she can watch and how
## fast it heals her.

## Ticks she can watch at most (while down is held).
@export var watch_frames: int
## Every this many ticks of watching, her % drops by `heal` (not below 0).
@export var heal_every: int
@export var heal: float


func create_ability() -> FighterAbility:
	return IpadAbility.new()
