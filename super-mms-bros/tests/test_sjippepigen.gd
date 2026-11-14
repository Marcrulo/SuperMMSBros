extends GutTest
## Sjippepigen's jump ropes (docs/specs/characters/sjippepigen.md#sjippepigen--jump-ropes): three ropes always
## spinning round her, hurting with their tips; no attacks; down special switches short ↔ long;
## up special is the lasso.
## P1 is Sjippepigen. Main platform top y 192 (x 96…384).

const MATCH_SCENE := preload("res://match/match.tscn")
const SJIPPE := "slot_12"

var _match: Match
var _p1: Fighter
var _p2: Fighter
var _saved_ids: Array[String] = []


func before_each() -> void:
	_saved_ids = [Game.character_id, Game.p2_character_id]
	Game.character_id = SJIPPE
	Game.p2_character_id = "slot_09"
	_match = MATCH_SCENE.instantiate()
	_match.auto_step = false
	add_child_autofree(_match)
	_p1 = _match.get_fighter(0)
	_p2 = _match.get_fighter(1)


func after_each() -> void:
	Game.character_id = _saved_ids[0]
	Game.p2_character_id = _saved_ids[1]


func _place(p1_at: Vector2, p2_at: Vector2, p1_inputs: Array[FighterInput] = [],
		p2_inputs: Array[FighterInput] = []) -> void:
	_p1.spawn_at(p1_at, 1)
	_p2.spawn_at(p2_at, -1)
	_match.set_controller(0, ScriptedController.new(p1_inputs))
	_match.set_controller(1, ScriptedController.new(p2_inputs))
	await wait_physics_frames(1)


func _steps(count: int) -> void:
	for i in count:
		_match.step()


func _ropes() -> RopeData:
	return _p1.stats.moveset.ability as RopeData


## [idle, a press of `kind`]: "attack", "special" (neutral), "side", "up", "down" (specials).
func _press(kind: String) -> Array[FighterInput]:
	var input := FighterInput.new()
	if kind == "attack":
		input.attack_pressed = true
	else:
		input.special_pressed = true
		input.special_held = true
		input.move_x = 1.0 if kind == "side" else 0.0
		input.up_held = kind == "up"
		input.down_held = kind == "down"
	return [FighterInput.new(), input]


## Steps until P2 is first hurt (at most `limit` steps); returns how many it took, or -1.
func _steps_until_hurt(limit: int) -> int:
	for i in limit:
		_match.step()
		if _p2.percent > 0.0:
			return i + 1
	return -1


# --- Data -----------------------------------------------------------------------------------------


func test_the_ropes_match_the_spec() -> void:
	var toggle := _p1.stats.moveset.down_special
	assert_true(_ropes().down_special_switches)
	assert_eq([toggle.startup, toggle.active, toggle.recovery], [6, 0, 6])
	var ropes := _ropes()
	assert_eq(ropes.count, 3)
	assert_eq(ropes.center, Vector2(0, -14))
	assert_eq([ropes.short_radius, ropes.long_radius], [Vector2(18, 24), Vector2(34, 34)])
	assert_eq([ropes.short_period, ropes.long_period], [30, 48])
	assert_eq(ropes.tip_size, Vector2(10, 10))
	assert_eq(ropes.immune_frames, 30)
	assert_eq([ropes.short_hit.damage, ropes.short_hit.base_knockback, ropes.short_hit.knockback_growth,
		ropes.short_hit.angle_deg], [3.0, 110.0, 1.0, 40.0], "short: the strong one")
	assert_eq([ropes.long_hit.damage, ropes.long_hit.base_knockback, ropes.long_hit.knockback_growth,
		ropes.long_hit.angle_deg], [2.0, 60.0, 0.4, 40.0], "long: the weak one")
	assert_null(_p2.stats.moveset.ability, "only her")


# --- No attacks -----------------------------------------------------------------------------------


func test_she_has_no_attacks() -> void:
	for kind in ["attack", "side"]:
		await _place(Vector2(200, 192), Vector2(380, 192), _press(kind))
		_steps(3)
		assert_ne(_p1.state, Fighter.State.ATTACK, kind)


func test_down_special_switches_the_rope_length() -> void:
	await _place(Vector2(200, 192), Vector2(380, 192), _press("down"))
	assert_false(_rope().rope_long, "short at every spawn")
	_steps(6)
	assert_false(_rope().rope_long, "not yet")
	_steps(1)
	assert_true(_rope().rope_long, "switched on frame 6")
	_steps(10)
	assert_ne(_p1.state, Fighter.State.ATTACK)


func test_it_switches_in_the_air_too() -> void:
	await _place(Vector2(200, 60), Vector2(380, 192), _press("down"))
	_steps(7)
	assert_true(_rope().rope_long)


func test_a_respawn_brings_back_short_ropes() -> void:
	await _place(Vector2(200, 192), Vector2(380, 192))
	_steps(5)
	_rope().rope_long = true
	_p1.spawn_at(Vector2(200, 192), 1)
	assert_false(_rope().rope_long)
	assert_eq(_rope().rope_tick, 0)


# --- Spinning -------------------------------------------------------------------------------------


func test_the_tips_go_round_her() -> void:
	await _place(Vector2(200, 192), Vector2(380, 192))
	var middle := Vector2(200, 192 - 14)
	assert_almost_eq(_rope().rope_tip(0), middle + Vector2(0, -24), Vector2(0.01, 0.01), "over her head")
	_rope().rope_turns = 0.5
	assert_almost_eq(_rope().rope_tip(0), middle + Vector2(0, 24), Vector2(0.01, 0.01), "under her feet")
	_rope().rope_turns = 0.0
	var front := _rope().rope_tip(1)  # A third of a turn on: down in front.
	assert_gt(front.x, middle.x)
	_p1.facing = -1
	assert_lt(_rope().rope_tip(1).x, middle.x, "mirrored facing left")


func test_the_ropes_spin_only_while_she_isnt_stunned() -> void:
	await _place(Vector2(200, 192), Vector2(380, 192))
	_steps(5)
	assert_eq(_rope().rope_tick, 5)
	_p1.take_hit(_p2.stats.moveset.jab, -1, 300.0)
	assert_false(_rope().ropes_active())
	var tick := _rope().rope_tick
	_steps(3)
	assert_eq(_rope().rope_tick, tick, "stopped while in hitstun")


# --- Hits -----------------------------------------------------------------------------------------


func test_a_rope_hurts_an_opponent_beside_her() -> void:
	await _place(Vector2(200, 192), Vector2(220, 192))
	assert_gt(_steps_until_hurt(30), 0, "a tip swept through")
	assert_almost_eq(_p2.percent, 3.0, 0.001, "a short rope's hit")
	assert_gt(_p2.velocity.x, 0.0, "away from her")


func test_a_shield_blocks_the_ropes() -> void:
	var shield: Array[FighterInput] = []
	for i in 60:
		var input := FighterInput.new()
		input.shield_held = true
		shield.append(input)
	await _place(Vector2(200, 192), Vector2(220, 192), [], shield)
	var health := _p2.shield_health
	_steps(40)
	assert_eq(_p2.percent, 0.0)
	assert_lt(_p2.shield_health, health - 1.0, "blocked, not just drained")


func test_long_ropes_reach_further_but_hurt_less() -> void:
	await _place(Vector2(200, 192), Vector2(234, 192))
	assert_eq(_steps_until_hurt(60), -1, "short ropes don't reach")
	_rope().rope_long = true
	assert_gt(_steps_until_hurt(60), 0, "long ones do")
	assert_almost_eq(_p2.percent, 2.0, 0.001, "a long rope's hit")


func test_each_rope_hits_once_per_turn() -> void:
	await _place(Vector2(200, 192), Vector2(380, 192))
	assert_true(_rope().rope_can_hit(0, 1))
	_rope().register_rope_hit(0, 1)
	assert_false(_rope().rope_can_hit(0, 1), "this turn")
	assert_true(_rope().rope_can_hit(1, 1), "another rope")
	_rope().rope_turns += 1.0
	assert_true(_rope().rope_can_hit(0, 1), "the next turn")


## Runs FighterVisuals._draw with the ropes, facing either way.
func test_the_ropes_are_drawn() -> void:
	await _place(Vector2(200, 192), Vector2(380, 192))
	_steps(5)
	await wait_frames(2)
	_p1.facing = -1
	_rope().rope_long = true
	await wait_frames(2)
	assert_true(_rope().ropes_active())


## Every drawing has her three pairs' hand positions, so each rope hangs between its pair's hands.
func test_each_rope_hangs_between_a_pair_of_hands() -> void:
	for animation: String in FighterVisuals.ANIMATIONS:
		var drawings: int = FighterVisuals.ANIMATIONS[animation].ticks.size()
		for frame in drawings:
			for pair in 3:
				var hands := RopeAbility.rope_hands(SJIPPE, animation, frame, pair)
				assert_ne(hands[0], RopeAbility.ROPE_HANDS, "%s %d pair %d" % [animation, frame, pair])
				assert_lt(hands[0].distance_to(Vector2(0, -14)), 24.0, "near her body")
	var idle := RopeAbility.rope_hands(SJIPPE, "idle", 0, 1)
	assert_ne(idle[0], idle[1], "two different hands")
	assert_eq(RopeAbility.rope_hands("slot_09", "idle", 0, 0),
		[RopeAbility.ROPE_HANDS, RopeAbility.ROPE_HANDS], "no hands file: a fallback")


## A rope's loop starts in one hand, ends in the other, and goes through its tip (without lag).
func test_a_rope_loop_runs_hand_to_tip_to_hand() -> void:
	var a := Vector2(3, -12)
	var b := Vector2(-4, -15)
	var tip := Vector2(20, -30)
	var none := Vector2.ZERO
	assert_almost_eq(RopeAbility.rope_loop_point(a, b, tip, none, 0.0), a, Vector2(0.01, 0.01))
	assert_almost_eq(RopeAbility.rope_loop_point(a, b, tip, none, PI), b, Vector2(0.01, 0.01))
	assert_almost_eq(RopeAbility.rope_loop_point(a, b, tip, none, PI / 2.0), tip, Vector2(0.01, 0.01))
	var side1 := RopeAbility.rope_loop_point(a, b, tip, none, PI / 4.0)
	var side2 := RopeAbility.rope_loop_point(a, b, tip, none, 3.0 * PI / 4.0)
	assert_gt(side1.distance_to(side2), (a - b).length() * 1.5, "a rounded loop, not a thin V")



## After a rope hurts someone, no rope can hurt them again for 30 ticks.
func test_a_rope_hit_gives_a_short_rope_immunity() -> void:
	await _place(Vector2(200, 192), Vector2(220, 192))
	assert_gt(_steps_until_hurt(30), 0)
	assert_eq(_rope().immune_frames(1), 29, "30 ticks, counting the tick of the hit")
	# Keep P2 standing beside her, so the ropes keep sweeping through.
	var hurt := _p2.percent
	for i in 28:
		_p2.global_position = Vector2(220, 192)
		_p2.velocity = Vector2.ZERO
		_match.step()
	assert_eq(_p2.percent, hurt, "no rope hits while immune")
	assert_eq(_rope().immune_frames(1), 1)
	var hit_again := false
	for i in 40:
		_p2.global_position = Vector2(220, 192)
		_p2.velocity = Vector2.ZERO
		_match.step()
		hit_again = hit_again or _p2.percent > hurt
	assert_true(hit_again, "ropes hurt again afterwards")


func test_a_blocked_rope_gives_no_immunity() -> void:
	var shield: Array[FighterInput] = []
	for i in 60:
		var input := FighterInput.new()
		input.shield_held = true
		shield.append(input)
	await _place(Vector2(200, 192), Vector2(220, 192), [], shield)
	_steps(30)
	assert_eq(_rope().immune_frames(1), 0)


## Her ropes stop (no spinning, no hits) while she shields or dodges.
func test_the_ropes_rest_while_she_shields_or_dodges() -> void:
	var shield: Array[FighterInput] = []
	for i in 40:
		var input := FighterInput.new()
		input.shield_held = true
		shield.append(input)
	await _place(Vector2(200, 192), Vector2(220, 192), shield)
	_steps(2)
	assert_eq(_p1.state, Fighter.State.SHIELD)
	assert_false(_rope().ropes_active())
	var tick := _rope().rope_tick
	_steps(30)
	assert_eq(_rope().rope_tick, tick, "not spinning")
	assert_eq(_p2.percent, 0.0, "not hurting")
	for state in [Fighter.State.SPOT_DODGE, Fighter.State.ROLL, Fighter.State.AIR_DODGE,
			Fighter.State.SHIELD_DROP]:
		_p1.state = state
		assert_false(_rope().ropes_active(), Fighter.State.keys()[state])



# --- Look: her colors -----------------------------------------------------------------------------


func test_her_ropes_are_her_own_colors() -> void:
	var colors := FighterVisuals.rope_colors_for(SJIPPE)
	assert_eq(colors.size(), 3)
	assert_true(colors[0].is_equal_approx(Color8(120, 128, 80)), "her patina green")
	assert_eq(FighterVisuals.rope_colors_for("slot_09").size(), 0, "others: the defaults")


# --- Up special: the lasso ------------------------------------------------------------------------


func _lasso() -> VineData:
	return _p1.stats.moveset.up_special.ability as VineData


func test_the_lasso_matches_the_spec() -> void:
	var up := _p1.stats.moveset.up_special
	assert_eq([up.startup, up.active, up.recovery], [6, 0, 0])
	var lasso := _lasso()
	assert_eq([lasso.length, lasso.swing_degrees, lasso.swing_frames, lasso.ledge_range,
		lasso.pull_frames], [140.0, 60.0, 30, 100.0, 12], "Fidusen's vine numbers")
	assert_eq([lasso.grab_range, lasso.reel_frames, lasso.reel_to, lasso.pop_speed, lasso.swing,
		lasso.miss_frames], [100.0, 12, Vector2(16, 0), 260.0, false, 18])
	var hit := lasso.grab_hit
	assert_eq([hit.damage, hit.base_knockback, hit.knockback_growth, hit.angle_deg],
		[7.0, 160.0, 1.0, 45.0])


func test_the_lasso_pulls_her_to_a_nearby_ledge() -> void:
	await _place(Vector2(420, 240), Vector2(150, 192), _press("up"))
	_steps(7)
	assert_eq(_p1.move, &"vine_pull")
	_steps(15)
	assert_eq(_p1.state, Fighter.State.LEDGE)
	assert_eq(_p1.ledge.point, Vector2(384, 192))


func test_the_lasso_catches_someone_in_the_air() -> void:
	# Both start at rest in the air and fall alike while she winds up.
	await _place(Vector2(200, 100), Vector2(250, 80), _press("up"))
	_steps(7)
	assert_eq(_p2.state, Fighter.State.HELD, "caught on frame 6")
	assert_eq(_p1.move, &"lasso_reel")
	assert_false(_p1.can_be_hit(), "not while reeling in")
	_steps(6)
	assert_lt(_p2.global_position.x, 250.0 - 10.0, "being reeled in")
	_steps(6)
	assert_eq(_p2.state, Fighter.State.HITSTUN, "whipped away")
	assert_almost_eq(_p2.percent, 7.0, 0.001)
	assert_gt(_p2.velocity.x, 0.0, "forward")
	assert_eq(_p1.move, &"up_special", "she pops up")
	assert_lt(_p1.velocity.y, 0.0)


func test_the_lasso_misses_someone_behind_her() -> void:
	await _place(Vector2(200, 100), Vector2(160, 100), _press("up"))
	_steps(7)
	assert_ne(_p2.state, Fighter.State.HELD)
	assert_eq(_p1.move, &"lasso_miss", "nothing caught: a miss")


func test_with_nothing_in_reach_the_lasso_misses() -> void:
	await _place(Vector2(200, 20), Vector2(380, 192), _press("up"))
	_steps(7)
	assert_eq(_p1.move, &"lasso_miss", "no swing from the ceiling")
	assert_false(_lasso().swing)
	var y := _p1.global_position.y
	_steps(17)
	assert_eq(_p1.move, &"lasso_miss")
	assert_gt(_p1.global_position.y, y, "falling meanwhile")
	_steps(2)
	assert_eq(_p1.state, Fighter.State.AIR, "free after 18 frames")
	assert_false(_p1.up_special_available, "used up until she lands")


func test_her_ropes_rest_during_the_up_special() -> void:
	await _place(Vector2(200, 100), Vector2(250, 80), _press("up"))
	for i in 18:
		_steps(1)
		if _p1.state == Fighter.State.ATTACK:
			assert_false(_rope().ropes_active(), "step %d: %s" % [i + 1, _p1.move])



## On the ground, a lasso that misses can be thrown again straight away (it never left the floor,
## so nothing "landed" to bring the up special back).
func test_on_the_ground_the_lasso_can_be_thrown_again_right_away() -> void:
	var inputs := _press("up")
	for i in 30:
		inputs.append(FighterInput.new())
	inputs.append_array(_press("up"))
	await _place(Vector2(200, 192), Vector2(380, 192), inputs)
	_steps(7)
	assert_eq(_p1.move, &"lasso_miss")
	_steps(26)
	assert_ne(_p1.state, Fighter.State.ATTACK, "done")
	assert_true(_p1.up_special_available, "ended standing: available again")
	_steps(2)
	assert_eq(_p1.state, Fighter.State.ATTACK, "the second press works")
	assert_eq(_p1.move, &"up_special")


## The lasso's rope points at the caught fighter from the very first tick (no stale point).
func test_the_lasso_rope_points_at_the_victim_from_the_start() -> void:
	await _place(Vector2(200, 100), Vector2(250, 80), _press("up"))
	(_p1.ability(VineAbility) as VineAbility).vine_anchor = Vector2.ZERO
	_steps(7)
	assert_eq(_p1.move, &"lasso_reel")
	assert_almost_eq((_p1.ability(VineAbility) as VineAbility).vine_anchor, _p2.get_center(), Vector2(0.5, 0.5))



# --- Neutral special: the frenzy -----------------------------------------------------------------


## [idle, neutral special held for `ticks`, then let go].
func _charge(ticks: int) -> Array[FighterInput]:
	var inputs: Array[FighterInput] = [FighterInput.new()]
	for i in ticks:
		var input := FighterInput.new()
		input.special_pressed = i == 0
		input.special_held = true
		inputs.append(input)
	inputs.append(FighterInput.new())
	return inputs


func test_the_frenzy_matches_the_spec() -> void:
	var b := _p1.stats.moveset.neutral_special
	assert_true(_ropes().neutral_special_frenzy)
	assert_eq([b.startup, b.active, b.recovery, b.charge_frames, _ropes().frenzy_min_charge_frames], [3, 0, 8, 60, 20])
	var ropes := _ropes()
	assert_eq([ropes.frenzy_frames, ropes.frenzy_speed, ropes.frenzy_charge_knockback,
		ropes.frenzy_refill_frames], [120, 2.0, 200.0, 720])
	var hit := ropes.frenzy_hit
	assert_eq([hit.damage, hit.base_knockback, hit.knockback_growth, hit.angle_deg], [0.0, 150.0, 1.6, 40.0])


func test_a_released_charge_starts_the_frenzy() -> void:
	await _place(Vector2(200, 192), Vector2(380, 192), _charge(30))
	_rope().frenzy_meter = 1.0
	_steps(20)
	assert_eq(_p1.move, &"neutral_special_charge", "charging")
	assert_eq(_rope().frenzy_frames_left, 0)
	_steps(12)
	assert_gt(_rope().frenzy_frames_left, 110, "released: a 2 s frenzy")
	assert_eq(_rope().rope_hit().damage, 0.0, "no damage")
	assert_almost_eq(_rope().rope_hit().base_knockback, 150.0 + 200.0 * 30.0 / 60.0, 5.0, "half a charge")
	_steps(12)
	assert_ne(_p1.state, Fighter.State.ATTACK, "free again: the frenzy goes on by itself")
	assert_gt(_rope().frenzy_frames_left, 0)


func test_the_frenzy_spins_twice_as_fast_then_stops() -> void:
	await _place(Vector2(200, 192), Vector2(380, 192))
	_steps(1)
	var before := _rope().rope_turns
	_steps(10)
	var normal := _rope().rope_turns - before
	_rope().start_frenzy(1.0)
	before = _rope().rope_turns
	_steps(10)
	assert_almost_eq(_rope().rope_turns - before, normal * 2.0, 0.001)
	_steps(110)
	assert_eq(_rope().frenzy_frames_left, 0, "over after 120 ticks")
	assert_eq(_rope().rope_hit(), _ropes().short_hit, "normal hits again")


func test_a_frenzy_rope_knocks_back_without_damage() -> void:
	await _place(Vector2(200, 192), Vector2(220, 192))
	_p2.percent = 100.0
	_rope().start_frenzy(1.0)
	var hit := false
	for i in 30:
		_match.step()
		if _p2.state == Fighter.State.HITSTUN:
			hit = true
			break
	assert_true(hit)
	assert_eq(_p2.percent, 100.0, "no damage")
	assert_gt(_p2.velocity.length(), 400.0, "a strong launch at 100 %")


func test_no_new_charge_during_a_frenzy() -> void:
	await _place(Vector2(200, 192), Vector2(380, 192), _press("special"))
	_rope().start_frenzy(0.0)
	_rope().frenzy_meter = 1.0
	_steps(3)
	assert_ne(_p1.state, Fighter.State.ATTACK)



## A tap (let go before 20 ticks of charging) does nothing: she has to hold it.
func test_a_tap_starts_no_frenzy() -> void:
	await _place(Vector2(200, 192), Vector2(380, 192), _charge(10))
	_rope().frenzy_meter = 1.0
	_steps(30)
	assert_eq(_rope().frenzy_frames_left, 0)
	await _place(Vector2(200, 192), Vector2(380, 192), _charge(22))
	_rope().frenzy_meter = 1.0
	_steps(30)
	assert_gt(_rope().frenzy_frames_left, 0, "held long enough")


## Her charge shows as the frenzy meter (not the punch glow), and her ropes light up with it.
func test_the_charge_is_shown() -> void:
	await _place(Vector2(200, 192), Vector2(380, 192), _charge(60))
	_rope().frenzy_meter = 1.0
	_steps(31)
	assert_almost_eq(RopeAbility.frenzy_charge(_p1), 0.5, 0.05)
	await wait_frames(2)
	_steps(30)
	assert_almost_eq(RopeAbility.frenzy_charge(_p1), 1.0, 0.001)
	await wait_frames(2)
	assert_eq(RopeAbility.frenzy_charge(_p2), 0.0, "Kim isn't charging a frenzy")



# --- The frenzy meter -----------------------------------------------------------------------------


func test_the_meter_starts_empty_and_refills_slowly() -> void:
	await _place(Vector2(200, 192), Vector2(380, 192))
	assert_eq(_rope().frenzy_meter, 0.0, "empty at every spawn")
	_steps(360)
	assert_almost_eq(_rope().frenzy_meter, 0.5, 0.01, "half in 6 s")
	_steps(360)
	assert_eq(_rope().frenzy_meter, 1.0, "full after 12 s")


func test_no_frenzy_without_a_full_meter() -> void:
	await _place(Vector2(200, 192), Vector2(380, 192), _charge(40))
	_rope().frenzy_meter = 0.9
	_steps(3)
	assert_ne(_p1.state, Fighter.State.ATTACK, "B does nothing")
	_steps(50)
	assert_eq(_rope().frenzy_frames_left, 0)


func test_a_frenzy_empties_the_meter_and_it_refills_after() -> void:
	await _place(Vector2(200, 192), Vector2(380, 192))
	_rope().frenzy_meter = 1.0
	_rope().start_frenzy(1.0)
	assert_eq(_rope().frenzy_meter, 0.0)
	_steps(100)
	assert_eq(_rope().frenzy_meter, 0.0, "no refilling during the frenzy")
	_steps(40)
	assert_gt(_rope().frenzy_meter, 0.0, "refilling once it's over")


func test_a_tap_costs_nothing() -> void:
	await _place(Vector2(200, 192), Vector2(380, 192), _charge(10))
	_rope().frenzy_meter = 1.0
	_steps(30)
	assert_eq(_rope().frenzy_meter, 1.0)


func test_her_card_shows_the_meter() -> void:
	await _place(Vector2(200, 192), Vector2(380, 192))
	var hud := _match.get_node("HUD") as Hud
	var cards := hud.find_children("*", "PlayerCard", true, false)
	var hers: PlayerCard = null
	var kims: PlayerCard = null
	for card: PlayerCard in cards:
		if card._fighter == _p1:
			hers = card
		elif card._fighter == _p2:
			kims = card
	assert_not_null(hers.get_badge(FrenzyBar), "her card has the bar")
	assert_null(kims.get_badge(FrenzyBar), "Kim's doesn't")
	_rope().frenzy_meter = 0.25
	hers.refresh()
	assert_eq((hers.get_badge(FrenzyBar) as FrenzyBar).value, 0.25)
	assert_true((hers.get_badge(FrenzyBar) as FrenzyBar).color.is_equal_approx(Color8(120, 128, 80)), "her green")
	var bar := (hers.get_badge(FrenzyBar) as FrenzyBar)
	bar.value = 1.0
	var colors := []
	for i in 20:
		bar._frames = i
		colors.append(bar.fill_color())
	assert_true(colors.has(bar.color) and colors.has(bar.color.lightened(0.6)), "flashing when full")


## Her rope ability.
func _rope() -> RopeAbility:
	return _p1.ability(RopeAbility) as RopeAbility
