class_name HammerData
extends AbilityData
## Kim's hammer (docs/specs/characters/kim.md#kim--handyman), on his neutral special. The throw's
## speed, angle, gravity, lifetime, size and hit are the move's own (`MoveData.projectile_*`,
## hitbox_size, damage…); this is what the hammer adds.

## Hammers of his that can be out at once.
@export var max_out: int = 1
## Ticks for one full turn of the spinning hammer.
@export var spin_ticks: int = 24


func create_ability() -> FighterAbility:
	return HammerAbility.new()
