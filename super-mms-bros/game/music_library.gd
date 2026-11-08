class_name MusicLibrary
## Finds and loads the looping music tracks: assets/music/<name>.ogg, one per stage plus "menu"
## (docs/specs/controls-and-display.md#audio). The tracks aren't in git, so any may be missing.

const DIR := "res://assets/music/"


static func path(track: String) -> String:
	return DIR + track + ".ogg"


## The track, set to loop; null if there's no such file.
static func load_looping(track: String) -> AudioStream:
	if not ResourceLoader.exists(path(track)):
		return null
	var music := load(path(track)) as AudioStream
	if music is AudioStreamOggVorbis:
		(music as AudioStreamOggVorbis).loop = true
	return music
