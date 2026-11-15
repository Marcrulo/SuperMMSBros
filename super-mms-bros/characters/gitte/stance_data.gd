class_name StanceData
extends AbilityData
## Gitte's stances (docs/specs/characters/gitte.md#gitte--scissors-and-stances): what each one changes.

## + : every hit's base knockback and growth ×this.
@export var knockback: float
## − : on a normal attack's first active frame, opponents within pull_cone_deg of the attack's
## direction and pull_reach px (center to center) are tugged toward her at pull_speed px/s.
@export var pull_cone_deg: float
@export var pull_reach: float
@export var pull_speed: float
## ÷ : size ×small_scale, run and air speed ×small_speed.
@export var small_scale: float
@export var small_speed: float
## × : size ×large_scale, specials' damage and base knockback ×large_special.
@export var large_scale: float
@export var large_special: float


func create_ability() -> FighterAbility:
	return StanceAbility.new()
