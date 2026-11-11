class_name FightSounds
extends Resource
## The fight sound set (docs/specs/sound.md): a stream and a volume per sound, how hard a hit must
## launch to sound medium or heavy, and how much each play's pitch varies. Tuned in the Inspector.

const DEFAULT_PATH := "res://match/fight_sounds.tres"
## Every fight sound, as named in the spec (and in assets/sfx/fight/<name>.wav).
const NAMES: Array[StringName] = [
	&"hit_light", &"hit_medium", &"hit_heavy", &"block", &"swing", &"swing_heavy", &"charge",
	&"zap", &"burst", &"dive", &"boost", &"step_1", &"step_2", &"jump", &"double_jump", &"land",
	&"shield_on", &"shield_break", &"dodge", &"ledge_grab", &"ko", &"respawn",
]

@export var streams: Dictionary[StringName, AudioStream] = {}
## Per-sound volume (dB) on top of the normalized files; missing = 0.
@export var volume_db: Dictionary[StringName, float] = {}
## A hit launching slower than this (px/s) sounds light...
@export var light_below := 200.0
## ...and from this speed on, heavy (medium in between).
@export var heavy_from := 400.0
@export var pitch_min := 0.95
@export var pitch_max := 1.05


## The hit sound for a victim launched at `launch_speed` px/s.
func hit_sound(launch_speed: float) -> StringName:
	if launch_speed < light_below:
		return &"hit_light"
	if launch_speed < heavy_from:
		return &"hit_medium"
	return &"hit_heavy"
