extends GutTest
## Fight sounds (docs/specs/sound.md): which sounds a tick's change in a fighter makes, the hit
## weights, and that playing them never changes the match.

const MATCH_SCENE := preload("res://match/match.tscn")
const S := Fighter.State


## A fighter snapshot as FighterSounds.snapshot() makes it, with only what a test sets changed.
func _snap(changes: Dictionary = {}) -> Dictionary:
	var snap := {
		"state": S.IDLE, "state_frame": 5, "move": Fighter.NO_MOVE, "jumps_left": 1,
		"velocity": Vector2.ZERO, "on_floor": true, "hitbox_active": false, "projectile_out": false,
	}
	snap.merge(changes, true)
	return snap


func _events(before: Dictionary, after: Dictionary) -> Array[StringName]:
	return FighterSounds.events(_snap(before), _snap(after))


func test_nothing_happens_nothing_plays() -> void:
	assert_eq(_events({}, {"state_frame": 6}), [] as Array[StringName])


func test_every_normal_swings() -> void:
	for move: StringName in [&"jab", &"down_tilt", &"up_tilt", &"side_tilt", &"neutral_air",
			&"forward_air", &"back_air", &"up_air", &"down_air"]:
		assert_has(_events({}, {"state": S.ATTACK, "state_frame": 1, "move": move}), &"swing", move)


func test_the_same_move_again_swings_again() -> void:
	var events := _events({"state": S.ATTACK, "state_frame": 14, "move": &"jab"},
			{"state": S.ATTACK, "state_frame": 1, "move": &"jab"})
	assert_has(events, &"swing")


func test_specials() -> void:
	assert_has(_events({"state": S.ATTACK, "move": &"neutral_special_charge"},
			{"state": S.ATTACK, "state_frame": 1, "move": &"neutral_special"}), &"swing_heavy")
	assert_has(_events({"state": S.AIR, "on_floor": false},
			{"state": S.ATTACK, "state_frame": 1, "move": &"down_special_dive", "on_floor": false}),
			&"dive")
	assert_has(_events({"state": S.ATTACK, "move": &"side_special", "state_frame": 9},
			{"state": S.ATTACK, "move": &"side_special", "state_frame": 10, "projectile_out": true}),
			&"zap")


func test_burst_on_its_first_active_frame() -> void:
	var before := {"state": S.ATTACK, "move": &"down_special", "state_frame": 10}
	var after := {"state": S.ATTACK, "move": &"down_special", "state_frame": 11, "hitbox_active": true}
	assert_has(_events(before, after), &"burst")
	before.hitbox_active = true
	after.state_frame = 12
	assert_does_not_have(_events(before, after), &"burst", "only once")


func test_boost_when_the_up_special_launches() -> void:
	var before := {"state": S.ATTACK, "move": &"up_special", "state_frame": 4}
	var after := {"state": S.ATTACK, "move": &"up_special", "state_frame": 5,
			"velocity": Vector2(0, -360), "on_floor": false}
	assert_has(_events(before, after), &"boost")


func test_pyramid_rumbles_when_it_starts_rising() -> void:
	var before := {"state": S.ATTACK, "move": &"up_special", "state_frame": 4}
	var after := {"state": S.ATTACK, "move": &"pyramid_rise", "state_frame": 1,
			"velocity": Vector2(0, -320), "on_floor": false, "sounds": PyramidAbility.new().sounds()}
	assert_has(_events(before, after), &"burst")
	var riding := {"state": S.ATTACK, "move": &"pyramid_rise", "state_frame": 2,
			"velocity": Vector2(0, -320), "on_floor": false, "sounds": PyramidAbility.new().sounds()}
	assert_does_not_have(_events(after, riding), &"burst", "only once")


func test_boost_when_she_pops_off_the_pyramid() -> void:
	var before := {"state": S.ATTACK, "move": &"pyramid_rise", "state_frame": 18,
			"velocity": Vector2(0, -320), "on_floor": false}
	var after := {"state": S.ATTACK, "move": &"up_special", "state_frame": 19,
			"velocity": Vector2(0, -170), "on_floor": false, "sounds": PyramidAbility.new().sounds()}
	assert_has(_events(before, after), &"boost")


func _loop(snap: Dictionary) -> StringName:
	return FighterSounds.loop_sound(_snap(snap))


func test_the_charge_loops_while_charging() -> void:
	assert_eq(_loop({"state": S.ATTACK, "move": &"neutral_special_charge"}), &"charge")
	assert_eq(_loop({"state": S.ATTACK, "move": &"neutral_special"}), &"", "the punch")
	assert_eq(_loop({"state": S.HITSTUN, "move": Fighter.NO_MOVE}), &"", "hit out of it")
	assert_does_not_have(_events({}, {"state": S.ATTACK, "state_frame": 1,
			"move": &"neutral_special_charge"}), &"charge", "a loop, not a one-shot")


func test_an_abilitys_phase_can_loop() -> void:
	var sounds := {"loop": {&"glide": &"wind"}, "start": {&"rise": &"charge"}}
	assert_eq(_loop({"state": S.ATTACK, "move": &"glide", "sounds": sounds}), &"wind")
	assert_eq(_loop({"state": S.ATTACK, "move": &"rise", "sounds": sounds}), &"charge",
			"a phase starting with the charge sound loops it")
	assert_eq(_loop({"state": S.AIR, "move": Fighter.NO_MOVE, "sounds": sounds}), &"",
			"stops when the phase ends")
	assert_does_not_have(_events({}, {"state": S.ATTACK, "state_frame": 1, "move": &"rise",
			"sounds": sounds}), &"charge")


func _move(sounds: Dictionary = {}, active: AudioStream = null, hit: AudioStream = null) -> MoveData:
	var data := MoveData.new()
	data.sounds.assign(sounds)
	data.active_sound = active
	data.hit_sound = hit
	return data


func test_a_moves_active_sound_on_its_first_active_frame() -> void:
	var data := _move({}, AudioStreamWAV.new())
	var before := {"state": S.ATTACK, "move": &"side_tilt", "state_frame": 11, "move_data": data}
	var after := {"state": S.ATTACK, "move": &"side_tilt", "state_frame": 12, "hitbox_active": true,
			"move_data": data}
	assert_has(_events(before, after), FighterSounds.ACTIVE_SOUND)
	before.hitbox_active = true
	after.state_frame = 13
	assert_does_not_have(_events(before, after), FighterSounds.ACTIVE_SOUND, "only once")
	after.move_data = _move()
	before.hitbox_active = false
	assert_does_not_have(_events(before, after), FighterSounds.ACTIVE_SOUND, "none set")


func test_streams_come_from_the_move_then_the_abilities_then_the_set() -> void:
	var set_ := FightSounds.new()
	var default_zap := AudioStreamWAV.new()
	var own_zap := AudioStreamWAV.new()
	var ability_zap := AudioStreamWAV.new()
	var scream := AudioStreamWAV.new()
	set_.streams[&"zap"] = default_zap
	var abilities := {"streams": {&"zap": ability_zap, &"scream": scream}}
	assert_eq(FighterSounds.stream_for(&"zap", null, {}, set_), default_zap)
	assert_eq(FighterSounds.stream_for(&"zap", null, abilities, set_), ability_zap)
	assert_eq(FighterSounds.stream_for(&"scream", null, abilities, set_), scream)
	assert_eq(FighterSounds.stream_for(&"zap", _move({&"zap": own_zap}), abilities, set_), own_zap)
	assert_eq(FighterSounds.stream_for(&"zap", _move({&"burst": own_zap}), {}, set_), default_zap)
	assert_null(FighterSounds.stream_for(&"nothing", null, abilities, set_))


func test_ability_sounds_merge_streams_and_loops() -> void:
	var merged := FighterSounds.ability_sounds(autofree(Fighter.new()))
	assert_eq(merged.get("streams"), {})
	assert_eq(merged.get("loop"), {})


func test_footsteps_on_the_foot_plants() -> void:
	var steps := {}
	for frame in range(1, 61):
		for event in _events({"state": S.RUN, "state_frame": frame - 1},
				{"state": S.RUN, "state_frame": frame}):
			steps[frame] = event
	assert_eq(steps, {1: &"step_1", 16: &"step_2", 31: &"step_1", 46: &"step_2"})


func test_faster_footsteps_while_dashing_and_sprinting() -> void:
	for state: Fighter.State in [S.DASH, S.SPRINT]:
		var steps := {}
		for frame in range(1, 37):
			for event in _events({"state": state, "state_frame": frame - 1},
					{"state": state, "state_frame": frame}):
				steps[frame] = event
		assert_eq(steps, {1: &"step_1", 10: &"step_2", 19: &"step_1", 28: &"step_2"})


func test_jump_and_double_jump() -> void:
	assert_has(_events({"state": S.IDLE},
			{"state": S.AIR, "state_frame": 1, "velocity": Vector2(0, -240), "on_floor": false}),
			&"jump")
	assert_has(_events({"state": S.AIR, "on_floor": false, "jumps_left": 1},
			{"state": S.AIR, "on_floor": false, "jumps_left": 0, "velocity": Vector2(0, -219)}),
			&"double_jump")


func test_a_launch_is_not_a_jump() -> void:
	var events := _events({"state": S.IDLE},
			{"state": S.HITSTUN, "state_frame": 1, "velocity": Vector2(100, -300), "on_floor": false})
	assert_does_not_have(events, &"jump")


func test_landing() -> void:
	assert_has(_events({"state": S.AIR, "on_floor": false}, {"state": S.IDLE, "state_frame": 1}),
			&"land")
	assert_does_not_have(_events({"state": S.KO, "on_floor": false}, {"state": S.IDLE}), &"land",
			"a respawn isn't a landing")


func test_states_with_a_sound_on_entering() -> void:
	assert_has(_events({}, {"state": S.SHIELD, "state_frame": 1}), &"shield_on")
	assert_has(_events({"state": S.SHIELD}, {"state": S.SHIELD_BREAK, "state_frame": 1}),
			&"shield_break")
	for state: Fighter.State in [S.SPOT_DODGE, S.ROLL, S.AIR_DODGE]:
		assert_has(_events({}, {"state": state, "state_frame": 1}), &"dodge", str(state))
	assert_has(_events({"state": S.AIR, "on_floor": false},
			{"state": S.LEDGE, "state_frame": 1, "on_floor": false}), &"ledge_grab")
	assert_does_not_have(_events({"state": S.SHIELD}, {"state": S.SHIELD, "state_frame": 6}),
			&"shield_on", "only on entering")


func test_hit_sound_thresholds() -> void:
	var sounds := FightSounds.new()
	assert_eq(sounds.hit_sound(0.0), &"hit_light")
	assert_eq(sounds.hit_sound(199.0), &"hit_light")
	assert_eq(sounds.hit_sound(200.0), &"hit_medium")
	assert_eq(sounds.hit_sound(399.0), &"hit_medium")
	assert_eq(sounds.hit_sound(400.0), &"hit_heavy")


func test_every_sound_has_a_stream_in_the_default_set() -> void:
	var sounds := load(FightSounds.DEFAULT_PATH) as FightSounds
	for sound_name in FightSounds.NAMES:
		assert_not_null(sounds.streams.get(sound_name), sound_name)


# --- In a match ---------------------------------------------------------------------------------

var _match: Match


## P1 plays a character with the default move set (Pia, the default P1, has her own specials).
const DEFAULT_MOVES_ID := "slot_08"

var _saved_character_id: String = ""

func before_each() -> void:
	_saved_character_id = Game.character_id
	Game.character_id = DEFAULT_MOVES_ID


func after_each() -> void:
	Game.character_id = _saved_character_id


func _start_match() -> void:
	_match = MATCH_SCENE.instantiate()
	_match.auto_step = false
	add_child_autofree(_match)
	await wait_physics_frames(1)


func _sounds(player_index: int) -> FighterSounds:
	return _match.get_fighter(player_index).get_node("Sounds") as FighterSounds


func test_events_follow_every_tick() -> void:
	await _start_match()
	var run := FighterInput.new()
	run.move_x = 1.0
	var inputs: Array[FighterInput] = []
	for i in 40:
		inputs.append(run)
	_match.set_controller(0, ScriptedController.new(inputs))
	var played: Array[StringName] = []
	_sounds(0).played.connect(func(sound: StringName) -> void: played.append(sound))
	for i in 40:
		_match.step()
	assert_eq(played.count(&"step_1") + played.count(&"step_2"), 3,
			"foot plants on running ticks 1, 16 and 31, all stepped in one frame")


func test_hits_play_for_the_victim() -> void:
	await _start_match()
	var played: Array[StringName] = []
	_sounds(1).played.connect(func(sound: StringName) -> void: played.append(sound))
	_match.get_fighter(1).velocity = Vector2(250, 0)
	_match.fighter_hit.emit(1)
	assert_eq(played, [&"hit_medium"] as Array[StringName])


func test_a_moves_hit_sound_plays_for_the_victim() -> void:
	await _start_match()
	var sounds := _sounds(1)
	var pipe := AudioStreamWAV.new()
	_match.hit_landed.emit(1, _move({}, null, pipe))
	_match.fighter_hit.emit(1)
	assert_eq(sounds.last_played, FighterSounds.MOVE_HIT)
	assert_eq(sounds.last_stream, pipe)
	_match.get_fighter(1).velocity = Vector2(250, 0)
	_match.hit_landed.emit(1, _move())
	_match.fighter_hit.emit(1)
	assert_eq(sounds.last_played, &"hit_medium", "no hit sound of its own: by strength")
	_match.fighter_hit.emit(1)
	assert_eq(sounds.last_played, &"hit_medium", "a hit without hit_landed (an ability's own)")


func test_charge_stops_when_hit() -> void:
	await _start_match()
	var sounds := _sounds(0)
	var hold := FighterInput.new()
	hold.special_pressed = true
	hold.special_held = true
	var keep := FighterInput.new()
	keep.special_held = true
	_match.set_controller(0, ScriptedController.new([hold, keep, keep, keep] as Array[FighterInput]))
	for i in 3:
		_match.step()
	assert_true(sounds.is_charging(), "charging")
	_match.get_fighter(0).take_hit(_match.get_fighter(0).stats.moveset.jab, 1, 0.0)
	_match.step()
	assert_false(sounds.is_charging(), "the hit ended the charge")


func test_sounds_do_not_change_the_match() -> void:
	var positions := []
	for with_sounds in [true, false]:
		await _start_match()
		if not with_sounds:
			for i in 2:
				_sounds(i).free()
		var inputs: Array[FighterInput] = []
		for i in 90:
			var input := FighterInput.new()
			input.move_x = 1.0 if i < 30 else 0.0
			input.jump_pressed = i == 35
			input.attack_pressed = i == 50 or i == 70
			inputs.append(input)
		_match.set_controller(0, ScriptedController.new(inputs))
		for i in 90:
			_match.step()
		positions.append([_match.get_fighter(0).position, _match.get_fighter(1).percent])
		_match.free()
	assert_eq(positions[0], positions[1])


func test_missing_sound_is_silent() -> void:
	await _start_match()
	var sounds := _sounds(0)
	var saved: AudioStream = sounds.sound_set.streams[&"jump"]
	sounds.sound_set.streams.erase(&"jump")
	sounds.play(&"jump")
	assert_eq(sounds.last_played, &"jump")
	sounds.sound_set.streams[&"jump"] = saved


func test_sounds_use_the_sfx_bus() -> void:
	await _start_match()
	for player in _sounds(0).find_children("*", "AudioStreamPlayer2D", false, false):
		assert_eq((player as AudioStreamPlayer2D).bus, &"SFX")


func test_every_character_sound_is_credited() -> void:
	var characters := DirAccess.open("res://characters")
	var files := 0
	for character in characters.get_directories():
		var folder := "res://characters/%s/sounds" % character
		if not DirAccess.dir_exists_absolute(folder):
			continue
		var credits := FileAccess.get_file_as_string(folder + "/CREDITS.txt")
		for file in DirAccess.get_files_at(folder):
			if file.ends_with(".wav"):
				files += 1
				assert_string_contains(credits, file, "%s/%s" % [character, file])
	if files == 0:
		pass_test("no character sounds yet")
