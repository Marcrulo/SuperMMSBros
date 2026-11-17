class_name SpeakerData
extends AbilityData
## Henrik's speaker jam down special's tuning (docs/specs/characters/henrik.md#henrik--guitar).

## The speakers' centers this far left and right of his x (px).
@export var offset: float
## Ticks he plays (the speakers blast on the beats), then ticks lowering the guitar.
@export var jam_frames: int
@export var end_frames: int
## The first beat's jam tick, then one every `beat_every` ticks while under `jam_frames`.
@export var first_beat: int
@export var beat_every: int
## Ticks each blast's hitbox is out, from its beat.
@export var blast_frames: int
## Ticks the speakers take to sink into the floor once the jam is over.
@export var sink_frames: int
## A speaker's blast: its hitbox from the speaker's foot (facing outward) and its hit.
@export var blast: MoveData
## His strum as the jam starts (docs/specs/sound.md#character-sounds); none = silent.
@export var sound: AudioStream


## True if jam tick `age` is a beat.
func is_beat(age: int) -> bool:
	return age >= first_beat and age < jam_frames and (age - first_beat) % beat_every == 0


## True while a blast is out on jam tick `age`.
func is_blasting(age: int) -> bool:
	if age < first_beat or age >= jam_frames:
		return false
	return (age - first_beat) % beat_every < blast_frames


func create_ability() -> FighterAbility:
	return SpeakerAbility.new()
