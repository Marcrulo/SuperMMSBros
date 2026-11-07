extends GutTest
## The shield (docs/specs/fighter.md#shield).

const STAGE_SCENE := preload("res://stage/battlefield.tscn")
const FIGHTER_SCENE := preload("res://fighter/fighter.tscn")
const MIDDLE := Vector2(240, 192)
const FLOOR_Y := 192.0

var _fighter: Fighter
var _stats: FighterStats


func before_each() -> void:
	add_child_autofree(STAGE_SCENE.instantiate())
	_fighter = add_child_autofree(FIGHTER_SCENE.instantiate())
	_stats = _fighter.stats


func _start() -> void:
	_fighter.spawn_at(MIDDLE, 1)
	await wait_physics_frames(1)
	_fighter.tick(FighterInput.new())


func _run(input: FighterInput, ticks: int) -> void:
	for i in ticks:
		_fighter.tick(input)


func _shield(move_x := 0.0, jump := false, attack := false) -> FighterInput:
	var input := FighterInput.new()
	input.shield_held = true
	input.move_x = move_x
	input.jump_pressed = jump
	input.jump_held = jump
	input.attack_pressed = attack
	return input


func _idle() -> FighterInput:
	return FighterInput.new()


func test_holding_shield_raises_it_and_slides_to_a_stop() -> void:
	await _start()
	var run := FighterInput.new()
	run.move_x = 1.0
	_run(run, 10)
	_run(_shield(1.0), 1)
	assert_eq(_fighter.state, Fighter.State.SHIELD)
	assert_almost_eq(_fighter.velocity.x, _stats.run_speed - _stats.ground_friction / 60.0, 0.001)
	_run(_shield(1.0), 10)
	assert_eq(_fighter.velocity.x, 0.0, "doesn't walk while shielding")


func test_shield_drains_and_regrows() -> void:
	await _start()
	assert_eq(_fighter.shield_health, _stats.shield_max)
	_run(_shield(), 40)
	assert_almost_eq(_fighter.shield_health, _stats.shield_max - 40 * _stats.shield_drain, 0.001)
	_run(_idle(), 7)
	var low := _fighter.shield_health
	_run(_idle(), 10)
	assert_almost_eq(_fighter.shield_health, low + 10 * _stats.shield_regen, 0.001)
	_run(_idle(), 600)
	assert_eq(_fighter.shield_health, _stats.shield_max, "capped")


func test_releasing_drops_the_shield_with_lag() -> void:
	await _start()
	_run(_shield(), 5)
	_run(_idle(), 1)
	assert_eq(_fighter.state, Fighter.State.SHIELD_DROP)
	_run(_shield(0.0, true, true), _stats.shield_drop_frames - 1)
	assert_eq(_fighter.state, Fighter.State.SHIELD_DROP, "can't act while lowering it")
	_run(_idle(), 1)
	assert_eq(_fighter.state, Fighter.State.IDLE)


func test_jump_out_of_shield() -> void:
	await _start()
	_run(_shield(), 5)
	_run(_shield(0.0, true), 1)
	assert_eq(_fighter.state, Fighter.State.AIR)
	assert_lt(_fighter.velocity.y, 0.0)


func test_attack_wins_over_shield() -> void:
	await _start()
	_run(_shield(0.0, false, true), 1)
	assert_eq(_fighter.state, Fighter.State.ATTACK)


func test_block_costs_shield_and_pushes_without_damage() -> void:
	await _start()
	_run(_shield(), 1)
	var health := _fighter.shield_health
	var jab := _stats.moveset.jab
	_fighter.block_hit(jab, -1)
	assert_almost_eq(_fighter.shield_health, health - jab.damage * _stats.shield_damage_scale, 0.001)
	assert_eq(_fighter.percent, 0.0)
	assert_eq(_fighter.velocity.x, -_stats.block_pushback)
	assert_eq(_fighter.state, Fighter.State.SHIELD)


func test_block_stun_holds_the_shield() -> void:
	await _start()
	_run(_shield(), 1)
	_fighter.block_hit(_stats.moveset.side_tilt, 1)
	# side tilt: 9 damage → max(4, round(7.2)) = 7 ticks of block stun.
	_run(_shield(0.0, true), 1)
	assert_eq(_fighter.state, Fighter.State.SHIELD, "can't jump out")
	_run(_idle(), 5)
	assert_eq(_fighter.state, Fighter.State.SHIELD, "can't drop it")
	_run(_idle(), 2)
	assert_eq(_fighter.state, Fighter.State.SHIELD_DROP)


func test_shield_break() -> void:
	await _start()
	_run(_shield(), 1)
	_fighter.shield_health = 2.0
	_fighter.block_hit(_stats.moveset.jab, 1)
	assert_eq(_fighter.state, Fighter.State.SHIELD_BREAK)
	_run(_shield(0.0, true, true), _stats.shield_break_frames)
	assert_eq(_fighter.state, Fighter.State.SHIELD_BREAK, "stunned")
	_run(_idle(), 1)
	assert_eq(_fighter.state, Fighter.State.IDLE)
	assert_almost_eq(_fighter.shield_health, _stats.shield_reset_health, 0.2)


func test_shield_runs_out_by_holding() -> void:
	await _start()
	_fighter.shield_health = 1.0
	_run(_shield(), 5)
	assert_eq(_fighter.state, Fighter.State.SHIELD_BREAK)


func test_no_shield_in_the_air() -> void:
	await _start()
	var jump := FighterInput.new()
	jump.jump_pressed = true
	jump.jump_held = true
	_run(jump, 1)
	_run(_shield(), 5)
	assert_eq(_fighter.state, Fighter.State.AIR)


func test_spawn_restores_the_shield() -> void:
	await _start()
	_fighter.shield_health = 10.0
	_fighter.spawn_at(MIDDLE, 1)
	assert_eq(_fighter.shield_health, _stats.shield_max)
