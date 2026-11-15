class_name ToolSwingData
extends AbilityData
## The tool Kim swings on one of his normal attacks (docs/specs/characters/kim.md#kim--handyman):
## which tool the game draws in his hand, and how it moves over the move's frames. Angles are in
## degrees in facing-right coordinates: 0 = pointing forward, −90 = up, 90 = down. Pivots are
## where the tool is held (relative to the feet).

## &"hammer", &"axe" or &"screwdriver".
@export var tool: StringName
## Held at rest (before the move and when it ends).
@export var rest_angle: float
@export var rest_pivot: Vector2
## Raised for the windup: reached at the end of the startup.
@export var wind_angle: float
@export var wind_pivot: Vector2
## The strike: from `hit_from` on the first active frame to `hit_to` on the last.
@export var hit_from_angle: float
@export var hit_from_pivot: Vector2
@export var hit_to_angle: float
@export var hit_to_pivot: Vector2


func create_ability() -> FighterAbility:
	return ToolSwingAbility.new()
