extends GutTest
## Mette's potions (docs/specs/characters/mette.md#mette--potions). P1 is Mette, P2 Casper (default
## moves). Scripted [idle, special] starts a special on step 2, so frame N of it is step N + 1.
## Main platform top y 192 (x 96…384); pass-through platforms at y 150 (x 132…204, 276…348).

const MATCH_SCENE := preload("res://match/match.tscn")
const METTE := "slot_10"
const RED := PotionAbility.Potion.RED
const BLUE := PotionAbility.Potion.BLUE
const GREEN := PotionAbility.Potion.GREEN
## Nothing above it (x 240 has the top platform at y 108 above it).
const FOAM_X := 116.0

var _match: Match
var _p1: Fighter
var _p2: Fighter
var _saved_ids: Array[String] = []


func before_each() -> void:
	_saved_ids = [Game.character_id, Game.p2_character_id]
	Game.character_id = METTE
	Game.p2_character_id = "slot_08"
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
	_p1.invulnerable_frames = 0
	_p2.invulnerable_frames = 0
	_match.set_controller(0, ScriptedController.new(p1_inputs))
	_match.set_controller(1, ScriptedController.new(p2_inputs))
	await wait_physics_frames(1)


func _steps(count: int) -> void:
	for i in count:
		_match.step()


func _potions() -> PotionAbility:
	return _p1.ability(PotionAbility) as PotionAbility


func _data() -> PotionData:
	return _potions().data as PotionData


## Specials in a row, each followed by `gap` idle ticks: "neutral", "down" or "side" (toward the
## right).
func _specials(which: Array[String], gap := 20) -> Array[FighterInput]:
	var inputs: Array[FighterInput] = []
	for w in which:
		inputs.append(FighterInput.new())
		var special := FighterInput.new()
		special.special_pressed = true
		special.special_held = true
		if w == "down":
			special.down_held = true
		elif w == "side":
			special.move_x = 1.0
		inputs.append(special)
		for i in gap:
			inputs.append(FighterInput.new())
	return inputs


func _shielding(ticks: int) -> Array[FighterInput]:
	var inputs: Array[FighterInput] = []
	for i in ticks:
		var input := FighterInput.new()
		input.shield_held = true
		input.shield_pressed = i == 0
		inputs.append(input)
	return inputs


func _flasks() -> Array[MatchEntity]:
	return _match.get_entities(Flask)


func _puddles() -> Array[MatchEntity]:
	return _match.get_entities(Puddle)


func _reactions() -> Array[MatchEntity]:
	return _match.get_entities(Reaction)


func _splash(x: float, potion: PotionAbility.Potion, y := 192.0) -> void:
	Puddle.splash(_match, 0, Vector2(x, y), potion, _data())


# --- Data -----------------------------------------------------------------------------------------


func test_mette_has_her_own_down_and_side_special() -> void:
	var defaults := (load("res://fighter/default_stats.tres") as FighterStats).moveset
	var moves := _p1.stats.moveset
	assert_true(moves.ability is PotionData, "the potions are on her move set")
	assert_ne(moves.neutral_special, defaults.neutral_special)
	assert_ne(moves.down_special, defaults.down_special)
	assert_ne(moves.side_special, defaults.side_special)
	for name in ["jab", "side_tilt", "up_special", "neutral_air"]:
		assert_eq(moves.get(name), defaults.get(name), name)
	var smash := moves.neutral_special
	assert_eq([smash.startup, smash.active, smash.recovery], [8, 4, 14])
	assert_eq([smash.hitbox_center, smash.hitbox_size], [Vector2(16, -16), Vector2(20, 18)])
	var down := moves.down_special
	assert_eq([down.startup, down.active, down.recovery], [8, 0, 7])
	var side := moves.side_special
	assert_eq([side.startup, side.active, side.recovery], [10, 0, 14])
	assert_eq([side.damage, side.base_knockback, side.knockback_growth, side.angle_deg],
		[3.0, 60.0, 0.3, 40.0])
	var data := moves.ability as PotionData
	assert_eq([data.flask_speed, data.flask_angle_deg, data.flask_gravity, data.flask_spawn],
		[230.0, 40.0, 700.0, Vector2(12, -18)])
	assert_eq([data.puddle_width, data.puddle_lifetime, data.max_puddles], [40.0, 480, 2])
	var hits := [data.smash_red, data.smash_blue, data.smash_green]
	var values: Array = []
	for hit: MoveData in hits:
		values.append([hit.damage, hit.base_knockback, hit.knockback_growth, hit.angle_deg])
	assert_eq(values, [[12.0, 70.0, 0.5, 40.0], [4.0, 150.0, 1.8, 40.0], [4.0, 30.0, 0.0, 40.0]])
	assert_eq(data.smash_stun, 60)


# --- Down special: picking a potion ---------------------------------------------------------------


func test_she_starts_with_red() -> void:
	await _place(Vector2(150, 192), Vector2(380, 192))
	assert_eq(_potions().potion, RED)


func test_down_special_switches_on_frame_eight() -> void:
	await _place(Vector2(150, 192), Vector2(380, 192), _specials(["down"]))
	_steps(8)
	assert_eq(_potions().potion, RED, "not before frame 8")
	_steps(1)
	assert_eq(_potions().potion, BLUE)
	assert_eq(_match.get_entities().size(), 0, "no burst, nothing thrown")


func test_potions_cycle_red_blue_green() -> void:
	await _place(Vector2(150, 192), Vector2(380, 192), _specials(["down", "down", "down"]))
	var seen: Array = []
	for i in 70:
		_match.step()
		if seen.is_empty() or seen[-1] != _potions().potion:
			seen.append(_potions().potion)
	assert_eq(seen, [RED, BLUE, GREEN, RED])


func test_down_special_in_the_air_switches_without_a_dive() -> void:
	await _place(Vector2(240, 60), Vector2(380, 192), _specials(["down"]))
	_steps(2)
	assert_eq(_p1.move, &"down_special", "no dive")
	_steps(7)
	assert_eq(_potions().potion, BLUE)


func test_flask_in_hand_shows_only_the_new_potion() -> void:
	await _place(Vector2(150, 192), Vector2(380, 192), _specials(["down"]))
	_steps(2)
	assert_eq(_potions().potion, RED, "not switched yet")
	assert_eq(_potions().held_potion(), BLUE, "but her hand shows the new one already")
	_steps(8)
	assert_eq(_potions().held_potion(), BLUE)


func test_back_to_red_at_spawn() -> void:
	await _place(Vector2(150, 192), Vector2(380, 192))
	_potions().potion = GREEN
	_p1.spawn_at(Vector2(150, 192), 1)
	assert_eq(_potions().potion, RED)


# --- Neutral special: the flask smash -------------------------------------------------------------


func _smash(potion: PotionAbility.Potion, p2_inputs: Array[FighterInput] = []) -> void:
	await _place(Vector2(150, 192), Vector2(170, 192), _specials(["neutral"]), p2_inputs)
	_potions().potion = potion
	_steps(14)


func test_smash_starts_without_a_charge() -> void:
	await _place(Vector2(150, 192), Vector2(380, 192), _specials(["neutral"]))
	_steps(2)
	assert_eq(_p1.move, &"neutral_special")
	_steps(26)
	assert_ne(_p1.state, Fighter.State.ATTACK, "over after 26 frames")


func test_red_smash_deals_damage() -> void:
	await _smash(RED)
	assert_almost_eq(_p2.percent, 12.0, 0.01)
	assert_eq(_p2.state, Fighter.State.HITSTUN)
	assert_gt(_p2.velocity.x, 0.0, "launched toward her facing side")


func test_blue_smash_knocks_back_hard() -> void:
	await _smash(RED)
	var red_speed := _p2.velocity.length()
	await _smash(BLUE)
	assert_almost_eq(_p2.percent, 4.0, 0.01, "a fresh P2: 4 %")
	assert_gt(_p2.velocity.length(), red_speed * 1.8, "much further than red")


func test_green_smash_stuns() -> void:
	await _smash(GREEN)
	assert_almost_eq(_p2.percent, 4.0, 0.01)
	assert_eq(_p2.state, Fighter.State.SHIELD_BREAK, "dizzy")
	_steps(55)
	assert_eq(_p2.state, Fighter.State.SHIELD_BREAK, "still dizzy")
	_steps(10)
	assert_ne(_p2.state, Fighter.State.SHIELD_BREAK, "over after 60 ticks")


func test_green_smash_on_a_shield_doesnt_stun() -> void:
	await _smash(GREEN, _shielding(40))
	assert_eq(_p2.percent, 0.0)
	assert_ne(_p2.state, Fighter.State.SHIELD_BREAK)


func test_smash_keeps_her_potion_and_leaves_no_puddle() -> void:
	await _smash(BLUE)
	_steps(20)
	assert_eq(_potions().potion, BLUE)
	assert_eq(_puddles().size(), 0)


# --- Side special: the flask ----------------------------------------------------------------------


func test_flask_leaves_her_hand_on_frame_ten() -> void:
	await _place(Vector2(150, 192), Vector2(380, 192), _specials(["side"]))
	_steps(10)
	assert_eq(_flasks().size(), 0, "not before frame 10")
	_steps(1)
	assert_eq(_flasks().size(), 1)
	var flask := _flasks()[0] as Flask
	assert_eq(flask.potion, RED, "the potion she holds")
	assert_almost_eq(flask.global_position, Vector2(162, 174), Vector2(5, 5))
	assert_gt(flask.velocity.x, 0.0, "toward her facing side")
	assert_lt(flask.velocity.y, 0.0, "upward")
	assert_eq(_match.get_projectiles().size(), 0, "no default projectile")


func test_flask_carries_the_chosen_potion() -> void:
	await _place(Vector2(150, 192), Vector2(380, 192), _specials(["down", "side"]))
	for i in 60:
		_match.step()
		if not _flasks().is_empty():
			break
	assert_eq((_flasks()[0] as Flask).potion, BLUE)


func test_one_flask_at_a_time() -> void:
	# The second Side+B comes after the first throw ended, while its flask still flies.
	await _place(Vector2(150, 192), Vector2(380, 192), _specials(["side", "side"], 24))
	var seen: Dictionary = {}
	for i in 60:
		_match.step()
		for flask in _flasks():
			seen[flask] = true
	assert_eq(seen.size(), 1)


func test_flask_landing_leaves_a_puddle() -> void:
	await _place(Vector2(150, 192), Vector2(380, 192), _specials(["side"], 60))
	_steps(60)
	assert_eq(_flasks().size(), 0, "shattered")
	assert_eq(_puddles().size(), 1)
	var puddle := _puddles()[0] as Puddle
	assert_eq(puddle.potion, RED)
	assert_eq(puddle.global_position.y, 192.0, "on the main platform")
	assert_between(puddle.global_position.x, 220.0, 290.0)


func test_flask_hits_a_fighter_and_splashes_below() -> void:
	await _place(Vector2(150, 192), Vector2(180, 192), _specials(["side"], 30))
	_steps(16)
	assert_almost_eq(_p2.percent, 3.0, 0.01)
	assert_eq(_flasks().size(), 0, "shattered")
	assert_eq(_puddles().size(), 1, "its potion fell to the floor")
	assert_eq(_puddles()[0].global_position.y, 192.0)


func test_flask_on_a_shield_splashes_too() -> void:
	await _place(Vector2(150, 192), Vector2(180, 192), _specials(["side"], 30), _shielding(40))
	_steps(16)
	assert_eq(_p2.percent, 0.0, "blocked")
	assert_eq(_puddles().size(), 1)


func test_flask_off_the_stage_splashes_away() -> void:
	await _place(Vector2(378, 192), Vector2(150, 192), _specials(["side"], 10))
	_steps(130)
	assert_eq(_flasks().size(), 0)
	assert_eq(_puddles().size(), 0, "no floor below")


# --- Puddles --------------------------------------------------------------------------------------


func test_splash_makes_a_puddle_there() -> void:
	await _place(Vector2(150, 192), Vector2(380, 192))
	_splash(240, GREEN)
	var puddle := _puddles()[0] as Puddle
	assert_eq(puddle.global_position, Vector2(240, 192))
	assert_eq(puddle.potion, GREEN)
	assert_eq(puddle.get_area_rect(), Rect2(220, 186, 40, 6))


func test_at_most_two_puddles_the_oldest_goes() -> void:
	await _place(Vector2(150, 192), Vector2(380, 192))
	_splash(120, RED)
	_splash(200, BLUE)
	_splash(300, GREEN)
	assert_eq(_puddles().size(), 2)
	assert_eq(_puddles()[0].global_position.x, 200.0)
	assert_eq(_reactions().size(), 0, "no reaction")


func test_puddle_dries_after_480_ticks() -> void:
	await _place(Vector2(150, 192), Vector2(380, 192))
	_splash(240, RED)
	_steps(479)
	assert_eq(_puddles().size(), 1)
	_steps(1)
	assert_eq(_puddles().size(), 0)


func test_same_colour_refills_the_puddle() -> void:
	await _place(Vector2(150, 192), Vector2(380, 192))
	_splash(240, RED)
	_steps(300)
	_splash(255, RED)
	assert_eq(_puddles().size(), 1)
	assert_eq((_puddles()[0] as Puddle).age, 0)
	assert_eq(_puddles()[0].global_position.x, 240.0, "stays where it was")


func test_another_colour_sets_off_a_reaction() -> void:
	await _place(Vector2(150, 192), Vector2(380, 192))
	_splash(240, RED)
	_splash(255, BLUE)
	assert_eq(_puddles().size(), 0, "the puddle is used up")
	assert_eq(_reactions().size(), 1)
	var reaction := _reactions()[0] as Reaction
	assert_eq(reaction.kind, Reaction.Kind.STEAM)
	assert_eq(reaction.global_position, Vector2(240, 192), "at the puddle's center")


func test_a_splash_beside_a_puddle_is_a_new_puddle() -> void:
	await _place(Vector2(150, 192), Vector2(380, 192))
	_splash(240, RED)
	_splash(290, BLUE)
	assert_eq(_puddles().size(), 2)
	assert_eq(_reactions().size(), 0)


func test_reaction_table() -> void:
	assert_eq(Reaction.kind_for(RED, BLUE), Reaction.Kind.STEAM)
	assert_eq(Reaction.kind_for(BLUE, RED), Reaction.Kind.STEAM)
	assert_eq(Reaction.kind_for(RED, GREEN), Reaction.Kind.EXPLOSION)
	assert_eq(Reaction.kind_for(GREEN, RED), Reaction.Kind.EXPLOSION)
	assert_eq(Reaction.kind_for(BLUE, GREEN), Reaction.Kind.FOAM)
	assert_eq(Reaction.kind_for(GREEN, BLUE), Reaction.Kind.FOAM)


# --- Standing in a puddle -------------------------------------------------------------------------


func test_acid_burns_everyone_standing_in_it() -> void:
	await _place(Vector2(232, 192), Vector2(248, 192))
	_splash(240, RED)
	_steps(14)
	assert_eq(_p2.percent, 0.0)
	_steps(1)
	assert_almost_eq(_p2.percent, 1.0, 0.01, "1 % every 15 ticks")
	_steps(45)
	assert_almost_eq(_p2.percent, 4.0, 0.01)
	assert_almost_eq(_p1.percent, 4.0, 0.01, "Mette too")
	assert_eq(_p2.state, Fighter.State.IDLE, "no hitstun")


func test_acid_spares_the_unhittable() -> void:
	await _place(Vector2(150, 192), Vector2(240, 192))
	_p2.invulnerable_frames = 100
	_splash(240, RED)
	_steps(30)
	assert_eq(_p2.percent, 0.0)


func test_ice_makes_the_floor_slippery() -> void:
	await _place(Vector2(150, 192), Vector2(240, 192))
	_splash(240, BLUE)
	_steps(1)
	assert_almost_eq(_p2.ground_grip, 0.1, 0.001)
	assert_eq(_p1.ground_grip, 1.0, "not standing in it")


func test_glue_makes_it_sticky() -> void:
	await _place(Vector2(240, 192), Vector2(380, 192))
	_splash(240, GREEN)
	_steps(1)
	assert_almost_eq(_p1.ground_speed, 0.4, 0.001, "Mette too")
	assert_almost_eq(_p1.ground_jump, 0.7, 0.001)


func test_puddles_dont_touch_fighters_in_the_air() -> void:
	await _place(Vector2(240, 160), Vector2(380, 192))
	_splash(240, BLUE)
	_steps(1)
	assert_eq(_p1.ground_grip, 1.0)


# --- Reactions ------------------------------------------------------------------------------------


func test_steam_blows_everyone_upward_once() -> void:
	await _place(Vector2(236, 192), Vector2(244, 192))
	_splash(240, RED)
	_splash(240, BLUE)
	_steps(1)
	for f in [_p1, _p2]:
		assert_almost_eq(f.percent, 3.0, 0.01)
		assert_eq(f.state, Fighter.State.HITSTUN)
		assert_lt(f.velocity.y, -100.0, "blown up")
		assert_almost_eq(f.velocity.x, 0.0, 0.01, "straight up")
	_steps(39)
	assert_almost_eq(_p2.percent, 3.0, 0.01, "one hit per steam")
	_steps(1)
	assert_eq(_reactions().size(), 0, "gone after 40 ticks")


func test_explosion_launches_away_from_its_center() -> void:
	await _place(Vector2(225, 192), Vector2(255, 192))
	_splash(240, RED)
	_splash(240, GREEN)
	_steps(1)
	assert_almost_eq(_p1.percent, 14.0, 0.01, "Mette too")
	assert_almost_eq(_p2.percent, 14.0, 0.01)
	assert_lt(_p1.velocity.x, 0.0, "left of it: launched left")
	assert_gt(_p2.velocity.x, 0.0, "right of it: launched right")
	_steps(6)
	assert_eq(_reactions().size(), 0, "gone after 6 ticks")


func test_explosion_is_blocked_by_a_shield() -> void:
	await _place(Vector2(150, 192), Vector2(250, 192), [], _shielding(20))
	_steps(2)
	_splash(240, GREEN)
	_splash(240, RED)
	_steps(1)
	assert_eq(_p2.percent, 0.0)


func test_foam_pillar_becomes_a_platform() -> void:
	await _place(Vector2(150, 192), Vector2(380, 192))
	_splash(FOAM_X, BLUE)
	_splash(FOAM_X, GREEN)
	var foam := _reactions()[0] as Reaction
	assert_eq(foam.kind, Reaction.Kind.FOAM)
	assert_false(foam.is_platform_solid(), "not while rising")
	_steps(12)
	assert_true(foam.is_platform_solid())
	assert_eq(foam.top_y(), 136.0, "56 px above the floor")
	_p2.spawn_at(Vector2(FOAM_X, 100), -1)
	_p2.invulnerable_frames = 0
	_steps(60)
	assert_true(_p2.is_on_floor())
	assert_almost_eq(_p2.global_position.y, 136.0, 1.0, "standing on the foam")


func test_foam_shrinks_away_after_five_seconds() -> void:
	await _place(Vector2(150, 192), Vector2(380, 192))
	_splash(FOAM_X, GREEN)
	_splash(FOAM_X, BLUE)
	var foam := _reactions()[0] as Reaction
	_steps(12 + 300)
	assert_true(foam.is_platform_solid())
	_steps(1)
	assert_false(foam.is_platform_solid(), "shrinking")
	_steps(19)
	assert_eq(_reactions().size(), 0)


func test_rising_foam_pops_a_fighter_on_top() -> void:
	await _place(Vector2(150, 192), Vector2(FOAM_X, 192))
	_splash(FOAM_X, BLUE)
	_splash(FOAM_X, GREEN)
	_steps(1)
	assert_lt(_p2.velocity.y, -200.0, "popped up")
	assert_eq(_p2.percent, 0.0, "no damage")
	assert_ne(_p2.state, Fighter.State.HITSTUN, "no hitstun")
	_steps(80)
	assert_true(_p2.is_on_floor())
	assert_almost_eq(_p2.global_position.y, 136.0, 1.0, "lands on top")


# --- HUD ------------------------------------------------------------------------------------------


func test_hands_json_has_every_drawing() -> void:
	for animation: String in FighterVisuals.ANIMATIONS:
		var drawings: int = FighterVisuals.ANIMATIONS[animation].ticks.size()
		for i in drawings:
			assert_ne(PotionAbility.front_hand(METTE, animation, i), PotionAbility.NO_HAND,
					"%s drawing %d" % [animation, i])


func test_flask_sits_in_her_front_hand() -> void:
	# From slot_10/hands.json (run drawing 2: the fist at (-2.01, -8.15)).
	assert_almost_eq(PotionAbility.front_hand(METTE, "run", 2), Vector2(-2.01, -8.15),
			Vector2(0.01, 0.01))


func test_she_always_holds_her_flask() -> void:
	await _place(Vector2(150, 192), Vector2(380, 192))
	_steps(3)
	assert_true(_potions().holds_flask(), "standing")
	_p1.stun(30)
	_steps(1)
	assert_true(_potions().holds_flask(), "even dizzy")


func test_hand_is_empty_from_the_throw_to_the_end_of_side_special() -> void:
	await _place(Vector2(150, 192), Vector2(380, 192), _specials(["side"], 40))
	_steps(10)
	assert_true(_potions().holds_flask(), "until the throw")
	_steps(1)
	assert_false(_potions().holds_flask(), "thrown")
	_steps(24)
	assert_ne(_p1.move, &"side_special")
	assert_true(_potions().holds_flask(), "a new one once the move is over")


func test_hand_is_empty_from_the_smash_to_the_end_of_neutral_special() -> void:
	await _place(Vector2(150, 192), Vector2(380, 192), _specials(["neutral"], 40))
	_steps(9)
	assert_true(_potions().holds_flask(), "until the smash")
	_steps(1)
	assert_false(_potions().holds_flask(), "smashed")
	_steps(26)
	assert_ne(_p1.move, &"neutral_special")
	assert_true(_potions().holds_flask(), "a new one once the move is over")


func test_card_shows_her_potion() -> void:
	var hud := _match.get_node("HUD") as Hud
	assert_true(hud.cards[0].get_badge(PotionBadge) != null, "Mette's card has the badge")
	assert_false(hud.cards[1].get_badge(PotionBadge) != null, "Casper's doesn't")
	_potions().potion = GREEN
	hud.cards[0].refresh()
	assert_eq((hud.cards[0].get_badge(PotionBadge) as PotionBadge).potion, GREEN)
