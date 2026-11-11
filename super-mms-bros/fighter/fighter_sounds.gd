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
	Fighter.State.IDLE, Fighter.State.RUN, Fighter.State.CROUCH, Fighter.State.SHIELD,
]
## Ticks in one run cycle, and the two foot plants in it (docs/specs/art-guide.md: 6 × 5 ticks).
const RUN_CYCLE := 30
const FOOT_PLANTS := {0: &"step_1", 15: &"step_2"}
## The up special's launch: from (at least) standing still to rising faster than this (px/s).
const BOOST_SPEED := 100.0
const VOICES := 4

@export var sound_set: FightSounds = preload(FightSounds.DEFAULT_PATH)

var last_played: StringName = &""

var _match: Match
var _snapshot: Dictionary = {}
## Panned with the fighter; the charge loop on its own; KO/respawn unpanned (off screen).
var _player := AudioStreamPlayer2D.new()
var _charge_player := AudioStreamPlayer2D.new()
var _flat_player := AudioStreamPlayer.new()
var _rng := RandomNumberGenerator.new()

@onready var _fighter := get_parent() as Fighter


## What sounds a fighter's state change over one tick makes (and &"charge_stop" when the neutral
## special's charge ends). `before` and `after` come from snapshot().
static func events(before: Dictionary, after: Dictionary) -> Array[StringName]:
	var out: Array[StringName] = []
	var state: Fighter.State = after.state
	var entered: bool = state != before.state
	var move: StringName = after.move
	var move_started: bool = state == Fighter.State.ATTACK and (
			move != before.move or before.state != Fighter.State.ATTACK
			or after.state_frame < before.state_frame)
	if move_started:
		if move in NORMALS:
			out.append(&"swing")
		elif move == &"neutral_special":
			out.append(&"swing_heavy")
		elif move == &"neutral_special_charge":
			out.append(&"charge")
		elif move == &"down_special_dive":
			out.append(&"dive")
	var was_charging: bool = before.state == Fighter.State.ATTACK and before.move == &"neutral_special_charge"
	if was_charging and not (state == Fighter.State.ATTACK and move == &"neutral_special_charge"):
		out.append(&"charge_stop")
	if after.projectile_out and not before.projectile_out:
		out.append(&"zap")
	if move == &"down_special" and after.hitbox_active and not before.hitbox_active:
		out.append(&"burst")
	if move == &"up_special" and state == Fighter.State.ATTACK and before.velocity.y >= 0.0 \
			and after.velocity.y < -BOOST_SPEED:
		out.append(&"boost")
	if state == Fighter.State.RUN:
		var step: Variant = FOOT_PLANTS.get((int(after.state_frame) - 1) % RUN_CYCLE)
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


## What events() compares: the fighter's state after a tick.
static func snapshot(fighter: Fighter, projectile_out: bool) -> Dictionary:
	return {
		"state": fighter.state, "state_frame": fighter.state_frame, "move": fighter.move,
		"jumps_left": fighter.jumps_left, "velocity": fighter.velocity,
		"on_floor": fighter.is_on_floor(), "hitbox_active": fighter.is_hitbox_active(),
		"projectile_out": projectile_out,
	}


func _ready() -> void:
	_rng.randomize()
	for player: Node in [_player, _charge_player, _flat_player]:
		player.set("bus", &"SFX")
		add_child(player)
	_player.max_polyphony = VOICES
	_player.stream = AudioStreamPolyphonic.new()
	(_player.stream as AudioStreamPolyphonic).polyphony = VOICES
	_flat_player.max_polyphony = 2
	var charge := sound_set.streams.get(&"charge") as AudioStreamWAV
	if charge != null:
		charge = charge.duplicate() as AudioStreamWAV
		charge.loop_mode = AudioStreamWAV.LOOP_FORWARD
		charge.loop_begin = 0
		charge.loop_end = int(charge.get_length() * charge.mix_rate)
		_charge_player.stream = charge
	_match = _fighter.owner as Match
	if _match == null:
		return
	_match.stepped.connect(_on_stepped)
	_match.fighter_hit.connect(_on_hit)
	_match.fighter_blocked.connect(_on_blocked)
	_match.fighter_ko.connect(_on_ko)
	_match.fighter_respawned.connect(_on_respawned)
	# The first "before": once the Match has placed the fighters (after everyone's _ready).
	_take_snapshot.call_deferred()


## Stops whatever is still playing, so nothing outlives the match (or the engine at exit).
func _exit_tree() -> void:
	for player: Node in [_player, _charge_player, _flat_player]:
		player.call("stop")


func _take_snapshot() -> void:
	_snapshot = snapshot(_fighter, _projectile_out())


func is_charging() -> bool:
	return _charge_player.playing


## Plays a fight sound from the fighter (panned), at a slightly varied pitch; silent when its file
## is missing.
func play(sound: StringName) -> void:
	last_played = sound
	played.emit(sound)
	var stream: AudioStream = sound_set.streams.get(sound)
	if stream == null:
		return
	if not _player.playing:
		_player.play()
	var playback := _player.get_stream_playback() as AudioStreamPlaybackPolyphonic
	if playback != null:
		playback.play_stream(stream, 0.0, sound_set.volume_db.get(sound, 0.0), _pitch())


func _play_flat(sound: StringName) -> void:
	last_played = sound
	played.emit(sound)
	var stream: AudioStream = sound_set.streams.get(sound)
	if stream == null:
		return
	_flat_player.stream = stream
	_flat_player.volume_db = sound_set.volume_db.get(sound, 0.0)
	_flat_player.play()


func _pitch() -> float:
	return _rng.randf_range(sound_set.pitch_min, sound_set.pitch_max)


func _on_stepped() -> void:
	var now := snapshot(_fighter, _projectile_out())
	if not _snapshot.is_empty():
		for event in events(_snapshot, now):
			if event == &"charge":
				_start_charge()
			elif event == &"charge_stop":
				_charge_player.stop()
			else:
				play(event)
	_snapshot = now


func _start_charge() -> void:
	played.emit(&"charge")
	last_played = &"charge"
	if _charge_player.stream != null:
		_charge_player.volume_db = sound_set.volume_db.get(&"charge", 0.0)
		_charge_player.play()


func _projectile_out() -> bool:
	for projectile in _match.get_projectiles():
		if projectile.owner_index == _fighter.player_index:
			return true
	return false


func _on_hit(player_index: int) -> void:
	if player_index == _fighter.player_index:
		play(sound_set.hit_sound(_fighter.velocity.length()))


func _on_blocked(player_index: int) -> void:
	if player_index == _fighter.player_index:
		play(&"block")


func _on_ko(player_index: int) -> void:
	if player_index == _fighter.player_index:
		_charge_player.stop()
		_play_flat(&"ko")


func _on_respawned(player_index: int) -> void:
	if player_index == _fighter.player_index:
		_play_flat(&"respawn")
