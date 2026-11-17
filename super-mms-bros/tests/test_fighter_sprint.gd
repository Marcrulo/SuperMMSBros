extends GutTest
## Sprinting (docs/specs/fighter.md#sprint): a double-tapped side dashes, a held dash becomes a
## sprint, the opposite side during a dash dashes back (dash dance), a sprint jump keeps its speed.

const STAGE_SCENE := preload("res://stage/battlefield.tscn")
const FIGHTER_SCENE := preload("res://fighter/fighter.tscn")
## The middle of the main platform, below the top platform: room to dash both ways.
const MIDDLE := Vector2(240, 192)

var _fighter: Fighter
var _stats: FighterStats


func before_each() -> void:
	add_child_autofree(STAGE_SCENE.instantiate())
	_fighter = add_child_autofree(FIGHTER_SCENE.instantiate())
	_stats = _fighter.stats


func _start_at(at: Vector2, facing: int = 1) -> void:
	_fighter.spawn_at(at, facing)
	await wait_physics_frames(1)


func _run(input: FighterInput, ticks: int) -> void:
	for i in ticks:
		_fighter.tick(input)


func _hold(side: int) -> FighterInput:
	var input := FighterInput.new()
	input.move_x = float(side)
	return input


## The tick a side goes down: pressed and held.
func _press(side: int) -> FighterInput:
	var input := _hold(side)
	input.side_pressed = side
	return input


## Press a side, let go for `gap` ticks, press it again (the second press is the last tick run).
func _double_tap(side: int, gap: int = 3) -> void:
	_run(_press(side), 1)
	_run(FighterInput.new(), gap)
	_run(_press(side), 1)


# --- Dash -------------------------------------------------------------------------------------


func test_a_double_tap_dashes() -> void:
	await _start_at(MIDDLE)
	_double_tap(1)
	assert_eq(_fighter.state, Fighter.State.DASH)
	assert_eq(_fighter.facing, 1)


func test_the_dash_bursts_to_dash_speed() -> void:
	await _start_at(MIDDLE)
	_double_tap(1)
	_run(_hold(1), 3)
	assert_eq(_fighter.velocity.x, _stats.dash_speed, "faster than walking")
	assert_gt(_stats.dash_speed, _stats.run_speed)


func test_a_double_tap_to_the_left_dashes_left() -> void:
	await _start_at(MIDDLE, 1)
	_double_tap(-1)
	_run(_hold(-1), 3)
	assert_eq(_fighter.state, Fighter.State.DASH)
	assert_eq(_fighter.facing, -1)
	assert_eq(_fighter.velocity.x, -_stats.dash_speed)


func test_holding_a_side_only_walks() -> void:
	await _start_at(MIDDLE)
	_run(_press(1), 1)
	_run(_hold(1), 30)
	assert_eq(_fighter.state, Fighter.State.RUN)
	assert_eq(_fighter.velocity.x, _stats.run_speed)


func test_taps_too_far_apart_only_walk() -> void:
	await _start_at(MIDDLE)
	_double_tap(1, _stats.sprint_double_tap_frames)
	assert_eq(_fighter.state, Fighter.State.RUN)


func test_taps_just_close_enough_dash() -> void:
	await _start_at(MIDDLE)
	_double_tap(1, _stats.sprint_double_tap_frames - 1)
	assert_eq(_fighter.state, Fighter.State.DASH)


func test_tapping_left_then_right_doesnt_dash() -> void:
	await _start_at(MIDDLE)
	_run(_press(-1), 1)
	_run(FighterInput.new(), 2)
	_run(_press(1), 1)
	assert_eq(_fighter.state, Fighter.State.RUN)


func test_walking_then_a_double_tap_dashes() -> void:
	await _start_at(MIDDLE)
	_run(_press(1), 1)
	_run(_hold(1), 20)
	_run(FighterInput.new(), 2)
	_run(_press(1), 1)
	assert_eq(_fighter.state, Fighter.State.DASH)


func test_the_dash_lasts_its_frames_even_if_released() -> void:
	await _start_at(MIDDLE)
	_double_tap(1)
	_run(FighterInput.new(), _stats.dash_frames - 1)
	assert_eq(_fighter.state, Fighter.State.DASH, "still dashing on its last frame")
	assert_eq(_fighter.velocity.x, _stats.dash_speed)
	_run(FighterInput.new(), 1)
	assert_eq(_fighter.state, Fighter.State.IDLE, "then skids to a stop")
	assert_lt(_fighter.velocity.x, _stats.dash_speed)
	assert_gt(_fighter.velocity.x, 0.0)


# --- Dash dance -------------------------------------------------------------------------------


func test_the_opposite_side_during_a_dash_dashes_back() -> void:
	await _start_at(MIDDLE)
	_double_tap(1)
	_run(_hold(1), 4)
	_run(_press(-1), 1)
	assert_eq(_fighter.state, Fighter.State.DASH)
	assert_eq(_fighter.state_frame, 1, "a new dash")
	assert_eq(_fighter.facing, -1)
	_run(_hold(-1), 3)
	assert_eq(_fighter.velocity.x, -_stats.dash_speed)


# --- Sprint -----------------------------------------------------------------------------------


func test_holding_after_the_dash_sprints() -> void:
	await _start_at(Vector2(110, 192))
	_double_tap(1)
	_run(_hold(1), _stats.dash_frames)
	assert_eq(_fighter.state, Fighter.State.SPRINT)
	_run(_hold(1), 10)
	assert_eq(_fighter.state, Fighter.State.SPRINT)
	assert_eq(_fighter.velocity.x, _stats.sprint_speed)
	assert_gt(_stats.sprint_speed, _stats.run_speed)


func _sprint_right() -> void:
	await _start_at(Vector2(110, 192))
	_double_tap(1)
	_run(_hold(1), _stats.dash_frames + 10)


func test_letting_go_skids_to_a_stop() -> void:
	await _sprint_right()
	_run(FighterInput.new(), 1)
	assert_eq(_fighter.state, Fighter.State.IDLE)
	assert_almost_eq(_fighter.velocity.x, _stats.sprint_speed - _stats.ground_friction / 60.0, 0.001)
	_run(FighterInput.new(), 20)
	assert_eq(_fighter.velocity.x, 0.0)


func test_turning_in_a_sprint_walks_back() -> void:
	await _sprint_right()
	_run(_press(-1), 1)
	assert_eq(_fighter.state, Fighter.State.RUN)
	assert_eq(_fighter.facing, -1)
	assert_gt(_fighter.velocity.x, 0.0, "still sliding the old way at first")
	_run(_hold(-1), 30)
	assert_eq(_fighter.velocity.x, -_stats.run_speed)


func test_sprinting_then_a_double_tap_dashes_again() -> void:
	await _sprint_right()
	_run(FighterInput.new(), 2)
	_run(_press(1), 1)
	assert_eq(_fighter.state, Fighter.State.DASH)


func test_crouching_ends_a_sprint() -> void:
	await _sprint_right()
	var input := _hold(1)
	input.down_held = true
	_run(input, 1)
	assert_eq(_fighter.state, Fighter.State.CROUCH)


func test_attacking_from_a_sprint_is_the_usual_ground_attack() -> void:
	await _sprint_right()
	var input := _hold(1)
	input.attack_pressed = true
	_run(input, 1)
	assert_eq(_fighter.state, Fighter.State.ATTACK)
	assert_eq(_fighter.move, &"side_tilt")


func test_shielding_from_a_dash() -> void:
	await _start_at(MIDDLE)
	_double_tap(1)
	var input := _hold(1)
	input.shield_held = true
	_run(input, 1)
	assert_eq(_fighter.state, Fighter.State.SHIELD)


# --- Into the air -----------------------------------------------------------------------------


func test_a_sprint_jump_keeps_its_speed() -> void:
	await _sprint_right()
	var input := _hold(1)
	input.jump_pressed = true
	input.jump_held = true
	_run(input, 1)
	assert_eq(_fighter.state, Fighter.State.AIR)
	var held := _hold(1)
	held.jump_held = true
	_run(held, 5)
	assert_gt(_fighter.velocity.x, _stats.air_speed, "faster than plain air speed")
	assert_almost_eq(_fighter.velocity.x, _stats.sprint_speed - 6 * _stats.air_friction / 60.0, 0.01,
		"slows only at air friction (from the jump tick on)")


func test_air_speed_still_caps_a_slow_jump() -> void:
	await _start_at(MIDDLE)
	var input := _hold(1)
	input.jump_pressed = true
	input.jump_held = true
	_run(input, 1)
	input.jump_pressed = false
	_run(input, 20)
	assert_eq(_fighter.state, Fighter.State.AIR)
	assert_eq(_fighter.velocity.x, _stats.air_speed)


func test_steering_back_against_a_sprint_jump_uses_air_accel() -> void:
	await _sprint_right()
	var input := _hold(1)
	input.jump_pressed = true
	_run(input, 1)
	var before := _fighter.velocity.x
	_run(_hold(-1), 1)
	assert_almost_eq(_fighter.velocity.x, before - _stats.air_accel / 60.0, 0.01)


func test_sprinting_off_a_ledge_falls() -> void:
	await _start_at(Vector2(330, 192))
	_double_tap(1)
	_run(_hold(1), 60)
	assert_eq(_fighter.state, Fighter.State.AIR)
	assert_eq(_fighter.jumps_left, _stats.max_air_jumps, "the double jump is still there")


func test_respawn_forgets_the_first_tap() -> void:
	await _start_at(MIDDLE)
	_run(_press(1), 1)
	_fighter.spawn_at(MIDDLE, 1)
	_run(FighterInput.new(), 1)
	_run(_press(1), 1)
	assert_eq(_fighter.state, Fighter.State.RUN)
