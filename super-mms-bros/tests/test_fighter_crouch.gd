extends GutTest
## Crouch, the hurtbox and the double-tap drop (docs/specs/fighter.md#crouch).

const STAGE_SCENE := preload("res://stage/battlefield.tscn")
const FIGHTER_SCENE := preload("res://fighter/fighter.tscn")
const FLOOR_Y := 192.0
const PLATFORM_Y := 150.0
const MIDDLE := Vector2(240, 192)
const UNDER_LEFT_PLATFORM := Vector2(168, 192)
const TOLERANCE := 0.5

var _fighter: Fighter
var _stats: FighterStats


func before_each() -> void:
	add_child_autofree(STAGE_SCENE.instantiate())
	_fighter = add_child_autofree(FIGHTER_SCENE.instantiate())
	_stats = _fighter.stats


func _start_at(at: Vector2, facing: int = 1) -> void:
	_fighter.spawn_at(at, facing)
	await wait_physics_frames(1)
	_fighter.tick(FighterInput.new())


func _run(input: FighterInput, ticks: int) -> void:
	for i in ticks:
		_fighter.tick(input)


func _make_input(move_x: float = 0.0, down_held: bool = false, down_pressed: bool = false,
		jump: bool = false) -> FighterInput:
	var input := FighterInput.new()
	input.move_x = move_x
	input.down_held = down_held or down_pressed
	input.down_pressed = down_pressed
	input.jump_pressed = jump
	input.jump_held = jump
	return input


func _land_on_left_platform() -> void:
	await _start_at(UNDER_LEFT_PLATFORM)
	_run(_make_input(0, false, false, true), 1)
	var hold := FighterInput.new()
	hold.jump_held = true
	for i in 120:
		_fighter.tick(hold)
		if _fighter.state != Fighter.State.AIR:
			return


func test_drop_double_tap_frames_stat() -> void:
	assert_eq(_stats.drop_double_tap_frames, 12)


func test_holding_down_crouches_with_the_small_hurtbox() -> void:
	await _start_at(MIDDLE)
	assert_eq(_fighter.get_hurtbox_rect(), Rect2(MIDDLE + Vector2(-8, -27), Vector2(16, 27)), "standing")
	_run(_make_input(0, true), 1)
	assert_eq(_fighter.state, Fighter.State.CROUCH)
	assert_eq(_fighter.get_hurtbox_rect(), Rect2(MIDDLE + Vector2(-8, -15), Vector2(16, 15)), "crouching")


func test_releasing_down_stands_up() -> void:
	await _start_at(MIDDLE)
	_run(_make_input(0, true), 3)
	_run(_make_input(), 1)
	assert_eq(_fighter.state, Fighter.State.IDLE)
	_run(_make_input(0, true), 1)
	_run(_make_input(1.0), 1)
	assert_eq(_fighter.state, Fighter.State.RUN)


func test_crouching_slides_to_a_stop_and_turns_without_walking() -> void:
	await _start_at(MIDDLE, 1)
	_run(_make_input(1.0), 10)
	_run(_make_input(1.0, true), 1)
	assert_eq(_fighter.state, Fighter.State.CROUCH)
	assert_almost_eq(_fighter.velocity.x, _stats.run_speed - _stats.ground_friction / 60.0, 0.001)
	_run(_make_input(1.0, true), 10)
	assert_eq(_fighter.velocity.x, 0.0)
	_run(_make_input(-1.0, true), 5)
	assert_eq(_fighter.facing, -1, "turned")
	assert_eq(_fighter.velocity.x, 0.0, "didn't walk")


func test_crouching_on_a_platform_stays_on_it() -> void:
	await _land_on_left_platform()
	_run(_make_input(0, true, true), 1)
	_run(_make_input(0, true), 30)
	assert_eq(_fighter.state, Fighter.State.CROUCH)
	assert_almost_eq(_fighter.position.y, PLATFORM_Y, TOLERANCE)


func test_two_presses_close_together_drop_through() -> void:
	await _land_on_left_platform()
	_run(_make_input(0, true, true), 1)
	_run(_make_input(), 4)
	_run(_make_input(0, true, true), 1)
	assert_eq(_fighter.state, Fighter.State.AIR, "5 ticks apart: dropped")


func test_two_presses_far_apart_do_not_drop() -> void:
	await _land_on_left_platform()
	_run(_make_input(0, true, true), 1)
	_run(_make_input(), 19)
	_run(_make_input(0, true, true), 1)
	assert_eq(_fighter.state, Fighter.State.CROUCH, "20 ticks apart: just crouching")
	assert_almost_eq(_fighter.position.y, PLATFORM_Y, TOLERANCE)


func test_landing_with_down_held_crouches() -> void:
	await _start_at(MIDDLE)
	_run(_make_input(0, false, false, true), 1)
	for i in 120:
		_fighter.tick(_make_input(0, true))
		if _fighter.state != Fighter.State.AIR:
			break
	assert_eq(_fighter.state, Fighter.State.CROUCH)


func test_jump_while_crouching_on_a_platform_drops_through() -> void:
	await _land_on_left_platform()
	_run(_make_input(0, true, true), 1)
	_run(_make_input(0, true), 5)
	_run(_make_input(0, true, false, true), 1)
	assert_eq(_fighter.state, Fighter.State.AIR, "dropped")
	assert_true(_fighter.velocity.y >= 0.0, "didn't jump up")
	assert_false(_fighter.get_collision_mask_value(2), "platforms ignored")
	_run(_make_input(), 20)
	assert_true(_fighter.position.y > PLATFORM_Y + 4.0, "fell below the platform")


func test_jump_while_crouching_on_the_main_platform_jumps() -> void:
	await _start_at(MIDDLE)
	_run(_make_input(0, true), 5)
	_run(_make_input(0, true, false, true), 1)
	assert_eq(_fighter.state, Fighter.State.AIR)
	assert_true(_fighter.velocity.y < 0.0, "a normal jump")
