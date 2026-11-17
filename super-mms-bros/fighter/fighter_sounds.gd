class_name FighterSounds
extends Node2D
## Plays the parent Fighter's fight sounds (docs/specs/sound.md). Presentation only: it listens to
## the Match and compares the fighter's state with the previous tick's, and never changes either.

## A sound started (for tests; also fires when its file is missing).
signal played(sound: StringName)

const NORMALS: Array[StringName] = [
	&"jab", &"down_tilt", &"up_tilt", &"side_tilt", &"neutral_air", &"forward_air", &"back_air",
	&"up_air", &"down_air",
]
const DODGES: Array[Fighter.State] = [
	Fighter.State.SPOT_DODGE, Fighter.State.ROLL, Fighter.State.AIR_DODGE,
]
const GROUNDED: Array[Fighter.State] = [
	Fighter.State.IDLE, Fighter.State.RUN, Fighter.State.DASH, Fighter.State.SPRINT,
	Fighter.State.CROUCH, Fighter.State.SHIELD,
]
## Ticks in one run cycle, and the two foot plants in it (docs/specs/art-guide.md: 6 × 5 ticks).
const RUN_CYCLE := 30
const FOOT_PLANTS := {0: &"step_1", 15: &"step_2"}
## The same for dashing and sprinting: the run played at 3 ticks a drawing.
const SPRINT_CYCLE := 18
const SPRINT_FOOT_PLANTS := {0: &"step_1", 9: &"step_2"}
## The up special's launch: from (at least) standing still to rising faster than this (px/s).
const BOOST_SPEED := 100.0
const VOICES := 4
## The event for a move's own active_sound, and what last_played says for a move's own hit_sound.
const ACTIVE_SOUND := &"active_sound"
const MOVE_HIT := &"move_hit"

@export var sound_set: FightSounds = preload(FightSounds.DEFAULT_PATH)

var last_played: StringName = &""
## The stream last_played played (null when its file was missing). For tests.
var last_stream: AudioStream

var _match: Match
var _snapshot: Dictionary = {}
## Panned with the fighter; loops on their own; KO/respawn unpanned (off screen).
var _player := AudioStreamPlayer2D.new()
var _loop_player := AudioStreamPlayer2D.new()
var _flat_player := AudioStreamPlayer.new()
var _rng := RandomNumberGenerator.new()
## The sound looping now (&"" = none), and looped copies of streams, made once each.
var _loop: StringName = &""
var _looped: Dictionary[AudioStream, AudioStream] = {}
## The move in progress and the abilities' sounds, as of the last tick (where streams come from).
var _move_data: MoveData
var _abilities: Dictionary = {}
## The hit_sound of the move whose hit_landed came just before fighter_hit, or null.
var _hit_sound: AudioStream

@onready var _fighter := get_parent() as Fighter


## What sounds a fighter's state change over one tick makes (loops are loop_sound()'s). `before`
## and `after` come from snapshot(); `after.sounds` holds the fighter's abilities' sounds
## (FighterAbility.sounds()), `after.move_data` the move in progress (ACTIVE_SOUND: its own
## active_sound).
static func events(before: Dictionary, after: Dictionary) -> Array[StringName]:
	var out: Array[StringName] = []
	var state: Fighter.State = after.state
	var entered: bool = state != before.state
	var move: StringName = after.move
	var sounds: Dictionary = after.get("sounds", {})
	var starts: Dictionary = sounds.get("start", {})
	var hit_moves: Array = sounds.get("hit", [])
	var pops: Array = sounds.get("pop", [])
	var move_started: bool = state == Fighter.State.ATTACK and (
			move != before.move or before.state != Fighter.State.ATTACK
			or after.state_frame < before.state_frame)
	if move_started:
		if move in NORMALS:
			out.append(&"swing")
		elif move == &"neutral_special":
			out.append(&"swing_heavy")
		elif move == &"down_special_dive":
			out.append(&"dive")
		elif starts.has(move) and starts[move] != &"charge":
			out.append(starts[move])  # An ability's phase (FighterAbility.sounds()); charge loops.
	if after.projectile_out and not before.projectile_out:
		out.append(&"zap")
	if (move == &"down_special" or move in hit_moves) and after.hitbox_active \
			and not before.hitbox_active:
		out.append(&"burst")
	var data: MoveData = after.get("move_data")
	if data != null and data.active_sound != null and after.hitbox_active \
			and not before.hitbox_active:
		out.append(ACTIVE_SOUND)
	var popped: bool = before.move in pops  # Out of an ability's phase (off a pyramid's tip).
	if move == &"up_special" and state == Fighter.State.ATTACK \
			and (before.velocity.y >= 0.0 or popped) and after.velocity.y < -BOOST_SPEED:
		out.append(&"boost")
	if state == Fighter.State.RUN:
		var step: Variant = FOOT_PLANTS.get((int(after.state_frame) - 1) % RUN_CYCLE)
		if step != null:
			out.append(step)
	elif state == Fighter.State.DASH or state == Fighter.State.SPRINT:
		var step: Variant = SPRINT_FOOT_PLANTS.get((int(after.state_frame) - 1) % SPRINT_CYCLE)
		if step != null:
			out.append(step)
	if state == Fighter.State.AIR and after.velocity.y < 0.0:
		var from_ground: bool = before.state in GROUNDED or before.state == Fighter.State.LEDGE
		if entered and from_ground:
			out.append(&"jump")
		elif not after.on_floor and after.jumps_left < before.jumps_left:
			out.append(&"double_jump")
	if after.on_floor and not before.on_floor and before.state != Fighter.State.KO \
			and state not in [Fighter.State.LEDGE, Fighter.State.LEDGE_CLIMB, Fighter.State.KO]:
		out.append(&"land")
	if entered:
		if state == Fighter.State.SHIELD:
			out.append(&"shield_on")
		elif state == Fighter.State.SHIELD_BREAK:
			out.append(&"shield_break")
		elif state in DODGES:
			out.append(&"dodge")
		elif state == Fighter.State.LEDGE:
			out.append(&"ledge_grab")
	return out


## The sound that loops for the move in progress in `snap` (docs/specs/sound.md#loops), or &"".
static func loop_sound(snap: Dictionary) -> StringName:
	if snap.state != Fighter.State.ATTACK:
		return &""
	var move: StringName = snap.move
	if move == &"neutral_special_charge":
		return &"charge"
	var sounds: Dictionary = snap.get("sounds", {})
	var loops: Dictionary = sounds.get("loop", {})
	if loops.has(move):
		return loops[move]
	if (sounds.get("start", {}) as Dictionary).get(move) == &"charge":
		return &"charge"
	return &""


## The stream `sound` plays for a fighter: the move in progress's own (its `sounds`), else its
## abilities' (`abilities.streams`), else the set's; null when there's none.
static func stream_for(sound: StringName, move_data: MoveData, abilities: Dictionary,
		sound_set_: FightSounds) -> AudioStream:
	if move_data != null and move_data.sounds.has(sound):
		return move_data.sounds[sound]
	var own: Dictionary = abilities.get("streams", {})
	if own.has(sound):
		return own[sound]
	return sound_set_.streams.get(sound)


## What events() compares: the fighter's state after a tick.
static func snapshot(fighter: Fighter, projectile_out: bool) -> Dictionary:
	return {
		"state": fighter.state, "state_frame": fighter.state_frame, "move": fighter.move,
		"jumps_left": fighter.jumps_left, "velocity": fighter.velocity,
		"on_floor": fighter.is_on_floor(), "hitbox_active": fighter.is_hitbox_active(),
		"projectile_out": projectile_out, "sounds": ability_sounds(fighter),
		"move_data": fighter.current_move(),
	}


## Every sound of `fighter`'s abilities, merged: {"start": {phase: sound}, "hit": [...], "pop": [...],
## "loop": {phase: sound}, "streams": {name: AudioStream}}.
static func ability_sounds(fighter: Fighter) -> Dictionary:
	var merged := {"start": {}, "hit": [], "pop": [], "loop": {}, "streams": {}}
	for ability in fighter.abilities:
		var own := ability.sounds()
		(merged.start as Dictionary).merge(own.get("start", {}))
		(merged.loop as Dictionary).merge(own.get("loop", {}))
		(merged.streams as Dictionary).merge(own.get("streams", {}))
		(merged.hit as Array).append_array(own.get("hit", []))
		(merged.pop as Array).append_array(own.get("pop", []))
	return merged


func _ready() -> void:
	_rng.randomize()
	for player: Node in [_player, _loop_player, _flat_player]:
		player.set("bus", &"SFX")
		add_child(player)
	_player.max_polyphony = VOICES
	_player.stream = AudioStreamPolyphonic.new()
	(_player.stream as AudioStreamPolyphonic).polyphony = VOICES
	_flat_player.max_polyphony = 2
	_match = _fighter.owner as Match
	if _match == null:
		return
	_match.stepped.connect(_on_stepped)
	_match.hit_landed.connect(_on_hit_landed)
	_match.fighter_hit.connect(_on_hit)
	_match.fighter_blocked.connect(_on_blocked)
	_match.fighter_ko.connect(_on_ko)
	_match.fighter_respawned.connect(_on_respawned)
	_match.owner_sound.connect(_on_owner_sound)
	# The first "before": once the Match has placed the fighters (after everyone's _ready).
	_take_snapshot.call_deferred()


## Stops whatever is still playing, so nothing outlives the match (or the engine at exit).
func _exit_tree() -> void:
	for player: Node in [_player, _loop_player, _flat_player]:
		player.call("stop")


func _take_snapshot() -> void:
	_snapshot = snapshot(_fighter, _projectile_out())


func is_charging() -> bool:
	return _loop == &"charge" and _loop_player.playing


## Plays a fight sound from the fighter (panned), at a slightly varied pitch; silent when its file
## is missing. The stream can be the move's or an ability's own (stream_for()).
func play(sound: StringName) -> void:
	var stream := stream_for(sound, _move_data, _abilities, sound_set)
	_play_stream(sound, stream, _volume(sound, stream))


func _play_stream(sound: StringName, stream: AudioStream, volume_db: float = 0.0) -> void:
	last_played = sound
	last_stream = stream
	played.emit(sound)
	if stream == null:
		return
	if not _player.playing:
		_player.play()
	var playback := _player.get_stream_playback() as AudioStreamPlaybackPolyphonic
	if playback != null:
		playback.play_stream(stream, 0.0, volume_db, _pitch())


## The set's volume for its own streams; a character's own files are mixed in the file.
func _volume(sound: StringName, stream: AudioStream) -> float:
	if stream != null and stream == sound_set.streams.get(sound):
		return sound_set.volume_db.get(sound, 0.0)
	return 0.0


func _play_flat(sound: StringName) -> void:
	var stream: AudioStream = sound_set.streams.get(sound)
	last_played = sound
	last_stream = stream
	played.emit(sound)
	if stream == null:
		return
	_flat_player.stream = stream
	_flat_player.volume_db = sound_set.volume_db.get(sound, 0.0)
	_flat_player.play()


func _pitch() -> float:
	return _rng.randf_range(sound_set.pitch_min, sound_set.pitch_max)


func _on_stepped() -> void:
	var now := snapshot(_fighter, _projectile_out())
	_move_data = now.move_data
	_abilities = now.sounds
	if not _snapshot.is_empty():
		for event in events(_snapshot, now):
			if event == ACTIVE_SOUND:
				_play_stream(ACTIVE_SOUND, _move_data.active_sound)
			else:
				play(event)
	_set_loop(loop_sound(now))
	_snapshot = now


## Starts `sound` looping (replacing the loop playing), or stops the loop (&"").
func _set_loop(sound: StringName) -> void:
	if sound == _loop:
		return
	_loop = sound
	_loop_player.stop()
	if sound == &"":
		return
	var stream := stream_for(sound, _move_data, _abilities, sound_set)
	last_played = sound
	last_stream = stream
	played.emit(sound)
	if stream == null:
		return
	if not _looped.has(stream):
		_looped[stream] = _looping_copy(stream)
	_loop_player.stream = _looped[stream]
	_loop_player.volume_db = _volume(sound, stream)
	_loop_player.play()


static func _looping_copy(stream: AudioStream) -> AudioStream:
	var copy := stream.duplicate() as AudioStream
	var wav := copy as AudioStreamWAV
	if wav != null:
		wav.loop_mode = AudioStreamWAV.LOOP_FORWARD
		wav.loop_begin = 0
		wav.loop_end = int(wav.get_length() * wav.mix_rate)
	elif "loop" in copy:
		copy.set("loop", true)
	return copy


func _projectile_out() -> bool:
	for projectile in _match.get_projectiles():
		if projectile.owner_index == _fighter.player_index:
			return true
	return false


func _on_hit_landed(player_index: int, move: MoveData) -> void:
	if player_index == _fighter.player_index:
		_hit_sound = move.hit_sound if move != null else null


func _on_hit(player_index: int) -> void:
	if player_index != _fighter.player_index:
		return
	if _hit_sound != null:
		_play_stream(MOVE_HIT, _hit_sound)
		_hit_sound = null
	else:
		play(sound_set.hit_sound(_fighter.velocity.length()))


func _on_blocked(player_index: int) -> void:
	if player_index == _fighter.player_index:
		play(&"block")


func _on_ko(player_index: int) -> void:
	if player_index == _fighter.player_index:
		_set_loop(&"")
		_play_flat(&"ko")


func _on_owner_sound(player_index: int, sound: StringName) -> void:
	if player_index == _fighter.player_index:
		play(sound)


func _on_respawned(player_index: int) -> void:
	if player_index == _fighter.player_index:
		_play_flat(&"respawn")
