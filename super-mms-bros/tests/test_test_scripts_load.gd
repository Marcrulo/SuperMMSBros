extends GutTest
## GUT skips a test script that fails to load (a typo, or a class the project doesn't have yet)
## and still reports success. This test fails instead, so exit code 0 really means "all passed".

const TESTS_DIR := "res://tests/"


func test_every_test_script_loads() -> void:
	for file in DirAccess.get_files_at(TESTS_DIR):
		if file.begins_with("test_") and file.ends_with(".gd"):
			var script := load(TESTS_DIR + file) as GDScript
			assert_true(script != null and script.can_instantiate(),
				"%s should load; see the SCRIPT ERROR lines above" % file)
