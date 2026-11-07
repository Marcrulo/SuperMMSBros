extends GutTest
## The Match drives every tick (docs/specs/architecture.md#tick-order), with KOs, stocks and respawn.

const MATCH_SCENE := preload("res://match/match.tscn")

var _match: Match


## Adds a match to the tree. With `auto_step` off, the test decides when ticks happen.
func _add_match(auto_step: bool) -> void:
	_match = MATCH_SCENE.instantiate()
	_match.auto_step = auto_step
	add_child_autofree(_match)


func test_scene_has_stage_fighter_and_camera() -> void:
	_add_match(false)
	assert_true(_match.get_node("Stage") is Stage)
	assert_eq(_match.get_node("Fighters").get_child_count(), 2, "P1 and the dummy")
	assert_true(_match.get_fighter(0) is Fighter)
	var camera := _match.get_node("Camera2D") as Camera2D
	assert_not_null(camera, "a camera (it follows the fighters from Task 4 on)")


func test_p1_starts_at_its_spawn_point() -> void:
	_add_match(false)
	var p1 := _match.get_fighter(0)
	assert_eq(_match.tick, 0)
	assert_eq(p1.player_index, 0)
	assert_eq(p1.position, Vector2(168, 192))
	assert_eq(p1.facing, 1)
	assert_eq(p1.state, Fighter.State.IDLE)


func test_p1_is_played_from_the_keyboard() -> void:
	_add_match(false)
	assert_true(_match.get_controller(0) is KeyboardController)


func test_step_drives_the_fighter_with_its_controller() -> void:
	_add_match(false)
	var right := FighterInput.new()
	right.move_x = 1.0
	var inputs: Array[FighterInput] = []
	for i in 10:
		inputs.append(right)
	_match.set_controller(0, ScriptedController.new(inputs))
	await wait_physics_frames(1)
	for i in 10:
		_match.step()
	assert_eq(_match.tick, 10)
	assert_eq(_match.get_fighter(0).state, Fighter.State.RUN)
	assert_gt(_match.get_fighter(0).position.x, 112.0, "moved right")


func test_without_auto_step_nothing_happens_by_itself() -> void:
	_add_match(false)
	await wait_physics_frames(5)
	assert_eq(_match.tick, 0)


func test_auto_step_ticks_once_per_physics_frame() -> void:
	_add_match(true)
	_match.set_controller(0, ScriptedController.new())
	await wait_physics_frames(5)
	assert_between(_match.tick, 5, 7)


func test_reset_puts_everything_back() -> void:
	_add_match(false)
	var right := FighterInput.new()
	right.move_x = 1.0
	_match.set_controller(0, ScriptedController.new([right, right, right]))
	await wait_physics_frames(1)
	for i in 3:
		_match.step()
	_match.reset()
	var p1 := _match.get_fighter(0)
	assert_eq(_match.tick, 0)
	assert_eq(p1.position, Vector2(168, 192))
	assert_eq(p1.velocity, Vector2.ZERO)
	assert_eq(p1.state, Fighter.State.IDLE)
	_match.step()
	assert_gt(p1.velocity.x, 0.0, "the controller was reset and plays its inputs again")


# --- KOs, stocks and respawn (docs/specs/match-and-stage.md#kos-stocks-and-respawn) ----------------


## A match with both fighters standing still, P1 about to be pushed out.
func _add_still_match() -> Fighter:
	_add_match(false)
	_match.set_controller(0, ScriptedController.new())
	await wait_physics_frames(1)
	return _match.get_fighter(0)


func test_fighters_start_with_3_stocks() -> void:
	var p1: Fighter = await _add_still_match()
	assert_eq(p1.stocks, 3)
	assert_eq(_match.get_fighter(1).stocks, 3)
	assert_eq(p1.invulnerable_frames, 0)


func test_leaving_the_blast_zone_on_any_side_is_a_ko() -> void:
	var p1: Fighter = await _add_still_match()
	watch_signals(_match)
	for outside in [Vector2(-80, 150), Vector2(560, 150), Vector2(240, -170), Vector2(240, 320)]:
		_match.reset()
		p1.global_position = outside
		p1.velocity = Vector2(100, 100)
		_match.step()
		assert_eq(p1.state, Fighter.State.KO, "KO'd at %s" % outside)
		assert_eq(p1.stocks, 2)
		assert_eq(p1.velocity, Vector2.ZERO)
	assert_signal_emitted_with_parameters(_match, "fighter_ko", [0])


func test_inside_the_blast_zone_nothing_happens() -> void:
	var p1: Fighter = await _add_still_match()
	p1.global_position = Vector2(545, 150)
	_match.step()
	assert_almost_eq(p1.position.x, 545.0, 0.01, "off the stage but still in play")
	assert_eq(p1.stocks, 3)


func test_respawn_60_ticks_later_at_0_percent_and_invulnerable() -> void:
	var p1: Fighter = await _add_still_match()
	watch_signals(_match)
	p1.percent = 80.0
	p1.facing = -1
	p1.global_position = Vector2(-100, 150)
	_match.step()
	for i in 59:
		_match.step()
	assert_eq(p1.state, Fighter.State.KO, "still waiting after 59 ticks")
	assert_signal_not_emitted(_match, "fighter_respawned")
	_match.step()
	assert_eq(p1.state, Fighter.State.IDLE, "back on the 60th")
	assert_eq(p1.position, Vector2(168, 192))
	assert_eq(p1.facing, 1)
	assert_eq(p1.percent, 0.0)
	assert_eq(p1.stocks, 2)
	assert_signal_emitted_with_parameters(_match, "fighter_respawned", [0])
	assert_eq(p1.invulnerable_frames, 119, "120 ticks, counting the respawn tick")
	assert_false(p1.can_be_hit())
	for i in 119:
		_match.step()
	assert_eq(p1.invulnerable_frames, 0)
	assert_true(p1.can_be_hit())


func test_a_ko_fighter_does_not_move() -> void:
	var p1: Fighter = await _add_still_match()
	p1.global_position = Vector2(-100, 150)
	_match.step()
	var where := p1.global_position
	for i in 10:
		_match.step()
	assert_eq(p1.global_position, where)
	assert_false(p1.can_be_hit())


func test_out_of_stocks_stays_ko() -> void:
	var p1: Fighter = await _add_still_match()
	p1.stocks = 1
	p1.global_position = Vector2(-100, 150)
	_match.step()
	for i in 200:
		_match.step()
	assert_eq(p1.stocks, 0)
	assert_eq(p1.state, Fighter.State.KO)


func test_reset_restores_stocks_and_clears_ko() -> void:
	var p1: Fighter = await _add_still_match()
	p1.global_position = Vector2(-100, 150)
	_match.step()
	_match.reset()
	assert_eq(p1.stocks, 3)
	assert_eq(p1.state, Fighter.State.IDLE)
	assert_eq(p1.invulnerable_frames, 0)
	for i in 70:
		_match.step()
	assert_eq(p1.stocks, 3, "no respawn left over from before the reset")
