extends GutTest
## Mads's side special, the over-the-head slam: a command grab (docs/specs/characters/mads.md#mads--grappler).
## P1 is Mads; scripted [idle, side special] starts it on step 2, so frame N of it is step N + 1:
## the grab box is out on frames 10–13 = steps 11–14. A catch on step 11 starts the throw, whose
## frame k is step 11 + k: the slam on throw frame 24 = step 35, free after frame 40 = step 52.
## Main platform top y 192 (x 96…384).

const MATCH_SCENE := preload("res://match/match.tscn")
const MADS := "slot_11"

var _match: Match
var _p1: Fighter
var _p2: Fighter
var _saved_ids: Array[String] = []


func before_each() -> void:
	_saved_ids = [Game.character_id, Game.p2_character_id]
	Game.character_id = MADS
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


## [idle, side special toward the right].
func _reach() -> Array[FighterInput]:
	var special := FighterInput.new()
	special.special_pressed = true
	special.special_held = true
	special.move_x = 1.0
	return [FighterInput.new(), special]


func _shield(ticks: int) -> Array[FighterInput]:
	var inputs: Array[FighterInput] = []
	for i in ticks:
		var shield := FighterInput.new()
		shield.shield_held = true
		inputs.append(shield)
	return inputs


func _grab() -> GrabData:
	return _p1.stats.moveset.side_special.grab


# --- Data -----------------------------------------------------------------------------------------


func test_the_slam_matches_the_spec() -> void:
	var reach := _p1.stats.moveset.side_special
	assert_not_null(reach.grab, "Mads's side special is a command grab")
	assert_eq([reach.startup, reach.active, reach.recovery], [9, 4, 24])
	assert_eq(reach.hitbox_center, Vector2(16, -14))
	assert_eq(reach.hitbox_size, Vector2(18, 24))
	assert_eq([_grab().throw_frames, _grab().turn_frame, _grab().slam_frame], [40, 15, 24])
	assert_eq(_grab().path, PackedVector2Array([Vector2(12, -16), Vector2(11, -28), Vector2(0, -34),
		Vector2(-9, -30), Vector2(-13, -10)]))
	assert_eq(_grab().held_middle, 16.0)
	var slam := _grab().slam_hit
	assert_eq([slam.damage, slam.base_knockback, slam.knockback_growth, slam.angle_deg],
		[12.0, 220.0, 1.3, 60.0])


func test_only_his_side_special_changes() -> void:
	var defaults := (load("res://fighter/default_stats.tres") as FighterStats).moveset
	var moves := _p1.stats.moveset
	for name in ["jab", "neutral_special", "up_special", "down_air"]:
		assert_eq(moves.get(name), defaults.get(name), name)
	assert_null(_p2.stats.moveset.side_special.grab, "Kim keeps the projectile")


# --- The grab -------------------------------------------------------------------------------------


func test_he_catches_someone_in_front() -> void:
	await _place(Vector2(200, 192), Vector2(222, 192), _reach())
	_steps(10)
	assert_eq(_p2.state, Fighter.State.IDLE, "not yet: the grab box comes out on frame 10")
	_steps(1)
	assert_eq(_p2.state, Fighter.State.HELD)
	assert_eq(_p2.held_by, _p1)
	assert_eq(_p1.move, &"grab_throw")
	assert_eq(_p2.percent, 0.0, "a grab doesn't hurt by itself")


func test_a_shield_doesnt_stop_it() -> void:
	await _place(Vector2(200, 192), Vector2(222, 192), _reach(), _shield(60))
	_steps(11)
	assert_eq(_p2.state, Fighter.State.HELD)


func test_he_throws_no_projectile() -> void:
	await _place(Vector2(200, 192), Vector2(330, 192), _reach())
	_steps(15)
	assert_eq(_match.get_projectiles().size(), 0)


func test_a_miss_plays_out_its_end_lag() -> void:
	await _place(Vector2(200, 192), Vector2(300, 192), _reach())
	_steps(14)
	assert_eq(_p2.state, Fighter.State.IDLE, "out of reach")
	_steps(23)
	assert_eq(_p1.move, &"side_special", "still recovering")
	_steps(2)
	assert_ne(_p1.state, Fighter.State.ATTACK)


func test_it_works_in_the_air_too() -> void:
	# Both start at rest in the air and fall alike, so the grab box finds P2 as on the ground.
	await _place(Vector2(200, 60), Vector2(222, 60), _reach())
	_steps(11)
	assert_eq(_p2.state, Fighter.State.HELD)
	var y := _p1.global_position.y
	_steps(10)
	assert_almost_eq(_p1.global_position.y, y, 0.01, "hangs in the air while throwing")
	_steps(14)  # Throw frame 24.
	assert_eq(_p2.state, Fighter.State.HITSTUN, "slammed all the same")


# --- The throw ------------------------------------------------------------------------------------


func test_the_victim_stays_in_his_grip() -> void:
	await _place(Vector2(200, 192), Vector2(222, 192), _reach())
	_steps(11 + 12)
	assert_almost_eq(_p2.global_position.x, 200.0, 0.5, "halfway: right above him")
	assert_almost_eq(_p2.global_position.y, 192.0 - 34.0 + 16.0, 0.5, "body's middle at his hands")
	_steps(3)  # Frame 15: between the 3rd and 4th keyframes.
	assert_almost_eq(_p2.global_position.x, 200.0 - 4.5, 0.5)
	assert_eq(_p2.state, Fighter.State.HELD)


func test_he_turns_round_with_the_victim_overhead() -> void:
	await _place(Vector2(200, 192), Vector2(222, 192), _reach())
	_steps(11 + 14)
	assert_eq(_p1.facing, 1)
	_steps(1)
	assert_eq(_p1.facing, -1, "turned on frame 15")


func test_neither_can_be_hit_during_the_throw() -> void:
	await _place(Vector2(200, 192), Vector2(222, 192), _reach())
	_steps(20)
	assert_false(_p1.can_be_hit())
	assert_false(_p2.can_be_hit())


func test_the_slam_lands_behind_him_and_launches_up_and_away() -> void:
	await _place(Vector2(200, 192), Vector2(222, 192), _reach())
	_steps(11 + 23)
	assert_eq(_p2.state, Fighter.State.HELD, "not yet")
	_steps(1)
	assert_eq(_p2.state, Fighter.State.HITSTUN)
	assert_almost_eq(_p2.global_position.x, 187.0, 0.5, "behind where he faced, on the floor")
	assert_almost_eq(_p2.global_position.y, 192.0, 0.5)
	assert_almost_eq(_p2.percent, 12.0, 0.001)
	assert_lt(_p2.velocity.x, 0.0, "away from Mads")
	assert_lt(_p2.velocity.y, 0.0, "bounces up")
	assert_eq(_p1.facing, -1, "he turned round")
	assert_null(_p2.held_by)


func test_he_is_free_after_the_throw() -> void:
	await _place(Vector2(200, 192), Vector2(222, 192), _reach())
	_steps(11 + 40)
	assert_eq(_p1.move, &"grab_throw")
	_steps(1)
	assert_ne(_p1.state, Fighter.State.ATTACK)


# --- Look -----------------------------------------------------------------------------------------


func test_the_drawings() -> void:
	assert_eq(FighterVisuals.animation_for(Fighter.State.HELD, 0.0), "hurt")
	assert_eq(FighterVisuals.animation_for(Fighter.State.ATTACK, 0.0, &"grab_throw"), "side_special")
	var grab := GrabData.new()
	grab.slam_frame = 24
	var expected := {1: 0, 3: 0, 4: 1, 8: 1, 9: 2, 14: 2, 15: 3, 18: 3, 19: 4, 30: 4, 31: 5, 40: 5}
	for ticks: int in expected:
		assert_eq(FighterVisuals.throw_frame(ticks), expected[ticks], "throw tick %d" % ticks)
	var textures := FighterVisuals.textures_for(MADS)
	assert_true(textures.has("grab_throw"), "his throw strip")
	assert_eq((textures["grab_throw"] as Texture2D).get_size(), Vector2(112 * 6, 80))
	assert_almost_eq(FighterVisuals.held_turn(12, grab), PI / 2.0, 0.001, "half way round")
	assert_almost_eq(FighterVisuals.held_turn(40, grab), PI, 0.001)


## Runs FighterVisuals._draw for both mid-throw (the held victim turned over).
func test_both_are_drawn_mid_throw() -> void:
	await _place(Vector2(200, 192), Vector2(222, 192), _reach())
	_steps(20)
	await wait_frames(2)
	assert_eq(_p2.state, Fighter.State.HELD)
