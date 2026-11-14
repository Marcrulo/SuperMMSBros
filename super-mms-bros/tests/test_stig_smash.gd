extends GutTest
## Stig's down special, the cross smash (docs/specs/moves.md#down-special--cross-smash): a burst of
## light in front that launches nearly sideways. P1 is Stig; scripted [idle, down special] starts it
## on step 2, so frame N of it is step N + 1 (the hitbox is out on frames 11–16 = steps 12–17).
## Main platform top y 192 (x 96…384).

const MATCH_SCENE := preload("res://match/match.tscn")
const STIG := "slot_07"

var _match: Match
var _p1: Fighter
var _p2: Fighter
var _saved_ids: Array[String] = []


func before_each() -> void:
	_saved_ids = [Game.character_id, Game.p2_character_id]
	Game.character_id = STIG
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


## [idle, down special].
func _smash() -> Array[FighterInput]:
	var special := FighterInput.new()
	special.special_pressed = true
	special.special_held = true
	special.down_held = true
	return [FighterInput.new(), special]


func _shield(ticks: int) -> Array[FighterInput]:
	var inputs: Array[FighterInput] = []
	for i in ticks:
		var shield := FighterInput.new()
		shield.shield_held = true
		inputs.append(shield)
	return inputs


# --- Data -----------------------------------------------------------------------------------------


func test_the_cross_smash_matches_the_spec() -> void:
	var smash := _p1.stats.moveset.down_special
	var default := (load("res://fighter/default_stats.tres") as FighterStats).moveset.down_special
	assert_eq([smash.startup, smash.active, smash.recovery],
		[default.startup, default.active, default.recovery], "the default frames (animation timing)")
	assert_eq([smash.hitbox_center, smash.hitbox_size], [Vector2(36, -10), Vector2(56, 20)])
	assert_eq([smash.damage, smash.base_knockback, smash.knockback_growth, smash.angle_deg],
		[9.0, 180.0, 1.4, 10.0])
	assert_eq(smash.direction, MoveData.Direction.FACING)
	assert_eq(smash.dive_speed, 360.0)


func test_his_dive_has_no_hitbox() -> void:
	var dive := _p1.stats.moveset.down_special_dive
	for frame in range(1, 600):
		assert_false(dive.is_active_frame(frame), "frame %d" % frame)


# --- The hit --------------------------------------------------------------------------------------


func test_the_smash_launches_nearly_sideways() -> void:
	watch_signals(_match)
	await _place(Vector2(200, 192), Vector2(240, 192), _smash())
	_steps(11)
	assert_eq(_p2.percent, 0.0, "not yet")
	_steps(1)
	assert_eq(_p2.state, Fighter.State.HITSTUN)
	assert_eq(_p2.percent, 9.0)
	assert_gt(_p2.velocity.x, 0.0, "away from Stig")
	var angle := rad_to_deg(atan2(-_p2.velocity.y, _p2.velocity.x))
	assert_almost_eq(angle, 10.0, 0.5, "10° above horizontal")
	assert_signal_emitted(_match, "fighter_hit")


func test_the_smash_misses_behind_him() -> void:
	await _place(Vector2(200, 192), Vector2(170, 192), _smash())
	_steps(30)
	assert_eq(_p2.percent, 0.0)


func test_a_shield_blocks_the_smash() -> void:
	await _place(Vector2(200, 192), Vector2(240, 192), _smash(), _shield(40))
	_steps(16)
	assert_eq(_p2.state, Fighter.State.SHIELD)
	assert_eq(_p2.percent, 0.0)


func test_in_the_air_he_drops_then_smashes_on_landing() -> void:
	# x 110: clear of the left platform (x 132…204), so he lands on the main platform.
	await _place(Vector2(110, 100), Vector2(150, 192), _smash())
	_steps(2)
	assert_eq(_p1.move, &"down_special_dive")
	assert_false(_p1.is_hitbox_active(), "no hitbox on the way down")
	var landed := false
	for i in 60:
		_match.step()
		if _p1.move == &"down_special":
			landed = true
			break
	assert_true(landed, "landed into the smash")
	assert_eq(_p2.percent, 0.0, "nothing hit on the way")
	_steps(12)
	assert_eq(_p2.percent, 9.0, "the smash hit on landing")


# --- Visuals --------------------------------------------------------------------------------------


## The light: drawn from the move's first active frame, 3 ticks per drawing, 4 drawings.
func test_the_light_burst_timing() -> void:
	var smash := _p1.stats.moveset.down_special
	assert_eq(FighterVisuals.burst_frame(smash, smash.startup), -1, "not before the smash")
	assert_eq(FighterVisuals.burst_frame(smash, smash.startup + 1), 0)
	assert_eq(FighterVisuals.burst_frame(smash, smash.startup + 4), 1)
	assert_eq(FighterVisuals.burst_frame(smash, smash.startup + 12), 3)
	assert_eq(FighterVisuals.burst_frame(smash, smash.startup + 13), -1, "gone")


func test_stig_has_a_light_burst_picture() -> void:
	var textures := FighterVisuals.textures_for(STIG)
	assert_true(textures.has("burst"), "burst.png")
	assert_eq((textures["burst"] as Texture2D).get_size(), Vector2(80 * 4, 28))
	assert_false(FighterVisuals.textures_for("slot_09").has("burst"), "only Stig")


## The light is drawn mid-smash (runs FighterVisuals._draw with the burst, facing either way).
func test_the_light_is_drawn_mid_smash() -> void:
	await _place(Vector2(200, 192), Vector2(300, 192), _smash())
	_steps(13)
	assert_gt(FighterVisuals.burst_frame(_p1.current_move(), _p1.state_frame), -1)
	await wait_frames(2)
	_p1.facing = -1
	await wait_frames(2)
	assert_eq(_p1.move, &"down_special")
