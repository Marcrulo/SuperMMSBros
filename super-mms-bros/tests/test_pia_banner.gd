extends GutTest
## Pia's Leverkusen banner (docs/specs/characters/pia.md#up-special--leverkusen-banner): on the
## ground she holds up a banner (98 / 0 / 10 frames); while it's up (frames 9–98) everyone within
## 100 px is stunned until it goes down (free on frame 99); 180 ticks of cooldown after.
## P1 is Pia; scripted [idle, up special] starts the banner on step 2, so frame N is step N + 1.
## Main platform top y 192 (x 96…384).

const MATCH_SCENE := preload("res://match/match.tscn")
const PIA := "slot_01"

var _match: Match
var _p1: Fighter
var _p2: Fighter
var _saved_ids: Array[String] = []


func before_each() -> void:
	_match_steps = 0
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
	_p1.invulnerable_frames = 0
	_p2.invulnerable_frames = 0
	_match.set_controller(0, ScriptedController.new(p1_inputs))
	_match.set_controller(1, ScriptedController.new(p2_inputs))
	await wait_physics_frames(1)


func _steps(count: int) -> void:
	for i in count:
		_match.step()


## Steps to the end of Pia's frame `frame` of a banner started on step 2.
func _to_frame(frame: int) -> void:
	_steps(frame + 1 - _match_steps)
	_match_steps = frame + 1


var _match_steps: int = 0


func _up_special() -> FighterInput:
	var input := FighterInput.new()
	input.special_pressed = true
	input.special_held = true
	input.up_held = true
	return input


## [idle, up special].
func _banner() -> Array[FighterInput]:
	return [FighterInput.new(), _up_special()]


func _held(ticks: int, make: Callable) -> Array[FighterInput]:
	var inputs: Array[FighterInput] = []
	for i in ticks:
		inputs.append(make.call())
	return inputs


func _dizzy(fighter: Fighter) -> bool:
	return fighter.state == Fighter.State.SHIELD_BREAK


func _banner_ability() -> BannerAbility:
	return _p1.ability(BannerAbility) as BannerAbility


# --- Data -----------------------------------------------------------------------------------------


func test_the_banner_matches_the_spec() -> void:
	var banner := _p1.stats.moveset.up_special
	assert_eq([banner.startup, banner.active, banner.recovery], [98, 0, 10])
	var data := banner.ability as BannerData
	assert_not_null(data)
	assert_eq([data.raise_frames, data.radius, data.cooldown_frames], [8, 100.0, 180])


func test_nobody_else_has_a_banner() -> void:
	var default := (load("res://fighter/default_stats.tres") as FighterStats).moveset
	assert_null(default.up_special.ability)
	assert_null(_p2.ability(BannerAbility))


# --- The gesture ----------------------------------------------------------------------------------


func test_she_stays_put_for_108_frames() -> void:
	await _place(Vector2(240, 192), Vector2(380, 192), _banner())
	_to_frame(1)
	assert_eq([_p1.state, _p1.move], [Fighter.State.ATTACK, &"banner"])
	var x := _p1.global_position.x
	_to_frame(108)
	assert_eq([_p1.state, _p1.move], [Fighter.State.ATTACK, &"banner"], "still on frame 108")
	assert_almost_eq(_p1.global_position.x, x, 0.01)
	_to_frame(109)
	assert_ne(_p1.state, Fighter.State.ATTACK, "done after 108 frames")


func test_no_banner_in_the_air() -> void:
	await _place(Vector2(240, 100), Vector2(380, 192), _banner())
	_to_frame(1)
	assert_ne(_p1.state, Fighter.State.ATTACK, "no banner and no jump boost")
	assert_true(_p1.up_special_available)


# --- The stun -------------------------------------------------------------------------------------


func test_the_banner_stuns_someone_near() -> void:
	await _place(Vector2(240, 192), Vector2(300, 192), _banner())
	for frame in range(1, 9):
		_to_frame(frame)
		assert_false(_dizzy(_p2), "not before it's up (frame %d)" % frame)
	_to_frame(9)
	assert_true(_dizzy(_p2), "stunned once it's up")
	_to_frame(98)
	assert_true(_dizzy(_p2), "still on frame 98")
	_to_frame(99)
	assert_false(_dizzy(_p2), "free once it goes down")


func test_someone_far_away_is_not_stunned() -> void:
	await _place(Vector2(240, 192), Vector2(360, 192), _banner())
	for frame in range(1, 109):
		_to_frame(frame)
		assert_false(_dizzy(_p2), "120 px away (frame %d)" % frame)


func test_someone_in_the_air_is_stunned_and_falls() -> void:
	await _place(Vector2(240, 192), Vector2(300, 120), _banner())
	_to_frame(9)
	assert_true(_dizzy(_p2))
	var y := _p2.global_position.y
	_to_frame(14)
	assert_true(_dizzy(_p2))
	assert_gt(_p2.global_position.y, y, "keeps falling")


func test_walking_in_later_is_stunned_until_the_end() -> void:
	var walk := func() -> FighterInput:
		var input := FighterInput.new()
		input.move_x = -1.0
		return input
	await _place(Vector2(240, 192), Vector2(370, 192), _banner(), _held(200, walk))
	_to_frame(9)
	assert_false(_dizzy(_p2), "still out of range")
	var stunned_on := -1
	for frame in range(10, 99):
		_to_frame(frame)
		if _dizzy(_p2):
			stunned_on = frame
			break
	assert_gt(stunned_on, 9, "stunned once it walks in")
	assert_lte(absf(_p2.get_center().x - _p1.get_center().x), 100.0 + 4.0)
	_to_frame(98)
	assert_true(_dizzy(_p2))
	_to_frame(99)
	assert_false(_dizzy(_p2))


func test_a_shield_does_not_help() -> void:
	var shield := func() -> FighterInput:
		var input := FighterInput.new()
		input.shield_held = true
		return input
	await _place(Vector2(240, 192), Vector2(300, 192), _banner(), _held(60, shield))
	_to_frame(9)
	assert_true(_dizzy(_p2))


func test_hitstun_then_stun() -> void:
	await _place(Vector2(240, 192), Vector2(280, 192), _banner())
	_to_frame(20)
	_p2.take_hit(_p1.stats.moveset.jab, 1, _p1.global_position.x)
	assert_eq(_p2.state, Fighter.State.HITSTUN)
	var stunned_again := false
	for frame in range(21, 99):
		_to_frame(frame)
		if _dizzy(_p2):
			stunned_again = true
			break
	assert_true(stunned_again, "dizzy again once the hitstun ends")


func test_a_shield_break_is_left_alone() -> void:
	await _place(Vector2(240, 192), Vector2(300, 192), _banner())
	_p2.stun(300)
	_to_frame(100)
	assert_true(_dizzy(_p2), "its own 300 ticks, not the banner's")


func test_someone_who_cannot_be_hit_is_not_stunned() -> void:
	await _place(Vector2(240, 192), Vector2(300, 192), _banner())
	_p2.invulnerable_frames = 200
	_to_frame(50)
	assert_false(_dizzy(_p2))


func test_a_hit_stops_it_and_lets_go() -> void:
	await _place(Vector2(240, 192), Vector2(300, 192), _banner())
	_to_frame(30)
	assert_true(_dizzy(_p2))
	_p1.take_hit(_p1.stats.moveset.jab, -1, _p2.global_position.x)
	_steps(1)
	_steps(2)
	assert_false(_dizzy(_p2), "let go within 2 ticks")
	assert_eq(_banner_ability().banner_cooldown, 180 - 2, "the cooldown started when it stopped")


# --- Cooldown -------------------------------------------------------------------------------------


func test_the_cooldown_starts_when_it_ends() -> void:
	await _place(Vector2(240, 192), Vector2(380, 192), _banner())
	_to_frame(108)
	assert_eq(_banner_ability().banner_cooldown, 0)
	_to_frame(109)
	assert_eq(_banner_ability().banner_cooldown, 180)


func test_no_banner_during_the_cooldown() -> void:
	var inputs := _banner()
	inputs.append_array(_held(120, func() -> FighterInput: return FighterInput.new()))
	inputs.append(_up_special())
	await _place(Vector2(240, 192), Vector2(380, 192), inputs)
	_to_frame(122)
	assert_ne(_p1.state, Fighter.State.ATTACK, "the second press does nothing")
	assert_gt(_banner_ability().banner_cooldown, 0)


func test_the_cooldown_runs_out() -> void:
	await _place(Vector2(240, 192), Vector2(380, 192), _banner())
	_to_frame(109 + 180)
	assert_eq(_banner_ability().banner_cooldown, 0)


func test_spawning_clears_the_cooldown() -> void:
	await _place(Vector2(240, 192), Vector2(380, 192), _banner())
	_to_frame(110)
	_p1.spawn_at(Vector2(240, 192), 1)
	assert_eq(_banner_ability().banner_cooldown, 0)


# --- Drawings -------------------------------------------------------------------------------------


func test_banner_drawings_follow_the_move() -> void:
	var expected := {1: 0, 8: 0, 9: 1, 16: 1, 17: 2, 24: 2, 25: 1, 32: 1, 33: 2, 98: 2 if (98 - 9) / 8 % 2 == 1 else 1,
		99: 3, 108: 3}
	for ticks: int in expected:
		assert_eq(BannerAbility.banner_frame(ticks, 8, 98), expected[ticks], "tick %d" % ticks)
