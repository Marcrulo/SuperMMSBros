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
