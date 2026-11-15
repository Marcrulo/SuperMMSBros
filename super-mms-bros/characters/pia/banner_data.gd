class_name BannerData
extends AbilityData
## Pia's Leverkusen banner (docs/specs/characters/pia.md#up-special--leverkusen-banner): on its move
## (no hitbox, ground only) she raises the banner for `raise_frames` frames, then holds it up until
## the move's startup ends; meanwhile everyone within `radius` px is stunned. Then she can't raise it
## again for `cooldown_frames` ticks.

@export var raise_frames: int
@export var radius: float
@export var cooldown_frames: int


func create_ability() -> FighterAbility:
	return BannerAbility.new()
