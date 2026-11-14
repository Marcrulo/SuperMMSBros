class_name StanceData
extends Resource
## Gitte's stances (docs/specs/characters/gitte.md#gitte--scissors-and-stances): what each one changes.

## + : her projectiles' damage ×this.
@export var projectile_damage: float
## − : her normal attacks lower her % by this share of the damage they deal.
@export var lifesteal: float
## ÷ : size ×small_scale, run and air speed ×small_speed.
@export var small_scale: float
@export var small_speed: float
## × : size ×large_scale, specials' damage and base knockback ×large_special.
@export var large_scale: float
@export var large_special: float
