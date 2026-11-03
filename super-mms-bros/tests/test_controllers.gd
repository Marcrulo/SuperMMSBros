extends GutTest
## FighterInput and controllers (docs/specs/fighter.md#input, docs/specs/controls-and-display.md).


func after_each() -> void:
	for action: String in ["move_left", "move_right", "jump", "down", "attack"]:
		Input.action_release(action)


func test_fighter_input_starts_empty() -> void:
	var input := FighterInput.new()
	assert_eq(input.move_x, 0.0)
	assert_false(input.jump_pressed)
	assert_false(input.jump_held)
	assert_false(input.down_pressed)
	assert_false(input.down_held)
	assert_false(input.attack_pressed)


func test_base_controller_returns_empty_input() -> void:
	var input := Controller.new().get_input(null)
	assert_not_null(input)
	assert_eq(input.move_x, 0.0)
	assert_false(input.jump_pressed)


func test_scripted_controller_plays_inputs_in_order_then_nothing() -> void:
	var right := FighterInput.new()
	right.move_x = 1.0
	var jump := FighterInput.new()
	jump.jump_pressed = true
	var controller := ScriptedController.new([right, jump])
	assert_eq(controller.get_input(null).move_x, 1.0)
	assert_true(controller.get_input(null).jump_pressed)
	var after_end := controller.get_input(null)
	assert_eq(after_end.move_x, 0.0)
	assert_false(after_end.jump_pressed)


func test_scripted_controller_reset_starts_over() -> void:
	var right := FighterInput.new()
	right.move_x = 1.0
	var controller := ScriptedController.new([right])
	controller.get_input(null)
	controller.reset()
	assert_eq(controller.get_input(null).move_x, 1.0)


func test_scripted_controller_without_inputs_is_a_dummy() -> void:
	var controller := ScriptedController.new()
	for i in 3:
		var input := controller.get_input(null)
		assert_eq(input.move_x, 0.0)
		assert_false(input.jump_pressed)


func test_keyboard_controller_reads_move_and_held_buttons() -> void:
	Input.action_press("move_left")
	Input.action_press("jump")
	Input.action_press("down")
	var input := KeyboardController.new().get_input(null)
	assert_eq(input.move_x, -1.0)
	assert_true(input.jump_held)
	assert_true(input.down_held)


func test_keyboard_controller_pressed_is_true_for_one_tick_only() -> void:
	var controller := KeyboardController.new()
	# A simulated press counts as "just pressed" during the next physics frame. Awaiting the tree's
	# physics_frame signal resumes the test inside exactly that frame (GUT's wait_physics_frames(1)
	# waits one frame longer and would miss it).
	await get_tree().physics_frame
	Input.action_press("jump")
	Input.action_press("down")
	Input.action_press("attack")
	await get_tree().physics_frame
	var first := controller.get_input(null)
	await get_tree().physics_frame
	var second := controller.get_input(null)
	assert_true(first.jump_pressed, "jump pressed on the first tick")
	assert_true(first.down_pressed, "down pressed on the first tick")
	assert_true(first.attack_pressed, "attack pressed on the first tick")
	assert_false(second.jump_pressed, "holding jump doesn't press it again")
	assert_false(second.down_pressed, "holding down doesn't press it again")
	assert_false(second.attack_pressed, "holding attack doesn't press it again")
	assert_true(second.jump_held, "jump is still held")
	assert_true(second.down_held, "down is still held")
