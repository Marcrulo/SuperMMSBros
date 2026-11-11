extends GutTest
## Michael's football (docs/specs/moves.md#michael-bech--football). P1 is Michael; scripted
## [idle, side special] starts the kick on step 2, so the ball appears on step 11 (frame 10).
## The right platform's top is y 150 (x 276…348).

const MATCH_SCENE := preload("res://match/match.tscn")
const MICHAEL := "slot_05"
const SPAWN := 11

var _match: Match
var _p1: Fighter
var _p2: Fighter
var _saved_ids: Array[String] = []


func before_each() -> void:
	_saved_ids = [Game.character_id, Game.p2_character_id]
	Game.character_id = MICHAEL
	Game.p2_character_id = "slot_09"
	_match = MATCH_SCENE.instantiate()
	_match.auto_step = false
	add_child_autofree(_match)
	_p1 = _match.get_fighter(0)
	_p2 = _match.get_fighter(1)


func after_each() -> void:
	Game.character_id = _saved_ids[0]
	Game.p2_character_id = _saved_ids[1]


func _place(p1_at: Vector2, p2_at: Vector2) -> void:
	_p1.spawn_at(p1_at, 1)
	_p2.spawn_at(p2_at, -1)
	var special := FighterInput.new()
	special.special_pressed = true
	special.special_held = true
	special.move_x = 1.0
	_match.set_controller(0, ScriptedController.new([FighterInput.new(), special]))
	_match.set_controller(1, ScriptedController.new([]))
	await wait_physics_frames(1)


func _steps(count: int) -> void:
	for i in count:
		_match.step()


func _kick_data() -> MoveData:
	return _p1.stats.moveset.side_special


# --- Data -----------------------------------------------------------------------------------------


func test_kick_data_matches_the_spec() -> void:
	var kick := _kick_data()
	var defaults := (load("res://fighter/default_stats.tres") as FighterStats).moveset
	assert_ne(kick, defaults.side_special)
	assert_eq([kick.startup, kick.active, kick.recovery], [10, 0, 12])
	assert_eq([kick.aim_cone_deg, kick.aim_range], [45.0, 200.0])
	assert_eq([kick.hitbox_center, kick.hitbox_size], [Vector2(14, -8), Vector2(8, 8)])
	assert_eq([kick.damage, kick.base_knockback, kick.angle_deg], [6.0, 110.0, 30.0])
	assert_almost_eq(kick.knockback_growth, 0.6, 0.0001)
	assert_eq([kick.projectile_speed, kick.projectile_lifetime], [240.0, 120])
	assert_eq(defaults.side_special.aim_cone_deg, 0.0, "the default flies straight")
	assert_eq(_p1.stats.moveset.neutral_special.hand != null, true, "still has his hand")


# --- Aiming (pure) --------------------------------------------------------------------------------


func _aim(facing: int, targets: Array[Vector2]) -> float:
	return Projectile.aim_angle(Vector2(100, 100), facing, targets, 45.0, 200.0)


func test_aim_angle_straight_ahead_and_up() -> void:
	assert_almost_eq(_aim(1, [Vector2(200, 100)]), 0.0, 0.001)
	assert_almost_eq(_aim(1, [Vector2(200, 100 - 100 * tan(deg_to_rad(30)))]), 30.0, 0.001)
	assert_almost_eq(_aim(1, [Vector2(200, 100 + 100 * tan(deg_to_rad(20)))]), -20.0, 0.001)


func test_aim_angle_facing_left() -> void:
	assert_almost_eq(_aim(-1, [Vector2(0, 100 - 100 * tan(deg_to_rad(30)))]), 30.0, 0.001)
	assert_true(is_nan(_aim(-1, [Vector2(200, 100)])), "behind")


func test_aim_angle_ignores_enemies_it_cant_see() -> void:
	assert_true(is_nan(_aim(1, [])), "nobody")
	assert_true(is_nan(_aim(1, [Vector2(0, 100)])), "behind")
	assert_true(is_nan(_aim(1, [Vector2(150, 0)])), "outside the cone (63°)")
	assert_true(is_nan(_aim(1, [Vector2(320, 100)])), "too far (220 px)")


func test_aim_angle_picks_the_nearest() -> void:
	var far := Vector2(280, 100)
	var near := Vector2(160, 100 - 60 * tan(deg_to_rad(40)))
	assert_almost_eq(_aim(1, [far, near]), 40.0, 0.001)


# --- In a match -----------------------------------------------------------------------------------


func test_ball_flies_at_the_enemy() -> void:
	await _place(Vector2(150, 192), Vector2(300, 150))
	_steps(SPAWN)
	var balls := _match.get_projectiles()
	assert_eq(balls.size(), 1)
	var ball := balls[0]
	var to_enemy := _p2.get_center() - ball.global_position
	var expected := rad_to_deg(atan2(-to_enemy.y, to_enemy.x))
	assert_almost_eq(ball.angle_deg, expected, 0.5, "aimed at P2")
	assert_gt(ball.angle_deg, 5.0, "upward, at the platform")
	var at := ball.global_position
	_steps(1)
	var step := Vector2(cos(deg_to_rad(expected)), -sin(deg_to_rad(expected))) * 4.0
	assert_almost_eq(ball.global_position, at + step, Vector2(0.01, 0.01))
	_steps(60)
	assert_eq(_p2.percent, 6.0, "it hits")


func test_ball_appears_at_the_kicking_foot() -> void:
	await _place(Vector2(150, 192), Vector2(60, 192))
	_steps(SPAWN)
	assert_almost_eq(_match.get_projectiles()[0].global_position, Vector2(164, 184),
		Vector2(4.1, 0.01))


func _random_kick_angle(seed_value: int) -> float:
	_match.reset(seed_value)
	await _place(Vector2(150, 192), Vector2(60, 192))
	_steps(SPAWN)
	return _match.get_projectiles()[0].angle_deg


func test_random_kick_is_seeded() -> void:
	var angles: Array[float] = []
	for seed_value in [1, 2, 3, 4, 5]:
		var angle: float = await _random_kick_angle(seed_value)
		assert_between(angle, -45.0, 45.0, "seed %d" % seed_value)
		angles.append(angle)
	var again: float = await _random_kick_angle(3)
	assert_eq(again, angles[2], "same seed, same kick")
	var distinct := {}
	for angle in angles:
		distinct[snappedf(angle, 0.01)] = true
	assert_gt(distinct.size(), 2, "the angle varies with the seed")


func test_enemy_out_of_range_gets_a_random_kick() -> void:
	_match.reset(7)
	await _place(Vector2(110, 192), Vector2(370, 192))
	_steps(SPAWN)
	var random_angle := _match.get_projectiles()[0].angle_deg
	assert_between(random_angle, -45.0, 45.0)
	assert_eq(_match.seed_value, 7)


func test_ball_has_its_own_spinning_picture() -> void:
	var texture := load("res://assets/fighters/slot_05/projectile.png") as Texture2D
	assert_eq(texture.get_size(), Vector2(48, 16))
