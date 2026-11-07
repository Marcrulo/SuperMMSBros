extends GutTest
## The default specials on one fighter (docs/specs/moves.md#specials-k). Projectiles themselves
## are the Match's (test_projectiles.gd).

const STAGE_SCENE := preload("res://stage/battlefield.tscn")
const FIGHTER_SCENE := preload("res://fighter/fighter.tscn")
const MIDDLE := Vector2(240, 192)
const FLOOR_Y := 192.0
const TOLERANCE := 0.5

var _fighter: Fighter
var _stats: FighterStats
var _moves: MoveSet


func before_each() -> void:
	add_child_autofree(STAGE_SCENE.instantiate())
	_fighter = add_child_autofree(FIGHTER_SCENE.instantiate())
	_stats = _fighter.stats
	_moves = _stats.moveset


func _start(at := MIDDLE, facing := 1) -> void:
	_fighter.spawn_at(at, facing)
	await wait_physics_frames(1)
	_fighter.tick(FighterInput.new())


func _run(input: FighterInput, ticks: int) -> void:
	for i in ticks:
		_fighter.tick(input)


func _special(move_x := 0.0, up := false, down := false, pressed := true) -> FighterInput:
	var input := FighterInput.new()
	input.special_pressed = pressed
	input.special_held = true
	input.move_x = move_x
	input.up_held = up
	input.down_held = down
	return input


func _hold_special() -> FighterInput:
	return _special(0.0, false, false, false)


func _idle() -> FighterInput:
	return FighterInput.new()


func _jump_up(ticks: int) -> void:
	var jump := FighterInput.new()
	jump.jump_pressed = true
	jump.jump_held = true
	_run(jump, 1)
	var hold := FighterInput.new()
	hold.jump_held = true
	_run(hold, ticks)


func test_direction_picks_the_special() -> void:
	var cases := [[_special(), &"neutral_special_charge"], [_special(0.0, true), &"up_special"], [_special(0.0, false, true), &"down_special"], [_special(1.0), &"side_special"]]
	for case: Array in cases:
		await _start()
		_run(case[0], 1)
		assert_eq(_fighter.state, Fighter.State.ATTACK)
		assert_eq(_fighter.move, case[1])


# --- Neutral: charged punch -----------------------------------------------------------------------


func test_charge_then_release_punches_with_scaled_power() -> void:
	await _start()
	_run(_special(), 1)
	_run(_hold_special(), 29)
	assert_eq(_fighter.move, &"neutral_special_charge")
	_run(_idle(), 1)
	assert_eq(_fighter.move, &"neutral_special")
	assert_eq(_fighter.state_frame, 1)
	var punch := _fighter.current_move()
	assert_almost_eq(punch.damage, 8.0 + 14.0 * 0.5, 0.001, "half charge")
	assert_almost_eq(punch.base_knockback, 200.0 + 200.0 * 0.5, 0.001)
	_run(_idle(), 3)
	assert_true(_fighter.is_hitbox_active(), "frame 4: active")


func test_full_charge_releases_by_itself() -> void:
	await _start()
	_run(_special(), 1)
	_run(_hold_special(), 60)
	assert_eq(_fighter.move, &"neutral_special")
	assert_almost_eq(_fighter.current_move().damage, 22.0, 0.001)


func test_hit_while_charging_loses_the_charge() -> void:
	await _start()
	_run(_special(), 1)
	_run(_hold_special(), 20)
	_fighter.take_hit(_moves.jab, -1, MIDDLE.x + 10.0)
	assert_eq(_fighter.state, Fighter.State.HITSTUN)
	assert_eq(_fighter.move, &"")


# --- Down: energy burst ---------------------------------------------------------------------------


func test_ground_burst_is_active_on_frames_11_to_16() -> void:
	await _start()
	_run(_special(0.0, false, true), 1)
	var active: Array[int] = []
	for i in _moves.down_special.total_frames():
		if _fighter.is_hitbox_active():
			active.append(_fighter.state_frame)
		_fighter.tick(_idle())
	assert_eq(active, [11, 12, 13, 14, 15, 16] as Array[int])


func test_air_down_special_dives_then_bursts() -> void:
	await _start()
	_jump_up(10)
	_run(_special(0.0, false, true), 1)
	assert_eq(_fighter.move, &"down_special_dive")
	assert_eq(_fighter.velocity, Vector2(0, _moves.down_special.dive_speed))
	for i in 60:
		_fighter.tick(_idle())
		if _fighter.move != &"down_special_dive":
			break
	assert_eq(_fighter.move, &"down_special", "landed into the burst")
	assert_almost_eq(_fighter.position.y, FLOOR_Y, TOLERANCE)
	assert_eq(_fighter.state_frame, 1)


# --- Side: projectile -----------------------------------------------------------------------------


func test_side_special_asks_for_a_projectile_on_frame_10() -> void:
	await _start()
	_run(_special(-1.0), 1)
	assert_eq(_fighter.facing, -1, "turned on the ground")
	var asked: Array[int] = []
	for i in _moves.side_special.total_frames():
		if _fighter.wants_projectile():
			asked.append(_fighter.state_frame)
		_fighter.tick(_idle())
	assert_eq(asked, [10] as Array[int])


func test_side_special_in_the_air_turns_toward_the_held_side() -> void:
	await _start(MIDDLE, 1)
	_jump_up(5)
	assert_eq(_fighter.state, Fighter.State.AIR)
	_run(_special(-1.0), 1)
	assert_eq(_fighter.move, &"side_special")
	assert_eq(_fighter.facing, -1, "turned around in the air")


func test_other_air_moves_still_keep_the_facing() -> void:
	await _start(MIDDLE, 1)
	_jump_up(5)
	var attack := FighterInput.new()
	attack.attack_pressed = true
	attack.move_x = -1.0
	_run(attack, 1)
	assert_eq(_fighter.move, &"back_air")
	assert_eq(_fighter.facing, 1)


func test_side_special_waits_for_the_last_projectile() -> void:
	await _start()
	_fighter.has_projectile = true
	_run(_special(1.0), 1)
	assert_ne(_fighter.state, Fighter.State.ATTACK, "nothing happens")


# --- Up: jump boost -------------------------------------------------------------------------------


func test_up_special_launches_on_frame_5_then_goes_helpless() -> void:
	await _start()
	_run(_special(1.0, true), 1)
	_run(_special(1.0, true, false, false), 3)
	assert_almost_eq(_fighter.position.y, FLOOR_Y, TOLERANCE, "startup: still on the ground")
	_run(_special(1.0, true, false, false), 1)
	assert_eq(_fighter.state_frame, 5)
	assert_lt(_fighter.velocity.y, -300.0, "launched")
	assert_true(_fighter.is_hitbox_active())
	for i in 120:
		_fighter.tick(_idle())
		if _fighter.state != Fighter.State.ATTACK:
			break
	assert_eq(_fighter.state, Fighter.State.HELPLESS)
	assert_gte(_fighter.velocity.y, 0.0)


func test_helpless_cannot_act_and_steers_slowly() -> void:
	await _start()
	_run(_special(0.0, true), 1)
	for i in 120:
		_fighter.tick(_idle())
		if _fighter.state == Fighter.State.HELPLESS:
			break
	var input := _special(1.0)
	input.attack_pressed = true
	input.jump_pressed = true
	_run(input, 20)
	assert_eq(_fighter.state, Fighter.State.HELPLESS)
	assert_lte(_fighter.velocity.x, _stats.helpless_air_speed)
	for i in 120:
		_fighter.tick(_idle())
		if _fighter.state != Fighter.State.HELPLESS:
			break
	assert_eq(_fighter.state, Fighter.State.IDLE, "landed")


func test_up_special_once_per_air_time() -> void:
	await _start()
	_jump_up(5)
	_run(_special(0.0, true), 1)
	assert_eq(_fighter.move, &"up_special")
	assert_false(_fighter.up_special_available)
	_fighter.take_hit(_moves.jab, 1, MIDDLE.x - 10.0)
	assert_true(_fighter.up_special_available, "restored by a hit")
	_fighter.up_special_available = false
	_fighter.state = Fighter.State.AIR
	_run(_special(0.0, true), 1)
	assert_eq(_fighter.state, Fighter.State.AIR, "not again in the same air time")
	for i in 120:
		_fighter.tick(_idle())
		if _fighter.state != Fighter.State.AIR:
			break
	assert_true(_fighter.up_special_available, "restored by landing")
