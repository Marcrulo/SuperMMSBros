class_name StageData
extends Resource
## One stage: its name and look (docs/specs/match-and-stage.md#stages). Every stage shares the
## Battlefield layout; this only dresses it. One .tres per stage in res://stage/stages/, named
## after its id.

const STAGES_DIR := "res://stage/stages/"
const DEFAULT_ID := "mms"
## Every stage, in stage-select order.
const ALL_IDS: Array[String] = ["mms", "fc", "slot_sunset", "cafe_station", "lindevej",
		"cafe_slotsbio"]

@export var id: String
@export var display_name: String
## 528×297: the 480×270 screen plus room for parallax drift.
@export var background: Texture2D
@export var style: PlatformStyle
## The background is mixed toward this color so the stage reads in front of it.
@export var haze_color: Color
## Tints everything in front of the background (white = no change).
@export var light_color: Color = Color.WHITE


## Loads the stage with this id, or the default stage if there is none.
static func load_stage(stage_id: String) -> StageData:
	var path := STAGES_DIR + stage_id + ".tres"
	if not ResourceLoader.exists(path):
		path = STAGES_DIR + DEFAULT_ID + ".tres"
	return load(path) as StageData


## Where the music for the stage `stage_id` lives (a track named after the stage).
static func music_path(stage_id: String) -> String:
	return MusicLibrary.path(stage_id)


## This stage's music, set to loop; null if there's no track (the tracks aren't in git).
func load_music() -> AudioStream:
	return MusicLibrary.load_looping(id)
