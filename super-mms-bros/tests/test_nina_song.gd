extends GutTest
## Nina's lullaby (docs/specs/characters/nina.md#down-special--lullaby). P1 is Nina; scripted
## [idle, Down+B] starts the song on step 2, so frame N of it is step N + 1 (the song is out on
## frames 20…79: steps 21…80). Main platform top y 192 (x 96…384).

const MATCH_SCENE := preload("res://match/match.tscn")
const NINA := "slot_04"

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


## [idle, Down+B], then `ticks` ticks holding `held` sideways (and jump on every one if `jump`).
func _sing(ticks := 0, held := 0.0, jump := false) -> Array[FighterInput]:
	var inputs: Array[FighterInput] = []
	inputs.append(FighterInput.new())
	var special := FighterInput.new()
	special.special_pressed = true
	special.special_held = true
	special.down_held = true
	special.down_pressed = true
	inputs.append(special)
	for i in ticks:
		var input := FighterInput.new()
		input.move_x = held
		input.jump_pressed = jump
		input.jump_held = jump
		inputs.append(input)
	return inputs


## `ticks` ticks of holding shield.
func _shielding(ticks: int) -> Array[FighterInput]:
	var inputs: Array[FighterInput] = []
	for i in ticks:
		var input := FighterInput.new()
		input.shield_held = true
		input.shield_pressed = i == 0
		inputs.append(input)
	return inputs


func _asleep(fighter: Fighter) -> bool:
	return fighter.state == Fighter.State.SHIELD_BREAK


# --- Data -----------------------------------------------------------------------------------------


func test_nina_has_her_own_down_special() -> void:
	var defaults := (load("res://fighter/default_stats.tres") as FighterStats).moveset
	var down := _p1.stats.moveset.down_special
	assert_ne(down, defaults.down_special)
	assert_eq([down.startup, down.active, down.recovery], [20, 60, 20])
	var song := down.ability as SongData
	assert_not_null(song)
	assert_eq([song.radius, song.voice, song.sleep_ticks, song.hover_fall_speed],
		[56.0, Vector2(0, -16), 120, 30.0])


# --- Singing --------------------------------------------------------------------------------------


func test_down_special_starts_the_song() -> void:
	await _place(Vector2(150, 192), Vector2(380, 192), _sing())
	_steps(2)
	assert_eq(_p1.state, Fighter.State.ATTACK)
	assert_eq(_p1.move, &"song")


func test_song_lasts_100_frames() -> void:
	await _place(Vector2(150, 192), Vector2(380, 192), _sing())
	_steps(1 + 99)
	assert_eq(_p1.move, &"song", "frame 99")
	_steps(2)
	assert_ne(_p1.state, Fighter.State.ATTACK)


func test_she_stands_still_while_singing() -> void:
	await _place(Vector2(150, 192), Vector2(380, 192), _sing(60, 1.0, true))
	_steps(40)
	assert_eq(_p1.move, &"song")
	assert_almost_eq(_p1.global_position.x, 150.0, 1.0, "no walking")
	assert_almost_eq(_p1.global_position.y, 192.0, 1.0, "no jumping")
	assert_eq(_p1.facing, 1, "no turning")


func test_in_the_air_she_sings_and_hovers() -> void:
	await _place(Vector2(240, 60), Vector2(380, 192), _sing())
	_steps(2)
	assert_eq(_p1.move, &"song", "also in the air (not the dive)")
	_steps(40)
	assert_eq(_p1.move, &"song")
	assert_lte(_p1.velocity.y, 30.0 + 0.01, "sinks at most hover_fall_speed")
	assert_gt(_p1.velocity.y, 0.0, "but does sink")


# --- Sleep ----------------------------------------------------------------------------------------


func test_a_fighter_in_range_falls_asleep_when_the_song_comes_out() -> void:
	await _place(Vector2(200, 192), Vector2(240, 192), _sing())
	_steps(20)
	assert_false(_asleep(_p2), "frame 19: not yet")
	_steps(1)
	assert_true(_asleep(_p2), "frame 20")


func test_a_fighter_out_of_range_stays_awake() -> void:
	await _place(Vector2(150, 192), Vector2(300, 192), _sing())
	_steps(101)
	assert_false(_asleep(_p2))


func test_walking_into_the_song_late_still_puts_you_to_sleep() -> void:
	await _place(Vector2(150, 192), Vector2(300, 192), _sing())
	_steps(50)
	assert_false(_asleep(_p2))
	_p2.global_position.x = 190.0
	_steps(1)
	assert_true(_asleep(_p2), "while the song is out")


func test_no_sleep_after_the_song_ends() -> void:
	await _place(Vector2(150, 192), Vector2(300, 192), _sing())
	_steps(81)
	_p2.global_position.x = 190.0
	_steps(5)
	assert_false(_asleep(_p2), "recovery: the song is over")


func test_a_shield_doesnt_protect() -> void:
	await _place(Vector2(200, 192), Vector2(240, 192), _sing(), _shielding(40))
	_steps(20)
	assert_eq(_p2.state, Fighter.State.SHIELD)
	_steps(1)
	assert_true(_asleep(_p2))
	var health := _p2.shield_health
	_steps(10)
	assert_eq(_p2.shield_health, health, "the shield is left as it was")


func test_an_invulnerable_fighter_stays_awake() -> void:
	await _place(Vector2(200, 192), Vector2(240, 192), _sing())
	_p2.invulnerable_frames = 200
	_steps(40)
	assert_false(_asleep(_p2))


func test_sleep_lasts_120_ticks() -> void:
	await _place(Vector2(200, 192), Vector2(240, 192), _sing())
	_steps(21)
	assert_true(_asleep(_p2))
	_p2.global_position.x = 380.0   # out of range: only one sleep
	_steps(119)
	assert_true(_asleep(_p2), "tick 119 of the sleep")
	_steps(2)
	assert_false(_asleep(_p2))


func test_each_fighter_sleeps_once_per_song() -> void:
	await _place(Vector2(200, 192), Vector2(240, 192), _sing())
	_steps(21)
	_p2.stun(1)   # woken (as if by anything) while still in range
	_steps(3)
	assert_false(_asleep(_p2), "not put to sleep again by the same song")


func test_a_hit_wakes_the_sleeper() -> void:
	await _place(Vector2(200, 192), Vector2(240, 192), _sing())
	_steps(21)
	_p2.take_hit(_p1.stats.moveset.jab, 1, 200.0)
	assert_eq(_p2.state, Fighter.State.HITSTUN)


func test_nina_herself_never_sleeps() -> void:
	await _place(Vector2(200, 192), Vector2(380, 192), _sing())
	_steps(60)
	assert_eq(_p1.move, &"song")


# --- Zzz ------------------------------------------------------------------------------------------


func test_a_sleeper_gets_a_sleep_mark_that_goes_when_it_wakes() -> void:
	await _place(Vector2(200, 192), Vector2(240, 192), _sing())
	_steps(21)
	var marks := _match.get_entities(SleepMark, 0)
	assert_eq(marks.size(), 1)
	assert_eq((marks[0] as SleepMark).sleeper, _p2)
	_p2.global_position.x = 380.0
	_steps(125)
	assert_eq(_match.get_entities(SleepMark, 0).size(), 0)
