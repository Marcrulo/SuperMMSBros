extends GutTest
## Fighter movement on the Battlefield (docs/specs/fighter.md#movement-rules).
## Every test begins with `await _start_at(...)`: waiting one physics frame registers the stage's
## colliders and resumes the test inside a physics frame, where Fighter.tick() may run.

const STAGE_SCENE := preload("res://stage/battlefield.tscn")
const FIGHTER_SCENE := preload("res://fighter/fighter.tscn")
const FLOOR_Y := 128.0
const PLATFORM_Y := 96.0
## A spot on the main platform with open sky above: no pass-through platform to land on.
const OPEN_SKY := Vector2(76, 128)
## Right below the left pass-through platform.
const UNDER_LEFT_PLATFORM := Vector2(112, 128)
## move_and_slide() keeps a tiny gap (the collision "safe margin") between body and floor.
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


func _run(input: FighterInput, ticks: int) -> void:
	for i in ticks:
		_fighter.tick(input)


func _idle() -> FighterInput:
	return FighterInput.new()


func _move(move_x: float) -> FighterInput:
	var input := FighterInput.new()
	input.move_x = move_x
	return input


# --- Ground -----------------------------------------------------------------------------------


func test_scene_setup() -> void:
	assert_eq(_fighter.collision_layer, 1 << 2, "body only on layer 3 (fighter)")
	assert_true(_fighter.get_collision_mask_value(1), "collides with stage_solid")
	assert_true(_fighter.get_collision_mask_value(2), "collides with stage_platform")
	assert_false(_fighter.get_collision_mask_value(3), "fighters don't collide with each other")
	var shape := _fighter.get_node("BodyShape") as CollisionShape2D
	assert_eq((shape.shape as RectangleShape2D).size, Vector2(16, 24))
	assert_eq(shape.position, Vector2(0, -12))
	assert_eq(_stats.resource_path, "res://fighter/default_stats.tres")


func test_spawn_at_resets_the_fighter() -> void:
	_fighter.velocity = Vector2(50, 50)
	_fighter.jumps_left = 0
	_fighter.spawn_at(Vector2(208, 128), -1)
	assert_eq(_fighter.position, Vector2(208, 128))
	assert_eq(_fighter.facing, -1)
	assert_eq(_fighter.velocity, Vector2.ZERO)
	assert_eq(_fighter.state, Fighter.State.IDLE)
	assert_eq(_fighter.state_frame, 0)
	assert_eq(_fighter.jumps_left, _stats.max_air_jumps)


func test_stands_on_the_main_platform() -> void:
	await _start_at(UNDER_LEFT_PLATFORM)
	_run(_idle(), 30)
	assert_eq(_fighter.state, Fighter.State.IDLE)
	assert_true(_fighter.is_on_floor())
	assert_almost_eq(_fighter.position.y, FLOOR_Y, TOLERANCE)
	assert_eq(_fighter.position.x, UNDER_LEFT_PLATFORM.x)


func test_runs_up_to_run_speed() -> void:
	await _start_at(UNDER_LEFT_PLATFORM)
	_run(_move(1.0), 1)
	assert_almost_eq(_fighter.velocity.x, _stats.ground_accel / 60.0, 0.001, "one tick of accel")
	_run(_move(1.0), 10)
	assert_eq(_fighter.velocity.x, _stats.run_speed)
	assert_eq(_fighter.state, Fighter.State.RUN)
	assert_eq(_fighter.facing, 1)


func test_friction_stops_the_fighter() -> void:
	await _start_at(UNDER_LEFT_PLATFORM)
	_run(_move(1.0), 10)
	_run(_idle(), 1)
	assert_almost_eq(_fighter.velocity.x, _stats.run_speed - _stats.ground_friction / 60.0, 0.001)
	_run(_idle(), 10)
	assert_eq(_fighter.velocity.x, 0.0)
	assert_eq(_fighter.state, Fighter.State.IDLE)


func test_turns_to_face_the_direction_held_on_the_ground() -> void:
	await _start_at(UNDER_LEFT_PLATFORM, 1)
	_run(_move(-1.0), 1)
	assert_eq(_fighter.facing, -1)
	_run(_move(1.0), 1)
	assert_eq(_fighter.facing, 1)


func test_state_frame_counts_ticks_in_the_current_state() -> void:
	await _start_at(UNDER_LEFT_PLATFORM)
	_run(_idle(), 2)
	assert_eq(_fighter.state_frame, 2, "2 ticks in IDLE")
	_run(_move(1.0), 1)
	assert_eq(_fighter.state, Fighter.State.RUN)
	assert_eq(_fighter.state_frame, 1, "1 on the tick RUN is entered")
	_run(_move(1.0), 2)
	assert_eq(_fighter.state_frame, 3)
	_run(_idle(), 1)
	assert_eq(_fighter.state, Fighter.State.IDLE)
	assert_eq(_fighter.state_frame, 1)


# --- Jumps ------------------------------------------------------------------------------------


func test_jump_leaves_the_ground() -> void:
	await _start_at(OPEN_SKY)
	_run(_jump(), 1)
	assert_eq(_fighter.state, Fighter.State.AIR)
	assert_lt(_fighter.velocity.y, 0.0, "moving up")
	assert_eq(_fighter.jumps_left, _stats.max_air_jumps, "a ground jump doesn't use the double jump")


func test_ground_jump_rises_about_48_px() -> void:
	await _start_at(OPEN_SKY)
	assert_almost_eq(_jump_height(60), 48.0, 3.0)
	assert_eq(_fighter.state, Fighter.State.IDLE, "landed again")
	assert_almost_eq(_fighter.position.y, FLOOR_Y, TOLERANCE)


func test_short_hop_is_lower_than_a_full_jump() -> void:
	await _start_at(OPEN_SKY)
	var full := _jump_height(60)
	var short := _jump_height(0)
	assert_lt(short, full * 0.5, "short hop (%.1f px) vs full jump (%.1f px)" % [short, full])
	assert_gt(short, 8.0)


func test_double_jump_rises_about_40_px() -> void:
	await _start_at(OPEN_SKY)
	_run(_jump(), 1)
	_run_until_falling(_hold_jump())
	var start_y := _fighter.position.y
	_run(_jump(), 1)
	var highest := _run_until_falling(_hold_jump())
	assert_almost_eq(start_y - highest, 40.0, 3.0)
	assert_eq(_fighter.jumps_left, 0)


func test_only_one_double_jump() -> void:
	await _start_at(OPEN_SKY)
	_run(_jump(), 1)
	_run(_idle(), 1)
	_run(_jump(), 1)
	assert_eq(_fighter.jumps_left, 0)
	_run(_idle(), 1)
	var speed_before := _fighter.velocity.y
	_run(_jump(), 1)
	assert_gt(_fighter.velocity.y, speed_before, "no upward kick: gravity keeps pulling")
	assert_eq(_fighter.jumps_left, 0)


func test_landing_restores_the_double_jump() -> void:
	await _start_at(OPEN_SKY)
	_run(_jump(), 1)
	_run(_idle(), 1)
	_run(_jump(), 1)
	_run_until_landed(_idle())
	assert_eq(_fighter.state, Fighter.State.IDLE)
	assert_eq(_fighter.jumps_left, _stats.max_air_jumps)


func test_walking_off_a_ledge_keeps_the_double_jump() -> void:
	await _start_at(Vector2(244, 128))
	for i in 60:
		_fighter.tick(_move(1.0))
		if _fighter.state == Fighter.State.AIR:
			break
	assert_eq(_fighter.state, Fighter.State.AIR, "walked off the right edge")
	assert_eq(_fighter.jumps_left, _stats.max_air_jumps)
	_run(_jump(), 1)
	assert_lt(_fighter.velocity.y, 0.0, "double jump works")
	assert_eq(_fighter.jumps_left, 0)


func test_facing_does_not_change_in_the_air() -> void:
	await _start_at(Vector2(160, 128), 1)
	_run(_jump(), 1)
	_run(_move(-1.0), 10)
	assert_eq(_fighter.state, Fighter.State.AIR)
	assert_eq(_fighter.facing, 1, "still facing right while drifting left")
	_run_until_landed(_idle())
	_run(_move(-1.0), 1)
	assert_eq(_fighter.facing, -1, "turns once back on the ground")


## The tick jump goes down (it's also held).
func _jump() -> FighterInput:
	var input := FighterInput.new()
	input.jump_pressed = true
	input.jump_held = true
	return input


func _hold_jump() -> FighterInput:
	var input := FighterInput.new()
	input.jump_held = true
	return input


## Ticks with `input` until the fighter is back on the ground (at most 2 seconds).
func _run_until_landed(input: FighterInput) -> void:
	for i in 120:
		_fighter.tick(input)
		if _fighter.state != Fighter.State.AIR:
			return


## Ticks with `input` until the fighter stops rising; returns the highest y reached.
func _run_until_falling(input: FighterInput) -> float:
	var highest := _fighter.position.y
	for i in 120:
		_fighter.tick(input)
		highest = minf(highest, _fighter.position.y)
		if _fighter.velocity.y >= 0.0:
			break
	return highest


## Presses jump, keeps holding it for `hold_ticks` more ticks, then lets go and waits for the
## landing. Returns how many pixels the feet rose.
func _jump_height(hold_ticks: int) -> float:
	var start_y := _fighter.position.y
	var highest := start_y
	_fighter.tick(_jump())
	for i in 120:
		highest = minf(highest, _fighter.position.y)
		if _fighter.state != Fighter.State.AIR:
			break
		_fighter.tick(_hold_jump() if i < hold_ticks else _idle())
	return start_y - highest


# --- Pass-through platforms -------------------------------------------------------------------


func test_jumps_up_through_a_platform_and_lands_on_it() -> void:
	await _land_on_left_platform()
	assert_eq(_fighter.state, Fighter.State.IDLE)
	assert_true(_fighter.is_on_floor())
	assert_almost_eq(_fighter.position.y, PLATFORM_Y, TOLERANCE)


func test_down_drops_through_a_platform() -> void:
	await _land_on_left_platform()
	_run(_down(), 1)
	assert_eq(_fighter.state, Fighter.State.AIR)
	assert_false(_fighter.get_collision_mask_value(2), "ignoring pass-through platforms")
	_run_until_landed(_idle())
	assert_eq(_fighter.state, Fighter.State.IDLE)
	assert_almost_eq(_fighter.position.y, FLOOR_Y, TOLERANCE, "landed on the main platform")
	assert_true(_fighter.get_collision_mask_value(2), "pass-through platforms are solid again")


func test_platforms_are_ignored_for_drop_through_frames_ticks() -> void:
	await _land_on_left_platform()
	_run(_down(), 1)
	_run(_idle(), _stats.drop_through_frames - 2)
	assert_false(_fighter.get_collision_mask_value(2), "still ignored after %d ticks" % (_stats.drop_through_frames - 1))
	_run(_idle(), 1)
	assert_true(_fighter.get_collision_mask_value(2), "solid again after %d ticks" % _stats.drop_through_frames)


func test_down_on_the_main_platform_does_nothing() -> void:
	await _start_at(Vector2(160, 128))
	_run(_idle(), 1)
	_run(_down(), 1)
	assert_eq(_fighter.state, Fighter.State.IDLE)
	assert_true(_fighter.get_collision_mask_value(2))
	assert_almost_eq(_fighter.position.y, FLOOR_Y, TOLERANCE)


func test_holding_down_while_falling_passes_through_a_platform() -> void:
	await _land_on_left_platform()
	_run(_jump(), 1)
	_run_until_falling(_hold_jump())
	_run_until_landed(_hold_down())
	assert_eq(_fighter.state, Fighter.State.IDLE)
	assert_almost_eq(_fighter.position.y, FLOOR_Y, TOLERANCE, "fell past the platform to the main one")
	assert_true(_fighter.get_collision_mask_value(2), "pass-through platforms are solid again")


func test_letting_go_of_down_in_the_air_lands_on_the_platform() -> void:
	await _land_on_left_platform()
	_run(_jump(), 1)
	_run(_hold_down(), 5)
	assert_false(_fighter.get_collision_mask_value(2), "ignoring pass-through platforms while down is held")
	_run_until_landed(_idle())
	assert_almost_eq(_fighter.position.y, PLATFORM_Y, TOLERANCE, "caught by the platform again")


func test_holding_down_on_a_platform_does_not_drop() -> void:
	await _land_on_left_platform()
	_run(_hold_down(), 10)
	assert_eq(_fighter.state, Fighter.State.IDLE, "dropping needs a press, not a hold")
	assert_almost_eq(_fighter.position.y, PLATFORM_Y, TOLERANCE)


## Down held, but not pressed this tick.
func _hold_down() -> FighterInput:
	var input := FighterInput.new()
	input.down_held = true
	return input


func _down() -> FighterInput:
	var input := FighterInput.new()
	input.down_pressed = true
	return input


func _land_on_left_platform() -> void:
	await _start_at(UNDER_LEFT_PLATFORM)
	_run(_jump(), 1)
	_run_until_landed(_hold_jump())
