extends GutTest
## Nina's letter volley (docs/specs/characters/nina.md#nina--existentialism). P1 is Nina; scripted
## [idle, special] starts a special on step 2, so frame N of it is step N + 1 (the first letter on
## step 11, letter k on step 11 + 6k). Main platform top y 192 (x 96…384).

const MATCH_SCENE := preload("res://match/match.tscn")
const NINA := "slot_04"
const TEXT := "EKSISTENTIALISME"

var _match: Match
var _p1: Fighter
var _p2: Fighter
var _saved_ids: Array[String] = []


func before_each() -> void:
	_saved_ids = [Game.character_id, Game.p2_character_id]
	Game.character_id = NINA
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
		p1_facing := 1) -> void:
	_p1.spawn_at(p1_at, p1_facing)
	_p2.spawn_at(p2_at, -1)
	_p1.invulnerable_frames = 0
	_p2.invulnerable_frames = 0
	_match.set_controller(0, ScriptedController.new(p1_inputs))
	_match.set_controller(1, ScriptedController.new())
	await wait_physics_frames(1)


func _steps(count: int) -> void:
	for i in count:
		_match.step()


## [idle, Side+B toward `x`], then `after` for `ticks` ticks (move_x `held`).
func _volley(x := 1.0, ticks := 0, held := 0.0) -> Array[FighterInput]:
	var inputs: Array[FighterInput] = []
	inputs.append(FighterInput.new())
	var special := FighterInput.new()
	special.special_pressed = true
	special.special_held = true
	special.move_x = x
	inputs.append(special)
	for i in ticks:
		var input := FighterInput.new()
		input.move_x = held
		inputs.append(input)
	return inputs


func _letters() -> Array[MatchEntity]:
	return _match.get_entities(Letter, 0)


# --- Data -----------------------------------------------------------------------------------------


func test_nina_has_her_own_side_special() -> void:
	var defaults := (load("res://fighter/default_stats.tres") as FighterStats).moveset
	var moves := _p1.stats.moveset
	assert_ne(moves.side_special, defaults.side_special)
	for name in ["jab", "side_tilt", "neutral_special", "up_special", "down_special"]:
		assert_eq(moves.get(name), defaults.get(name), name)
	var side := moves.side_special
	assert_eq([side.startup, side.active, side.recovery], [10, 0, 16])
	assert_eq([side.hitbox_center, side.hitbox_size], [Vector2(14, -16), Vector2(8, 10)])
	assert_eq([side.damage, side.base_knockback, side.knockback_growth, side.angle_deg],
		[2.0, 70.0, 0.4, 25.0])
	assert_eq([side.projectile_speed, side.projectile_lifetime], [240.0, 50])
	var letters := side.ability as LetterData
	assert_eq(letters.text, TEXT)
	assert_eq([letters.interval, letters.walk_scale, letters.back_hand], [6, 0.5, Vector2(4, -12)])


# --- The volley -----------------------------------------------------------------------------------


func test_first_letter_leaves_on_frame_ten() -> void:
	await _place(Vector2(150, 192), Vector2(380, 192), _volley())
	_steps(10)
	assert_eq(_letters().size(), 0, "not before frame 10")
	_steps(1)
	assert_eq(_letters().size(), 1)
	var letter := _letters()[0] as Letter
	assert_eq(letter.character, "E")
	assert_eq(letter.direction, 1)
	assert_almost_eq(letter.global_position, Vector2(164, 176), Vector2(4.0, 1.0))


func test_one_letter_every_six_ticks_in_order() -> void:
	await _place(Vector2(150, 192), Vector2(380, 192), _volley())
	_steps(11 + 6 * 3)
	var spelled := ""
	for letter in _letters():
		spelled += (letter as Letter).character
	assert_eq(spelled, "EKSI")


func test_whole_word_then_the_move_ends() -> void:
	await _place(Vector2(150, 192), Vector2(380, 192), _volley())
	var spelled := ""
	var seen: Dictionary = {}
	for i in 140:
		_match.step()
		for letter in _letters():
			if not seen.has(letter):
				seen[letter] = true
				spelled += (letter as Letter).character
	assert_eq(spelled, TEXT)
	assert_ne(_p1.state, Fighter.State.ATTACK, "over by frame 116")


func test_move_lasts_116_frames() -> void:
	await _place(Vector2(150, 192), Vector2(380, 192), _volley())
	_steps(1 + 115)
	assert_eq(_p1.state, Fighter.State.ATTACK, "frame 115")
	_steps(2)
	assert_ne(_p1.state, Fighter.State.ATTACK)


func test_letters_alternate_hands() -> void:
	await _place(Vector2(150, 192), Vector2(380, 192), _volley())
	_steps(11 + 6)
	var front := _letters()[0] as Letter
	var back := _letters()[1] as Letter
	assert_ne(front.start_y, back.start_y)
	assert_eq(front.start_y, 192.0 - 16.0)
	assert_eq(back.start_y, 192.0 - 12.0)


func test_letters_fly_straight_and_vanish() -> void:
	await _place(Vector2(150, 192), Vector2(380, 192), _volley())
	_steps(11)
	var letter := _letters()[0] as Letter
	var x0 := letter.global_position.x
	_steps(5)
	assert_almost_eq(letter.global_position.x - x0, 20.0, 0.1, "240 px/s = 4 px per tick")
	assert_eq(letter.global_position.y, 192.0 - 16.0)
	_steps(45)
	assert_false(is_instance_valid(letter) and not letter.removed, "gone after 50 ticks")


func test_letter_hits_once_for_two_percent() -> void:
	await _place(Vector2(150, 192), Vector2(190, 192), _volley())
	_steps(19)
	assert_eq(_p2.percent, 2.0)
	assert_eq(_p2.state, Fighter.State.HITSTUN)
	assert_gt(_p2.velocity.x, 0.0, "launched forward")


func test_shield_blocks_a_letter() -> void:
	await _place(Vector2(150, 192), Vector2(190, 192), _volley())
	var shield: Array[FighterInput] = []
	for i in 40:
		var input := FighterInput.new()
		input.shield_held = true
		input.shield_pressed = i == 0
		shield.append(input)
	_match.set_controller(1, ScriptedController.new(shield))
	_steps(11 + 8)
	assert_eq(_p2.state, Fighter.State.SHIELD)
	assert_eq(_p2.percent, 0.0)
	assert_eq(_letters().size(), 1, "the E was used up on the shield")


# --- Facing and moving ----------------------------------------------------------------------------


func test_she_turns_toward_the_held_direction_to_start() -> void:
	await _place(Vector2(300, 192), Vector2(120, 192), _volley(-1.0), 1)
	_steps(11)
	assert_eq(_p1.facing, -1)
	assert_eq((_letters()[0] as Letter).direction, -1)


func test_direction_is_locked() -> void:
	await _place(Vector2(150, 192), Vector2(380, 192), _volley(1.0, 120, -1.0))
	_steps(60)
	assert_eq(_p1.facing, 1, "holding left doesn't turn her")
	for letter in _letters():
		assert_eq((letter as Letter).direction, 1)
	_steps(60)
	assert_eq(_p1.facing, 1)


func test_she_walks_during_the_volley_at_half_speed() -> void:
	await _place(Vector2(150, 192), Vector2(380, 192), _volley(1.0, 60, 1.0))
	_steps(2)
	var x0 := _p1.global_position.x
	_steps(30)
	var moved := _p1.global_position.x - x0
	assert_gt(moved, 18.0, "she moves around")
	assert_lt(moved, 26.0, "at half of her 100 px/s run speed: 25 px in 30 ticks")
	assert_eq(_p1.state, Fighter.State.ATTACK)


func test_she_walks_backwards_too_without_turning() -> void:
	await _place(Vector2(250, 192), Vector2(380, 192), _volley(1.0, 60, -1.0))
	_steps(2)
	var x0 := _p1.global_position.x
	_steps(30)
	assert_lt(_p1.global_position.x, x0 - 18.0)
	assert_eq(_p1.facing, 1)


func test_standing_still_without_input() -> void:
	await _place(Vector2(150, 192), Vector2(380, 192), _volley())
	_steps(40)
	assert_almost_eq(_p1.global_position.x, 150.0, 0.5)


func test_walking_off_the_edge_makes_her_fall_and_keep_going() -> void:
	await _place(Vector2(370, 192), Vector2(120, 192), _volley(1.0, 100, 1.0))
	_steps(45)
	assert_eq(_p1.state, Fighter.State.ATTACK, "still shooting")
	assert_gt(_p1.global_position.y, 192.0, "falling")
	_steps(15)
	assert_gt(_letters().size(), 0, "letters keep coming while she falls")


# --- In the air -----------------------------------------------------------------------------------


func test_works_in_the_air() -> void:
	await _place(Vector2(250, 120), Vector2(380, 192), _volley(1.0, 40, 1.0))
	_steps(11)
	assert_eq(_p1.state, Fighter.State.ATTACK)
	assert_eq(_letters().size(), 1, "the first letter, mid-air")
	assert_gt(_p1.global_position.y, 120.0, "she's falling")
	_steps(6)
	assert_eq(_letters().size(), 2)
	assert_eq(_p1.facing, 1)


func test_landing_doesnt_end_it() -> void:
	await _place(Vector2(250, 160), Vector2(120, 192), _volley(1.0, 150, 0.0))
	_steps(40)
	assert_true(_p1.is_on_floor(), "landed")
	assert_eq(_p1.state, Fighter.State.ATTACK)
	_steps(30)
	assert_eq(_p1.state, Fighter.State.ATTACK, "carries on on the ground")


# --- Interruptions ------------------------------------------------------------------------------


func test_a_hit_ends_it_but_the_letters_keep_flying() -> void:
	await _place(Vector2(150, 192), Vector2(380, 192), _volley())
	_steps(11 + 12)
	var out := _letters().size()
	assert_eq(out, 3)
	_p1.take_hit(_p2.stats.moveset.jab, -1, 200.0)
	_steps(1)
	assert_eq(_p1.state, Fighter.State.HITSTUN)
	assert_eq(_letters().size(), out, "they're still out")
	_steps(10)
	assert_eq(_letters().size(), out, "no new letters")


func test_a_second_volley_can_follow() -> void:
	var inputs := _volley()
	for i in 118:
		inputs.append(FighterInput.new())
	inputs.append_array(_volley())
	await _place(Vector2(150, 192), Vector2(380, 192), inputs)
	_steps(11 + 118 + 12)
	assert_gt(_letters().size(), 0)


# --- Jumping, and cancelling with the shield -----------------------------------------------------------------------


## A volley whose input on tick `at` (counting from the first idle tick = 0) is `cancel`.
func _cancelled_by(cancel: FighterInput, at := 30) -> Array[FighterInput]:
	var inputs := _volley(1.0, 120, 0.0)
	inputs[at] = cancel
	return inputs


func _jump_press() -> FighterInput:
	var input := FighterInput.new()
	input.jump_pressed = true
	input.jump_held = true
	return input


func _shield_press(side := 0, down := false) -> FighterInput:
	var input := FighterInput.new()
	input.shield_pressed = true
	input.shield_held = true
	input.side_pressed = side
	input.move_x = float(side)
	input.down_pressed = down
	input.down_held = down
	return input


func test_she_can_jump_and_keeps_shooting() -> void:
	await _place(Vector2(150, 192), Vector2(380, 192), _cancelled_by(_jump_press(), 20))
	_steps(20)
	var out := _letters().size()
	_steps(1)
	assert_eq(_p1.state, Fighter.State.ATTACK, "the volley goes on")
	assert_eq(_p1.move, &"letters")
	assert_lt(_p1.velocity.y, -100.0, "jumping")
	_steps(12)
	assert_lt(_p1.global_position.y, 192.0 - 10.0, "in the air")
	assert_gt(_letters().size(), out, "still shooting")
	assert_eq(_p1.facing, 1)


func test_jump_is_a_full_jump() -> void:
	await _place(Vector2(150, 192), Vector2(380, 192), _cancelled_by(_jump_press(), 20))
	_steps(21)
	assert_almost_eq(_p1.velocity.y, -_p1.stats.jump_velocity, _p1.stats.gravity / 30.0)


func test_she_steers_in_the_air_after_jumping() -> void:
	var inputs := _cancelled_by(_jump_press(), 20)
	for i in range(21, 60):
		inputs[i].move_x = -1.0
	await _place(Vector2(250, 192), Vector2(380, 192), inputs)
	_steps(20)
	var x0 := _p1.global_position.x
	_steps(30)
	assert_lt(_p1.global_position.x, x0 - 10.0)
	assert_eq(_p1.facing, 1, "still facing the way she shoots")


func test_landing_after_a_jump_keeps_the_volley() -> void:
	await _place(Vector2(150, 192), Vector2(380, 192), _cancelled_by(_jump_press(), 20))
	_steps(20 + 50)
	assert_true(_p1.is_on_floor(), "landed")
	assert_eq(_p1.state, Fighter.State.ATTACK)


func test_double_jump_in_the_air_keeps_the_volley() -> void:
	await _place(Vector2(250, 20), Vector2(380, 192), _cancelled_by(_jump_press(), 12))
	_steps(13)
	assert_eq(_p1.state, Fighter.State.ATTACK)
	assert_lt(_p1.velocity.y, -100.0)
	assert_eq(_p1.jumps_left, _p1.stats.max_air_jumps - 1)


func test_jump_with_no_double_jump_left_does_nothing() -> void:
	await _place(Vector2(250, 20), Vector2(380, 192), _cancelled_by(_jump_press(), 12))
	_p1.jumps_left = 0
	_steps(13)
	assert_eq(_p1.state, Fighter.State.ATTACK, "the volley goes on")
	assert_gt(_p1.velocity.y, 0.0, "still falling")


func test_shield_on_the_ground_cancels_into_a_shield() -> void:
	await _place(Vector2(150, 192), Vector2(380, 192), _cancelled_by(_shield_press()))
	_steps(31)
	assert_eq(_p1.state, Fighter.State.SHIELD)


func test_roll_cancels_the_volley() -> void:
	await _place(Vector2(250, 192), Vector2(380, 192), _cancelled_by(_shield_press(-1)))
	_steps(31)
	assert_eq(_p1.state, Fighter.State.ROLL)
	assert_eq(_p1.facing, 1, "(she rolls backwards)")


func test_spot_dodge_cancels_the_volley() -> void:
	await _place(Vector2(250, 192), Vector2(380, 192), _cancelled_by(_shield_press(0, true)))
	_steps(31)
	assert_eq(_p1.state, Fighter.State.SPOT_DODGE)


func test_air_dodge_cancels_the_volley() -> void:
	await _place(Vector2(250, 20), Vector2(380, 192), _cancelled_by(_shield_press(), 12))
	_steps(13)
	assert_eq(_p1.state, Fighter.State.AIR_DODGE)


func test_air_dodge_already_used_does_nothing() -> void:
	await _place(Vector2(250, 20), Vector2(380, 192), _cancelled_by(_shield_press(), 12))
	_p1.air_dodge_available = false
	_steps(13)
	assert_eq(_p1.state, Fighter.State.ATTACK)


func test_letters_already_out_keep_flying_after_a_cancel() -> void:
	await _place(Vector2(150, 192), Vector2(380, 192), _cancelled_by(_shield_press()))
	_steps(31)
	var out := _letters().size()
	assert_gt(out, 2)
	var letter := _letters()[0] as Letter
	var x0 := letter.global_position.x
	_steps(3)
	assert_almost_eq(letter.global_position.x - x0, 12.0, 0.1)
