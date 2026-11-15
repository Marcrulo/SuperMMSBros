class_name WaterGunData
extends AbilityData
## Magnus's water gun (docs/specs/characters/magnus.md#neutral-special--water-gun-water): the
## tuning that isn't in the neutral special's own MoveData (a droplet's size, hit, speed and
## lifetime are that move's values; it leaves at the move's hitbox_center).

## How many droplets one use shoots.
@export var drops: int
## Ticks between two droplets.
@export var interval: int


func create_ability() -> FighterAbility:
	return WaterGunAbility.new()
