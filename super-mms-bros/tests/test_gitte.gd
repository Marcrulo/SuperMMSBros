extends GutTest
## Gitte's scissors and stances (docs/specs/moves.md#gitte--scissors-and-stances). P1 is Gitte;
## scripted [idle, input] starts a move on step 2, so its frame N is step N + 1.

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


func _place(p1_at: Vector2, p2_at: Vector2, p1_inputs: Array[FighterInput],
		stance := Fighter.Stance.PLUS) -> void:
	_p1.spawn_at(p1_at, 1)
	_p2.spawn_at(p2_at, -1)
	_p1.stance = stance
	_match.set_controller(0, ScriptedController.new(p1_inputs))
	_match.set_controller(1, ScriptedController.new([]))
	await wait_physics_frames(1)


func _steps(count: int) -> void:
	for i in count:
		_match.step()


## [idle, the move, `gap` idle ticks] × times. kind: "jab", "cut" (a tap of neutral special),
## "volley", "switch".
func _moves(kind: String, times := 1, gap := 30) -> Array[FighterInput]:
	var inputs: Array[FighterInput] = []
	for i in times:
		var press := FighterInput.new()
		match kind:
			"jab":
				press.attack_pressed = true
			"cut":
				press.special_pressed = true
			"volley":
				press.special_pressed = true
				press.special_held = true
				press.move_x = 1.0
			"switch":
				press.special_pressed = true
				press.special_held = true
				press.down_held = true
		inputs.append(FighterInput.new())
		inputs.append(press)
		for j in gap:
			inputs.append(FighterInput.new())
	return inputs


func _stances() -> StanceData:
	return _p1.stats.moveset.down_special.stances


# --- Data -----------------------------------------------------------------------------------------


func test_gitte_has_her_own_specials() -> void:
	var defaults := (load("res://fighter/default_stats.tres") as FighterStats).moveset
	var moves := _p1.stats.moveset
	for name in ["neutral_special", "side_special", "down_special", "up_special"]:
		assert_ne(moves.get(name), defaults.get(name), name)
	for name in ["jab", "side_tilt", "neutral_air"]:
		assert_eq(moves.get(name), defaults.get(name), name)
	var s := _stances()
	assert_eq([s.projectile_damage, s.lifesteal, s.small_scale, s.small_speed, s.large_scale,
		s.large_special], [1.5, 0.5, 0.75, 1.25, 1.25, 1.3])
	var volley := moves.side_special
	assert_eq([volley.projectile_count, volley.projectile_spread_deg, volley.damage], [3, 12.0, 4.0])
	var cut := moves.neutral_special
	assert_eq([cut.hitbox_center, cut.hitbox_size, cut.charge_frames], [Vector2(26, -16), Vector2(24, 14), 60])


func test_others_have_no_stance_effects() -> void:
	assert_null((load("res://fighter/default_stats.tres") as FighterStats).moveset.down_special.stances)


# --- Switching ------------------------------------------------------------------------------------


func test_down_special_cycles_the_stances() -> void:
	await _place(Vector2(150, 192), Vector2(380, 192), _moves("switch", 4, 20))
	assert_eq(_p1.stance, Fighter.Stance.PLUS, "starts in plus")
	_steps(8)
	assert_eq(_p1.stance, Fighter.Stance.PLUS, "not before frame 8")
	_steps(1)
	assert_eq(_p1.stance, Fighter.Stance.MINUS)
	_steps(22)
	assert_eq(_p1.stance, Fighter.Stance.DIVIDE)
	_steps(22)
	assert_eq(_p1.stance, Fighter.Stance.MULTIPLY)
	_steps(22)
	assert_eq(_p1.stance, Fighter.Stance.PLUS, "back to plus")


func test_stance_switch_is_short() -> void:
	await _place(Vector2(150, 192), Vector2(380, 192), _moves("switch"))
	_steps(16)
	assert_eq(_p1.state, Fighter.State.ATTACK)
	_steps(2)
	assert_ne(_p1.state, Fighter.State.ATTACK, "free after 15 frames")


func test_stance_switch_works_in_the_air() -> void:
	await _place(Vector2(150, 80), Vector2(380, 192), _moves("switch"))
	_steps(9)
	assert_eq(_p1.stance, Fighter.Stance.MINUS)
	assert_ne(_p1.move, &"down_special_dive")


func test_stance_resets_on_spawn() -> void:
	_p1.stance = Fighter.Stance.MULTIPLY
	_p1.spawn_at(Vector2(150, 192), 1)
	assert_eq(_p1.stance, Fighter.Stance.PLUS)


# --- Plus: projectiles ----------------------------------------------------------------------------


func test_volley_throws_three_in_a_fan() -> void:
	await _place(Vector2(150, 192), Vector2(60, 192), _moves("volley"))
	_steps(11)
	var angles: Array[float] = []
	for projectile in _match.get_projectiles():
		angles.append(projectile.angle_deg)
		assert_almost_eq(projectile.global_position, Vector2(166, 178), Vector2(4.1, 0.01))
	angles.sort()
	assert_eq(angles, [-12.0, 0.0, 12.0])


func test_no_new_volley_while_one_is_out() -> void:
	await _place(Vector2(150, 192), Vector2(60, 192), _moves("volley", 2, 10))
	_steps(11 + 12 + 11)
	assert_eq(_match.get_projectiles().size(), 3)


func _volley_damage(stance: Fighter.Stance) -> float:
	# Only the straight one reaches P2 this far away. (A fresh start: no scissors still flying.)
	_match.reset()
	await _place(Vector2(150, 192), Vector2(330, 192), _moves("volley"), stance)
	_steps(60)
	return _p2.percent


func test_plus_projectiles_do_more_damage() -> void:
	assert_eq(await _volley_damage(Fighter.Stance.MINUS), 4.0)
	assert_eq(await _volley_damage(Fighter.Stance.PLUS), 6.0)


# --- Minus: lifesteal -----------------------------------------------------------------------------


func _jab_heal(stance: Fighter.Stance) -> float:
	await _place(Vector2(150, 192), Vector2(165, 192), _moves("jab"), stance)
	_p1.percent = 20.0
	_steps(10)
	assert_eq(_p2.percent, 3.0, "the jab hit")
	return _p1.percent


func test_minus_heals_on_normal_hits() -> void:
	assert_eq(await _jab_heal(Fighter.Stance.MINUS), 18.5)


func test_other_stances_dont_heal() -> void:
	assert_eq(await _jab_heal(Fighter.Stance.PLUS), 20.0)


func test_minus_doesnt_heal_on_specials() -> void:
	await _place(Vector2(150, 192), Vector2(175, 192), _moves("cut"), Fighter.Stance.MINUS)
	_p1.percent = 20.0
	_steps(20)
	assert_gt(_p2.percent, 7.9, "the cut hit")
	assert_eq(_p1.percent, 20.0)


# --- Divide: small and fast -----------------------------------------------------------------------


func test_divide_is_small() -> void:
	await _place(Vector2(150, 192), Vector2(380, 192), [], Fighter.Stance.DIVIDE)
	assert_eq(_p1.size_scale(), 0.75)
	var hurtbox := _p1.get_hurtbox_rect()
	assert_almost_eq(hurtbox.size, Vector2(12, 20.25), Vector2(0.01, 0.01))
	assert_almost_eq(hurtbox.end.y, 192.0, 0.01, "feet stay on the floor")
	assert_almost_eq(_p1.get_center().y, 192.0 - 12.0 * 0.75, 0.01)


func test_divide_scales_move_hitboxes() -> void:
	await _place(Vector2(150, 192), Vector2(380, 192), _moves("jab"), Fighter.Stance.DIVIDE)
	_steps(6)
	var hitbox := _p1.get_hitbox_rect()
	assert_almost_eq(hitbox.size, Vector2(14, 10) * 0.75, Vector2(0.01, 0.01))
	assert_almost_eq(hitbox.get_center(), Vector2(150 + 15 * 0.75, 192 - 13 * 0.75), Vector2(0.01, 0.01))


func test_divide_is_faster() -> void:
	var walk: Array[FighterInput] = []
	for i in 40:
		var input := FighterInput.new()
		input.move_x = 1.0
		walk.append(input)
	await _place(Vector2(120, 192), Vector2(380, 192), walk, Fighter.Stance.DIVIDE)
	_steps(30)
	assert_almost_eq(_p1.velocity.x, _p1.stats.run_speed * 1.25, 0.01)


# --- Multiply: large, strong specials -------------------------------------------------------------


func test_multiply_is_large() -> void:
	await _place(Vector2(150, 192), Vector2(380, 192), [], Fighter.Stance.MULTIPLY)
	assert_eq(_p1.size_scale(), 1.25)
	assert_almost_eq(_p1.get_hurtbox_rect().size, Vector2(20, 33.75), Vector2(0.01, 0.01))


func _cut_damage(stance: Fighter.Stance) -> float:
	await _place(Vector2(150, 192), Vector2(178, 192), _moves("cut"), stance)
	_steps(20)
	return _p2.percent


func test_multiply_specials_hit_harder() -> void:
	var normal: float = await _cut_damage(Fighter.Stance.PLUS)
	var strong: float = await _cut_damage(Fighter.Stance.MULTIPLY)
	assert_gt(normal, 7.9)
	assert_almost_eq(strong, normal * 1.3, 0.01)


func test_multiply_normals_are_not_boosted() -> void:
	await _place(Vector2(150, 192), Vector2(168, 192), _moves("jab"), Fighter.Stance.MULTIPLY)
	_steps(10)
	assert_eq(_p2.percent, 3.0)


# --- Player card ----------------------------------------------------------------------------------


func test_card_shows_her_stance() -> void:
	var hud := _match.get_node("HUD") as Hud
	assert_true(hud.cards[0].has_stance_badge(), "Gitte's card has the badge")
	assert_false(hud.cards[1].has_stance_badge(), "Kim's doesn't")
	_p1.stance = Fighter.Stance.DIVIDE
	hud.cards[0].refresh()
	assert_eq(hud.cards[0].get_shown_stance(), Fighter.Stance.DIVIDE)


# --- Art ------------------------------------------------------------------------------------------


func test_volley_picture() -> void:
	assert_eq((load("res://assets/fighters/slot_02/projectile.png") as Texture2D).get_size(),
		Vector2(48, 16))
