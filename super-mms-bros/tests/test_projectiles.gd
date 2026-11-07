extends GutTest
## Projectiles and shields in Match.step() (docs/specs/moves.md#side-special--projectile,
## docs/specs/architecture.md#tick-order). Scripted [idle, side special] starts the move on step 2,
## so the projectile appears on step 11 (the move's frame 10).

const MATCH_SCENE := preload("res://match/match.tscn")

var _match: Match
var _p1: Fighter
var _p2: Fighter


func before_each() -> void:
	_match = MATCH_SCENE.instantiate()
	_match.auto_step = false
	add_child_autofree(_match)
	_p1 = _match.get_fighter(0)
	_p2 = _match.get_fighter(1)


func _place(p1_at: Vector2, p2_at: Vector2, p1_inputs: Array[FighterInput],
		p2_inputs: Array[FighterInput] = []) -> void:
	_p1.spawn_at(p1_at, 1)
	_p2.spawn_at(p2_at, -1)
	_match.set_controller(0, ScriptedController.new(p1_inputs))
	_match.set_controller(1, ScriptedController.new(p2_inputs))
	await wait_physics_frames(1)


func _steps(count: int) -> void:
	for i in count:
		_match.step()


func _fire(times := 1) -> Array[FighterInput]:
	var inputs: Array[FighterInput] = []
	for i in times:
		var special := FighterInput.new()
		special.special_pressed = true
		special.special_held = true
		special.move_x = 1.0
		inputs.append(FighterInput.new())
		inputs.append(special)
		for j in 30:
			inputs.append(FighterInput.new())
	return inputs


func _hold_shield(ticks: int) -> Array[FighterInput]:
	var inputs: Array[FighterInput] = []
	for i in ticks:
		var input := FighterInput.new()
		input.shield_held = true
		inputs.append(input)
	return inputs


func test_side_special_spawns_a_projectile_in_front() -> void:
	await _place(Vector2(150, 192), Vector2(380, 192), _fire())
	_steps(10)
	assert_eq(_match.get_projectiles().size(), 0, "not before frame 10")
	_steps(1)
	var projectiles := _match.get_projectiles()
	assert_eq(projectiles.size(), 1)
	var projectile := projectiles[0]
	assert_eq(projectile.owner_index, 0)
	assert_eq(projectile.direction, 1)
	assert_almost_eq(projectile.global_position, Vector2(150 + 16, 192 - 13), Vector2(4.1, 0.01))


func test_projectile_flies_4_px_per_tick() -> void:
	await _place(Vector2(150, 192), Vector2(380, 192), _fire())
	_steps(11)
	var x := _match.get_projectiles()[0].global_position.x
	_steps(5)
	assert_almost_eq(_match.get_projectiles()[0].global_position.x, x + 20.0, 0.01)


func test_projectile_hits_and_disappears() -> void:
	await _place(Vector2(150, 192), Vector2(220, 192), _fire())
	_steps(30)
	assert_eq(_p2.percent, 5.0)
	assert_gt(_p2.velocity.x, 0.0, "launched the way it flew")
	assert_eq(_match.get_projectiles().size(), 0)


func test_a_ko_removes_the_fighters_projectile() -> void:
	await _place(Vector2(168, 192), Vector2(400, 100), _fire())
	_steps(11)
	assert_eq(_match.get_projectiles().size(), 1)
	_p1.global_position = Vector2(-100, 150)
	_steps(1)
	assert_eq(_match.get_projectiles().size(), 0)


func test_projectile_never_hits_its_owner() -> void:
	await _place(Vector2(150, 192), Vector2(450, 192), _fire())
	_steps(11)
	_p1.global_position = _match.get_projectiles()[0].global_position + Vector2(0, 13)
	_steps(2)
	assert_eq(_p1.percent, 0.0)


## A fired projectile flies 480 px in its lifetime, wider than the stage's blast zone leaves room
## for, so the lifetime is checked on a lone projectile with a big zone.
func test_projectile_expires_after_its_lifetime() -> void:
	var projectile := Projectile.new()
	add_child_autofree(projectile)
	projectile.setup(0, 1, Vector2.ZERO, _p1.stats.moveset.side_special)
	var huge := Rect2(-10000, -10000, 20000, 20000)
	for i in 119:
		projectile.advance()
	assert_false(projectile.is_expired(huge), "still there at 119 ticks old")
	projectile.advance()
	assert_true(projectile.is_expired(huge), "gone at 120 ticks")


func test_projectile_leaving_the_blast_zone_disappears() -> void:
	await _place(Vector2(100, 192), Vector2(240, 128), _fire())
	_steps(11)
	assert_eq(_match.get_projectiles().size(), 1)
	_steps(120)
	assert_eq(_match.get_projectiles().size(), 0, "flew out past x 552")


func test_one_projectile_at_a_time() -> void:
	await _place(Vector2(100, 192), Vector2(240, 128), _fire(3))
	_steps(80)
	assert_eq(_match.get_projectiles().size(), 1, "the second press did nothing")


func test_shield_blocks_a_projectile() -> void:
	await _place(Vector2(150, 192), Vector2(220, 192), _fire(), _hold_shield(60))
	_steps(30)
	assert_eq(_p2.percent, 0.0)
	# 30 ticks of drain alone would leave 92.5; the blocked shot (5 × 1.5) takes more.
	assert_lt(_p2.shield_health, _p2.stats.shield_max - 30 * _p2.stats.shield_drain - 5.0)
	assert_eq(_match.get_projectiles().size(), 0)


func test_shield_blocks_a_jab_in_the_match() -> void:
	var jab: Array[FighterInput] = [FighterInput.new(), FighterInput.new()]
	jab[1].attack_pressed = true
	await _place(Vector2(230, 192), Vector2(250, 192), jab, _hold_shield(30))
	_steps(10)
	assert_eq(_p2.percent, 0.0)
	assert_eq(_p2.state, Fighter.State.SHIELD)
	assert_gt(_p2.position.x, 250.0, "pushed away")
