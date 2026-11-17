class_name SpeakerAbility
extends FighterAbility
## Henrik's speaker jam down special (docs/specs/characters/henrik.md#henrik--guitar): on the
## move's frame `startup` (on the ground, or after the default dive lands) it becomes the phase
## `speaker_jam` and a speaker appears on each side of him; he plays for `jam_frames`, the
## speakers blast on the beats (their own hits), then he lowers the guitar for `end_frames`.

const JAM := &"speaker_jam"
## The strum swaps between drawings 1 and 2 every this many ticks.
const STRUM_TICKS := 4


func _numbers() -> SpeakerData:
	return data as SpeakerData


func phases() -> Array[StringName]:
	return [JAM]


## True while he's playing (or lowering the guitar after it).
func is_jamming() -> bool:
	return fighter.state == Fighter.State.ATTACK and fighter.move == JAM


## The down special's last startup frame: the jam starts and the speakers appear.
func spawn_entities(match_: Match) -> void:
	var down := fighter.stats.moveset.get(slot) as MoveData
	if not (fighter.state == Fighter.State.ATTACK and fighter.move == slot
			and fighter.state_frame == down.startup):
		return
	fighter.clear_hit_victims()
	fighter.move = JAM
	fighter.state_frame = 0
	for side in [-1, 1]:
		var speaker := Speaker.new()
		match_.add_entity(speaker)
		speaker.setup(fighter.player_index, side,
			fighter.global_position + Vector2(side * _numbers().offset, 0.0), _numbers(),
			fighter.character_id)


## One `burst` per beat (for both speakers).
func end_step(match_: Match) -> void:
	if is_jamming() and _numbers().is_beat(fighter.state_frame):
		match_.owner_sound.emit(fighter.player_index, &"burst")


func phase_finished(_move: StringName) -> bool:
	return fighter.state_frame >= _numbers().jam_frames + _numbers().end_frames


func phase_animation(_move: StringName) -> String:
	return "down_special"


## 0 for the startup; in the jam 3 on a blast, else 1 and 2 swapping; 4 lowering the guitar.
func drawing(_animation: String, frame: int) -> int:
	if fighter.state != Fighter.State.ATTACK:
		return frame
	if fighter.move == slot:
		return 0
	if fighter.move != JAM:
		return frame
	var age := fighter.state_frame
	if age >= _numbers().jam_frames:
		return 4
	if _numbers().is_blasting(age):
		return 3
	return 1 if (age / STRUM_TICKS) % 2 == 0 else 2


## His strum as the jam starts (docs/specs/sound.md#character-sounds).
func sounds() -> Dictionary:
	var sound := _numbers().sound
	if sound == null:
		return {}
	return {"start": {JAM: &"henrik_strum"}, "streams": {&"henrik_strum": sound}}
