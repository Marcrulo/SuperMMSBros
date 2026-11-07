extends GutTest
## Normal attacks, getting hit and damage % on one fighter (docs/specs/moves.md,
## docs/specs/fighter.md#getting-hit). Every test begins with `await _start_at(...)`, which waits
## one physics frame so the stage's colliders exist, then ticks once so the fighter stands.

const STAGE_SCENE := preload("res://stage/battlefield.tscn")
const FIGHTER_SCENE := preload("res://fighter/fighter.tscn")
const FLOOR_Y := 192.0
## On the main platform, no pass-through platform within jump reach.
const MIDDLE := Vector2(240, 192)
const OPEN_SKY := Vector2(110, 192)
const TOLERANCE := 0.5

var _fighter: Fighter
var _stats: FighterStats
var _moves: MoveSet


func before_each() -> void:
	add_child_autofree(STAGE_SCENE.instantiate())
	_fighter = add_child_autofree(FIGHTER_SCENE.instantiate())
	_stats = _fighter.stats
	_moves = _stats.moveset


func _start_at(at: Vector2, facing: int = 1) -> void:
	_fighter.spawn_at(at, facing)
	await wait_physics_frames(1)
	_fighter.tick(_make_input())


func _run(input: FighterInput, ticks: int) -> void:
	for i in ticks:
		_fighter.tick(input)


func _make_input(move_x: float = 0.0, attack := false, jump := false, up := false, down := false) -> FighterInput:
	var input := FighterInput.new()
	input.move_x = move_x
	input.attack_pressed = attack
	input.jump_pressed = jump
	input.jump_held = jump
	input.up_held = up
	input.down_held = down
	return input


func _attack(move_x: float = 0.0, up := false, down := false) -> FighterInput:
	return _make_input(move_x, true, false, up, down)


func _hold_jump() -> FighterInput:
	var input := FighterInput.new()
	input.jump_held = true
	return input


# --- Picking a move -------------------------------------------------------------------------------


func test_direction_picks_the_move() -> void:
	var cases := [[_attack(), &"jab"], [_attack(0.0, true), &"up_tilt"], [_attack(0.0, false, true), &"down_tilt"], [_attack(1.0), &"side_tilt"], [_attack(1.0, true, true), &"up_tilt"]]
	for case: Array in cases:
		await _start_at(MIDDLE)
		_run(case[0], 1)
		assert_eq(_fighter.state, Fighter.State.ATTACK)
		assert_eq(_fighter.move, case[1])


## Jumps from the open sky and rises a few ticks: in the air, well above the floor.
func _start_in_the_air(facing: int = 1) -> void:
	await _start_at(OPEN_SKY, facing)
	_run(_make_input(0.0, false, true), 1)
	_run(_hold_jump(), 5)
	assert_eq(_fighter.state, Fighter.State.AIR)


func test_air_direction_picks_the_aerial() -> void:
	var cases := [[_attack(), &"neutral_air"], [_attack(0.0, true), &"up_air"],
			[_attack(0.0, false, true), &"down_air"], [_attack(1.0), &"forward_air"],
			[_attack(-1.0), &"back_air"], [_attack(-1.0, true), &"up_air"]]
	for case: Array in cases:
		await _start_in_the_air(1)
		_run(case[0], 1)
		assert_eq(_fighter.state, Fighter.State.ATTACK)
		assert_eq(_fighter.move, case[1])
		assert_eq(_fighter.facing, 1, "no turning in the air")


func test_back_air_hits_behind_and_launches_backward() -> void:
	await _start_in_the_air(1)
	_run(_attack(-1.0), 1)
	assert_lt(_fighter.get_hitbox_rect().get_center().x, _fighter.global_position.x, "behind")
	var behind := _fighter.get_center() + Vector2(-16, 0)
	assert_eq(_fighter.knockback_side(_moves.back_air, behind), -1)


func test_side_tilt_on_the_ground_turns_first() -> void:
	await _start_at(MIDDLE, 1)
	_run(_attack(-1.0), 1)
	assert_eq(_fighter.move, &"side_tilt")
	assert_eq(_fighter.facing, -1)


func test_attack_wins_over_jump() -> void:
	await _start_at(MIDDLE)
	_run(_make_input(0.0, true, true), 1)
	assert_eq(_fighter.state, Fighter.State.ATTACK)
	assert_almost_eq(_fighter.position.y, FLOOR_Y, TOLERANCE, "didn't jump")


# --- During a move --------------------------------------------------------------------------------


func test_hitbox_is_active_exactly_on_each_moves_active_frames() -> void:
	var inputs := {&"jab": _attack(), &"up_tilt": _attack(0.0, true), &"down_tilt": _attack(0.0, false, true), &"side_tilt": _attack(1.0)}
	for name: StringName in inputs:
		await _start_at(MIDDLE)
		var data := _moves.get(name) as MoveData
		var active_frames: Array[int] = []
		_fighter.tick(inputs[name])
		for i in data.total_frames():
			if _fighter.is_hitbox_active():
				active_frames.append(_fighter.state_frame)
			_fighter.tick(_make_input())
		var expected: Array[int] = []
		for frame in range(data.startup + 1, data.startup + data.active + 1):
			expected.append(frame)
		assert_eq(active_frames, expected, String(name))


func test_move_lasts_its_total_frames_then_can_act() -> void:
	await _start_at(MIDDLE)
	_run(_attack(), 1)
	_run(_make_input(), _moves.jab.total_frames() - 1)
	assert_eq(_fighter.state, Fighter.State.ATTACK)
	assert_eq(_fighter.state_frame, _moves.jab.total_frames())
	_run(_make_input(0.0, false, true), 1)
	assert_eq(_fighter.state, Fighter.State.AIR, "the jump on the next tick isn't lost")


func test_cannot_act_or_turn_during_a_move() -> void:
	await _start_at(MIDDLE, 1)
	_run(_attack(), 1)
	_run(_make_input(-1.0, true, true), 5)
	assert_eq(_fighter.state_frame, 6, "pressing attack again doesn't restart it")
	assert_eq(_fighter.facing, 1)
	assert_almost_eq(_fighter.position.y, FLOOR_Y, TOLERANCE)


func test_ground_move_does_not_steer() -> void:
	await _start_at(MIDDLE)
	_run(_make_input(1.0), 10)
	_run(_attack(), 1)
	assert_almost_eq(_fighter.velocity.x, _stats.run_speed - _stats.ground_friction / 60.0, 0.001)


func test_air_move_steers_and_ends_on_landing() -> void:
	await _start_at(OPEN_SKY)
	_run(_make_input(0.0, false, true), 1)
	# A full jump (jump held), attacking past its top (about 24 ticks up), so it lands during the
	# forward air.
	_run(_hold_jump(), 38)
	_run(_attack(1.0), 1)
	assert_eq(_fighter.state, Fighter.State.ATTACK)
	assert_eq(_fighter.facing, 1, "no turning in the air")
	assert_gt(_fighter.velocity.x, 0.0, "air steering")
	var ticks := 1
	while _fighter.state == Fighter.State.ATTACK and ticks < 40:
		_fighter.tick(_make_input())
		ticks += 1
	assert_ne(_fighter.state, Fighter.State.AIR)
	assert_eq(_fighter.move, &"", "the forward air ended")
	assert_lt(ticks, _moves.forward_air.total_frames(), "landed out of it early")
	assert_almost_eq(_fighter.position.y, FLOOR_Y, TOLERANCE)


func test_hitbox_rect_mirrors_with_facing() -> void:
	await _start_at(MIDDLE, 1)
	_run(_attack(), 1)
	assert_eq(_fighter.get_hitbox_rect(), Rect2(MIDDLE + Vector2(8, -18), Vector2(14, 10)))
	await _start_at(MIDDLE, -1)
	_run(_attack(), 1)
	assert_eq(_fighter.get_hitbox_rect(), Rect2(MIDDLE + Vector2(-22, -18), Vector2(14, 10)))


func test_a_new_move_forgets_who_it_hit() -> void:
	await _start_at(MIDDLE)
	_run(_attack(), 1)
	_fighter.register_hit(1)
	assert_true(_fighter.has_hit(1))
	_run(_make_input(), 18)
	_run(_attack(), 1)
	assert_false(_fighter.has_hit(1))


# --- Getting hit ----------------------------------------------------------------------------------


func test_knockback_uses_percent_after_damage() -> void:
	await _start_at(MIDDLE)
	_fighter.take_hit(_moves.jab, 1, MIDDLE.x - 10.0)
	assert_eq(_fighter.percent, 3.0)
	var speed := 120.0 + 0.8 * 3.0
	assert_almost_eq(_fighter.velocity.x, cos(deg_to_rad(30.0)) * speed, 0.01)
	assert_almost_eq(_fighter.velocity.y, -sin(deg_to_rad(30.0)) * speed, 0.01)


func test_downward_launch_on_the_ground_bounces_up() -> void:
	var spike := MoveData.new()
	spike.base_knockback = 200.0
	spike.angle_deg = -75.0
	await _start_at(MIDDLE)
	_fighter.take_hit(spike, 1, MIDDLE.x - 10.0)
	assert_almost_eq(_fighter.velocity.x, cos(deg_to_rad(75.0)) * 200.0, 0.01)
	assert_almost_eq(_fighter.velocity.y, -sin(deg_to_rad(75.0)) * 200.0, 0.01, "up, not into the floor")


func test_downward_launch_in_the_air_spikes() -> void:
	var spike := MoveData.new()
	spike.base_knockback = 200.0
	spike.angle_deg = -75.0
	await _start_in_the_air()
	_fighter.take_hit(spike, 1, _fighter.global_position.x - 10.0)
	assert_almost_eq(_fighter.velocity.y, sin(deg_to_rad(75.0)) * 200.0, 0.01, "driven down")


func test_knockback_grows_with_percent() -> void:
	await _start_at(MIDDLE)
	_fighter.percent = 100.0
	_fighter.take_hit(_moves.side_tilt, -1, MIDDLE.x + 10.0)
	assert_eq(_fighter.percent, 109.0)
	var speed := 180.0 + 1.6 * 109.0
	assert_almost_eq(_fighter.velocity.length(), speed, 0.01)
	assert_lt(_fighter.velocity.x, 0.0, "launched to the left")


func test_percent_caps_at_999() -> void:
	await _start_at(MIDDLE)
	_fighter.percent = 998.0
	_fighter.take_hit(_moves.jab, 1, MIDDLE.x - 10.0)
	assert_eq(_fighter.percent, 999.0)


func test_hitstun_from_launch_speed_with_a_minimum() -> void:
	await _start_at(MIDDLE)
	_fighter.take_hit(_moves.jab, 1, MIDDLE.x - 10.0)
	assert_eq(_fighter.state, Fighter.State.HITSTUN)
	# 122.4 px/s × 0.06 = 7.3 → 7 ticks.
	_run(_make_input(), 7)
	assert_eq(_fighter.state, Fighter.State.HITSTUN)
	_run(_make_input(), 1)
	assert_ne(_fighter.state, Fighter.State.HITSTUN)


func test_minimum_hitstun() -> void:
	var weak := MoveData.new()
	weak.damage = 1.0
	weak.base_knockback = 10.0
	await _start_at(MIDDLE)
	_fighter.take_hit(weak, 1, MIDDLE.x - 10.0)
	_run(_make_input(), _stats.min_hitstun)
	assert_eq(_fighter.state, Fighter.State.HITSTUN)
	_run(_make_input(), 1)
	assert_eq(_fighter.state, Fighter.State.IDLE)


func test_knockback_side_facing_and_away() -> void:
	await _start_at(MIDDLE, -1)
	assert_eq(_fighter.knockback_side(_moves.jab, MIDDLE + Vector2(30, -12)), -1, "FACING: own facing")
	assert_eq(_fighter.knockback_side(_moves.up_tilt, MIDDLE + Vector2(5, -40)), 1, "AWAY: victim on the right")
	assert_eq(_fighter.knockback_side(_moves.up_tilt, MIDDLE + Vector2(-5, -40)), -1, "AWAY: victim on the left")
	assert_eq(_fighter.knockback_side(_moves.up_tilt, MIDDLE + Vector2(0, -40)), -1, "AWAY, level: own facing")


func test_hit_faces_the_attacker_restores_jumps_and_cancels_the_move() -> void:
	await _start_at(MIDDLE, 1)
	_run(_attack(), 5)
	assert_true(_fighter.is_hitbox_active())
	_fighter.jumps_left = 0
	_fighter.take_hit(_moves.jab, 1, MIDDLE.x - 10.0)
	assert_eq(_fighter.facing, -1)
	assert_eq(_fighter.jumps_left, _stats.max_air_jumps)
	assert_false(_fighter.is_hitbox_active())
	assert_eq(_fighter.move, &"")


func test_hitstun_ignores_input() -> void:
	await _start_at(MIDDLE)
	_fighter.take_hit(_moves.side_tilt, 1, MIDDLE.x - 10.0)
	_run(_make_input(-1.0, true, true), 3)
	assert_eq(_fighter.state, Fighter.State.HITSTUN)
	assert_eq(_fighter.facing, -1)


func test_a_second_hit_restarts_hitstun() -> void:
	await _start_at(MIDDLE)
	_fighter.take_hit(_moves.jab, 1, MIDDLE.x - 10.0)
	_run(_make_input(), 5)
	_fighter.take_hit(_moves.jab, 1, MIDDLE.x - 10.0)
	assert_eq(_fighter.state_frame, 0)
	_run(_make_input(), 7)
	assert_eq(_fighter.state, Fighter.State.HITSTUN)


func test_launch_from_the_ground_uses_air_friction_and_gravity() -> void:
	await _start_at(MIDDLE)
	_fighter.take_hit(_moves.jab, 1, MIDDLE.x - 10.0)
	var before := _fighter.velocity
	_run(_make_input(), 1)
	assert_almost_eq(_fighter.velocity.x, before.x - _stats.hitstun_friction / 60.0, 0.001)
	assert_almost_eq(_fighter.velocity.y, before.y + _stats.gravity / 60.0, 0.001)
	assert_lt(_fighter.position.y, FLOOR_Y, "left the ground")


func test_can_act_on_the_tick_hitstun_ends() -> void:
	await _start_at(MIDDLE)
	var flat := MoveData.new()
	flat.base_knockback = 0.0
	_fighter.take_hit(flat, 1, MIDDLE.x - 10.0)
	_run(_make_input(), _stats.min_hitstun)
	_run(_make_input(0.0, false, true), 1)
	assert_eq(_fighter.state, Fighter.State.AIR)


func test_spawn_resets_percent() -> void:
	await _start_at(MIDDLE)
	_fighter.percent = 55.0
	_fighter.spawn_at(MIDDLE, 1)
	assert_eq(_fighter.percent, 0.0)
	assert_eq(_fighter.move, &"")
