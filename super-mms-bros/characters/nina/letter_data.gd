class_name LetterData
extends AbilityData
## Nina's letter volley (docs/specs/characters/nina.md#nina--existentialism): the tuning that isn't
## in the side special's own MoveData (the letter's size, hit and speed are that move's values).

## The letters, shot one by one.
@export var text: String
## Ticks between two letters.
@export var interval: int
## Her walking speed while shooting, as a share of her run speed.
@export var walk_scale: float
## Her back hand, relative to the feet, facing right (the front hand is the move's hitbox_center).
@export var back_hand: Vector2


func create_ability() -> FighterAbility:
	return LetterAbility.new()
