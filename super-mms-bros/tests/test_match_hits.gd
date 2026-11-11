extends GutTest
## Hit resolution in Match.step() (docs/specs/architecture.md#tick-order,
## docs/specs/fighter.md#getting-hit). Scripted [idle, attack] starts the attack on step 2, so the
## jab's active frames 5–7 are steps 6–8.

const MATCH_SCENE := preload("res://match/match.tscn")
## The jab on a fighter at 0 %: 120 + 0.8 × 3 = 122.4 px/s at 30°.
const JAB_SPEED := 122.4

var _match: Match
var _p1: Fighter
var _p2: Fighter


func before_each() -> void:
	_match = MATCH_SCENE.instantiate()
	_match.auto_step = false
	add_child_autofree(_match)
	_p1 = _match.get_fighter(0)
	_p2 = _match.get_fighter(1)


func _place(p1_at: Vector2, p1_facing: int, p2_at: Vector2, p2_facing: int,
		p1_inputs: Array[FighterInput], p2_inputs: Array[FighterInput]) -> void:
	_p1.spawn_at(p1_at, p1_facing)
	_p2.spawn_at(p2_at, p2_facing)
	_match.set_controller(0, ScriptedController.new(p1_inputs))
	_match.set_controller(1, ScriptedController.new(p2_inputs))
	await wait_physics_frames(1)


func _steps(count: int) -> void:
	for i in count:
		_match.step()


func _jabs(count: int = 1) -> Array[FighterInput]:
	var inputs: Array[FighterInput] = []
	for i in count:
		var attack := FighterInput.new()
		attack.attack_pressed = true
		inputs.append(FighterInput.new())
		inputs.append(attack)
		for j in 18:
			inputs.append(FighterInput.new())
	return inputs


func test_p2_is_a_dummy_at_its_spawn_point() -> void:
	assert_eq(_match.get_node("Fighters").get_child_count(), 2)
	assert_eq(_p2.player_index, 1)
	assert_eq(_p2.position, Vector2(312, 192))
	assert_eq(_p2.facing, -1)
	assert_true(_match.get_controller(1) is ScriptedController)


func test_jab_hits_on_its_first_active_frame() -> void:
	await _place(Vector2(230, 192), 1, Vector2(250, 192), -1, _jabs(), [])
	_steps(5)
	assert_eq(_p2.state, Fighter.State.IDLE, "not hit during startup")
	_steps(1)
	assert_eq(_p2.state, Fighter.State.HITSTUN)
	assert_eq(_p2.percent, 3.0)
	assert_almost_eq(_p2.velocity.x, cos(deg_to_rad(30.0)) * JAB_SPEED, 0.01)


func test_out_of_range_misses() -> void:
	await _place(Vector2(230, 192), 1, Vector2(270, 192), -1, _jabs(), [])
	_steps(20)
	assert_eq(_p2.percent, 0.0)


func test_one_hit_per_move() -> void:
	await _place(Vector2(230, 192), 1, Vector2(250, 192), -1, _jabs(), [])
	_steps(8)
	assert_eq(_p2.percent, 3.0, "hit on step 6 only, not again on steps 7–8")


func test_knockback_follows_the_attackers_facing() -> void:
	await _place(Vector2(250, 192), -1, Vector2(230, 192), 1, _jabs(), [])
	_steps(6)
	assert_lt(_p2.velocity.x, 0.0)


func test_hit_from_behind_turns_the_victim() -> void:
	await _place(Vector2(230, 192), 1, Vector2(250, 192), 1, _jabs(), [])
	_steps(6)
	assert_eq(_p2.facing, -1)
	assert_gt(_p2.velocity.x, 0.0)


func test_trade_hits_both_fighters() -> void:
	await _place(Vector2(230, 192), 1, Vector2(250, 192), -1, _jabs(), _jabs())
	_steps(6)
	assert_eq(_p1.state, Fighter.State.HITSTUN)
	assert_eq(_p2.state, Fighter.State.HITSTUN)
	assert_lt(_p1.velocity.x, 0.0, "P1 knocked left")
	assert_gt(_p2.velocity.x, 0.0, "P2 knocked right")
	assert_eq(_p1.facing, 1)
	assert_eq(_p2.facing, -1)


## P1 dives onto P2, both in the air: P2 is spiked down, and hit only once by the dive.
func test_dive_spikes_in_the_match() -> void:
	var dive := FighterInput.new()
	dive.special_pressed = true
	dive.special_held = true
	dive.down_held = true
	await _place(Vector2(240, 60), 1, Vector2(240, 100), -1, [FighterInput.new(), dive], [])
	for i in 15:
		_match.step()
		if _p2.state == Fighter.State.HITSTUN:
			break
	assert_eq(_p2.state, Fighter.State.HITSTUN, "the dive hit")
	assert_eq(_p2.percent, 8.0)
	assert_gt(_p2.velocity.y, 0.0, "spiked down")
	_steps(3)
	assert_eq(_p1.move, &"down_special_dive", "still diving")
	assert_eq(_p2.percent, 8.0, "one hit per victim")


func test_invulnerable_fighters_cant_be_hit() -> void:
	await _place(Vector2(230, 192), 1, Vector2(250, 192), -1, _jabs(), [])
	_p2.invulnerable_frames = 100
	_steps(8)
	assert_eq(_p2.percent, 0.0)
	assert_eq(_p2.state, Fighter.State.IDLE)


func test_percent_adds_up() -> void:
	await _place(Vector2(230, 192), 1, Vector2(250, 192), -1, _jabs(3), [])
	for i in 3:
		_p2.global_position = Vector2(250, 192)
		_p2.velocity = Vector2.ZERO
		_steps(20)
	assert_eq(_p2.percent, 9.0)


func _shielding(count: int) -> Array[FighterInput]:
	var inputs: Array[FighterInput] = []
	for i in count:
		var input := FighterInput.new()
		input.shield_held = true
		input.shield_pressed = i == 0
		inputs.append(input)
	return inputs


func test_stepped_once_per_step() -> void:
	await wait_physics_frames(1)
	watch_signals(_match)
	_steps(3)
	assert_signal_emit_count(_match, "stepped", 3)


func test_blocked_hit_is_announced() -> void:
	await _place(Vector2(230, 192), 1, Vector2(250, 192), -1, _jabs(), _shielding(20))
	watch_signals(_match)
	_steps(8)
	assert_eq(_p2.state, Fighter.State.SHIELD, "the jab hit the shield")
	assert_signal_emitted_with_parameters(_match, "fighter_blocked", [1])
	assert_signal_not_emitted(_match, "fighter_hit", "a blocked hit isn't a hit")
