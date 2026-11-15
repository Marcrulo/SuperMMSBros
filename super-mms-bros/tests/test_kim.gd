extends GutTest
## Kim's specials (docs/specs/characters/kim.md). P1 is Kim; scripted [idle, special] starts a
## special on step 2, so frame N of it is step N + 1 (the hammer on step 11, the ladder's choice on
## step 7, the blower's gust on step 22). Main platform top y 192 (x 96…384).

const MATCH_SCENE := preload("res://match/match.tscn")
const KIM := "slot_09"

var _match: Match
var _p1: Fighter
var _p2: Fighter
var _saved_ids: Array[String] = []


func before_each() -> void:
	_saved_ids = [Game.character_id, Game.p2_character_id]
	Game.character_id = KIM
	Game.p2_character_id = "slot_01"
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


## [idle, special in `direction`, `gap` idle ticks] × times.
func _special(direction: String, times := 1, gap := 60) -> Array[FighterInput]:
	var inputs: Array[FighterInput] = []
	for i in times:
		var special := FighterInput.new()
		special.special_pressed = true
		special.special_held = true
		match direction:
			"down":
				special.down_held = true
			"up":
				special.up_held = true
			"side":
				special.move_x = 1.0
		inputs.append(FighterInput.new())
		inputs.append(special)
		for j in gap:
			inputs.append(FighterInput.new())
	return inputs


## [idle, attack in `direction`, idle ticks].
func _attack(direction: String) -> Array[FighterInput]:
	var inputs: Array[FighterInput] = []
	var attack := FighterInput.new()
	attack.attack_pressed = true
	match direction:
		"down":
			attack.down_held = true
		"side":
			attack.move_x = 1.0
	inputs.append(FighterInput.new())
	inputs.append(attack)
	for j in 60:
		inputs.append(FighterInput.new())
	return inputs


func _hammers() -> Array[MatchEntity]:
	return _match.get_entities(Hammer, 0)


func _ladders() -> Array[MatchEntity]:
	return _match.get_entities(Ladder, 0)


# --- Data -----------------------------------------------------------------------------------------


func test_kim_has_his_own_specials() -> void:
	var defaults := (load("res://fighter/default_stats.tres") as FighterStats).moveset
	var moves := _p1.stats.moveset
	for name in ["neutral_special", "down_special", "side_special", "up_special"]:
		assert_ne(moves.get(name), defaults.get(name), name)
	for name in ["up_tilt", "neutral_air", "down_special_dive"]:
		assert_eq(moves.get(name), defaults.get(name), name)
	var hammer := moves.neutral_special
	assert_true(hammer.ability is HammerData)
	assert_eq([hammer.startup, hammer.active, hammer.recovery], [10, 0, 12])
	assert_eq([hammer.projectile_speed, hammer.projectile_angle_deg, hammer.projectile_gravity],
		[260.0, 20.0, 600.0])
	assert_eq([hammer.damage, hammer.base_knockback, hammer.knockback_growth], [8.0, 130.0, 0.8])
	var ladder := moves.up_special.ability as LadderData
	assert_eq([moves.up_special.startup, ladder.climb_frames, ladder.climb_speed], [6, 16, 300.0])
	assert_eq([ladder.jump_speed, ladder.jump_drift, ladder.lifetime], [280.0, 90.0, 60])
	var blower := moves.down_special
	assert_true(blower.ability is BlowerData)
	assert_eq([blower.startup, blower.active, blower.recovery], [20, 12, 14])
	assert_eq([blower.damage, blower.knockback_growth], [0.0, 0.0])
	var torch := moves.side_special
	assert_true(torch.ability is TorchData)
	assert_eq([torch.startup, torch.active, torch.recovery], [8, 40, 10])
	assert_eq([torch.damage, (torch.ability as TorchData).hit_interval], [2.0, 8])


# --- Hammer ---------------------------------------------------------------------------------------


func test_hammer_is_thrown_on_frame_10() -> void:
	await _place(Vector2(150, 192), Vector2(380, 192), _special("none"))
	_steps(10)
	assert_eq(_hammers().size(), 0, "not before frame 10")
	_steps(1)
	assert_eq(_hammers().size(), 1)
	assert_almost_eq(_hammers()[0].global_position, Vector2(164, 176), Vector2(3.0, 3.0))


func test_hammer_flies_in_an_arc() -> void:
	await _place(Vector2(150, 192), Vector2(380, 192), _special("none"))
	_steps(11)
	var hammer := _hammers()[0]
	var start := hammer.global_position
	_steps(10)
	assert_gt(hammer.global_position.x, start.x + 30.0, "flies forward")
	assert_lt(hammer.global_position.y, start.y, "rises first")
	_steps(40)
	assert_gt(hammer.global_position.y, start.y, "then falls")


func test_hammer_one_at_a_time() -> void:
	await _place(Vector2(150, 192), Vector2(380, 192), _special("none", 2, 20))
	_steps(30)
	assert_eq(_hammers().size(), 1)
	assert_eq(_p1.move, Fighter.NO_MOVE, "the second press does nothing while it's out")


func test_hammer_lands_and_is_gone() -> void:
	await _place(Vector2(150, 192), Vector2(380, 192), _special("none"))
	_steps(11)
	assert_eq(_hammers().size(), 1)
	_steps(90)
	assert_eq(_hammers().size(), 0)


func test_hammer_hits_and_is_gone() -> void:
	await _place(Vector2(150, 192), Vector2(215, 192), _special("none"))
	_steps(60)
	assert_eq(_p2.percent, 8.0)
	assert_eq(_hammers().size(), 0)


func test_hammer_cannot_hit_its_owner() -> void:
	await _place(Vector2(150, 192), Vector2(380, 192), _special("none"))
	_steps(60)
	assert_eq(_p1.percent, 0.0)


# --- Ladder ---------------------------------------------------------------------------------------


func test_ladder_is_set_up_on_frame_6_and_climbed() -> void:
	await _place(Vector2(150, 192), Vector2(380, 192), _special("up"))
	_steps(6)
	assert_eq(_ladders().size(), 0, "not before frame 6")
	_steps(1)
	assert_eq(_ladders().size(), 1)
	assert_eq(_p1.move, &"ladder_climb")
	var ladder := _ladders()[0]
	assert_almost_eq(ladder.global_position, Vector2(150, 192), Vector2(1.0, 1.0))
	var y := _p1.global_position.y
	_steps(8)
	assert_lt(_p1.global_position.y, y - 30.0, "climbing fast")
	assert_eq(_p1.move, &"ladder_climb")


func test_ladder_climb_has_no_gravity_and_no_hit() -> void:
	await _place(Vector2(150, 192), Vector2(160, 192), _special("up"))
	_steps(12)
	assert_almost_eq(_p1.velocity.y, -300.0, 1.0)
	assert_eq(_p2.percent, 0.0)


func test_ladder_then_jumps_off_and_becomes_helpless() -> void:
	await _place(Vector2(150, 192), Vector2(380, 192), _special("up"))
	_steps(7 + 16 + 2)
	assert_eq(_p1.move, &"up_special", "jumped off")
	assert_true(_p1.launched)
	assert_lt(_p1.velocity.y, 0.0, "still rising")
	var top := _p1.global_position.y
	for i in 120:
		_steps(1)
		top = minf(top, _p1.global_position.y)
		if _p1.state == Fighter.State.HELPLESS:
			break
	assert_eq(_p1.state, Fighter.State.HELPLESS)
	assert_lt(top, 192.0 - 130.0, "climbs further than the default jump boost (108 px)")


func test_ladder_jump_goes_toward_held_direction() -> void:
	var inputs := _special("up", 1, 0)
	for i in 30:
		var hold := FighterInput.new()
		hold.move_x = 1.0
		inputs.append(hold)
	await _place(Vector2(150, 192), Vector2(380, 192), inputs)
	_steps(7 + 16 + 4)
	assert_gt(_p1.velocity.x, 40.0)


func test_ladder_goes_after_its_time() -> void:
	await _place(Vector2(150, 192), Vector2(380, 192), _special("up"))
	_steps(7 + 55)
	assert_eq(_ladders().size(), 1)
	_steps(10)
	assert_eq(_ladders().size(), 0)


func test_ladder_up_special_once_per_air_stay() -> void:
	await _place(Vector2(150, 192), Vector2(380, 192), _special("up"))
	_steps(8)
	assert_false(_p1.up_special_available)


# --- Leaf blower ----------------------------------------------------------------------------------


func test_blower_charges_then_pushes_without_damage() -> void:
	await _place(Vector2(150, 192), Vector2(185, 192), _special("down"))
	_steps(20)
	assert_eq(_p2.state, Fighter.State.IDLE, "still charging up")
	_steps(4)
	assert_eq(_p2.state, Fighter.State.HITSTUN)
	assert_eq(_p2.percent, 0.0, "no damage")
	assert_gt(_p2.velocity.x, 200.0, "pushed away")
	_steps(60)
	assert_eq(_p2.percent, 0.0)
	assert_gt(_p2.global_position.x, 230.0, "ended up well away")


func test_blower_push_does_not_grow_with_percent() -> void:
	await _place(Vector2(150, 192), Vector2(185, 192), _special("down"))
	_p2.percent = 150.0
	_steps(22)
	assert_almost_eq(_p2.velocity.x, 260.0 * cos(deg_to_rad(8.0)), 4.0)


func test_blower_works_in_the_air_without_diving() -> void:
	await _place(Vector2(150, 100), Vector2(380, 192), _special("down"))
	_steps(10)
	assert_eq(_p1.move, &"down_special")
	assert_lt(_p1.velocity.y, 200.0, "no dive")


func test_blower_hits_a_fighter_once() -> void:
	await _place(Vector2(150, 192), Vector2(185, 192), _special("down"))
	_steps(40)
	assert_eq(_p2.percent, 0.0)
	assert_true(_p1.has_hit(1))


# --- Torch ----------------------------------------------------------------------------------------


func test_torch_hits_again_and_again() -> void:
	await _place(Vector2(150, 192), Vector2(178, 192), _special("side"))
	_steps(9)
	assert_eq(_p2.percent, 0.0, "not before frame 9")
	_steps(2)
	assert_eq(_p2.percent, 2.0, "the first hit")
	_steps(40)
	assert_gte(_p2.percent, 6.0, "keeps hitting while the flame is out")
	assert_eq(fmod(_p2.percent, 2.0), 0.0)


func test_torch_makes_no_projectile() -> void:
	await _place(Vector2(150, 192), Vector2(380, 192), _special("side"))
	_steps(20)
	assert_eq(_match.get_projectiles().size(), 0)
	assert_eq(_p1.move, &"side_special")


func test_torch_flame_ends_with_the_move() -> void:
	await _place(Vector2(150, 192), Vector2(380, 192), _special("side"))
	_steps(70)
	assert_eq(_p1.state, Fighter.State.IDLE)


# --- Burning --------------------------------------------------------------------------------------


func _burns() -> Array[MatchEntity]:
	return _match.get_entities(Burn)


func _torch_data() -> TorchData:
	return (_p1.stats.moveset.side_special as MoveData).ability as TorchData


## Steps until P2 burns (at most `limit` steps); returns how many it took, or -1.
func _steps_until_burning(limit: int) -> int:
	for i in limit:
		_match.step()
		if not _burns().is_empty():
			return i + 1
	return -1


func test_burn_numbers() -> void:
	var torch := _torch_data()
	assert_eq(torch.burn_ticks, 180, "3 seconds")
	assert_eq(torch.burn_interval, 30)
	assert_eq(torch.burn_damage, 1.0)


func test_no_burn_while_the_flame_keeps_hitting() -> void:
	await _place(Vector2(150, 192), Vector2(178, 192), _special("side"))
	_steps(12)
	assert_gt(_p2.percent, 0.0, "the flame hit")
	assert_eq(_burns().size(), 0, "not burning while still in the flame")


func test_burn_starts_once_the_flame_stops_hitting() -> void:
	await _place(Vector2(150, 192), Vector2(178, 192), _special("side"))
	var took := _steps_until_burning(120)
	assert_gt(took, 12, "after the flame's hits")
	assert_lte(took, 62, "by the end of the flame")
	assert_eq(_burns().size(), 1)
	assert_eq((_burns()[0] as Burn).victim_index, 1)
	assert_eq(_burns()[0].owner_index, 0)


func test_burn_deals_damage_over_three_seconds_then_goes_out() -> void:
	await _place(Vector2(150, 192), Vector2(178, 192), _special("side"))
	assert_gt(_steps_until_burning(120), 0)
	var before := _p2.percent
	_steps(29)
	assert_eq(_p2.percent, before, "nothing before the first 30 ticks")
	_steps(1)
	assert_eq(_p2.percent, before + 1.0)
	_steps(150)
	assert_eq(_p2.percent, before + 6.0, "1 % every 30 ticks for 180 ticks")
	assert_eq(_burns().size(), 0, "out after 3 s")
	_steps(60)
	assert_eq(_p2.percent, before + 6.0)


func test_burn_has_no_knockback() -> void:
	await _place(Vector2(150, 192), Vector2(178, 192), _special("side"))
	assert_gt(_steps_until_burning(120), 0)
	_steps(40)
	assert_ne(_p2.state, Fighter.State.HITSTUN)
	assert_true(_p2.is_on_floor())


func test_burn_does_not_stack() -> void:
	await _place(Vector2(150, 192), Vector2(300, 192), [])
	Burn.ignite(_match, 0, _p2, _torch_data())
	_steps(100)
	Burn.ignite(_match, 0, _p2, _torch_data())
	assert_eq(_burns().size(), 1, "one burn per fighter")
	_steps(179)
	assert_eq(_burns().size(), 1, "catching fire again restarted the 3 s")
	assert_eq(_p2.percent, 3.0 + 5.0, "3 % from the first, then the restarted burn's own")
	_steps(1)
	assert_eq(_burns().size(), 0)
	assert_eq(_p2.percent, 9.0)


func test_a_shield_keeps_the_flame_from_burning() -> void:
	var shielding: Array[FighterInput] = []
	for i in 120:
		var input := FighterInput.new()
		input.shield_held = true
		input.shield_pressed = i == 0
		shielding.append(input)
	await _place(Vector2(150, 192), Vector2(178, 192), _special("side"), shielding)
	_steps(90)
	assert_eq(_p2.percent, 0.0)
	assert_eq(_burns().size(), 0)


func test_a_ko_puts_the_burn_out() -> void:
	await _place(Vector2(150, 192), Vector2(300, 192), [])
	Burn.ignite(_match, 0, _p2, _torch_data())
	_steps(2)
	_p2.global_position = Vector2(2000, 100)
	_steps(2)
	assert_eq(_burns().size(), 0)


# --- Normal attacks: hammer, axe, screwdriver -----------------------------------------------------


func test_kim_has_his_own_normals() -> void:
	var defaults := (load("res://fighter/default_stats.tres") as FighterStats).moveset
	var moves := _p1.stats.moveset
	for name in ["jab", "side_tilt", "down_tilt"]:
		assert_ne(moves.get(name), defaults.get(name), name)
		assert_true(moves.get(name).ability is ToolSwingData, name)
	for name in ["up_tilt", "neutral_air", "forward_air", "back_air", "up_air", "down_air"]:
		assert_eq(moves.get(name), defaults.get(name), name)
	assert_eq([moves.jab.startup, moves.jab.active, moves.jab.recovery], [4, 3, 7])
	assert_eq([moves.side_tilt.startup, moves.side_tilt.active, moves.side_tilt.recovery], [12, 4, 14])
	assert_eq([moves.down_tilt.startup, moves.down_tilt.active, moves.down_tilt.recovery], [5, 4, 8])
	assert_eq([moves.jab.damage, moves.side_tilt.damage, moves.down_tilt.damage], [4.0, 14.0, 5.0])
	assert_eq([moves.jab.ability.tool, moves.side_tilt.ability.tool, moves.down_tilt.ability.tool],
		[&"hammer", &"axe", &"screwdriver"])


func test_hammer_jab_hits_on_frame_5() -> void:
	await _place(Vector2(150, 192), Vector2(172, 192), _attack("none"))
	_steps(5)
	assert_eq(_p2.percent, 0.0, "not before frame 4 ends")
	_steps(2)
	assert_eq(_p2.percent, 4.0)
	assert_gt(_p2.velocity.x, 0.0)


func test_axe_is_slow_strong_and_reaches_far() -> void:
	await _place(Vector2(150, 192), Vector2(190, 192), _attack("side"))
	_steps(13)
	assert_eq(_p2.percent, 0.0, "slow: nothing by frame 12")
	_steps(3)
	assert_eq(_p2.percent, 14.0)
	assert_gt(_p2.velocity.length(), 200.0, "strong")


func test_jab_does_not_reach_as_far_as_the_axe() -> void:
	await _place(Vector2(150, 192), Vector2(190, 192), _attack("none"))
	_steps(30)
	assert_eq(_p2.percent, 0.0)


func test_screwdriver_stabs_low_and_pops_up() -> void:
	await _place(Vector2(150, 192), Vector2(185, 192), _attack("down"))
	_steps(5)
	assert_eq(_p2.percent, 0.0)
	_steps(3)
	assert_eq(_p2.percent, 5.0)
	assert_lt(_p2.velocity.y, 0.0, "popped up")


func test_screwdriver_passes_under_a_high_target() -> void:
	# A fighter in the air well above the floor isn't touched by the low stab.
	await _place(Vector2(150, 192), Vector2(185, 192), _attack("down"))
	_p2.global_position.y = 140.0
	_steps(12)
	assert_eq(_p2.percent, 0.0)


func test_tool_swing_stretches_the_body_drawings_over_the_frames() -> void:
	await _place(Vector2(150, 192), Vector2(380, 192), _attack("side"))
	var swing: FighterAbility = null
	for a in _p1.abilities:
		if a.slot == &"side_tilt":
			swing = a
	_steps(7)
	assert_eq(swing.drawing("side_tilt", 0), 0, "winding up")
	_steps(8)
	assert_eq(swing.drawing("side_tilt", 0), 2, "the strike drawing on the active frames")
	_steps(12)
	assert_gte(swing.drawing("side_tilt", 0), 3, "recovering")
