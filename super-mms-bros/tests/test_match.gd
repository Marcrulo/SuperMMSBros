extends GutTest
## The Match drives every tick (docs/specs/architecture.md#tick-order). M2: one fighter, no rules.

const MATCH_SCENE := preload("res://match/match.tscn")

var _match: Match


## Adds a match to the tree. With `auto_step` off, the test decides when ticks happen.
func _add_match(auto_step: bool) -> void:
	_match = MATCH_SCENE.instantiate()
	_match.auto_step = auto_step
	add_child_autofree(_match)


func test_scene_has_stage_fighter_and_camera() -> void:
	_add_match(false)
	assert_true(_match.get_node("Stage") is Stage)
	assert_eq(_match.get_node("Fighters").get_child_count(), 1, "M2 has one fighter")
	assert_true(_match.get_fighter(0) is Fighter)
	var camera := _match.get_node("Camera2D") as Camera2D
	assert_eq(camera.position, Vector2(160, 90))


func test_p1_starts_at_its_spawn_point() -> void:
	_add_match(false)
	var p1 := _match.get_fighter(0)
	assert_eq(_match.tick, 0)
	assert_eq(p1.player_index, 0)
	assert_eq(p1.position, Vector2(112, 128))
	assert_eq(p1.facing, 1)
	assert_eq(p1.state, Fighter.State.IDLE)


func test_p1_is_played_from_the_keyboard() -> void:
	_add_match(false)
	assert_true(_match.get_controller(0) is KeyboardController)


func test_step_drives_the_fighter_with_its_controller() -> void:
	_add_match(false)
	var right := FighterInput.new()
	right.move_x = 1.0
	var inputs: Array[FighterInput] = []
	for i in 10:
		inputs.append(right)
	_match.set_controller(0, ScriptedController.new(inputs))
	await wait_physics_frames(1)
	for i in 10:
		_match.step()
	assert_eq(_match.tick, 10)
	assert_eq(_match.get_fighter(0).state, Fighter.State.RUN)
	assert_gt(_match.get_fighter(0).position.x, 112.0, "moved right")


func test_without_auto_step_nothing_happens_by_itself() -> void:
	_add_match(false)
	await wait_physics_frames(5)
	assert_eq(_match.tick, 0)


func test_auto_step_ticks_once_per_physics_frame() -> void:
	_add_match(true)
	_match.set_controller(0, ScriptedController.new())
	await wait_physics_frames(5)
	assert_between(_match.tick, 5, 7)


func test_reset_puts_everything_back() -> void:
	_add_match(false)
	var right := FighterInput.new()
	right.move_x = 1.0
	_match.set_controller(0, ScriptedController.new([right, right, right]))
	await wait_physics_frames(1)
	for i in 3:
		_match.step()
	_match.reset()
	var p1 := _match.get_fighter(0)
	assert_eq(_match.tick, 0)
	assert_eq(p1.position, Vector2(112, 128))
	assert_eq(p1.velocity, Vector2.ZERO)
	assert_eq(p1.state, Fighter.State.IDLE)
	_match.step()
	assert_gt(p1.velocity.x, 0.0, "the controller was reset and plays its inputs again")
