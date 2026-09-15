class_name KeyboardController
extends Controller
## Plays a fighter from the Input Map actions, so keyboard and gamepad both work
## (docs/specs/controls-and-display.md). The Match calls it inside the physics frame, where
## "just pressed" means "went down since the last tick".


func get_input(_state: RefCounted) -> FighterInput:
	var input := FighterInput.new()
	input.move_x = Input.get_axis("move_left", "move_right")
	input.jump_pressed = Input.is_action_just_pressed("jump")
	input.jump_held = Input.is_action_pressed("jump")
	input.down_pressed = Input.is_action_just_pressed("down")
	input.attack_pressed = Input.is_action_just_pressed("attack")
	return input
