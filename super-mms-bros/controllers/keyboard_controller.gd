class_name KeyboardController
extends Controller
## Plays a fighter from the Input Map actions, so keyboard and gamepad both work
## (docs/specs/controls-and-display.md). The Match calls it inside the physics frame, where
## "just pressed" means "went down since the last tick".

## The side pressed last (−1 left, 1 right): it wins while both are held.
var _last_side: int = 0


func get_input(_state: RefCounted) -> FighterInput:
	var input := FighterInput.new()
	if Input.is_action_just_pressed("move_right"):
		_last_side = 1
	elif Input.is_action_just_pressed("move_left"):
		_last_side = -1
	if Input.is_action_pressed("move_left") and Input.is_action_pressed("move_right"):
		input.move_x = float(_last_side)
	else:
		input.move_x = Input.get_axis("move_left", "move_right")
	input.jump_pressed = Input.is_action_just_pressed("jump")
	input.jump_held = Input.is_action_pressed("jump")
	input.down_pressed = Input.is_action_just_pressed("down")
	input.down_held = Input.is_action_pressed("down")
	input.attack_pressed = Input.is_action_just_pressed("attack")
	input.up_held = Input.is_action_pressed("up")
	input.special_pressed = Input.is_action_just_pressed("special")
	input.special_held = Input.is_action_pressed("special")
	input.shield_held = Input.is_action_pressed("shield")
	input.shield_pressed = Input.is_action_just_pressed("shield")
	input.up_pressed = Input.is_action_just_pressed("up")
	if Input.is_action_just_pressed("move_right"):
		input.side_pressed = 1
	elif Input.is_action_just_pressed("move_left"):
		input.side_pressed = -1
	return input


func reset() -> void:
	_last_side = 0
