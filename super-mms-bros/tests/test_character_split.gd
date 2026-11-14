extends GutTest
## Shared code never names a character's own mechanics (docs/specs/architecture.md#abilities):
## a character's scripts live in res://characters/<name>/, and the shared scripts reach them only
## through FighterAbility / MatchEntity hooks. Keeps character branches from clashing in shared
## files.

## The shared scripts' folders.
const SHARED_DIRS: Array[String] = ["res://fighter/", "res://match/", "res://ui/",
		"res://controllers/", "res://stage/", "res://game/"]
const CHARACTERS_DIR := "res://characters/"


## Every .gd file directly in `dir` and its subfolders.
func _scripts_in(dir: String) -> Array[String]:
	var found: Array[String] = []
	for file in DirAccess.get_files_at(dir):
		if file.get_extension() == "gd":
			found.append(dir + file)
	for sub in DirAccess.get_directories_at(dir):
		found.append_array(_scripts_in(dir + sub + "/"))
	return found


## A script's code without its comments (a `#` that starts a line or follows a space; a `#`
## inside a color string like "#1a1c2c" stays).
func _code(path: String) -> String:
	var lines: PackedStringArray = []
	for line in FileAccess.get_file_as_string(path).split("\n"):
		var cut := RegEx.create_from_string("(^|\\s)#.*$").sub(line, "")
		lines.append(cut)
	return "\n".join(lines)


## Class names, ability phases and character names that belong to one character.
func _character_words() -> Array[String]:
	var words: Array[String] = []
	var class_name_re := RegEx.create_from_string("(?m)^class_name\\s+(\\w+)")
	for path in _scripts_in(CHARACTERS_DIR):
		var found := class_name_re.search(FileAccess.get_file_as_string(path))
		if found == null:
			continue
		words.append(found.get_string(1))
		var script := load(path) as Script
		if script.get_instance_base_type() == &"RefCounted" and script.can_instantiate():
			var instance: Object = script.new()
			if instance is FighterAbility:
				for phase in (instance as FighterAbility).phases():
					words.append(String(phase))
	for character in Game.roster().characters:
		for word in character.display_name.split(" "):
			if word.length() > 2 and word != "???":
				words.append(word)
	return words


func test_character_scripts_live_in_their_folders() -> void:
	for dir in SHARED_DIRS:
		for path in _scripts_in(dir):
			var code := FileAccess.get_file_as_string(path)
			assert_false(code.contains("extends FighterAbility") or code.contains("extends AbilityData")
				or code.contains("extends MatchEntity"),
				"%s is a character's script: it belongs in %s<name>/" % [path, CHARACTERS_DIR])


func test_shared_code_never_names_a_character_mechanic() -> void:
	var words := _character_words()
	assert_gt(words.size(), 20, "found the characters' classes and phases")
	for dir in SHARED_DIRS:
		for path in _scripts_in(dir):
			var code := _code(path)
			for word in words:
				var re := RegEx.create_from_string("\\b" + word + "\\b")
				assert_null(re.search(code), "%s names %s (use an ability hook instead)" % [path, word])
