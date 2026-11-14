extends GutTest
## Michael's big hand (docs/specs/characters/michael.md#michael-bech--big-hand). P1 is Michael; scripted
## [idle, neutral special] starts the summon on step 2, so the hand appears on step 11 (frame 10).
## The main platform's top is y 192 (x 96…384); the left platform's top y 150 (x 132…204).

const MATCH_SCENE := preload("res://match/match.tscn")
const MICHAEL := "slot_05"
## Steps until the hand appears.
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


func _summon(times := 1, gap := 30) -> Array[FighterInput]:
	var inputs: Array[FighterInput] = []
	for i in times:
		var special := FighterInput.new()
		special.special_pressed = true
		special.special_held = true
		inputs.append(FighterInput.new())
		inputs.append(special)
		for j in gap:
			inputs.append(FighterInput.new())
	return inputs


func _hold_shield(ticks: int) -> Array[FighterInput]:
	var inputs: Array[FighterInput] = []
	for i in ticks:
		var input := FighterInput.new()
		input.shield_held = true
		inputs.append(input)
	return inputs


func _hand_data() -> HandData:
	return _p1.stats.moveset.neutral_special.ability as HandData


# --- Data -----------------------------------------------------------------------------------------


func test_michael_summons_and_keeps_the_other_default_moves() -> void:
	var defaults := (load("res://fighter/default_stats.tres") as FighterStats).moveset
	var moves := _p1.stats.moveset
	assert_ne(moves.neutral_special, defaults.neutral_special)
	for name in ["jab", "side_tilt", "up_tilt", "down_tilt", "neutral_air", "up_special",
			"down_special", "down_special_dive"]:
		assert_eq(moves.get(name), defaults.get(name), name)
	var summon := moves.neutral_special
	assert_eq([summon.startup, summon.active, summon.recovery, summon.charge_frames], [10, 0, 7, 0])
	assert_null(defaults.neutral_special.ability, "the default neutral special charges")


func test_hand_data_matches_the_spec() -> void:
	var hand := _hand_data()
	assert_eq(hand.offset, Vector2(60, -50))
	assert_eq(hand.size, Vector2(28, 20))
	assert_eq([hand.hover_frames, hand.impact_frames], [60, 8])
	assert_eq(hand.slam_speed, 600.0)
	var hover := hand.hover_hit
	assert_eq([hover.damage, hover.base_knockback, hover.angle_deg], [4.0, 100.0, 45.0])
	assert_almost_eq(hover.knockback_growth, 0.4, 0.0001)
	var slam := hand.slam_hit
	assert_eq([slam.damage, slam.base_knockback, slam.angle_deg], [14.0, 280.0, 90.0])
	assert_almost_eq(slam.knockback_growth, 1.5, 0.0001)
	assert_eq(slam.direction, MoveData.Direction.AWAY)


func test_floor_below() -> void:
	var stage := _match.get_node("Stage") as Stage
	assert_eq(stage.floor_below(Vector2(210, 142)), 192.0, "main platform")
	assert_eq(stage.floor_below(Vector2(160, 100)), 192.0, "through the left platform")
	assert_eq(stage.floor_below(Vector2(240, 100)), 192.0, "through the top platform")
	assert_eq(stage.floor_below(Vector2(210, 195)), INF, "below the main platform's top")
	assert_eq(stage.floor_below(Vector2(430, 142)), INF, "off the stage")


# --- Summon ---------------------------------------------------------------------------------------


func test_summon_spawns_the_hand_in_front() -> void:
	await _place(Vector2(150, 192), Vector2(380, 192), _summon())
	_steps(SPAWN - 1)
	assert_eq(_hands().size(), 0, "not before frame 10")
	_steps(1)
	assert_eq(_hands().size(), 1)
	var hand := _hands()[0]
	assert_eq(hand.owner_index, 0)
	assert_almost_eq(hand.global_position, Vector2(210, 142), Vector2(4.1, 0.01))


func test_hand_faces_and_appears_on_michaels_side() -> void:
	_p1.spawn_at(Vector2(300, 192), -1)
	_p2.spawn_at(Vector2(120, 192), 1)
	_match.set_controller(0, ScriptedController.new(_summon()))
	_match.set_controller(1, ScriptedController.new([]))
	await wait_physics_frames(1)
	_steps(SPAWN)
	var hand := _hands()[0]
	assert_eq(hand.facing, -1)
	assert_almost_eq(hand.global_position.x, 240.0, 4.1)


func test_michael_is_free_while_the_hand_hovers() -> void:
	await _place(Vector2(150, 192), Vector2(380, 192), _summon())
	_steps(SPAWN + 8)
	assert_ne(_p1.state, Fighter.State.ATTACK, "free after its 17 frames")
	assert_eq(_hands().size(), 1, "the hand still hovers")


func test_one_hand_at_a_time() -> void:
	await _place(Vector2(150, 192), Vector2(380, 192), _summon(2, 10))
	_steps(SPAWN + 12)
	assert_eq(_hands().size(), 1)
	assert_ne(_p1.state, Fighter.State.ATTACK, "the second press does nothing")


func test_hand_stays_put_when_michael_moves() -> void:
	var inputs := _summon(1, 0)
	for i in 40:
		var walk := FighterInput.new()
		walk.move_x = -1.0
		inputs.append(walk)
	await _place(Vector2(200, 192), Vector2(380, 192), inputs)
	_steps(SPAWN)
	var at := _hands()[0].global_position
	_steps(30)
	assert_lt(_p1.global_position.x, 190.0, "Michael walked away")
	assert_eq(_hands()[0].global_position, at)


# --- Hover and slam -------------------------------------------------------------------------------


func test_hand_hovers_for_a_second_then_slams() -> void:
	await _place(Vector2(150, 192), Vector2(380, 192), _summon())
	_steps(SPAWN + 60)
	var hand := _hands()[0]
	assert_eq(hand.global_position.y, 142.0, "still hovering")
	_steps(1)
	assert_almost_eq(hand.global_position.y, 152.0, 0.01, "dropping 10 px a tick")


func test_hand_lands_on_the_floor_below() -> void:
	watch_signals(_match)
	await _place(Vector2(150, 192), Vector2(380, 192), _summon())
	_steps(SPAWN + 60 + 5)
	var hand := _hands()[0]
	assert_eq(hand.global_position.y, 192.0, "on the main platform")
	assert_signal_emit_count(_match, "owner_sound", 1)
	assert_signal_emitted_with_parameters(_match, "owner_sound", [0, &"burst"])
	_steps(8)
	assert_eq(_hands().size(), 0, "gone after the impact")


func test_hand_goes_through_platforms() -> void:
	await _place(Vector2(100, 192), Vector2(380, 192), _summon())
	_steps(SPAWN + 60 + 2)
	assert_almost_eq(_hands()[0].global_position.y, 162.0, 0.01, "past the left platform")
	_steps(3)
	assert_eq(_hands()[0].global_position.y, 192.0, "on the main platform")


func test_hand_without_floor_falls_away() -> void:
	await _place(Vector2(370, 192), Vector2(150, 192), _summon())
	_steps(SPAWN + 60 + 10)
	assert_eq(_hands().size(), 1, "still falling")
	_steps(20)
	assert_eq(_hands().size(), 0, "gone below the blast zone")


func test_slam_launches_straight_up() -> void:
	await _place(Vector2(150, 192), Vector2(210, 192), _summon())
	_steps(SPAWN + 60)
	assert_eq(_p2.percent, 0.0, "the hovering hand is above P2")
	_steps(5)
	assert_eq(_p2.percent, 14.0)
	assert_eq(_p2.state, Fighter.State.HITSTUN)
	assert_lt(_p2.velocity.y, -250.0, "launched up")
	assert_almost_eq(_p2.velocity.x, 0.0, 1.0, "straight up")
	_steps(8)
	assert_eq(_p2.percent, 14.0, "hits once")


func test_touching_the_hovering_hand_hurts_a_little() -> void:
	await _place(Vector2(150, 192), Vector2(210, 130), _summon())
	_steps(SPAWN)
	assert_eq(_p2.percent, 4.0)
	assert_eq(_hands().size(), 1, "the hand keeps hovering")


func test_shield_blocks_the_slam() -> void:
	await _place(Vector2(150, 192), Vector2(210, 192), _summon(), _hold_shield(90))
	var shield := _p2.shield_health
	_steps(SPAWN + 60 + 5)
	assert_eq(_p2.percent, 0.0)
	assert_lt(_p2.shield_health, shield - 14.0, "the shield took it")


func test_hand_cant_hit_michael() -> void:
	var inputs := _summon(1, 0)
	for i in 30:
		var walk := FighterInput.new()
		walk.move_x = 1.0
		inputs.append(walk)
	await _place(Vector2(150, 192), Vector2(380, 192), inputs)
	_steps(SPAWN + 60 + 13)
	assert_eq(_p1.percent, 0.0)


# --- Removal --------------------------------------------------------------------------------------


func test_hand_disappears_when_michael_is_knocked_out() -> void:
	await _place(Vector2(150, 192), Vector2(380, 192), _summon())
	_steps(SPAWN)
	_p1.global_position = Vector2(150, 400)
	_steps(1)
	assert_eq(_p1.state, Fighter.State.KO)
	assert_eq(_hands().size(), 0)


func test_reset_removes_hands() -> void:
	await _place(Vector2(150, 192), Vector2(380, 192), _summon())
	_steps(SPAWN)
	_match.reset()
	assert_eq(_hands().size(), 0)


# --- Art ------------------------------------------------------------------------------------------


func test_hand_picture_has_an_open_and_a_flat_drawing() -> void:
	var texture := load("res://assets/fighters/slot_05/hand.png") as Texture2D
	assert_eq(texture.get_size(), Vector2(112, 44))
	var image := texture.get_image()
	var white := 0
	for y in 44:
		for x in 56:
			var color := image.get_pixel(x, y)
			if color.a > 0.5 and color.r > 0.9 and color.g > 0.9 and color.b > 0.9:
				white += 1
	assert_gt(white, 200, "a white glove")


## The summoned hands in the match, oldest first.
func _hands() -> Array[Hand]:
	var found: Array[Hand] = []
	found.assign(_match.get_entities(Hand))
	return found
