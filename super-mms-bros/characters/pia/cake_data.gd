class_name CakeData
extends AbilityData
## Pia's cake (docs/specs/characters/pia.md#neutral-special--cake): on its move (no hitbox, ground
## only) she heals `heal` % on frame `heal_frame`, then can't eat again for `cooldown_frames` ticks.

@export var heal: float
@export var heal_frame: int
@export var cooldown_frames: int


func create_ability() -> FighterAbility:
	return CakeAbility.new()
