extends GutTest
## Spot dodge, roll and air dodge (docs/specs/fighter.md#dodges).

const STAGE_SCENE := preload("res://stage/battlefield.tscn")
const FIGHTER_SCENE := preload("res://fighter/fighter.tscn")
const MIDDLE := Vector2(240, 192)
## The main platform's right edge.
const RIGHT_EDGE := 384.0

var _fighter: Fighter
var _stats: FighterStats


func before_each() -> void:
	add_child_autofree(STAGE_SCENE.instantiate())
	_fighter = add_child_autofree(FIGHTER_SCENE.instantiate())
	_stats = _fighter.stats


func _start(at := MIDDLE, facing := 1) -> void:
	_fighter.spawn_at(at, facing)
	await wait_physics_frames(1)
	_fighter.tick(FighterInput.new())


func _run(input: FighterInput, ticks: int) -> void:
	for i in ticks:
		_fighter.tick(input)


func _shield(side_pressed := 0, down_pressed := false) -> FighterInput:
	var input := FighterInput.new()
	input.shield_held = true
	input.side_pressed = side_pressed
	input.move_x = float(side_pressed)
	input.down_pressed = down_pressed
	input.down_held = down_pressed
	return input


func _idle() -> FighterInput:
	return FighterInput.new()


func _air_dodge(move_x := 0.0, up := false, down := false) -> FighterInput:
	var input := FighterInput.new()
	input.shield_pressed = true
	input.shield_held = true
	input.move_x = move_x
	input.up_held = up
	input.down_held = down
	return input


func _jump_into_the_air() -> void:
	var jump := FighterInput.new()
	jump.jump_pressed = true
	jump.jump_held = true
	_run(jump, 1)
	var hold := FighterInput.new()
	hold.jump_held = true
	_run(hold, 3)
	assert_eq(_fighter.state, Fighter.State.AIR)


# --- Spot dodge -------------------------------------------------------------------------------------


func test_down_in_shield_spot_dodges_in_place() -> void:
	await _start()
	_run(_shield(), 3)
	_run(_shield(0, true), 1)
	assert_eq(_fighter.state, Fighter.State.SPOT_DODGE)
	var x := _fighter.position.x
	var still := _shield()
	still.down_held = true
	_run(still, _stats.spot_dodge_frames - 1)
	assert_eq(_fighter.state, Fighter.State.SPOT_DODGE)
	assert_almost_eq(_fighter.position.x, x, 0.01, "stays in place")
	_run(_idle(), 1)
	assert_eq(_fighter.state, Fighter.State.IDLE)


func test_spot_dodge_is_intangible_in_the_middle() -> void:
	await _start()
	_run(_shield(0, true), 1)
	assert_eq(_fighter.state, Fighter.State.SPOT_DODGE, "straight from the ground with shield + down")
	for frame in range(1, _stats.spot_dodge_frames + 1):
		var expected := frame >= _stats.spot_dodge_intangible_start \
				and frame <= _stats.spot_dodge_intangible_end
		assert_eq(_fighter.state_frame, frame)
		assert_eq(_fighter.is_intangible(), expected, "frame %d" % frame)
		assert_eq(_fighter.can_be_hit(), not expected, "frame %d" % frame)
		_run(_idle(), 1)


func test_still_holding_shield_after_a_dodge_shields_again() -> void:
	await _start()
	_run(_shield(0, true), 1)
	_run(_shield(), _stats.spot_dodge_frames)
	assert_eq(_fighter.state, Fighter.State.SHIELD)


func test_no_dodge_during_block_stun() -> void:
	await _start()
	_run(_shield(), 1)
	_fighter.block_hit(_stats.moveset.side_tilt, 1)
	_run(_shield(0, true), 1)
	assert_eq(_fighter.state, Fighter.State.SHIELD)
	_run(_shield(1), 1)
	assert_eq(_fighter.state, Fighter.State.SHIELD)


# --- Roll -------------------------------------------------------------------------------------------


func test_side_in_shield_rolls_and_ends_facing_back() -> void:
	await _start(MIDDLE, 1)
	_run(_shield(), 3)
	_run(_shield(1), 1)
	assert_eq(_fighter.state, Fighter.State.ROLL)
	_run(_idle(), _stats.roll_frames - 1)
	assert_eq(_fighter.state, Fighter.State.ROLL)
	var distance := _fighter.position.x - MIDDLE.x
	assert_almost_eq(distance, _stats.roll_speed * _stats.roll_frames / 60.0, 2.0, "rolled right")
	_run(_idle(), 1)
	assert_eq(_fighter.state, Fighter.State.IDLE)
	assert_eq(_fighter.facing, -1, "faces away from the roll")
	assert_eq(_fighter.velocity.x, 0.0, "stops when the roll ends")


func test_roll_is_intangible_in_the_middle() -> void:
	await _start()
	_run(_shield(1), 1)
	assert_eq(_fighter.state, Fighter.State.ROLL, "straight from the ground with shield + side")
	for frame in range(1, _stats.roll_frames + 1):
		var expected := frame >= _stats.roll_intangible_start and frame <= _stats.roll_intangible_end
		assert_eq(_fighter.is_intangible(), expected, "frame %d" % frame)
		_run(_idle(), 1)


func test_holding_a_side_while_shielding_does_not_roll() -> void:
	await _start()
	var held := _shield()
	held.move_x = 1.0
	_run(held, 10)
	assert_eq(_fighter.state, Fighter.State.SHIELD)


func test_roll_stops_at_the_edge() -> void:
	await _start(Vector2(RIGHT_EDGE - 12, 192), -1)
	_run(_shield(1), 1)
	_run(_idle(), _stats.roll_frames + 5)
	assert_true(_fighter.is_on_floor(), "still on the stage")
	assert_eq(_fighter.state, Fighter.State.IDLE)
	assert_lte(_fighter.position.x, RIGHT_EDGE + 8.0, "not past the edge")
	assert_gt(_fighter.position.x, RIGHT_EDGE - 10.0, "rolled up to it")


# --- Air dodge --------------------------------------------------------------------------------------


func test_shield_in_the_air_air_dodges() -> void:
	await _start()
	_jump_into_the_air()
	_run(_air_dodge(), 1)
	assert_eq(_fighter.state, Fighter.State.AIR_DODGE)
	for frame in range(2, _stats.air_dodge_frames + 1):
		_run(_idle(), 1)
		var expected := frame >= _stats.air_dodge_intangible_start \
				and frame <= _stats.air_dodge_intangible_end
		assert_eq(_fighter.is_intangible(), expected, "frame %d" % frame)
	_run(_idle(), 1)
	assert_eq(_fighter.state, Fighter.State.AIR)


func test_directional_air_dodge_bursts_that_way_without_gravity() -> void:
	await _start()
	_jump_into_the_air()
	_run(_air_dodge(1.0, true), 1)
	var expected := Vector2(1, -1).normalized() * _stats.air_dodge_speed
	expected = expected.move_toward(Vector2.ZERO, _stats.air_dodge_friction / 60.0)
	assert_almost_eq(_fighter.velocity.x, expected.x, 0.01)
	assert_almost_eq(_fighter.velocity.y, expected.y, 0.01)
	_run(_idle(), 5)
	assert_lt(_fighter.velocity.y, 0.0, "no gravity: still moving up")
	assert_almost_eq(_fighter.velocity.length(), _stats.air_dodge_speed - 6 * _stats.air_dodge_friction / 60.0, 0.01)


func test_one_air_dodge_per_air_stay() -> void:
	await _start()
	_jump_into_the_air()
	_run(_air_dodge(), 1)
	_run(_idle(), _stats.air_dodge_frames)
	assert_eq(_fighter.state, Fighter.State.AIR)
	_run(_air_dodge(), 1)
	assert_eq(_fighter.state, Fighter.State.AIR, "used up")
	assert_false(_fighter.air_dodge_available)
	_run(_idle(), 120)
	assert_true(_fighter.is_on_floor())
	assert_true(_fighter.air_dodge_available, "restored on landing")


func test_air_dodge_still_allows_the_double_jump() -> void:
	await _start()
	_jump_into_the_air()
	_run(_air_dodge(), 1)
	_run(_idle(), _stats.air_dodge_frames)
	var jump := FighterInput.new()
	jump.jump_pressed = true
	_run(jump, 1)
	assert_almost_eq(_fighter.velocity.y, -_stats.double_jump_velocity + _stats.gravity / 60.0, 0.01)


func test_neutral_air_dodge_stops_in_place() -> void:
	await _start()
	_jump_into_the_air()
	_run(_air_dodge(), 1)
	assert_eq(_fighter.velocity, Vector2.ZERO)
	var y := _fighter.position.y
	_run(_idle(), 10)
	assert_eq(_fighter.position.y, y, "hangs in the air")


func test_landing_ends_the_air_dodge() -> void:
	await _start()
	_jump_into_the_air()
	_run(_air_dodge(0.0, false, true), 1)
	assert_eq(_fighter.state, Fighter.State.AIR_DODGE)
	_run(_idle(), 15)
	assert_true(_fighter.is_on_floor())
	assert_ne(_fighter.state, Fighter.State.AIR_DODGE)


func test_being_hit_restores_the_air_dodge() -> void:
	await _start()
	_jump_into_the_air()
	_run(_air_dodge(), 1)
	_run(_idle(), _stats.air_dodge_frames)
	_fighter.take_hit(_stats.moveset.jab, 1, 0.0)
	assert_true(_fighter.air_dodge_available)
