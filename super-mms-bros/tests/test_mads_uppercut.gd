extends GutTest
## Mads's up special, the rising uppercut (docs/specs/characters/mads.md#mads--grappler).
## P1 is Mads; scripted [idle, up special] starts it on step 2, so frame N of it is step N + 1.
## The rise starts on frame 4 (step 5): rise frame k is step 4 + k. Main platform top y 192.

const MATCH_SCENE := preload("res://match/match.tscn")
const MADS := "slot_11"

var _match: Match
var _p1: Fighter
var _p2: Fighter
var _saved_ids: Array[String] = []


func before_each() -> void:
	_saved_ids = [Game.character_id, Game.p2_character_id]
	Game.character_id = MADS
	Game.p2_character_id = "slot_08"
	_match = MATCH_SCENE.instantiate()
	_match.auto_step = false
	add_child_autofree(_match)
	_p1 = _match.get_fighter(0)
	_p2 = _match.get_fighter(1)


func after_each() -> void:
	Game.character_id = _saved_ids[0]
	Game.p2_character_id = _saved_ids[1]


func _place(p1_at: Vector2, p2_at: Vector2, p1_inputs: Array[FighterInput]) -> void:
	_p1.spawn_at(p1_at, 1)
	_p2.spawn_at(p2_at, -1)
	_match.set_controller(0, ScriptedController.new(p1_inputs))
	_match.set_controller(1, ScriptedController.new([]))
	await wait_physics_frames(1)


func _steps(count: int) -> void:
	for i in count:
		_match.step()


## [idle, up special, then holding `move_x` for 10 ticks].
func _uppercut(move_x: float = 0.0) -> Array[FighterInput]:
	var special := FighterInput.new()
	special.special_pressed = true
	special.special_held = true
	special.up_held = true
	special.move_x = move_x
	var inputs: Array[FighterInput] = [FighterInput.new(), special]
	for i in 10:
		var held := FighterInput.new()
		held.move_x = move_x
		inputs.append(held)
	return inputs


func _numbers() -> UppercutData:
	return _p1.stats.moveset.up_special.ability as UppercutData


func _ability() -> UppercutAbility:
	for a in _p1.abilities:
		if a is UppercutAbility:
			return a
	return null


# --- Data -----------------------------------------------------------------------------------------


func test_the_uppercut_matches_the_spec() -> void:
	var up := _p1.stats.moveset.up_special
	assert_true(up.ability is UppercutData, "Mads's up special is the uppercut")
	assert_eq([up.startup, up.active, up.recovery], [3, 0, 0])
	var u := _numbers()
	assert_eq(u.invulnerable_frames, 5)
	assert_eq([u.rise_speed, u.forward_speed, u.rise_gravity], [560.0, 70.0, 1400.0])
	assert_eq(u.clean_frames, 4)
	var clean := u.clean_hit
	assert_eq([clean.startup, clean.active], [0, 4])
	assert_eq([clean.hitbox_center, clean.hitbox_size], [Vector2(12, -22), Vector2(16, 28)])
	assert_eq([clean.damage, clean.base_knockback, clean.knockback_growth, clean.angle_deg],
		[13.0, 220.0, 1.4, 80.0])
	assert_eq(clean.direction, MoveData.Direction.FACING)
	var late := u.late_hit
	assert_eq(late.startup, 4)
	assert_eq([late.hitbox_center, late.hitbox_size], [Vector2(10, -32), Vector2(14, 16)])
	assert_eq([late.damage, late.base_knockback, late.knockback_growth, late.angle_deg],
		[5.0, 110.0, 0.5, 75.0])
	assert_eq(late.direction, MoveData.Direction.FACING)


func test_others_keep_the_jump_boost() -> void:
	assert_null(_p2.stats.moveset.up_special.ability, "Casper keeps the default up special")


# --- The rise -------------------------------------------------------------------------------------


func test_startup_then_he_rises_forward() -> void:
	await _place(Vector2(200, 192), Vector2(330, 192), _uppercut())
	_steps(4)  # Frame 3: still the startup.
	assert_eq(_p1.move, &"up_special")
	assert_almost_eq(_p1.global_position.y, 192.0, 0.5, "still on the floor")
	_steps(1)  # Frame 4: the rise.
	assert_eq(_p1.move, &"uppercut_rise")
	assert_lt(_p1.global_position.y, 192.0, "rising")
	assert_gt(_p1.velocity.x, 0.0, "forward, toward his facing side")
	var x := _p1.global_position.x
	_steps(10)
	assert_eq(_p1.move, &"uppercut_rise", "still rising")
	assert_gt(_p1.global_position.x, x, "moved forward")


func test_he_turns_to_the_held_side() -> void:
	await _place(Vector2(200, 192), Vector2(330, 192), _uppercut(-1.0))
	_steps(5)
	assert_eq(_p1.facing, -1)
	assert_lt(_p1.velocity.x, 0.0)


func test_helpless_at_the_top() -> void:
	await _place(Vector2(200, 192), Vector2(330, 192), _uppercut())
	_steps(20)  # Rise frame 16.
	assert_eq(_p1.state, Fighter.State.ATTACK)
	_steps(10)  # Rise frame 26: past the top (about rise frame 24).
	assert_eq(_p1.state, Fighter.State.HELPLESS)
	var risen := 192.0 - _p1.global_position.y
	assert_between(risen, 100.0, 125.0, "about 112 px up")


func test_he_cant_be_hit_on_frames_1_to_5() -> void:
	await _place(Vector2(200, 192), Vector2(330, 192), _uppercut())
	_steps(1)
	assert_true(_p1.can_be_hit(), "before it starts")
	for frame in range(1, 6):
		_steps(1)
		assert_false(_p1.can_be_hit(), "frame %d" % frame)
	_steps(1)
	assert_true(_p1.can_be_hit(), "frame 6")


# --- The hits -------------------------------------------------------------------------------------


func test_clean_hit_then_late_hit() -> void:
	await _place(Vector2(200, 192), Vector2(330, 192), _uppercut())
	var u := _numbers()
	_steps(4)
	assert_false(_p1.is_hitbox_active(), "no hitbox during the startup")
	for k in range(1, 5):
		_steps(1)
		assert_eq(_p1.current_move(), u.clean_hit, "rise frame %d: clean" % k)
		assert_true(_p1.is_hitbox_active())
	_steps(1)
	assert_eq(_p1.current_move(), u.late_hit, "rise frame 5: late")
	assert_true(_p1.is_hitbox_active())
	_steps(15)
	assert_true(_p1.is_hitbox_active(), "late hit until the top (rise frame 20)")


func test_the_clean_hit_launches_up() -> void:
	await _place(Vector2(200, 192), Vector2(214, 192), _uppercut())
	_steps(5)  # Rise frame 1.
	assert_eq(_p2.percent, 13.0)
	assert_eq(_p2.state, Fighter.State.HITSTUN)
	assert_lt(_p2.velocity.y, 0.0, "launched up")
	_steps(20)
	assert_eq(_p2.percent, 13.0, "hit once")


# --- Drawings -------------------------------------------------------------------------------------


func test_drawings_follow_the_phases() -> void:
	await _place(Vector2(200, 192), Vector2(330, 192), _uppercut())
	_steps(2)
	assert_eq(_ability().drawing("up_special", 0), 0, "startup: crouched")
	_steps(3)
	assert_eq(_ability().drawing("up_special", 1), 1, "clean: the uppercut")
	_steps(4)
	assert_eq(_ability().drawing("up_special", 1), 2, "late: elbow bent")
