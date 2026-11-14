extends GutTest
## Gitte's pyramid up special (docs/specs/characters/gitte.md#gitte--scissors-and-stances). P1 is Gitte;
## scripted [idle, up special] starts it on step 2, so its frame 4 (the choice) is step 5, the
## rise's 18 ticks are steps 6–23 and the pop is step 24. Main platform top y 192 (x 96…384);
## left platform top y 150 (x 132…204). x 110 has no platform above the main one.

const MATCH_SCENE := preload("res://match/match.tscn")
const GITTE := "slot_02"

var _match: Match
var _p1: Fighter
var _p2: Fighter
var _saved_ids: Array[String] = []


func before_each() -> void:
	_saved_ids = [Game.character_id, Game.p2_character_id]
	Game.character_id = GITTE
	Game.p2_character_id = "slot_09"
	_match = MATCH_SCENE.instantiate()
	_match.auto_step = false
	add_child_autofree(_match)
	_p1 = _match.get_fighter(0)
	_p2 = _match.get_fighter(1)


func after_each() -> void:
	Game.character_id = _saved_ids[0]
	Game.p2_character_id = _saved_ids[1]


func _place(p1_at: Vector2, p2_at := Vector2(370, 192), stance := Fighter.Stance.PLUS) -> void:
	_p1.spawn_at(p1_at, 1)
	_p2.spawn_at(p2_at, -1)
	_p1.stance = stance
	var press := FighterInput.new()
	press.special_pressed = true
	press.special_held = true
	press.up_held = true
	var inputs: Array[FighterInput] = [FighterInput.new(), press]
	_match.set_controller(0, ScriptedController.new(inputs))
	_match.set_controller(1, ScriptedController.new([]))
	await wait_physics_frames(1)


func _steps(count: int) -> void:
	for i in count:
		_match.step()


func _data() -> PyramidData:
	return _p1.stats.moveset.up_special.pyramid


# --- Data -----------------------------------------------------------------------------------------


func test_pyramid_data() -> void:
	var up := _p1.stats.moveset.up_special
	assert_not_null(up.pyramid)
	assert_eq([up.startup, up.active, up.drift_speed], [4, 0, 80.0])
	var d := _data()
	assert_eq([d.reach, d.height, d.rise_frames, d.pop_speed, d.hop_speed, d.sink_frames],
		[64.0, 96.0, 18, 180.0, 200.0, 20])
	var tip := d.tip_hit
	assert_eq([tip.startup, tip.active], [0, d.rise_frames], "out for the whole rise")
	assert_eq([tip.hitbox_center, tip.hitbox_size, tip.damage, tip.base_knockback,
		tip.knockback_growth, tip.angle_deg, tip.direction],
		[Vector2(0, -10), Vector2(32, 28), 7.0, 160.0, 0.8, 85.0, MoveData.Direction.AWAY])


func test_others_have_no_pyramid() -> void:
	assert_null((load("res://fighter/default_stats.tres") as FighterStats).moveset.up_special.pyramid)


# --- Pyramid or hop ---------------------------------------------------------------------------------


func test_pyramid_from_the_ground() -> void:
	await _place(Vector2(110, 192))
	_steps(5)
	assert_eq(_p1.move, &"pyramid_rise")
	assert_eq(_match.get_pyramids().size(), 1)
	var pyramid := _match.get_pyramids()[0]
	assert_eq(pyramid.owner_index, 0)
	assert_almost_eq(pyramid.global_position, Vector2(110, 192), Vector2(0.5, 0.5))
	assert_false(_p1.up_special_available)


func test_pyramid_lifts_her_and_pops_her_off() -> void:
	await _place(Vector2(110, 192))
	_steps(5)
	_steps(9)
	assert_almost_eq(_p1.global_position.y, 192.0 - 48.0, 1.0, "halfway up")
	assert_almost_eq(_p1.global_position.x, 110.0, 0.5, "straight up")
	assert_almost_eq(_match.get_pyramids()[0].tip_height(), 48.0, 0.01)
	_steps(9)
	assert_almost_eq(_p1.global_position.y, 96.0, 1.0, "on top")
	_steps(1)
	assert_eq(_p1.move, &"up_special", "popped off")
	assert_almost_eq(_p1.velocity.y, -180.0 + 10.0, 0.5, "pop speed, one tick of gravity")
	for i in 60:
		_match.step()
		if _p1.state == Fighter.State.HELPLESS:
			break
	assert_eq(_p1.state, Fighter.State.HELPLESS)


func test_waits_in_the_air_for_the_tip() -> void:
	await _place(Vector2(110, 152))
	_steps(5)
	assert_eq(_p1.move, &"pyramid_rise", "the floor is 40 px below")
	var start_y := _p1.global_position.y
	_steps(5)
	assert_almost_eq(_p1.global_position.y, start_y, 0.5, "the tip is still below her")
	_steps(13)
	assert_almost_eq(_p1.global_position.y, 96.0, 1.0, "then it carries her to the top")


func test_too_high_means_a_hop() -> void:
	await _place(Vector2(110, 100))
	_steps(5)
	assert_eq(_p1.move, &"up_special")
	assert_eq(_match.get_pyramids().size(), 0)
	assert_almost_eq(_p1.velocity.y, -200.0, 0.5)
	assert_false(_p1.is_hitbox_active())
	for i in 60:
		_match.step()
		if _p1.state == Fighter.State.HELPLESS:
			break
	assert_eq(_p1.state, Fighter.State.HELPLESS)


func test_off_stage_means_a_hop() -> void:
	await _place(Vector2(60, 150))
	_steps(5)
	assert_eq(_match.get_pyramids().size(), 0)
	assert_almost_eq(_p1.velocity.y, -200.0, 0.5)


func test_rises_from_a_platform() -> void:
	await _place(Vector2(168, 150))
	_steps(5)
	assert_eq(_match.get_pyramids().size(), 1)
	assert_almost_eq(_match.get_pyramids()[0].floor_y, 150.0, 0.01)


# --- The tip hit ----------------------------------------------------------------------------------


func test_tip_hits_upward() -> void:
	await _place(Vector2(110, 192), Vector2(124, 192))
	_steps(7)
	assert_eq(_p2.percent, 7.0)
	assert_lt(_p2.velocity.y, -100.0, "launched up")
	assert_gt(_p2.velocity.x, 0.0, "away from her")


func test_tip_hitbox_is_at_the_tip() -> void:
	await _place(Vector2(110, 152))
	_steps(7)
	var tip := _match.get_pyramids()[0].tip_height()
	assert_lt(tip, 40.0, "below her still")
	var box := _p1.get_hitbox_rect()
	assert_almost_eq(box.get_center(), Vector2(110, 192 - tip - 10), Vector2(0.5, 0.5))
	assert_eq(box.size, Vector2(32, 28))


func test_multiply_boosts_the_tip() -> void:
	await _place(Vector2(110, 192), Vector2(124, 192), Fighter.Stance.MULTIPLY)
	_steps(10)
	assert_almost_eq(_p2.percent, 7.0 * 1.3, 0.01)


# --- Sinking --------------------------------------------------------------------------------------


func test_pyramid_sinks_after_the_pop() -> void:
	await _place(Vector2(110, 192))
	_steps(24)
	var pyramid := _match.get_pyramids()[0]
	assert_true(pyramid.sinking)
	assert_lt(pyramid.tip_height(), 96.0)
	_steps(18)
	assert_eq(_match.get_pyramids().size(), 1, "still sinking")
	_steps(1)
	assert_eq(_match.get_pyramids().size(), 0, "gone after 20 ticks")


func test_a_hit_ends_the_ride() -> void:
	await _place(Vector2(110, 192))
	_steps(10)
	_p1.take_hit(load("res://fighter/moves/default/jab.tres"), 1, 0.0)
	_steps(1)
	assert_true(_match.get_pyramids()[0].sinking)
	assert_false(_p1.is_hitbox_active())


func test_reset_removes_pyramids() -> void:
	await _place(Vector2(110, 192))
	_steps(8)
	_match.reset()
	assert_eq(_match.get_pyramids().size(), 0)


# --- Drawing --------------------------------------------------------------------------------------


func test_only_the_part_above_the_floor_is_drawn() -> void:
	# 48 px of the pyramid above the floor = the top 64 px of the 128 px drawing.
	assert_eq(Pyramid.drawn_region(48.0), Rect2(0, 0, 168, 64))
	assert_eq(Pyramid.drawn_region(96.0), Rect2(0, 0, 168, 128))
	assert_eq(Pyramid.drawn_region(0.0).size.y, 0.0)


func test_riding_shows_the_arms_up_drawing() -> void:
	assert_eq(FighterVisuals.animation_for(Fighter.State.ATTACK, -300.0, &"pyramid_rise"), "up_special")


func test_pyramid_picture() -> void:
	assert_eq((load("res://assets/fighters/slot_02/pyramid.png") as Texture2D).get_size(),
		Vector2(168, 128))
