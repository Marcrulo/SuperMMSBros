extends GutTest
## The project targets Godot 4.7 (see CLAUDE.md).


func test_runs_on_godot_4_7() -> void:
	var version := Engine.get_version_info()
	assert_eq(version.major, 4)
	assert_eq(version.minor, 7)
