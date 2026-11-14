extends GutTest
## Fidusen's specials (docs/specs/characters/fidusen.md#fidusen--banana-book-vine). P1 is Fidusen; scripted
## [idle, special] starts a special on step 2, so frame N of it is step N + 1 (peel on step 9, book
## on step 11, the vine's choice on step 7). Main platform top y 192 (x 96…384, ledges at its
## corners); left platform top y 150 (x 132…204).

const MATCH_SCENE := preload("res://match/match.tscn")
const FIDUSEN := "slot_13"

var _match: Match
var _p1: Fighter
var _p2: Fighter
var _saved_ids: Array[String] = []


func before_each() -> void:
	_saved_ids = [Game.character_id, Game.p2_character_id]
	Game.character_id = FIDUSEN
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


## [idle, special in `direction`, `gap` idle ticks] × times.
func _special(direction: String, times := 1, gap := 30) -> Array[FighterInput]:
	var inputs: Array[FighterInput] = []
	for i in times:
		var special := FighterInput.new()
		special.special_pressed = true
		special.special_held = true
		match direction:
			"down":
				special.down_held = true
			"up":
				special.up_held = true
			"side":
				special.move_x = 1.0
		inputs.append(FighterInput.new())
		inputs.append(special)
		for j in gap:
			inputs.append(FighterInput.new())
	return inputs


func _walk(ticks: int, x: float, idle_first := 0) -> Array[FighterInput]:
	var inputs: Array[FighterInput] = []
	for i in idle_first:
		inputs.append(FighterInput.new())
	for i in ticks:
		var walk := FighterInput.new()
		walk.move_x = x
		inputs.append(walk)
	return inputs


# --- Data -----------------------------------------------------------------------------------------


func test_fidusen_has_his_own_specials() -> void:
	var defaults := (load("res://fighter/default_stats.tres") as FighterStats).moveset
	var moves := _p1.stats.moveset
	for name in ["down_special", "side_special", "up_special"]:
		assert_ne(moves.get(name), defaults.get(name), name)
	for name in ["jab", "side_tilt", "neutral_air", "neutral_special"]:
		assert_eq(moves.get(name), defaults.get(name), name)
	var peel := moves.down_special.ability as PeelData
	assert_eq([peel.max_out, peel.lifetime, peel.trip_frames], [3, 600, 45])
	assert_eq([peel.damage, peel.fall_speed, peel.size], [3.0, 300.0, Vector2(12, 4)])
	var book := moves.side_special
	assert_eq([book.projectile_angle_deg, book.projectile_gravity, book.damage], [25.0, 700.0, 7.0])
	var vine := moves.up_special.ability as VineData
	assert_eq([vine.length, vine.swing_degrees, vine.swing_frames], [140.0, 60.0, 30])
	assert_eq([vine.ledge_range, vine.pull_frames], [100.0, 12])


func test_floor_below_with_platforms() -> void:
	var stage := _match.get_node("Stage") as Stage
	assert_eq(stage.floor_below(Vector2(160, 100), true), 150.0, "left platform")
	assert_eq(stage.floor_below(Vector2(160, 100)), 192.0, "main platform only")
	assert_eq(stage.floor_below(Vector2(240, 100), true), 108.0, "top platform")


# --- Banana peel ----------------------------------------------------------------------------------


func test_peel_drops_at_his_feet() -> void:
	await _place(Vector2(150, 192), Vector2(380, 192), _special("down"))
	_steps(8)
	assert_eq(_peels().size(), 0, "not before frame 8")
	_steps(1)
	assert_eq(_peels().size(), 1)
	var peel := _peels()[0]
	assert_eq(peel.owner_index, 0)
	assert_almost_eq(peel.global_position, Vector2(158, 192), Vector2(2.1, 0.5))
	assert_true(peel.landed)


func test_peel_falls_to_the_platform_below() -> void:
	await _place(Vector2(160, 80), Vector2(380, 192), _special("down"))
	_steps(9)
	var peel := _peels()[0]
	assert_false(peel.landed)
	_steps(30)
	assert_true(peel.landed)
	assert_eq(peel.global_position.y, 150.0, "on the left platform")


func test_peel_without_floor_falls_away() -> void:
	await _place(Vector2(60, 100), Vector2(380, 192), _special("down"))
	_steps(9)
	assert_eq(_peels().size(), 1)
	_steps(60)
	assert_eq(_peels().size(), 0)


func test_at_most_three_peels() -> void:
	await _place(Vector2(150, 192), Vector2(380, 192), _special("down", 4, 25))
	_steps(9)
	var first := _peels()[0]
	_steps(27 * 3)
	assert_eq(_peels().size(), 3)
	assert_false(first in _peels(), "the oldest is gone")


func test_peels_last_ten_seconds() -> void:
	await _place(Vector2(150, 192), Vector2(380, 192), _special("down"))
	_steps(9 + 598)
	assert_eq(_peels().size(), 1)
	_steps(2)
	assert_eq(_peels().size(), 0)


func test_walking_onto_a_peel_trips() -> void:
	watch_signals(_match)
	await _place(Vector2(150, 192), Vector2(200, 192), _special("down"), _walk(60, -1.0, 12))
	var tripped_at := -1
	for i in 60:
		_match.step()
		if _p2.state == Fighter.State.TRIPPED:
			tripped_at = i
			break
	assert_gt(tripped_at, 0, "P2 slipped")
	assert_eq(_p2.percent, 3.0)
	assert_eq(_p2.velocity.x, 0.0, "no launch")
	assert_eq(_peels().size(), 0, "the peel is used up")
	assert_signal_emitted(_match, "fighter_hit")
	assert_eq(_p2.get_hurtbox_rect().size.y, 15.0, "lying low")
	_steps(44)
	assert_eq(_p2.state, Fighter.State.TRIPPED, "45 ticks on the floor")
	_steps(2)
	assert_ne(_p2.state, Fighter.State.TRIPPED)


func test_fidusen_never_trips_on_his_own_peel() -> void:
	var inputs := _special("down", 1, 0)
	inputs.append_array(_walk(30, 1.0))
	await _place(Vector2(150, 192), Vector2(380, 192), inputs)
	for i in 40:
		_match.step()
		assert_ne(_p1.state, Fighter.State.TRIPPED)
	assert_eq(_peels().size(), 1)


func test_a_tripped_fighter_can_be_hit() -> void:
	await _place(Vector2(150, 192), Vector2(200, 192), _special("down"), _walk(60, -1.0, 12))
	for i in 60:
		_match.step()
		if _p2.state == Fighter.State.TRIPPED:
			break
	_p2.take_hit(_p1.stats.moveset.jab, -1, 150.0)
	assert_eq(_p2.state, Fighter.State.HITSTUN)


# --- Book -----------------------------------------------------------------------------------------


func test_book_arcs_and_lands() -> void:
	await _place(Vector2(150, 192), Vector2(380, 192), _special("side"))
	_steps(11)
	assert_eq(_match.get_projectiles().size(), 1)
	var book := _match.get_projectiles()[0]
	assert_almost_eq(book.global_position, Vector2(164, 176), Vector2(4.1, 0.01))
	var start_y := book.global_position.y
	_steps(3)
	assert_lt(book.global_position.y, start_y, "thrown upward")
	_steps(15)
	assert_gt(book.global_position.y, start_y, "then falling")
	_steps(9)
	assert_eq(_match.get_projectiles().size(), 0, "landed on the floor")
	assert_eq(_p2.percent, 0.0)


## Thrown in the air left of the stage, the book comes down over the left platform (x 132…204,
## top y 150) and falls on past it instead of landing on it.
func test_book_goes_through_platforms() -> void:
	await _place(Vector2(10, 100), Vector2(300, 192), _special("side"))
	_steps(11)
	var book := _match.get_projectiles()[0]
	var past_platform := false
	for i in 40:
		_match.step()
		if _match.get_projectiles().is_empty():
			break
		past_platform = past_platform or book.global_position.y > 152.0
	assert_true(past_platform, "fell past the platform top")


func test_book_hits() -> void:
	await _place(Vector2(150, 192), Vector2(220, 192), _special("side"))
	_steps(30)
	assert_eq(_p2.percent, 7.0)


# --- Vine -----------------------------------------------------------------------------------------


func test_vine_swings_forward_and_flings() -> void:
	await _place(Vector2(150, 80), Vector2(380, 192), _special("up"))
	_steps(7)
	assert_eq(_p1.move, &"vine_swing")
	var start := _p1.global_position
	assert_almost_eq((_p1.ability(VineAbility) as VineAbility).vine_anchor, start + Vector2(0, -140), Vector2(0.5, 0.5))
	assert_false(_p1.up_special_available)
	_steps(15)
	assert_gt(_p1.global_position.x, start.x + 20.0, "forward")
	assert_lt(_p1.global_position.y, start.y - 5.0, "and up")
	_steps(16)
	assert_eq(_p1.move, &"up_special", "let go")
	assert_almost_eq(_p1.velocity.x, 146.0, 20.0)
	assert_lt(_p1.velocity.y, -200.0)
	for i in 60:
		_match.step()
		if _p1.state == Fighter.State.HELPLESS:
			break
	assert_eq(_p1.state, Fighter.State.HELPLESS)


func test_vine_pulls_to_a_nearby_ledge() -> void:
	await _place(Vector2(420, 240), Vector2(150, 192), _special("up"))
	_steps(7)
	assert_eq(_p1.move, &"vine_pull")
	_steps(12)
	assert_eq(_p1.state, Fighter.State.LEDGE)
	assert_eq(_p1.ledge.point, Vector2(384, 192))


func test_a_ledge_too_far_means_a_swing() -> void:
	await _place(Vector2(480, 270), Vector2(150, 192), _special("up"))
	_steps(7)
	assert_eq(_p1.move, &"vine_swing")


# --- Art ------------------------------------------------------------------------------------------


func test_peel_and_book_pictures() -> void:
	assert_eq((load("res://assets/fighters/slot_13/peel.png") as Texture2D).get_size(), Vector2(16, 8))
	assert_eq((load("res://assets/fighters/slot_13/projectile.png") as Texture2D).get_size(),
		Vector2(48, 16))


## The banana peels in the match, oldest first.
func _peels() -> Array[Peel]:
	var found: Array[Peel] = []
	found.assign(_match.get_entities(Peel))
	return found
