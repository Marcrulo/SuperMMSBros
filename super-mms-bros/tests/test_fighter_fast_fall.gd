extends GutTest
## Fast fall: holding down while falling, after a short wait so down then A is a down air
## (docs/specs/fighter.md#movement-rules).

const STAGE_SCENE := preload("res://stage/battlefield.tscn")
const FIGHTER_SCENE := preload("res://fighter/fighter.tscn")
## High above the main platform, away from the pass-through platforms.
const HIGH_UP := Vector2(110, 40)
const FLOOR_Y := 192.0

var _fighter: Fighter
var _stats: FighterStats


func before_each() -> void:
	add_child_autofree(STAGE_SCENE.instantiate())
	_fighter = add_child_autofree(FIGHTER_SCENE.instantiate())
	_stats = _fighter.stats


## Puts the fighter high in the air, starting to fall.
func _start_falling() -> void:
	_fighter.spawn_at(HIGH_UP, 1)
	await wait_physics_frames(1)
	_fighter.tick(_make_input())
	assert_eq(_fighter.state, Fighter.State.AIR)


func _run(input: FighterInput, ticks: int) -> void:
	for i in ticks:
		_fighter.tick(input)


func _make_input(down := false, jump := false, attack := false) -> FighterInput:
	var input := FighterInput.new()
	input.down_held = down
	input.jump_pressed = jump
	input.jump_held = jump
	input.attack_pressed = attack
	return input


## Holds down long enough to fast-fall (the wait, then the tick it starts).
func _hold_down_to_fast_fall() -> void:
	_run(_make_input(true), _stats.fast_fall_delay + 1)


func test_fast_fall_stats() -> void:
	assert_eq(_stats.fast_fall_speed, 400.0)
	assert_eq(_stats.fast_fall_delay, 4)


func test_holding_down_while_falling_fast_falls_after_the_wait() -> void:
	await _start_falling()
	_run(_make_input(true), _stats.fast_fall_delay)
	assert_lt(_fighter.velocity.y, _stats.fast_fall_speed, "still waiting for an A")
	_run(_make_input(true), 1)
	assert_eq(_fighter.velocity.y, _stats.fast_fall_speed)
	_run(_make_input(), 3)
	assert_eq(_fighter.velocity.y, _stats.fast_fall_speed, "letting go doesn't end it")


func test_holding_down_while_rising_waits_until_falling() -> void:
	_fighter.spawn_at(Vector2(110, FLOOR_Y), 1)
	await wait_physics_frames(1)
	_fighter.tick(_make_input())
	var jump := FighterInput.new()
	jump.jump_pressed = true
	jump.jump_held = true
	_run(jump, 1)
	var rise_and_hold := FighterInput.new()
	rise_and_hold.jump_held = true
	rise_and_hold.down_held = true
	_run(rise_and_hold, 3)
	assert_lt(_fighter.velocity.y, 0.0, "still rising normally")
	assert_gt(_fighter.velocity.y, -_stats.jump_velocity, "gravity still slows the rise")
	for i in 60:
		_fighter.tick(rise_and_hold)
		if _fighter.velocity.y >= 0.0:
			break
	_fighter.tick(rise_and_hold)
	assert_eq(_fighter.velocity.y, _stats.fast_fall_speed, "fast-falls once it starts to fall")


func test_landing_ends_the_fast_fall() -> void:
	await _start_falling()
	_hold_down_to_fast_fall()
	for i in 60:
		_fighter.tick(_make_input())
		if _fighter.state != Fighter.State.AIR:
			break
	assert_almost_eq(_fighter.position.y, FLOOR_Y, 0.5)
	# Walk off nothing: jump and check the fall is normal again after the top.
	_run(_make_input(false, true), 1)
	for i in 60:
		_fighter.tick(_make_input())
		if _fighter.velocity.y > 0.0:
			break
	var before := _fighter.velocity.y
	_fighter.tick(_make_input())
	assert_almost_eq(_fighter.velocity.y, before + _stats.gravity / 60.0, 0.001, "normal gravity")


func test_double_jump_ends_the_fast_fall() -> void:
	await _start_falling()
	_hold_down_to_fast_fall()
	_run(_make_input(false, true), 1)
	# The jump tick already has one tick of gravity in it.
	var step := _stats.gravity / 60.0
	assert_almost_eq(_fighter.velocity.y, -_stats.double_jump_velocity + step, 0.001)
	_fighter.tick(_make_input())
	assert_almost_eq(_fighter.velocity.y, -_stats.double_jump_velocity + 2.0 * step, 0.001)


func test_getting_hit_ends_the_fast_fall() -> void:
	await _start_falling()
	_hold_down_to_fast_fall()
	_fighter.take_hit(_stats.moveset.jab, 1, _fighter.global_position.x - 10.0)
	var launched := _fighter.velocity.y
	_fighter.tick(_make_input())
	assert_almost_eq(_fighter.velocity.y, launched + _stats.gravity / 60.0, 0.001)


func test_fast_fall_during_an_air_attack() -> void:
	await _start_falling()
	_hold_down_to_fast_fall()
	_run(_make_input(true, false, true), 1)
	assert_eq(_fighter.move, &"down_air")
	assert_eq(_fighter.velocity.y, _stats.fast_fall_speed, "already fast-falling: it goes on")


# --- Down then A ----------------------------------------------------------------------------------


func _assert_normal_fall() -> void:
	assert_lt(_fighter.velocity.y, _stats.fast_fall_speed, "not a fast fall")


func test_down_and_a_together_is_a_down_air_at_normal_speed() -> void:
	await _start_falling()
	_run(_make_input(true, false, true), 1)
	assert_eq(_fighter.move, &"down_air")
	_run(_make_input(true), 20)
	_assert_normal_fall()


func test_down_then_a_within_the_wait_is_a_down_air_at_normal_speed() -> void:
	await _start_falling()
	_run(_make_input(true), _stats.fast_fall_delay - 1)
	_run(_make_input(true, false, true), 1)
	assert_eq(_fighter.state, Fighter.State.ATTACK)
	assert_eq(_fighter.move, &"down_air")
	_run(_make_input(true), 20)
	_assert_normal_fall()


func test_the_used_down_needs_a_new_press_after_the_move() -> void:
	await _start_falling()
	_run(_make_input(true, false, true), 1)
	for i in 60:
		_fighter.tick(_make_input(true))
		if _fighter.state == Fighter.State.AIR:
			break
	assert_eq(_fighter.state, Fighter.State.AIR, "the down air is over, still in the air")
	_run(_make_input(true), 10)
	_assert_normal_fall()
	_run(_make_input(), 1)
	_hold_down_to_fast_fall()
	assert_eq(_fighter.velocity.y, _stats.fast_fall_speed, "a new press fast-falls")


func test_a_new_down_press_during_an_air_attack_fast_falls() -> void:
	await _start_falling()
	_run(_make_input(false, false, true), 1)
	assert_eq(_fighter.move, &"neutral_air")
	_run(_make_input(true), _stats.fast_fall_delay)
	_assert_normal_fall()
	_run(_make_input(true), 1)
	assert_eq(_fighter.velocity.y, _stats.fast_fall_speed)


func test_dropping_through_a_platform_is_not_a_fast_fall_by_itself() -> void:
	# Stand on the left pass-through platform (x 132–204, top y 150).
	_fighter.spawn_at(Vector2(168, 150), 1)
	await wait_physics_frames(1)
	_fighter.tick(_make_input())
	var tap := _make_input(true)
	tap.down_pressed = true
	_run(tap, 1)
	_run(_make_input(), 1)
	_run(tap, 1)
	assert_eq(_fighter.state, Fighter.State.AIR, "dropped")
	assert_lt(_fighter.velocity.y, _stats.fast_fall_speed, "not fast-falling on the drop tick")
	_run(_make_input(true), _stats.fast_fall_delay - 1)
	assert_lt(_fighter.velocity.y, _stats.fast_fall_speed, "the wait")
	_run(_make_input(true), 1)
	assert_eq(_fighter.velocity.y, _stats.fast_fall_speed, "still holding down: then it fast-falls")


func test_no_fast_fall_while_helpless() -> void:
	await _start_falling()
	_fighter.state = Fighter.State.HELPLESS
	_run(_make_input(true), 1)
	assert_lt(_fighter.velocity.y, _stats.fast_fall_speed)


# --- Cancelling a double jump's rise ---------------------------------------------------------------


## Falling high up, then a double jump; returns once it has risen for `ticks` ticks.
func _double_jump_and_rise(ticks: int) -> void:
	await _start_falling()
	_run(_make_input(false, true), 1)
	_run(_make_input(), ticks)
	assert_lt(_fighter.velocity.y, 0.0, "still rising from the double jump")


func _press_down() -> FighterInput:
	var input := _make_input(true)
	input.down_pressed = true
	return input


func test_pressing_down_cancels_a_double_jumps_rise() -> void:
	await _double_jump_and_rise(5)
	_run(_press_down(), 1)
	_run(_make_input(true), _stats.fast_fall_delay - 1)
	assert_lt(_fighter.velocity.y, 0.0, "still rising during the wait")
	_run(_make_input(true), 1)
	assert_eq(_fighter.velocity.y, _stats.fast_fall_speed, "then falling fast")
	_run(_make_input(), 3)
	assert_eq(_fighter.velocity.y, _stats.fast_fall_speed, "and stays a fast fall")


func test_down_held_since_before_the_double_jump_doesnt_cancel_it() -> void:
	await _start_falling()
	var jump_holding_down := _make_input(true, true)
	_run(jump_holding_down, 1)
	_run(_make_input(true), 3)
	assert_lt(_fighter.velocity.y, 0.0, "the double jump still rises")


func test_pressing_down_doesnt_cancel_a_first_jumps_rise() -> void:
	_fighter.spawn_at(Vector2(110, FLOOR_Y), 1)
	await wait_physics_frames(1)
	_fighter.tick(_make_input())
	_run(_make_input(false, true), 1)
	_run(_make_input(), 3)
	_run(_press_down(), 1)
	assert_lt(_fighter.velocity.y, 0.0, "a first jump still rises")


func test_cancelling_works_during_an_air_attack_too() -> void:
	await _double_jump_and_rise(3)
	_run(_make_input(false, false, true), 1)
	assert_eq(_fighter.state, Fighter.State.ATTACK)
	_run(_press_down(), 1)
	_run(_make_input(true), _stats.fast_fall_delay)
	assert_eq(_fighter.velocity.y, _stats.fast_fall_speed)


func test_down_then_a_after_a_double_jump_keeps_rising_into_the_down_air() -> void:
	await _double_jump_and_rise(3)
	_run(_press_down(), 1)
	_run(_make_input(true, false, true), 1)
	assert_eq(_fighter.move, &"down_air")
	_run(_make_input(true), 6)
	assert_lt(_fighter.velocity.y, 0.0, "the double jump's rise goes on")
