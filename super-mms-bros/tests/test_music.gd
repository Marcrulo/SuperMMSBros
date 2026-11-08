extends GutTest
## Stage music (docs/specs/controls-and-display.md#audio). The tracks aren't in git, so the checks
## that need a track are pending where it's missing.

const MATCH_SCENE := preload("res://match/match.tscn")


func after_each() -> void:
	Game.stage_id = ""


func test_music_is_found_by_stage_id() -> void:
	assert_eq(StageData.music_path("fc"), "res://assets/music/fc.ogg")


func test_a_stage_without_a_track_is_silent() -> void:
	var data := StageData.new()
	data.id = "no_such_stage"
	assert_null(data.load_music())


func test_every_stage_track_loops() -> void:
	for id in StageData.ALL_IDS:
		if not ResourceLoader.exists(StageData.music_path(id)):
			pending("no track for %s on this machine" % id)
			continue
		var music := StageData.load_stage(id).load_music() as AudioStreamOggVorbis
		assert_not_null(music, id)
		assert_true(music.loop, "%s loops" % id)


func test_match_plays_the_stage_music() -> void:
	Game.stage_id = "fc"
	var match_node: Match = add_child_autofree(MATCH_SCENE.instantiate())
	var player := match_node.get_node("Music") as AudioStreamPlayer
	assert_not_null(player, "the Match has a Music player")
	if not ResourceLoader.exists(StageData.music_path("fc")):
		assert_null(player.stream, "silent without a track")
		return
	assert_eq(player.stream.resource_path, StageData.music_path("fc"))
	assert_true(player.playing)
