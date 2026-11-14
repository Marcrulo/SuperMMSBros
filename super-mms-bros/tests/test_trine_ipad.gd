extends GutTest
## Trine's down special, the iPad break (docs/specs/characters/trine.md#trine--ipad-break): she sits down
## and watches her iPad while down is held, healing 1 % every 10 ticks, up to 300 ticks. P1 is
## Trine; scripted [idle, down special, down held…] starts it on step 2, so she's seated after
## step 11 and heal n comes on step 11 + 10 × n. Main platform top y 192 (x 96…384).

const MATCH_SCENE := preload("res://match/match.tscn")
const TRINE := "slot_03"

var _match: Match
var _p1: Fighter
var _p2: Fighter
var _saved_ids: Array[String] = []


func before_each() -> void:
	_saved_ids = [Game.character_id, Game.p2_character_id]
	Game.character_id = TRINE
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


## [idle, down special, then down held for `held` more ticks, then idle].
func _sit(held: int) -> Array[FighterInput]:
	var press := FighterInput.new()
	press.special_pressed = true
	press.special_held = true
	press.down_held = true
	var inputs: Array[FighterInput] = [FighterInput.new(), press]
	for i in held:
		var down := FighterInput.new()
		down.down_held = true
		inputs.append(down)
	return inputs


func _ipad() -> IpadData:
	return _p1.stats.moveset.down_special.ability as IpadData


# --- Data -----------------------------------------------------------------------------------------


func test_the_ipad_break_matches_the_spec() -> void:
	var sit := _p1.stats.moveset.down_special
	assert_true(sit.ability is IpadData, "Trine's down special is the iPad break")
	assert_eq([sit.startup, sit.active, sit.recovery], [10, 0, 12])
	assert_eq([_ipad().watch_frames, _ipad().heal_every], [300, 10])
	assert_almost_eq(_ipad().heal, 1.0, 0.001)


func test_only_her_down_special_changes() -> void:
	var defaults := (load("res://fighter/default_stats.tres") as FighterStats).moveset
	var moves := _p1.stats.moveset
	for name in ["jab", "side_tilt", "neutral_special", "side_special", "up_special", "down_air"]:
		assert_eq(moves.get(name), defaults.get(name), name)
	assert_null(_p2.stats.moveset.down_special.ability, "Kim keeps the default down special")


# --- Healing --------------------------------------------------------------------------------------


func test_she_sits_then_watches() -> void:
	await _place(Vector2(200, 192), Vector2(380, 192), _sit(200))
	_steps(5)
	assert_eq(_p1.move, &"down_special", "sitting down")
	_steps(7)
	assert_eq(_p1.move, &"ipad_watch")
	assert_false(_p1.is_hitbox_active(), "no hitbox")


func test_watching_heals_one_percent_every_ten_ticks() -> void:
	await _place(Vector2(200, 192), Vector2(380, 192), _sit(200))
	_p1.percent = 50.0
	_steps(11 + 100)
	assert_almost_eq(_p1.percent, 40.0, 0.001)
	assert_eq(_p1.move, &"ipad_watch")


func test_healing_stops_at_zero() -> void:
	await _place(Vector2(200, 192), Vector2(380, 192), _sit(200))
	_p1.percent = 3.0
	_steps(11 + 100)
	assert_eq(_p1.percent, 0.0)


func test_a_full_sit_heals_thirty_percent_then_she_gets_up() -> void:
	await _place(Vector2(200, 192), Vector2(380, 192), _sit(500))
	_p1.percent = 100.0
	_steps(11 + 300)
	assert_almost_eq(_p1.percent, 70.0, 0.001)
	assert_eq(_p1.move, &"ipad_stand", "time's up, though down is still held")
	_steps(40)
	assert_almost_eq(_p1.percent, 70.0, 0.001, "no more healing")
	assert_ne(_p1.state, Fighter.State.ATTACK)


func test_letting_go_of_down_gets_her_up() -> void:
	await _place(Vector2(200, 192), Vector2(380, 192), _sit(40))
	_steps(11 + 25)
	assert_eq(_p1.move, &"ipad_watch")
	_steps(10)
	assert_eq(_p1.move, &"ipad_stand", "down released")
	_steps(12)
	assert_eq(_p1.state, Fighter.State.IDLE, "free after 12 frames of getting up")


func test_she_cant_act_while_sitting() -> void:
	var inputs := _sit(60)
	inputs[40].attack_pressed = true
	inputs[41].jump_pressed = true
	inputs[42].move_x = 1.0
	await _place(Vector2(200, 192), Vector2(380, 192), inputs)
	_steps(45)
	assert_eq(_p1.move, &"ipad_watch")
	assert_almost_eq(_p1.global_position.x, 200.0, 0.5, "doesn't move")
	assert_eq(_p1.facing, 1)


func test_a_hit_ends_it() -> void:
	var jab := FighterInput.new()
	jab.attack_pressed = true
	var p2: Array[FighterInput] = []
	for i in 30:
		p2.append(FighterInput.new())
	p2.append(jab)
	await _place(Vector2(200, 192), Vector2(222, 192), _sit(200), p2)
	_p1.percent = 20.0
	_steps(40)
	assert_eq(_p1.state, Fighter.State.HITSTUN)
	assert_eq(_p1.move, Fighter.NO_MOVE)
	assert_gt(_p1.percent, 20.0, "the hit's damage")


func test_nothing_happens_in_the_air() -> void:
	await _place(Vector2(200, 100), Vector2(380, 192), _sit(20))
	_steps(4)
	assert_eq(_p1.state, Fighter.State.AIR)


# --- Look -----------------------------------------------------------------------------------------


func test_every_phase_uses_the_down_special_strip() -> void:
	for phase in [&"down_special", &"ipad_watch", &"ipad_stand"]:
		assert_eq(FighterVisuals.animation_for(Fighter.State.ATTACK, 0.0, phase, FighterVisuals.phase_animations_of(_p1)), "down_special")


func test_the_drawing_for_each_phase() -> void:
	assert_eq(IpadAbility.ipad_frame(&"down_special", 1), 0, "bending down")
	assert_eq(IpadAbility.ipad_frame(&"down_special", 6), 1, "seated")
	assert_eq(IpadAbility.ipad_frame(&"ipad_watch", 1), 1, "watching")
	assert_eq(IpadAbility.ipad_frame(&"ipad_watch", 16), 2, "watching, the screen shifts")
	assert_eq(IpadAbility.ipad_frame(&"ipad_watch", 30), 2)
	assert_eq(IpadAbility.ipad_frame(&"ipad_watch", 31), 3, "a sip of coffee")
	assert_eq(IpadAbility.ipad_frame(&"ipad_watch", 60), 3)
	assert_eq(IpadAbility.ipad_frame(&"ipad_watch", 61), 1, "back to watching")
	assert_eq(IpadAbility.ipad_frame(&"ipad_watch", 91), 3, "the next sip")
	assert_eq(IpadAbility.ipad_frame(&"ipad_stand", 3), 4, "getting up")


func test_the_heal_plus_rises_after_each_heal() -> void:
	var ipad := IpadData.new()
	ipad.heal_every = 10
	assert_eq(IpadAbility.heal_plus_ages(ipad, 9), [], "before the first heal")
	assert_eq(IpadAbility.heal_plus_ages(ipad, 10), [0])
	assert_eq(IpadAbility.heal_plus_ages(ipad, 25), [15, 5], "two at once")
	assert_eq(IpadAbility.heal_plus_ages(ipad, 45), [15, 5])


## Runs FighterVisuals._draw while she watches (with the "+"), facing either way.
func test_she_is_drawn_watching() -> void:
	await _place(Vector2(200, 192), Vector2(380, 192), _sit(200))
	_p1.percent = 30.0
	_steps(30)
	await wait_frames(2)
	_p1.facing = -1
	await wait_frames(2)
	assert_eq(_p1.move, &"ipad_watch")
