extends GutTest
## The fighter's ground modifiers (docs/specs/fighter.md#ground-modifiers): something on the floor
## sets ground_grip / ground_speed / ground_jump for the fighter's next tick only. P1 and P2 are
## Casper (default moves); main platform top y 192 (x 96…384).

const MATCH_SCENE := preload("res://match/match.tscn")

var _match: Match
var _p1: Fighter
var _saved_ids: Array[String] = []


func before_each() -> void:
	_saved_ids = [Game.character_id, Game.p2_character_id]
	Game.character_id = "slot_08"
	Game.p2_character_id = "slot_08"
	_match = MATCH_SCENE.instantiate()
	_match.auto_step = false
	add_child_autofree(_match)
	_p1 = _match.get_fighter(0)


func after_each() -> void:
	Game.character_id = _saved_ids[0]
	Game.p2_character_id = _saved_ids[1]


func _place(inputs: Array[FighterInput]) -> void:
	_p1.spawn_at(Vector2(200, 192), 1)
	_match.get_fighter(1).spawn_at(Vector2(360, 192), -1)
	_match.set_controller(0, ScriptedController.new(inputs))
	_match.set_controller(1, ScriptedController.new())
	await wait_physics_frames(1)


func _held(ticks: int, move_x: float, jump_on := -1) -> Array[FighterInput]:
	var inputs: Array[FighterInput] = []
	for i in ticks:
		var input := FighterInput.new()
		input.move_x = move_x
		if i == jump_on:
			input.jump_pressed = true
			input.jump_held = true
		inputs.append(input)
	return inputs


## Steps `ticks` times, setting the modifiers before every step (as a puddle does each tick).
func _steps(ticks: int, grip := 1.0, speed := 1.0, jump := 1.0) -> void:
	for i in ticks:
		_p1.ground_grip = grip
		_p1.ground_speed = speed
		_p1.ground_jump = jump
		_match.step()


func test_modifiers_start_at_one() -> void:
	await _place([])
	assert_eq([_p1.ground_grip, _p1.ground_speed, _p1.ground_jump], [1.0, 1.0, 1.0])


func test_modifiers_last_one_tick() -> void:
	await _place([])
	_p1.ground_grip = 0.1
	_p1.ground_speed = 0.4
	_p1.ground_jump = 0.7
	_match.step()
	assert_eq([_p1.ground_grip, _p1.ground_speed, _p1.ground_jump], [1.0, 1.0, 1.0])


func test_low_grip_speeds_up_slowly() -> void:
	await _place(_held(6, 1.0))
	_steps(6, 0.1)
	var accel := _p1.stats.ground_accel * 0.1 * Fighter.DELTA
	assert_almost_eq(_p1.velocity.x, accel * 6.0, accel + 0.1, "a tenth of the acceleration")


func test_low_grip_slides_further() -> void:
	await _place(_held(20, 1.0))
	_steps(20)
	assert_almost_eq(_p1.velocity.x, _p1.stats.run_speed, 0.1, "at full speed")
	_steps(10, 0.1)  # No input now.
	assert_gt(_p1.velocity.x, _p1.stats.run_speed * 0.7, "still sliding")


func test_full_grip_stops_quickly() -> void:
	await _place(_held(20, 1.0))
	_steps(30)
	assert_eq(_p1.velocity.x, 0.0)


func test_ground_speed_caps_running() -> void:
	await _place(_held(30, 1.0))
	_steps(30, 1.0, 0.4)
	assert_almost_eq(_p1.velocity.x, _p1.stats.run_speed * 0.4, 0.1)


func test_ground_jump_scales_the_jump() -> void:
	await _place(_held(2, 0.0, 1))
	_steps(2)
	var normal := _p1.velocity.y
	await _place(_held(2, 0.0, 1))
	_steps(2, 1.0, 1.0, 0.7)
	var sticky := _p1.velocity.y
	assert_lt(normal, 0.0, "jumped")
	assert_almost_eq(sticky - normal, _p1.stats.jump_velocity * 0.3, 0.5)
