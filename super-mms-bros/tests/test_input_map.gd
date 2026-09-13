extends GutTest
## Input Map from docs/specs/controls-and-display.md.

const ACTIONS := ["move_left", "move_right", "jump", "down", "attack", "pause"]


func test_actions_exist() -> void:
	for action: String in ACTIONS:
		assert_true(InputMap.has_action(action), "missing action: %s" % action)


func test_keyboard_bindings() -> void:
	_assert_keys("move_left", [KEY_A])
	_assert_keys("move_right", [KEY_D])
	_assert_keys("jump", [KEY_W, KEY_SPACE])
	_assert_keys("down", [KEY_S])
	_assert_keys("attack", [KEY_J])
	_assert_keys("pause", [KEY_ESCAPE])


func test_gamepad_buttons() -> void:
	_assert_buttons("move_left", [JOY_BUTTON_DPAD_LEFT])
	_assert_buttons("move_right", [JOY_BUTTON_DPAD_RIGHT])
	_assert_buttons("jump", [JOY_BUTTON_A])
	_assert_buttons("down", [JOY_BUTTON_DPAD_DOWN])
	_assert_buttons("attack", [JOY_BUTTON_X])
	_assert_buttons("pause", [JOY_BUTTON_START])


func test_gamepad_stick() -> void:
	_assert_axis("move_left", JOY_AXIS_LEFT_X, -1.0)
	_assert_axis("move_right", JOY_AXIS_LEFT_X, 1.0)
	_assert_axis("down", JOY_AXIS_LEFT_Y, 1.0)


func test_deadzones() -> void:
	assert_almost_eq(InputMap.action_get_deadzone("move_left"), 0.2, 0.001)
	assert_almost_eq(InputMap.action_get_deadzone("move_right"), 0.2, 0.001)
	assert_almost_eq(InputMap.action_get_deadzone("down"), 0.5, 0.001)


func test_bindings_work_for_every_device() -> void:
	for action: String in ACTIONS:
		for event: InputEvent in InputMap.action_get_events(action):
			assert_eq(event.device, -1, "%s: %s should listen to all devices" % [action, event])


func _assert_keys(action: String, keys: Array) -> void:
	var found: Array = []
	for event: InputEvent in InputMap.action_get_events(action):
		if event is InputEventKey:
			found.append(event.physical_keycode)
	for key: Key in keys:
		assert_has(found, key, "%s should be bound to %s" % [action, OS.get_keycode_string(key)])


func _assert_buttons(action: String, buttons: Array) -> void:
	var found: Array = []
	for event: InputEvent in InputMap.action_get_events(action):
		if event is InputEventJoypadButton:
			found.append(event.button_index)
	for button: JoyButton in buttons:
		assert_has(found, button, "%s should be bound to joypad button %d" % [action, button])


func _assert_axis(action: String, axis: JoyAxis, value: float) -> void:
	for event: InputEvent in InputMap.action_get_events(action):
		if event is InputEventJoypadMotion and event.axis == axis and is_equal_approx(event.axis_value, value):
			pass_test("%s bound to axis %d (%s)" % [action, axis, value])
			return
	fail_test("%s should be bound to axis %d with value %s" % [action, axis, value])
