extends GutTest
## Fighter.stun() (docs/specs/fighter.md#shield): an ability makes a fighter dizzy (SHIELD_BREAK)
## for a number of ticks, its shield left as it was. P1 and P2 are Casper (default moves).

const MATCH_SCENE := preload("res://match/match.tscn")

var _match: Match
var _p1: Fighter
var _saved_ids: Array[String] = []


func before_each() -> void:
	_saved_ids = [Game.character_id, Game.p2_character_id]
	Game.character_id = "slot_08"
	Game.p2_character_id = "slot_08"
	_match = MATCH_SCENE.instantiate()
	_match.auto_step = false
	add_child_autofree(_match)
	_p1 = _match.get_fighter(0)
	_p1.spawn_at(Vector2(200, 192), 1)
	_match.get_fighter(1).spawn_at(Vector2(360, 192), -1)
	_match.set_controller(0, ScriptedController.new())
	_match.set_controller(1, ScriptedController.new())
	await wait_physics_frames(1)


func after_each() -> void:
	Game.character_id = _saved_ids[0]
	Game.p2_character_id = _saved_ids[1]


func test_stun_is_dizzy_for_its_ticks() -> void:
	_p1.stun(30)
	assert_eq(_p1.state, Fighter.State.SHIELD_BREAK)
	for i in 30:
		_match.step()
	assert_eq(_p1.state, Fighter.State.SHIELD_BREAK, "dizzy for 30 whole ticks")
	_match.step()
	assert_eq(_p1.state, Fighter.State.IDLE)


func test_stun_leaves_the_shield_alone() -> void:
	_p1.shield_health = 40.0
	_p1.stun(10)
	for i in 12:
		_match.step()
	assert_almost_eq(_p1.shield_health, 40.0, 5.0, "not reset to shield_reset_health")


func test_stun_ends_a_move() -> void:
	_p1.move = &"jab"
	_p1.set_state(Fighter.State.ATTACK)
	_p1.stun(10)
	assert_eq(_p1.move, Fighter.NO_MOVE)
