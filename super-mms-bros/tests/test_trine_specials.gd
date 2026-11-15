extends GutTest
## Trine's bun pitch (neutral special) and banana peel throw (side special)
## (docs/specs/characters/trine.md#trine--bun-pitch, #trine--banana-peel-throw). P1 is Trine,
## facing right. Main platform top y 192 (x 96…384); left platform x 132…204, top y 150.

const MATCH_SCENE := preload("res://match/match.tscn")
const TRINE := "slot_03"

var _match: Match
var _p1: Fighter
var _p2: Fighter
var _saved_ids: Array[String] = []


func before_each() -> void:
	_saved_ids = [Game.character_id, Game.p2_character_id]
	Game.character_id = TRINE
	Game.p2_character_id = "slot_08"
	_match = MATCH_SCENE.instantiate()
	_match.auto_step = false
	add_child_autofree(_match)
	_p1 = _match.get_fighter(0)
	_p2 = _match.get_fighter(1)


func after_each() -> void:
	Game.character_id = _saved_ids[0]
	Game.p2_character_id = _saved_ids[1]


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


## [idle, K pressed, K held for `held` more ticks, then idle]: the windup lasts `held` + 1 ticks.
func _pitch(held: int) -> Array[FighterInput]:
	var press := FighterInput.new()
	press.special_pressed = true
	press.special_held = true
	var inputs: Array[FighterInput] = [FighterInput.new(), press]
	for i in held:
		var hold := FighterInput.new()
		hold.special_held = true
		inputs.append(hold)
	for i in 10:
		inputs.append(FighterInput.new())
	return inputs


## [idle, Side+B toward `x`, then `gap` idle ticks] × times.
func _toss(times := 1, gap := 40, x := 1.0) -> Array[FighterInput]:
	var inputs: Array[FighterInput] = []
	for i in times:
		var special := FighterInput.new()
		special.special_pressed = true
		special.special_held = true
		special.move_x = x
		inputs.append(FighterInput.new())
		inputs.append(special)
		for j in gap:
			inputs.append(FighterInput.new())
	return inputs


func _buns() -> Array[Bun]:
	var found: Array[Bun] = []
	found.assign(_match.get_entities(Bun, 0))
	return found


func _thrown() -> Array[ThrownPeel]:
	var found: Array[ThrownPeel] = []
	found.assign(_match.get_entities(ThrownPeel, 0))
	return found


func _traps() -> Array[Peel]:
	var found: Array[Peel] = []
	found.assign(_match.get_entities(Peel, 0))
	return found


## Steps until her bun is out (at most `limit` ticks); returns it, or null.
func _until_bun(limit := 200) -> Bun:
	for i in limit:
		_match.step()
		if not _buns().is_empty():
			return _buns()[0]
	return null


## Steps until her thrown peel has landed (a trap of hers exists); false if it never did.
func _until_landed(limit := 120) -> bool:
	for i in limit:
		_match.step()
		if not _traps().is_empty():
			return true
	return false


# --- Data -----------------------------------------------------------------------------------------


func test_her_specials_match_the_spec() -> void:
	var pitch := _p1.stats.moveset.neutral_special
	assert_true(pitch.ability is BunData, "neutral special: the bun pitch")
	assert_eq([pitch.startup, pitch.active, pitch.recovery, pitch.charge_frames], [4, 0, 13, 120])
	assert_eq([(pitch.ability as BunData).speed_min, (pitch.ability as BunData).speed_max],
		[200.0, 520.0])
	assert_eq([pitch.damage, pitch.charge_damage, pitch.base_knockback, pitch.charge_knockback],
		[4.0, 12.0, 60.0, 200.0])
	var toss := _p1.stats.moveset.side_special
	assert_true(toss.ability is PeelThrowData, "side special: the peel throw")
	assert_eq([toss.startup, toss.active, toss.recovery], [10, 0, 12])
	assert_eq([toss.projectile_speed, toss.projectile_angle_deg, toss.projectile_gravity],
		[150.0, 40.0, 700.0])
	var trap := (toss.ability as PeelThrowData).trap
	assert_eq([trap.max_out, trap.lifetime, trap.trip_frames], [2, 600, 45])
	assert_eq(trap.damage, 3.0)


func test_the_rest_is_the_default_move_set() -> void:
	var defaults := (load("res://fighter/default_stats.tres") as FighterStats).moveset
	var moves := _p1.stats.moveset
	for name in ["jab", "side_tilt", "up_special", "down_air", "forward_air"]:
		assert_eq(moves.get(name), defaults.get(name), name)


# --- Bun pitch ------------------------------------------------------------------------------------


func test_she_winds_up_while_k_is_held() -> void:
	await _place(Vector2(150, 192), Vector2(380, 192), _pitch(90))
	_steps(60)
	assert_eq(_p1.move, &"neutral_special_charge", "still winding up after 1 s")
	assert_true(_buns().is_empty())


func test_a_quick_tap_throws_a_slow_weak_bun() -> void:
	await _place(Vector2(150, 192), Vector2(380, 192), _pitch(0))
	var bun := _until_bun()
	assert_not_null(bun, "the bun is thrown")
	assert_almost_eq(bun.global_position, Vector2(164, 176), Vector2(4.1, 0.01), "from her hand")
	var x := bun.global_position.x
	_match.step()
	assert_almost_eq(bun.global_position.x - x, 200.0 / 60.0, 0.4, "slow")
	assert_lt(bun.data.damage, 4.5)


func test_a_full_windup_throws_a_fast_hard_bun_by_itself() -> void:
	await _place(Vector2(150, 192), Vector2(380, 192), _pitch(300))
	var bun := _until_bun()
	assert_not_null(bun, "thrown at full charge, though K is still held")
	var x := bun.global_position.x
	var y := bun.global_position.y
	_match.step()
	assert_almost_eq(bun.global_position.x - x, 520.0 / 60.0, 0.01, "fast")
	assert_eq(bun.global_position.y, y, "straight, no gravity")
	assert_almost_eq(bun.data.damage, 16.0, 0.01)
	assert_almost_eq(bun.data.base_knockback, 260.0, 0.01)


func test_a_charged_bun_hits_harder() -> void:
	await _place(Vector2(150, 192), Vector2(260, 192), _pitch(60))
	for i in 200:
		_match.step()
		if _p2.percent > 0.0:
			break
	# 61 ticks charged of 120.
	assert_almost_eq(_p2.percent, 4.0 + 12.0 * 61.0 / 120.0, 0.01)
	assert_eq(_p2.state, Fighter.State.HITSTUN)
	assert_true(_buns().is_empty(), "used up on the hit")


func test_the_throw_itself_has_no_hitbox() -> void:
	await _place(Vector2(150, 192), Vector2(162, 192), _pitch(0))
	for i in 10:
		_match.step()
		assert_false(_p1.is_hitbox_active())


func test_one_bun_at_a_time() -> void:
	var inputs := _pitch(0)
	inputs.append_array(_pitch(0))
	await _place(Vector2(150, 192), Vector2(380, 192), inputs)
	_steps(30)
	assert_eq(_buns().size(), 1)
	assert_ne(_p1.move, &"neutral_special_charge", "the second press did nothing")


func test_the_bun_is_gone_after_two_seconds() -> void:
	# P2 waits on the left platform, above the bun's path.
	await _place(Vector2(100, 192), Vector2(170, 150), _pitch(0))
	assert_not_null(_until_bun())
	_steps(119)
	assert_eq(_buns().size(), 1)
	_steps(1)
	assert_true(_buns().is_empty())


# --- Banana peel throw ----------------------------------------------------------------------------


func test_the_peel_arcs_and_becomes_a_trap() -> void:
	await _place(Vector2(150, 192), Vector2(380, 192), _toss())
	_steps(11)
	assert_eq(_thrown().size(), 1, "thrown on frame 10")
	var peel := _thrown()[0]
	assert_almost_eq(peel.global_position, Vector2(164, 176), Vector2(3.0, 0.01))
	var start_y := peel.global_position.y
	_steps(3)
	assert_lt(peel.global_position.y, start_y, "tossed upward")
	assert_true(_until_landed(), "it lands")
	assert_true(_thrown().is_empty())
	var trap := _traps()[0]
	assert_eq(trap.global_position.y, 192.0, "lying on the floor")
	assert_almost_eq(trap.global_position.x, 210.0, 15.0, "about 60 px in front of her")
	assert_true(trap.landed)
	assert_eq(_match.get_projectiles().size(), 0, "no default projectile")


func test_a_trap_peel_trips_the_opponent_but_not_her() -> void:
	var p2_walk: Array[FighterInput] = []
	for i in 50:
		p2_walk.append(FighterInput.new())
	for i in 60:
		var walk := FighterInput.new()
		walk.move_x = -1.0
		p2_walk.append(walk)
	await _place(Vector2(150, 192), Vector2(300, 192), _toss(), p2_walk)
	assert_true(_until_landed())
	_p1.spawn_at(_traps()[0].global_position, 1)
	_match.step()
	assert_ne(_p1.state, Fighter.State.TRIPPED, "her own peel never trips her")
	_p1.spawn_at(Vector2(110, 192), 1)
	var tripped := false
	for i in 80:
		_match.step()
		if _p2.state == Fighter.State.TRIPPED:
			tripped = true
			break
	assert_true(tripped, "P2 slipped")
	assert_eq(_p2.percent, 3.0)
	assert_true(_traps().is_empty(), "used up")


func test_a_hit_in_flight_is_a_normal_hit_and_leaves_no_trap() -> void:
	await _place(Vector2(150, 192), Vector2(190, 192), _toss())
	for i in 40:
		_match.step()
		if _p2.percent > 0.0:
			break
	assert_eq(_p2.percent, 4.0)
	assert_eq(_p2.state, Fighter.State.HITSTUN, "knocked back, not tripped")
	_steps(40)
	assert_true(_thrown().is_empty())
	assert_true(_traps().is_empty(), "no trap after a hit")


func test_one_peel_in_the_air_at_a_time() -> void:
	# The second press comes after the first throw ended (22 frames), while the peel still flies.
	await _place(Vector2(150, 192), Vector2(380, 192), _toss(2, 24))
	_steps(30)
	assert_eq(_thrown().size(), 1)
	assert_ne(_p1.move, &"side_special", "the second press did nothing")


func test_at_most_two_traps() -> void:
	# From the middle: right, left, then right again (52 ticks apart).
	var inputs := _toss(1, 50, 1.0)
	inputs.append_array(_toss(1, 50, -1.0))
	inputs.append_array(_toss(1, 50, 1.0))
	await _place(Vector2(240, 192), Vector2(380, 80), inputs)
	_steps(52)
	assert_eq(_traps().size(), 1)
	var first := _traps()[0]
	_steps(52)
	assert_eq(_traps().size(), 2)
	_steps(52)
	assert_eq(_traps().size(), 2, "the third removed her oldest")
	assert_false(_traps().has(first))


func test_a_falling_peel_lands_on_a_platform() -> void:
	# Thrown from the air left of the left platform, it comes down on the platform (top y 150).
	await _place(Vector2(120, 110), Vector2(380, 192), _toss())
	assert_true(_until_landed(), "it lands")
	assert_eq(_traps()[0].global_position.y, 150.0)


func test_a_peel_thrown_off_the_stage_falls_away() -> void:
	await _place(Vector2(370, 192), Vector2(150, 192), _toss(1, 40, 1.0))
	_steps(11)
	# Push the peel far past the stage edge.
	_thrown()[0].global_position.x = 420.0
	_steps(200)
	assert_true(_thrown().is_empty())
	assert_true(_traps().is_empty())


# --- Pictures -------------------------------------------------------------------------------------


func test_bun_and_peel_pictures() -> void:
	assert_eq((load("res://assets/fighters/slot_03/peel.png") as Texture2D).get_size(), Vector2(16, 8))
	assert_eq((load("res://assets/fighters/slot_03/projectile.png") as Texture2D).get_size(),
		Vector2(30, 10))
