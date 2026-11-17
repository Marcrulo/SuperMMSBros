extends GutTest
## Henrik's speaker jam down special (docs/specs/characters/henrik.md#henrik--guitar). P1 is Henrik;
## scripted [idle, down special] starts it on step 2, so its frame 12 (the jam starts, the speakers
## appear) is step 13; the speakers' age is then (step - 13), the beats are on ages 6, 24, 42, 60
## (steps 19, 37, 55, 73), each blast out for 4 ticks. Main platform top y 192 (x 96…384).

const MATCH_SCENE := preload("res://match/match.tscn")
const HENRIK := "slot_06"
const FEET := Vector2(240, 192)

var _match: Match
var _p1: Fighter
var _p2: Fighter
var _saved_ids: Array[String] = []


func before_each() -> void:
	_saved_ids = [Game.character_id, Game.p2_character_id]
	Game.character_id = HENRIK
	Game.p2_character_id = "slot_09"
	_match = MATCH_SCENE.instantiate()
	_match.auto_step = false
	add_child_autofree(_match)
	_p1 = _match.get_fighter(0)
	_p2 = _match.get_fighter(1)


func after_each() -> void:
	Game.character_id = _saved_ids[0]
	Game.p2_character_id = _saved_ids[1]


func _place(p1_at: Vector2 = FEET, p2_at := Vector2(370, 192)) -> void:
	_p1.spawn_at(p1_at, 1)
	_p2.spawn_at(p2_at, -1)
	var press := FighterInput.new()
	press.special_pressed = true
	press.special_held = true
	press.down_held = true
	var inputs: Array[FighterInput] = [FighterInput.new(), press]
	_match.set_controller(0, ScriptedController.new(inputs))
	_match.set_controller(1, ScriptedController.new([]))
	await wait_physics_frames(1)


func _steps(count: int) -> void:
	for i in count:
		_match.step()


func _data() -> SpeakerData:
	return _p1.stats.moveset.down_special.ability as SpeakerData


func _speakers() -> Array[MatchEntity]:
	return _match.get_entities(Speaker, 0)


func _ability() -> SpeakerAbility:
	return _p1.ability(SpeakerAbility) as SpeakerAbility


## Puts P2 back at `at`, standing and unhurt-looking (keeps its %), for checking repeat hits.
func _put_p2(at: Vector2) -> void:
	var percent := _p2.percent
	_p2.spawn_at(at, -1)
	_p2.percent = percent


# --- Data -----------------------------------------------------------------------------------------


func test_speaker_data() -> void:
	var down := _p1.stats.moveset.down_special
	assert_true(down.ability is SpeakerData)
	assert_eq([down.startup, down.active, down.recovery, down.dive_speed], [12, 0, 1, 360.0])
	var d := _data()
	assert_eq([d.offset, d.jam_frames, d.end_frames, d.first_beat, d.beat_every, d.blast_frames,
		d.sink_frames], [26.0, 72, 12, 6, 18, 4, 8])
	var b := d.blast
	assert_eq([b.hitbox_center, b.hitbox_size, b.damage, b.base_knockback, b.knockback_growth,
		b.angle_deg], [Vector2(20, -12), Vector2(52, 24), 3.0, 260.0, 0.6, 15.0])


func test_beats() -> void:
	var d := _data()
	var beats: Array[int] = []
	for age in d.jam_frames + 20:
		if d.is_beat(age):
			beats.append(age)
	assert_eq(beats, [6, 24, 42, 60])
	assert_true(d.is_blasting(9))
	assert_false(d.is_blasting(10))
	assert_false(d.is_blasting(5))


func test_others_have_no_speakers() -> void:
	assert_null((load("res://fighter/default_stats.tres") as FighterStats).moveset.down_special.ability)


# --- The jam --------------------------------------------------------------------------------------


func test_speakers_appear_on_frame_12() -> void:
	await _place()
	_steps(12)
	assert_eq(_p1.move, &"down_special", "still the startup")
	assert_eq(_speakers().size(), 0)
	_steps(1)
	assert_eq(_p1.move, &"speaker_jam")
	var speakers := _speakers()
	assert_eq(speakers.size(), 2)
	var at: Array[Vector2] = []
	var sides: Array[int] = []
	for s in speakers:
		at.append(s.global_position)
		sides.append((s as Speaker).side)
	assert_has(at, Vector2(240 - 26, 192))
	assert_has(at, Vector2(240 + 26, 192))
	for s in speakers:
		assert_eq((s as Speaker).side, 1 if s.global_position.x > 240.0 else -1, "facing away")


func test_he_plays_for_the_whole_jam() -> void:
	await _place()
	_steps(13)
	var x := _p1.global_position.x
	_steps(80)
	assert_eq(_p1.state, Fighter.State.ATTACK)
	assert_eq(_p1.move, &"speaker_jam")
	assert_almost_eq(_p1.global_position.x, x, 0.5, "stands still")
	_steps(10)
	assert_ne(_p1.state, Fighter.State.ATTACK, "free after 72 + 12 ticks")


func test_blast_launches_away_to_the_right() -> void:
	await _place(FEET, Vector2(262, 192))
	_steps(18)
	assert_eq(_p2.percent, 0.0, "no blast before the first beat")
	_steps(1)
	assert_eq(_p2.percent, 3.0)
	assert_eq(_p2.state, Fighter.State.HITSTUN)
	assert_gt(_p2.velocity.x, 0.0, "away from Henrik")
	assert_lt(_p2.velocity.y, 0.0, "a little up")


func test_blast_launches_away_to_the_left() -> void:
	await _place(FEET, Vector2(218, 192))
	_steps(19)
	assert_eq(_p2.percent, 3.0)
	assert_lt(_p2.velocity.x, 0.0, "away from Henrik")


func test_out_of_reach_is_safe() -> void:
	await _place(FEET, Vector2(330, 192))
	_steps(30)
	assert_eq(_p2.percent, 0.0)


func test_each_blast_hits_once_then_the_next_beat_again() -> void:
	await _place(FEET, Vector2(262, 192))
	_steps(19)
	assert_eq(_p2.percent, 3.0)
	for i in 3:
		_put_p2(Vector2(262, 192))
		_steps(1)
	assert_eq(_p2.percent, 3.0, "once per blast")
	for i in 15:
		_put_p2(Vector2(262, 192))
		_steps(1)
	assert_eq(_p2.percent, 6.0, "the second beat (step 37)")


func test_shield_blocks_a_blast() -> void:
	await _place(FEET, Vector2(262, 192))
	var shield := FighterInput.new()
	shield.shield_held = true
	var holds: Array[FighterInput] = []
	for i in 40:
		holds.append(shield)
	_match.set_controller(1, ScriptedController.new(holds))
	_steps(19)
	assert_eq(_p2.percent, 0.0)
	assert_eq(_p2.state, Fighter.State.SHIELD)


func test_hit_ends_the_jam_and_the_speakers_sink() -> void:
	await _place()
	_steps(15)
	var punch := _p1.stats.moveset.jab
	_p1.take_hit(punch, -1, 300.0)
	_steps(1)
	assert_ne(_p1.move, &"speaker_jam")
	for s in _speakers():
		assert_true((s as Speaker).sinking)
	_steps(8)
	assert_eq(_speakers().size(), 0, "sunk")


func test_speakers_sink_after_the_jam() -> void:
	await _place()
	_steps(13 + 72)
	assert_eq(_speakers().size(), 2)
	for s in _speakers():
		assert_true((s as Speaker).sinking)
		assert_false((s as Speaker).is_blasting())
	_steps(8)
	assert_eq(_speakers().size(), 0)


func test_no_blasts_after_the_jam() -> void:
	await _place()
	_steps(13 + 70)
	_put_p2(Vector2(262, 192))
	var percent := _p2.percent
	_steps(10)
	assert_eq(_p2.percent, percent)


func test_reset_removes_the_speakers() -> void:
	await _place()
	_steps(14)
	_match.reset()
	assert_eq(_speakers().size(), 0)


func test_speakers_go_with_him_on_a_ko() -> void:
	await _place()
	_steps(14)
	assert_true(_speakers()[0].removed_with_owner())


func test_air_down_special_is_still_the_dive_and_lands_into_the_jam() -> void:
	await _place(Vector2(240, 140))
	_steps(2)
	assert_eq(_p1.move, &"down_special_dive")
	for i in 30:
		_match.step()
		if _p1.move == &"down_special":
			break
	assert_eq(_p1.move, &"down_special", "landed")
	for i in 14:
		_match.step()
		if _p1.move == &"speaker_jam":
			break
	assert_eq(_p1.move, &"speaker_jam")
	assert_eq(_speakers().size(), 2)


func test_each_beat_makes_a_sound() -> void:
	await _place()
	watch_signals(_match)
	_steps(19)
	assert_signal_emit_count(_match, "owner_sound", 1, "one per beat, not per speaker")
	assert_signal_emitted_with_parameters(_match, "owner_sound", [0, &"burst"])


# --- Drawing --------------------------------------------------------------------------------------


func test_playing_drawings() -> void:
	await _place()
	_steps(5)
	assert_eq(_ability().drawing("down_special", 2), 0, "startup: swung round")
	_steps(9)  # Jam tick 1.
	assert_eq(_ability().drawing("down_special", 0), 1, "strumming, high")
	_steps(4)  # Jam tick 5.
	assert_eq(_ability().drawing("down_special", 0), 2, "strumming, low")
	_steps(1)  # Jam tick 6: the first beat.
	assert_eq(_ability().drawing("down_special", 0), 3, "the beat")
	_steps(4)  # Jam tick 10: the blast is over.
	assert_ne(_ability().drawing("down_special", 0), 3)
	_steps(62)  # Jam tick 72.
	assert_eq(_ability().drawing("down_special", 0), 4, "lowering it")
	assert_eq(_ability().phase_animation(&"speaker_jam"), "down_special")


func test_drawing_leaves_other_moves_alone() -> void:
	await _place()
	assert_eq(_ability().drawing("jab", 3), 3)


func test_he_strums_once_as_the_jam_starts() -> void:
	await _place()
	var sounds := _p1.get_node("Sounds") as FighterSounds
	var strums: Array[StringName] = []
	var strum := load("res://characters/henrik/sounds/strum.wav")
	sounds.played.connect(func(_sound: StringName) -> void:
		if sounds.last_stream == strum:
			strums.append(_p1.move))
	_steps(90)
	assert_eq(strums, [SpeakerAbility.JAM] as Array[StringName], "once, as the jam starts")
