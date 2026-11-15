extends GutTest
## Magnus's elements and Avatar State (docs/specs/characters/magnus.md#the-elements-on-his-card,
## #avatar-state). P1 is Magnus, P2 Casper. Main platform top y 192 (x 96…384).

const MATCH_SCENE := preload("res://match/match.tscn")
const MAGNUS := "slot_14"
const RISE := 60
const FLY := 480

var _match: Match
var _p1: Fighter
var _p2: Fighter
var _avatar: AvatarAbility
var _saved_ids: Array[String] = []


func before_each() -> void:
	_saved_ids = [Game.character_id, Game.p2_character_id]
	Game.character_id = MAGNUS
	Game.p2_character_id = "slot_08"
	_match = MATCH_SCENE.instantiate()
	_match.auto_step = false
	add_child_autofree(_match)
	_p1 = _match.get_fighter(0)
	_p2 = _match.get_fighter(1)
	_avatar = _p1.ability(AvatarAbility) as AvatarAbility


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


func _special(x := 0.0, up := false, down := false) -> Array[FighterInput]:
	var special := FighterInput.new()
	special.special_pressed = true
	special.special_held = true
	special.move_x = x
	special.up_held = up
	special.down_held = down
	var inputs: Array[FighterInput] = [FighterInput.new(), special]
	return inputs


## `count` ticks holding the given direction.
func _hold(count: int, x := 0.0, up := false, down := false) -> Array[FighterInput]:
	var inputs: Array[FighterInput] = []
	for i in count:
		var input := FighterInput.new()
		input.move_x = x
		input.up_held = up
		input.down_held = down
		inputs.append(input)
	return inputs


func _shielding(count: int) -> Array[FighterInput]:
	var inputs: Array[FighterInput] = []
	for i in count:
		var input := FighterInput.new()
		input.shield_held = true
		input.shield_pressed = i == 0
		inputs.append(input)
	return inputs


func _light_all() -> void:
	for element in AvatarAbility.Element.values():
		_avatar.light(element)


# --- Lighting -------------------------------------------------------------------------------------


func test_all_dark_at_the_start() -> void:
	assert_eq(_avatar.lit, [false, false, false, false])


func test_each_special_lights_its_element_when_it_lands() -> void:
	await _place(Vector2(200, 192), Vector2(230, 192), _special())
	_steps(12)
	assert_true(_avatar.lit[AvatarAbility.Element.WATER])
	await _place(Vector2(200, 192), Vector2(300, 192), _special(1.0))
	_steps(40)
	assert_true(_avatar.lit[AvatarAbility.Element.FIRE])
	await _place(Vector2(200, 192), Vector2(185, 192), _special(0.0, true))
	_steps(8)
	assert_true(_avatar.lit[AvatarAbility.Element.AIR])
	_avatar.lit[AvatarAbility.Element.FIRE] = false  # (So the Avatar State doesn't start.)
	await _place(Vector2(200, 192), Vector2(172, 192), _special(0.0, false, true))
	_steps(14)
	assert_true(_avatar.lit[AvatarAbility.Element.EARTH])


func test_a_blocked_hit_lights_nothing() -> void:
	await _place(Vector2(200, 192), Vector2(300, 192), _special(1.0), _shielding(60))
	_steps(40)
	assert_eq(_match.get_entities(Fireball, 0).size(), 0, "the shield took it")
	assert_false(_avatar.lit[AvatarAbility.Element.FIRE])
	await _place(Vector2(200, 192), Vector2(185, 192), _special(0.0, true), _shielding(60))
	_steps(10)
	assert_false(_avatar.lit[AvatarAbility.Element.AIR])


func test_normals_light_nothing() -> void:
	var jab := FighterInput.new()
	jab.attack_pressed = true
	var inputs: Array[FighterInput] = [FighterInput.new(), jab]
	await _place(Vector2(200, 192), Vector2(214, 192), inputs)
	_steps(10)
	assert_gt(_p2.percent, 0.0)
	assert_eq(_avatar.lit, [false, false, false, false])


# --- Avatar State ---------------------------------------------------------------------------------


func test_all_four_start_the_rise_frozen_and_unhittable() -> void:
	await _place(Vector2(200, 160), Vector2(330, 192), [])
	_light_all()
	_steps(1)
	assert_eq(_p1.move, &"avatar_rise")
	assert_true(_avatar.in_avatar_state())
	var at := _p1.global_position
	_steps(RISE - 2)
	assert_eq(_p1.move, &"avatar_rise")
	assert_eq(_p1.global_position, at, "frozen in the air: no gravity")
	assert_false(_p1.can_be_hit())
	_steps(2)
	assert_eq(_p1.move, &"avatar_fly")


func test_the_fourth_element_mid_move_waits_until_he_is_free() -> void:
	await _place(Vector2(200, 192), Vector2(380, 192), _special(1.0))
	_steps(5)
	_light_all()
	_steps(1)
	assert_eq(_p1.move, &"side_special", "the fireball throw goes on")
	_steps(20)
	assert_eq(_p1.move, &"avatar_rise")


func test_flight_follows_the_held_direction_without_gravity() -> void:
	var inputs := _hold(RISE + 1)
	inputs.append_array(_hold(30, 1.0))
	inputs.append_array(_hold(30, 0.0, true))
	inputs.append_array(_hold(60))
	await _place(Vector2(200, 120), Vector2(380, 192), inputs)
	_light_all()
	_steps(RISE + 1)
	var start := _p1.global_position
	_steps(30)
	assert_almost_eq(_p1.velocity, Vector2(300, 0), Vector2(0.01, 0.01))
	assert_gt(_p1.global_position.x, start.x + 60.0)
	assert_almost_eq(_p1.global_position.y, start.y, 0.01)
	_steps(30)
	assert_almost_eq(_p1.velocity, Vector2(0, -300), Vector2(0.01, 0.01))
	_steps(60)
	assert_eq(_p1.velocity, Vector2.ZERO, "slows to a stop and hangs there")
	assert_eq(_p1.move, &"avatar_fly")


func test_diagonals_are_as_fast_as_straight_lines() -> void:
	var inputs := _hold(RISE + 1)
	inputs.append_array(_hold(40, -1.0, true))
	await _place(Vector2(250, 150), Vector2(380, 192), inputs)
	_light_all()
	_steps(RISE + 41)
	assert_almost_eq(_p1.velocity.length(), 300.0, 0.01)
	assert_eq(_p1.facing, -1)


func test_he_cannot_fly_out_of_the_blast_zone() -> void:
	var inputs := _hold(RISE + FLY - 1, -1.0, true)
	await _place(Vector2(200, 150), Vector2(380, 192), inputs)
	_light_all()
	_steps(RISE + FLY - 2)
	var zone := _match.get_stage().blast_zone.grow(-24.0)
	assert_eq(_p1.move, &"avatar_fly")
	assert_true(zone.has_point(_p1.global_position))
	assert_ne(_p1.state, Fighter.State.KO)


func test_touching_hurts_again_every_thirty_ticks() -> void:
	await _place(Vector2(200, 192), Vector2(380, 192), [])
	_light_all()
	_steps(RISE + 1)
	assert_eq(_p1.move, &"avatar_fly")
	_p2.spawn_at(_p1.global_position + Vector2(10, 0), -1)
	_p2.invulnerable_frames = 0
	# P2 is kept right next to him; note the steps on which it gets hit.
	var hit_on: Array[int] = []
	for i in 65:
		_p2.global_position = _p1.global_position + Vector2(10, 0)
		_p2.velocity = Vector2.ZERO
		var before := _p2.percent
		_steps(1)
		if _p2.percent > before:
			hit_on.append(i)
	assert_eq(hit_on, [0, 30, 60])
	assert_eq(_p2.percent, 24.0)


func test_after_the_flight_he_falls_with_his_air_options_and_the_elements_go_dark() -> void:
	await _place(Vector2(200, 100), Vector2(380, 192), [])
	_light_all()
	_steps(RISE + FLY + 1)
	assert_eq(_p1.state, Fighter.State.AIR)
	assert_false(_avatar.in_avatar_state())
	assert_eq(_avatar.lit, [false, false, false, false])
	assert_eq(_p1.jumps_left, _p1.stats.max_air_jumps)
	assert_true(_p1.up_special_available)
	assert_true(_p1.air_dodge_available)
	assert_true(_p1.can_be_hit())


func test_the_elements_can_be_lit_again_after_the_avatar_state() -> void:
	await _place(Vector2(200, 100), Vector2(380, 192), [])
	_light_all()
	_steps(RISE + FLY + 1)
	_avatar.light(AvatarAbility.Element.FIRE)
	assert_eq(_avatar.lit, [false, true, false, false])


func test_a_ko_keeps_the_lit_elements_and_a_reset_clears_them() -> void:
	await _place(Vector2(200, 192), Vector2(380, 192), [])
	_avatar.light(AvatarAbility.Element.WATER)
	_avatar.light(AvatarAbility.Element.EARTH)
	_p1.global_position = Vector2(200, 1000)
	_steps(1)
	assert_eq(_p1.state, Fighter.State.KO)
	_steps(Match.RESPAWN_FRAMES + 2)
	assert_ne(_p1.state, Fighter.State.KO)
	assert_eq(_avatar.lit, [true, false, false, true])
	_match.reset()
	assert_eq(_avatar.lit, [false, false, false, false])


func test_his_card_shows_the_element_badge() -> void:
	await _place(Vector2(200, 192), Vector2(380, 192), [])
	var hud := _match.get_node("HUD") as Hud
	var badge := hud.cards[0].get_badge(ElementBadge) as ElementBadge
	assert_not_null(badge)
	assert_null(hud.cards[1].get_badge(ElementBadge))
	_avatar.light(AvatarAbility.Element.AIR)
	hud.cards[0].refresh()
	assert_eq(badge.lit, [false, false, true, false])


func test_the_avatar_state_draws_his_avatar_strip() -> void:
	await _place(Vector2(200, 160), Vector2(380, 192), [])
	var textures := FighterVisuals.textures_for(MAGNUS)
	assert_true(textures.has("avatar"))
	assert_eq(_avatar.strip(textures), [], "not outside the Avatar State")
	_light_all()
	_steps(1)
	assert_eq(_avatar.strip(textures), [textures["avatar"], 1, 2, 0], "the rise drawing")
	_steps(RISE)
	assert_eq(_avatar.strip(textures), [textures["avatar"], 1, 2, 1], "the flight drawing")


func test_the_eye_glow_sits_on_his_glowing_eyes() -> void:
	var numbers := _avatar.data as AvatarData
	var image := (FighterVisuals.textures_for(MAGNUS)["avatar"] as Texture2D).get_image()
	var width := image.get_width() / 2
	for drawing in 2:
		var eyes := numbers.rise_eyes if drawing == 0 else numbers.fly_eyes
		assert_eq(eyes.size(), 2)
		for eye in eyes:
			# Game px from the feet (¾ scale) → the drawing's pixel.
			var px := Vector2i(floori(eye.x / 0.75 + 32.0), floori(eye.y / 0.75 + 64.0))
			var color := image.get_pixel(drawing * width + px.x, px.y)
			assert_gt(color.b, 0.95, "drawing %d eye %s is a glowing pixel" % [drawing, eye])
			assert_gt(color.g, 0.9)


func test_eye_points_follow_the_drawing_facing_and_size() -> void:
	await _place(Vector2(200, 160), Vector2(380, 192), [])
	var numbers := _avatar.data as AvatarData
	assert_eq(_avatar.eye_points(), PackedVector2Array(), "none outside the Avatar State")
	_light_all()
	_steps(1)
	assert_eq(_avatar.eye_points(), numbers.rise_eyes)
	_steps(RISE + 1)
	_p1.facing = -1
	var mirrored := PackedVector2Array()
	for eye in numbers.fly_eyes:
		mirrored.append(Vector2(-eye.x, eye.y))
	assert_eq(_avatar.eye_points(), mirrored)


func test_the_elements_appear_one_by_one_during_the_rise() -> void:
	await _place(Vector2(200, 160), Vector2(380, 192), [])
	_light_all()
	_steps(1)
	assert_gt(_avatar._grown(AvatarAbility.Element.WATER), 0.0, "water first")
	assert_eq(_avatar._grown(AvatarAbility.Element.FIRE), 0.0)
	assert_eq(_avatar._grown(AvatarAbility.Element.EARTH), 0.0)
	_steps(RISE)
	for element: int in AvatarAbility.Element.values():
		assert_eq(_avatar._grown(element), 1.0, "all four in full during the flight")


func test_each_ribbon_is_split_between_behind_and_in_front_of_him() -> void:
	await _place(Vector2(200, 160), Vector2(380, 192), [])
	_light_all()
	_steps(RISE + 10)
	for element: int in [AvatarAbility.Element.WATER, AvatarAbility.Element.FIRE,
			AvatarAbility.Element.AIR]:
		var front := _avatar._trail(element, 1.0, true, 1.0)
		var back := _avatar._trail(element, 1.0, false, 1.0)
		assert_eq(front.size() + back.size(), AvatarAbility.TRAIL_SAMPLES, "every sample once")
		assert_gt(front.size(), 0, "a long ribbon passes in front")
		assert_gt(back.size(), 0, "and behind him")
