extends GutTest
## Magnus's element specials (docs/specs/characters/magnus.md#magnus--the-avatar). P1 is Magnus,
## P2 Casper (default moves). Scripted [idle, special] starts a special on step 2, so frame N of it
## is step N + 1. Main platform top y 192 (x 96…384).

const MATCH_SCENE := preload("res://match/match.tscn")
const MAGNUS := "slot_14"

var _match: Match
var _p1: Fighter
var _p2: Fighter
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


## [idle, special with `x` / up / down held].
func _special(x := 0.0, up := false, down := false) -> Array[FighterInput]:
	var special := FighterInput.new()
	special.special_pressed = true
	special.special_held = true
	special.move_x = x
	special.up_held = up
	special.down_held = down
	var inputs: Array[FighterInput] = [FighterInput.new(), special]
	return inputs


# --- Data -----------------------------------------------------------------------------------------


func test_magnus_has_his_own_specials_and_default_normals() -> void:
	var defaults := (load("res://fighter/default_stats.tres") as FighterStats).moveset
	var moves := _p1.stats.moveset
	for name in ["neutral_special", "side_special", "up_special", "down_special"]:
		assert_ne(moves.get(name), defaults.get(name), name)
	for name in ["jab", "side_tilt", "up_tilt", "down_tilt", "neutral_air", "down_special_dive"]:
		assert_eq(moves.get(name), defaults.get(name), name)
	assert_true(moves.ability is AvatarData)
	assert_true(moves.neutral_special.ability is WaterGunData)
	assert_true(moves.side_special.ability is FireballData)


func test_up_and_down_special_numbers() -> void:
	var up := _p1.stats.moveset.up_special
	assert_eq([up.startup, up.active, up.launch_speed, up.drift_speed], [4, 12, 440.0, 90.0])
	assert_eq([up.hitbox_center, up.hitbox_size], [Vector2(0, -16), Vector2(56, 40)])
	assert_eq([up.damage, up.base_knockback, up.knockback_growth, up.angle_deg], [4.0, 250.0, 0.6, 40.0])
	assert_eq(up.direction, MoveData.Direction.AWAY)
	var down := _p1.stats.moveset.down_special
	assert_eq([down.startup, down.active, down.recovery], [10, 6, 12])
	assert_eq([down.hitbox_center, down.hitbox_size], [Vector2(0, -10), Vector2(64, 20)])
	assert_eq([down.damage, down.base_knockback, down.knockback_growth, down.angle_deg],
		[11.0, 230.0, 1.5, 80.0])


# --- Water gun ------------------------------------------------------------------------------------


func test_water_gun_has_no_charge_and_shoots_six_droplets() -> void:
	await _place(Vector2(200, 192), Vector2(380, 192), _special())
	_steps(2)
	assert_eq(_p1.move, &"water_gun")
	_steps(6)  # Step 8: frame 7, nothing yet.
	assert_eq(_match.get_entities(Droplet, 0).size(), 0)
	_steps(1)  # Step 9: frame 8, the first droplet.
	assert_eq(_match.get_entities(Droplet, 0).size(), 1)
	_steps(4)  # Step 13: the second.
	assert_eq(_match.get_entities(Droplet, 0).size(), 2)
	_steps(16)  # Step 29: the sixth (frame 28); no more after it.
	assert_eq(_match.get_entities(Droplet, 0).size(), 6)
	_steps(4)
	assert_eq(_match.get_entities(Droplet, 0).size(), 6)


func test_water_gun_droplets_fly_straight_and_expire() -> void:
	await _place(Vector2(200, 192), Vector2(380, 192), _special())
	_steps(9)
	var drop := _match.get_entities(Droplet, 0)[0] as Droplet
	var start := drop.global_position
	assert_eq(start, Vector2(216, 178))
	_steps(10)
	assert_almost_eq(drop.global_position.x, start.x + 50.0, 0.01)
	assert_eq(drop.global_position.y, start.y)
	_steps(18)  # 28 ticks old: gone.
	assert_false(drop in _match.get_entities(Droplet, 0))


func test_water_gun_ends_twelve_frames_after_the_last_droplet() -> void:
	await _place(Vector2(200, 192), Vector2(380, 192), _special())
	_steps(41)  # Last droplet on frame 28; frame 40 (step 41) is the move's last.
	assert_eq(_p1.move, &"water_gun")
	_steps(1)
	assert_ne(_p1.state, Fighter.State.ATTACK)


func test_a_droplet_hits_for_one_and_a_half() -> void:
	await _place(Vector2(200, 192), Vector2(230, 192), _special())
	_steps(10)
	assert_almost_eq(_p2.percent, 1.5, 0.001)


# --- Fireball -------------------------------------------------------------------------------------


func test_fireball_flies_straight_and_hits_for_seven() -> void:
	await _place(Vector2(200, 192), Vector2(300, 192), _special(1.0))
	_steps(11)  # Frame 10: the fireball appears.
	var balls := _match.get_entities(Fireball, 0)
	assert_eq(balls.size(), 1)
	assert_eq(balls[0].global_position, Vector2(216, 178))
	_steps(30)
	assert_eq(_p2.percent, 7.0)
	assert_eq(_match.get_entities(Fireball, 0).size(), 0, "gone on the hit")


func test_only_one_fireball_at_a_time() -> void:
	var inputs := _special(1.0)
	for i in 30:
		inputs.append(FighterInput.new())
	inputs.append_array(_special(1.0))
	await _place(Vector2(150, 192), Vector2(380, 192), inputs)
	_steps(34)
	assert_eq(_match.get_entities(Fireball, 0).size(), 1)
	assert_ne(_p1.state, Fighter.State.ATTACK, "Side+B does nothing while the fireball is out")


# --- Wind burst and earth smash ---------------------------------------------------------------


func test_wind_burst_launches_him_high_and_blows_others_away() -> void:
	await _place(Vector2(200, 192), Vector2(185, 192), _special(0.0, true))
	_steps(6)  # Frame 5: launch and burst.
	assert_almost_eq(_p1.velocity.y, -440.0 + 0.0, 20.0)
	assert_eq(_p2.percent, 4.0)
	assert_lt(_p2.velocity.x, 0.0, "blown away to the left (he was left of Magnus)")


func test_earth_smash_hits_on_both_sides() -> void:
	await _place(Vector2(200, 192), Vector2(172, 192), _special(0.0, false, true))
	_steps(12)  # Frame 11: the burst.
	assert_eq(_p2.percent, 11.0)
	assert_lt(_p2.velocity.x, 0.0)


func test_the_fireball_roars_as_it_appears() -> void:
	await _place(Vector2(200, 192), Vector2(380, 192), _special(1.0))
	var sounds := _p1.get_node("Sounds") as FighterSounds
	var heard: Array[AudioStream] = []
	sounds.played.connect(func(_sound: StringName) -> void: heard.append(sounds.last_stream))
	_steps(15)
	assert_eq(heard.count(load("res://characters/magnus/sounds/fire.wav")), 1)
