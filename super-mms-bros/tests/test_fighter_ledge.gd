extends GutTest
## Grabbing and leaving ledges (docs/specs/fighter.md#ledge). The Match does the grabbing, right
## after the fighters move (docs/specs/architecture.md#tick-order), so these tests run a Match.

const MATCH_SCENE := preload("res://match/match.tscn")
const RIGHT_LEDGE := Vector2(384, 192)
## Beside the right ledge, a little above it: falling from here grabs it.
const ABOVE_RIGHT := Vector2(395, 185)

var _match: Match
var _p1: Fighter
var _stats: FighterStats


func before_each() -> void:
	_match = MATCH_SCENE.instantiate()
	_match.auto_step = false
	add_child_autofree(_match)
	_p1 = _match.get_fighter(0)
	_stats = _p1.stats
	_match.set_controller(0, ScriptedController.new())
	await wait_physics_frames(1)


## One tick with P1 playing `input` (P2 stands still).
func _step(input := FighterInput.new()) -> void:
	_match.set_controller(0, ScriptedController.new([input]))
	_match.step()


func _steps(ticks: int, input := FighterInput.new()) -> void:
	for i in ticks:
		_step(input)


## Puts P1 at `at` in the air and lets it fall until it hangs from a ledge (or 60 ticks pass).
func _fall_onto_ledge(at := ABOVE_RIGHT) -> void:
	_p1.spawn_at(at, 1)
	for i in 60:
		_step()
		if _p1.state == Fighter.State.LEDGE:
			return


func _pressed(field: String, value: Variant = true) -> FighterInput:
	var input := FighterInput.new()
	input.set(field, value)
	return input


func test_the_stage_has_two_ledges() -> void:
	var ledges := (_match.get_node("Stage") as Stage).get_ledges()
	assert_eq(ledges.size(), 2)
	assert_eq(ledges[0].point, Vector2(96, 192))
	assert_eq(ledges[0].side, -1)
	assert_eq(ledges[1].point, RIGHT_LEDGE)
	assert_eq(ledges[1].side, 1)


func test_falling_past_a_ledge_grabs_it() -> void:
	_fall_onto_ledge()
	assert_eq(_p1.state, Fighter.State.LEDGE)
	assert_eq(_p1.position, RIGHT_LEDGE + _stats.ledge_hang_offset)
	assert_eq(_p1.facing, -1, "faces the stage")
	assert_eq(_p1.velocity, Vector2.ZERO)
	_steps(30)
	assert_eq(_p1.position, RIGHT_LEDGE + _stats.ledge_hang_offset, "hangs still")


func test_the_left_ledge_mirrors() -> void:
	_fall_onto_ledge(Vector2(85, 185))
	assert_eq(_p1.state, Fighter.State.LEDGE)
	var offset := _stats.ledge_hang_offset
	assert_eq(_p1.position, Vector2(96 - offset.x, 192 + offset.y))
	assert_eq(_p1.facing, 1)


func test_holding_down_does_not_grab() -> void:
	_p1.spawn_at(ABOVE_RIGHT, 1)
	var down := _pressed("down_held")
	_steps(15, down)
	assert_ne(_p1.state, Fighter.State.LEDGE)
	assert_gt(_p1.position.y, 260.0, "fell past")


func test_rising_in_the_air_does_not_grab() -> void:
	_p1.spawn_at(Vector2(395, 230), 1)
	_step()
	_p1.velocity.y = -200.0
	for i in 15:
		_step()
		assert_ne(_p1.state, Fighter.State.LEDGE)


func test_grabbing_restores_jumps_up_special_and_air_dodge() -> void:
	_p1.spawn_at(ABOVE_RIGHT, 1)
	_step()
	_p1.jumps_left = 0
	_p1.up_special_available = false
	_p1.air_dodge_available = false
	for i in 30:
		_step()
	assert_eq(_p1.state, Fighter.State.LEDGE)
	assert_eq(_p1.jumps_left, _stats.max_air_jumps)
	assert_true(_p1.up_special_available)
	assert_true(_p1.air_dodge_available)


func test_grabbing_gives_intangibility_for_a_while() -> void:
	_fall_onto_ledge()
	assert_true(_p1.is_intangible())
	assert_false(_p1.can_be_hit())
	_steps(_stats.ledge_intangible_frames - 1)
	assert_true(_p1.is_intangible())
	_step()
	assert_false(_p1.is_intangible())
	assert_true(_p1.can_be_hit())


func test_ledge_intangibility_must_be_earned_again() -> void:
	_fall_onto_ledge()
	var ledge := _p1.ledge
	_step(_pressed("down_pressed"))
	assert_eq(_p1.state, Fighter.State.AIR)
	_p1.grab_ledge(ledge)
	assert_eq(_p1.state, Fighter.State.LEDGE)
	assert_false(_p1.is_intangible(), "no intangibility on a regrab without touching ground")
	# Get up, stand on the stage, and come back: earned again.
	_step(_pressed("up_pressed"))
	_steps(_stats.ledge_climb_frames + 2)
	assert_eq(_p1.state, Fighter.State.IDLE)
	_p1.grab_ledge(ledge)
	assert_true(_p1.is_intangible())


func test_lets_go_after_hanging_too_long() -> void:
	_fall_onto_ledge()
	_steps(_stats.ledge_max_hang - 1)
	assert_eq(_p1.state, Fighter.State.LEDGE)
	_step()
	assert_eq(_p1.state, Fighter.State.AIR)


func test_jump_from_the_ledge() -> void:
	_fall_onto_ledge()
	_step(_pressed("jump_pressed"))
	assert_eq(_p1.state, Fighter.State.AIR)
	assert_almost_eq(_p1.velocity.y, -_stats.jump_velocity + _stats.gravity / 60.0, 0.01)
	assert_eq(_p1.jumps_left, _stats.max_air_jumps, "the double jump is kept")
	assert_null(_p1.ledge)


func test_up_climbs_onto_the_stage() -> void:
	_fall_onto_ledge()
	_steps(_stats.ledge_intangible_frames + 5)
	_step(_pressed("up_pressed"))
	assert_eq(_p1.state, Fighter.State.LEDGE_CLIMB)
	for i in _stats.ledge_climb_frames - 1:
		assert_true(_p1.is_intangible(), "climb frame %d" % (i + 1))
		_step()
	assert_eq(_p1.state, Fighter.State.LEDGE_CLIMB)
	_step()
	assert_eq(_p1.state, Fighter.State.IDLE)
	assert_almost_eq(_p1.position.x, RIGHT_LEDGE.x - _stats.ledge_climb_inset, 0.01)
	assert_almost_eq(_p1.position.y, RIGHT_LEDGE.y, 0.5)
	assert_true(_p1.is_on_floor())
	_steps(10)
	assert_eq(_p1.state, Fighter.State.IDLE, "stays standing")


func test_toward_the_stage_climbs_and_away_lets_go() -> void:
	_fall_onto_ledge()
	_step(_pressed("side_pressed", -1))
	assert_eq(_p1.state, Fighter.State.LEDGE_CLIMB)
	_fall_onto_ledge()
	assert_eq(_p1.state, Fighter.State.LEDGE)
	_step(_pressed("side_pressed", 1))
	assert_eq(_p1.state, Fighter.State.AIR)


func test_down_lets_go_and_blocks_regrabbing_for_a_while() -> void:
	_fall_onto_ledge()
	_step(_pressed("down_pressed"))
	assert_eq(_p1.state, Fighter.State.AIR)
	assert_null(_p1.ledge)
	var ledge := (_match.get_node("Stage") as Stage).get_ledges()[1]
	_p1.global_position = RIGHT_LEDGE + _stats.ledge_hang_offset
	assert_false(_p1.can_grab_ledge(ledge), "can't regrab at once")
	_p1.velocity = Vector2.ZERO
	_steps(_stats.ledge_regrab_frames)
	_p1.global_position = RIGHT_LEDGE + _stats.ledge_hang_offset
	_p1.velocity = Vector2.ZERO
	assert_true(_p1.can_grab_ledge(ledge), "can again later")


func test_up_special_grabs_the_ledge_while_rising() -> void:
	_p1.spawn_at(Vector2(396, 250), 1)
	_step()
	var up_b := _pressed("special_pressed")
	up_b.up_held = true
	up_b.special_held = true
	_step(up_b)
	var hold_up := _pressed("up_held")
	for i in 40:
		_step(hold_up)
		if _p1.state == Fighter.State.LEDGE:
			break
	assert_eq(_p1.state, Fighter.State.LEDGE)


func test_a_held_ledge_cannot_be_grabbed() -> void:
	_fall_onto_ledge()
	var p2 := _match.get_fighter(1)
	p2.spawn_at(ABOVE_RIGHT, -1)
	for i in 30:
		_step()
	assert_eq(_p1.state, Fighter.State.LEDGE)
	assert_ne(p2.state, Fighter.State.LEDGE)


func test_a_hit_knocks_the_fighter_off_the_ledge() -> void:
	_fall_onto_ledge()
	_steps(_stats.ledge_intangible_frames + 1)
	_p1.take_hit(_stats.moveset.jab, 1, 300.0)
	assert_eq(_p1.state, Fighter.State.HITSTUN)
	assert_null(_p1.ledge)
	_steps(3)
	assert_ne(_p1.position, RIGHT_LEDGE + _stats.ledge_hang_offset, "falls away")
