extends GutTest
## Pia's specials (docs/specs/characters/pia.md#pia--cake-belly-flop-flag): eating cake (neutral special:
## heals, with a cooldown), the belly flop (down special: on the ground a hop, then flat on her
## belly she drops — the belly spikes — and the landing's shockwave hits on both sides) and the
## German flag (side special). P1 is Pia; scripted [idle, special] starts a move on step 2.
## Main platform top y 192 (x 96…384); the left platform spans x 132…204.

const MATCH_SCENE := preload("res://match/match.tscn")
const PIA := "slot_01"

var _match: Match
var _p1: Fighter
var _p2: Fighter
var _saved_ids: Array[String] = []


func before_each() -> void:
	_saved_ids = [Game.character_id, Game.p2_character_id]
	Game.character_id = PIA
	Game.p2_character_id = "slot_09"
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


## Steps until Pia is in `phase` (at most `limit` steps); returns the steps taken, or -1.
func _step_until_move(phase: StringName, limit: int = 120) -> int:
	for i in limit:
		_match.step()
		if _p1.state == Fighter.State.ATTACK and _p1.move == phase:
			return i + 1
	return -1


func _special(down := false, move_x := 0.0) -> FighterInput:
	var special := FighterInput.new()
	special.special_pressed = true
	special.special_held = true
	special.down_held = down
	special.move_x = move_x
	return special


## [idle, down special].
func _flop() -> Array[FighterInput]:
	return [FighterInput.new(), _special(true)]


## [idle, neutral special].
func _cake() -> Array[FighterInput]:
	return [FighterInput.new(), _special()]


func _shield(ticks: int) -> Array[FighterInput]:
	var inputs: Array[FighterInput] = []
	for i in ticks:
		var shield := FighterInput.new()
		shield.shield_held = true
		inputs.append(shield)
	return inputs


# --- Data -----------------------------------------------------------------------------------------


func test_the_flop_matches_the_spec() -> void:
	var flop := _p1.stats.moveset.down_special
	assert_eq([flop.startup, flop.active, flop.recovery], [0, 6, 22])
	assert_eq([flop.hitbox_center, flop.hitbox_size], [Vector2(0, -8), Vector2(80, 16)])
	assert_eq([flop.damage, flop.base_knockback, flop.knockback_growth, flop.angle_deg],
		[11.0, 200.0, 1.4, 70.0])
	assert_eq(flop.direction, MoveData.Direction.AWAY)
	assert_eq([(flop.ability as FlopData).hop_speed, flop.dive_speed], [240.0, 400.0])
	assert_eq([(flop.ability as FlopData).dive_ticks_per_damage, (flop.ability as FlopData).max_dive_damage],
		[5, 10.0])


func test_the_belly_dive_matches_the_spec() -> void:
	var dive := (_p1.stats.moveset.down_special.ability as FlopData).dive_hit
	assert_not_null(dive)
	assert_eq([dive.hitbox_center, dive.hitbox_size], [Vector2(0, -7), Vector2(36, 14)])
	assert_eq([dive.damage, dive.base_knockback, dive.knockback_growth, dive.angle_deg],
		[7.0, 150.0, 1.1, -70.0])
	assert_eq(dive.direction, MoveData.Direction.AWAY)
	assert_true(dive.is_active_frame(1) and dive.is_active_frame(300), "out for the whole dive")


func test_the_cake_matches_the_spec() -> void:
	var cake := _p1.stats.moveset.neutral_special
	assert_eq([cake.startup, cake.active, cake.recovery], [45, 0, 15])
	var eating := cake.ability as CakeData
	assert_eq([eating.heal, eating.heal_frame, eating.cooldown_frames], [8.0, 45, 300])


func test_the_flag_matches_the_spec() -> void:
	var flag := _p1.stats.moveset.side_special
	assert_eq([flag.startup, flag.active, flag.recovery], [10, 0, 12])
	assert_eq([flag.hitbox_center, flag.hitbox_size], [Vector2(16, -16), Vector2(12, 8)])
	assert_eq([flag.damage, flag.base_knockback, flag.knockback_growth, flag.angle_deg],
		[6.0, 100.0, 0.6, 30.0])
	assert_eq([flag.projectile_speed, flag.projectile_lifetime], [260.0, 120])


func test_nobody_else_hops_or_eats() -> void:
	var default := (load("res://fighter/default_stats.tres") as FighterStats).moveset
	for data in [default.neutral_special, default.down_special]:
		assert_null(data.ability)


# --- Belly flop: the hop and the dive -------------------------------------------------------------


func test_on_the_ground_she_hops_first() -> void:
	await _place(Vector2(240, 192), Vector2(380, 192), _flop())
	_steps(2)
	assert_eq(_p1.state, Fighter.State.ATTACK)
	assert_eq(_p1.move, &"belly_hop")
	assert_almost_eq(_p1.velocity.y, -240.0 + 600.0 / 60.0, 0.01, "launched up, then gravity")
	assert_false(_p1.is_hitbox_active(), "no hitbox on the way up")
	_steps(10)
	assert_lt(_p1.global_position.y, 192.0 - 20.0, "in the air")
	assert_eq(_p1.move, &"belly_hop", "still rising")


func test_the_hop_turns_into_the_dive_when_she_stops_rising() -> void:
	await _place(Vector2(240, 192), Vector2(380, 192), _flop())
	_steps(2)
	assert_eq(_p1.move, &"belly_hop")
	var top := _p1.global_position.y
	var steps := 1
	while _p1.move == &"belly_hop" and steps < 60:
		top = minf(top, _p1.global_position.y)
		_match.step()
		steps += 1
	assert_eq(_p1.move, &"belly_dive")
	assert_between(steps, 20, 30, "about 24 ticks up")
	assert_between(top, 192.0 - 56.0, 192.0 - 40.0, "about 46 px high")
	_steps(1)
	assert_eq(_p1.velocity.y, 400.0, "drops at the dive speed")
	assert_true(_p1.is_hitbox_active(), "the belly hits on the way down")


func test_in_the_air_she_flops_at_once() -> void:
	# x 110: clear of the left platform (x 132…204), so she lands on the main platform.
	await _place(Vector2(110, 100), Vector2(380, 192), _flop())
	_steps(2)
	assert_eq(_p1.move, &"belly_dive")
	assert_eq(_p1.velocity.y, 400.0)


func test_the_belly_spikes_a_fighter_below() -> void:
	await _place(Vector2(110, 100), Vector2(110, 140), _flop())
	_steps(2)
	for i in 30:
		_match.step()
		if _p2.percent > 0.0:
			break
	assert_eq(_p2.percent, 7.0, "the belly hits on the way down")
	assert_gt(_p2.velocity.y, 0.0, "driven down")


# --- Belly flop: the landing ----------------------------------------------------------------------


func test_the_flop_hits_on_the_landing_tick() -> void:
	watch_signals(_match)
	await _place(Vector2(240, 192), Vector2(270, 192), _flop())
	_steps(1)
	assert_gt(_step_until_move(&"belly_flop"), 0, "lands into the flop")
	assert_true(_p1.is_on_floor())
	assert_true(_p1.is_hitbox_active(), "the impact is on the landing tick")
	assert_eq(_p2.state, Fighter.State.HITSTUN)
	assert_eq(_p2.percent, 12.0, "11, +1 for the short dive after the hop")
	assert_gt(_p2.velocity.x, 0.0, "away from her")
	var angle := rad_to_deg(atan2(-_p2.velocity.y, _p2.velocity.x))
	assert_almost_eq(angle, 70.0, 0.5, "70° above horizontal")
	assert_signal_emitted(_match, "fighter_hit")


func test_the_flop_hits_behind_her_too() -> void:
	await _place(Vector2(240, 192), Vector2(210, 192), _flop())
	_steps(1)
	_step_until_move(&"belly_flop")
	assert_eq(_p2.percent, 12.0)
	assert_lt(_p2.velocity.x, 0.0, "launched away from her, to the left")


func test_the_flop_misses_far_away() -> void:
	await _place(Vector2(240, 192), Vector2(300, 192), _flop())
	_steps(80)
	assert_eq(_p2.percent, 0.0)


func test_a_shield_blocks_the_flop() -> void:
	await _place(Vector2(240, 192), Vector2(270, 192), _flop(), _shield(80))
	_steps(1)
	_step_until_move(&"belly_flop")
	_steps(1)
	assert_eq(_p2.state, Fighter.State.SHIELD)
	assert_eq(_p2.percent, 0.0)


## Pia dives from `height` px above the main platform onto P2 standing next to her; P2's damage.
## x 110: clear of the platforms above the main one.
func _flop_from(height: float) -> float:
	await _place(Vector2(110, 192 - height), Vector2(140, 192), _flop())
	_steps(1)
	assert_gt(_step_until_move(&"belly_flop", 240), 0, "lands into the flop")
	return _p2.percent


func test_a_longer_dive_hits_harder() -> void:
	var ticks := 0
	await _place(Vector2(110, 92), Vector2(140, 192), _flop())
	_steps(1)
	while _p1.move != &"belly_flop" and ticks < 240:
		_match.step()
		if _p1.move == &"belly_dive":
			ticks += 1
	ticks += 1  # The landing tick moves at the dive speed too.
	assert_eq(_p2.percent, 11.0 + floorf(ticks / 5.0), "+1 per 5 ticks of diving")
	assert_gt(_p2.percent, 12.0, "harder than from the ground")


func test_a_drop_from_the_top_reaches_the_cap() -> void:
	# 340 px: just under the blast zone's top (y −160), about 51 ticks of diving.
	assert_eq(await _flop_from(340.0), 21.0, "11 + at most 10")


func test_the_dive_bonus_is_capped() -> void:
	for a in _p1.abilities:
		if a is FlopAbility:
			var low_cap := a.data.duplicate() as FlopData
			low_cap.max_dive_damage = 2.0
			a.data = low_cap
	assert_eq(await _flop_from(300.0), 13.0, "11 + at most the cap")


func test_a_flop_from_higher_up_launches_further() -> void:
	await _flop_from(40.0)
	var low := _p2.velocity.length()
	var high_percent := await _flop_from(300.0)
	assert_gt(high_percent, 12.0)
	assert_gt(_p2.velocity.length(), low, "more damage, more knockback")


func test_the_bonus_starts_over_each_flop() -> void:
	await _flop_from(300.0)
	_p2.percent = 0.0
	_p2.spawn_at(Vector2(140, 192), -1)
	_steps(40)
	_match.set_controller(0, ScriptedController.new(_flop()))
	_steps(1)
	_step_until_move(&"belly_flop")
	assert_eq(_p2.percent, 12.0, "a ground flop again")


func test_she_gets_up_after_the_flop() -> void:
	await _place(Vector2(240, 192), Vector2(380, 192), _flop())
	_steps(1)
	_step_until_move(&"belly_flop")
	_steps(27)
	assert_eq(_p1.state, Fighter.State.ATTACK, "still on the floor on frame 28")
	_steps(1)
	assert_eq(_p1.state, Fighter.State.IDLE)


func test_a_hit_stops_the_hop() -> void:
	await _place(Vector2(240, 192), Vector2(380, 192), _flop())
	_steps(4)
	_p1.take_hit(_p1.stats.moveset.jab, -1, _p2.global_position.x)
	assert_eq(_p1.state, Fighter.State.HITSTUN)
	assert_eq(_p1.move, Fighter.NO_MOVE)


# --- Cake -----------------------------------------------------------------------------------------


func test_eating_cake_heals_on_frame_45() -> void:
	await _place(Vector2(240, 192), Vector2(380, 192), _cake())
	_p1.percent = 20.0
	_steps(2)
	assert_eq(_p1.move, &"cake")
	_steps(43)  # Frame N is step N + 1.
	assert_eq(_p1.percent, 20.0, "not yet on frame 44")
	_steps(1)
	assert_eq(_p1.percent, 12.0, "8 % less on frame 45")
	assert_eq(_eating().cake_cooldown, 300)
	_steps(15)
	assert_eq(_p1.state, Fighter.State.ATTACK, "still eating on frame 60")
	_steps(1)
	assert_eq(_p1.state, Fighter.State.IDLE, "done after 60 frames")


func test_cake_never_heals_below_zero() -> void:
	await _place(Vector2(240, 192), Vector2(380, 192), _cake())
	_p1.percent = 3.0
	_steps(47)
	assert_eq(_p1.percent, 0.0)


func test_no_second_slice_during_the_cooldown() -> void:
	var inputs := _cake()
	for i in 60:
		inputs.append(FighterInput.new())
	inputs.append(_special())
	await _place(Vector2(240, 192), Vector2(380, 192), inputs)
	_steps(63)
	assert_ne(_p1.state, Fighter.State.ATTACK, "the second press does nothing")
	assert_gt(_eating().cake_cooldown, 0)


func test_the_cooldown_runs_out() -> void:
	await _place(Vector2(240, 192), Vector2(380, 192), _cake())
	_steps(47)
	_steps(300)
	assert_eq(_eating().cake_cooldown, 0)


func test_no_cake_in_the_air() -> void:
	await _place(Vector2(110, 100), Vector2(380, 192), _cake())
	_steps(2)
	assert_ne(_p1.state, Fighter.State.ATTACK)


func test_a_hit_before_the_bite_means_no_heal() -> void:
	await _place(Vector2(240, 192), Vector2(380, 192), _cake())
	_p1.percent = 20.0
	_steps(20)
	_p1.take_hit(_p1.stats.moveset.jab, -1, _p2.global_position.x)
	_steps(40)
	assert_eq(_p1.percent, 23.0, "the jab's 3 %, no heal")
	assert_eq(_eating().cake_cooldown, 0, "no slice eaten, no cooldown")


func test_spawning_clears_the_cooldown() -> void:
	await _place(Vector2(240, 192), Vector2(380, 192), _cake())
	_steps(47)
	_p1.spawn_at(Vector2(240, 192), 1)
	assert_eq(_eating().cake_cooldown, 0)


# --- Flag -----------------------------------------------------------------------------------------


func test_the_flag_flies_straight_and_hits() -> void:
	await _place(Vector2(200, 192), Vector2(290, 192), [FighterInput.new(), _special(false, 1.0)])
	_steps(2)
	assert_eq(_p1.move, &"side_special")
	for i in 40:
		_match.step()
		if _p2.percent > 0.0:
			break
	assert_eq(_p2.percent, 6.0)
	assert_gt(_p2.velocity.x, 0.0, "launched away from her")


# --- Look -----------------------------------------------------------------------------------------


func test_animations_for_her_phases() -> void:
	assert_eq(FighterVisuals.animation_for(Fighter.State.ATTACK, -100.0, &"belly_hop", FighterVisuals.phase_animations_of(_p1)), "jump")
	assert_eq(FighterVisuals.animation_for(Fighter.State.ATTACK, 0.0, &"belly_dive", FighterVisuals.phase_animations_of(_p1)),
		"down_special_dive")
	assert_eq(FighterVisuals.animation_for(Fighter.State.ATTACK, 0.0, &"belly_flop", FighterVisuals.phase_animations_of(_p1)),
		"down_special")
	assert_eq(FighterVisuals.animation_for(Fighter.State.ATTACK, 0.0, &"cake", FighterVisuals.phase_animations_of(_p1)), "neutral_special")


func test_cake_drawings_follow_the_bites() -> void:
	var expected := {1: 0, 10: 0, 11: 1, 19: 1, 20: 2, 28: 2, 29: 1, 37: 1, 38: 2, 45: 2,
		46: 3, 52: 3, 53: 3, 60: 3}
	for ticks: int in expected:
		assert_eq(CakeAbility.cake_frame(ticks), expected[ticks], "tick %d" % ticks)


## The belly-flop drawings lie flat: wider than tall, resting on the floor row.
func test_her_dive_and_flop_drawings_lie_flat() -> void:
	for animation in ["down_special_dive", "down_special"]:
		var image := (load("res://assets/fighters/%s/fighter_%s.png" % [PIA, animation])
			as Texture2D).get_image()
		var size := image.get_height()
		assert_eq(image.get_width(), size * (1 if animation == "down_special_dive" else 5))
		var used := image.get_region(Rect2i(0, 0, size, size)).get_used_rect()
		assert_gt(used.size.x, used.size.y * 1.4, "%s drawing 1 lies flat" % animation)
		if animation == "down_special":
			assert_eq(used.end.y, size, "her belly on the floor row")


func test_she_has_dust_and_a_flag() -> void:
	var dust := load("res://assets/fighters/%s/dust.png" % PIA) as Texture2D
	assert_eq(dust.get_size(), Vector2(40 * FlopAbility.DUST_DRAWINGS, 20))
	var flag := load("res://assets/fighters/%s/projectile.png" % PIA) as Texture2D
	assert_eq(flag.get_size(), Vector2(32 * 3, 32))


## Her cake ability.
func _eating() -> CakeAbility:
	return _p1.ability(CakeAbility) as CakeAbility
