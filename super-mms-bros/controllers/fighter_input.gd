class_name FighterInput
extends RefCounted
## One tick of input for one fighter (docs/specs/fighter.md#input).
## "Pressed" means the button went down this tick; holding it never presses it again.

## Horizontal direction, from -1 (left) to 1 (right).
var move_x: float = 0.0
## Jump went down this tick.
var jump_pressed: bool = false
## Jump is held down.
var jump_held: bool = false
## Down went down this tick.
var down_pressed: bool = false
## Down is held down.
var down_held: bool = false
## Attack went down this tick.
var attack_pressed: bool = false
## Up is held (aims moves; doesn't jump).
var up_held: bool = false
## Special ("B") went down this tick.
var special_pressed: bool = false
## Special is held (charging).
var special_held: bool = false
## Shield is held.
var shield_held: bool = false
