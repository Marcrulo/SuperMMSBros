extends GutTest
## Display, rendering and font settings from docs/specs/controls-and-display.md.

const FONT_PATH := "res://assets/fonts/PressStart2P-Regular.ttf"


func test_display_settings() -> void:
	assert_eq(ProjectSettings.get_setting("display/window/size/viewport_width"), 320)
	assert_eq(ProjectSettings.get_setting("display/window/size/viewport_height"), 180)
	assert_eq(ProjectSettings.get_setting("display/window/size/window_width_override"), 1280)
	assert_eq(ProjectSettings.get_setting("display/window/size/window_height_override"), 720)
	assert_eq(ProjectSettings.get_setting("display/window/stretch/mode"), "viewport")
	assert_eq(ProjectSettings.get_setting("display/window/stretch/aspect"), "keep")
	assert_eq(ProjectSettings.get_setting("display/window/stretch/scale_mode"), "integer")


func test_pixel_art_rendering() -> void:
	assert_eq(ProjectSettings.get_setting("rendering/textures/canvas_textures/default_texture_filter"), 0,
		"default texture filter should be Nearest")
	assert_true(ProjectSettings.get_setting("rendering/2d/snap/snap_2d_transforms_to_pixel"))
	assert_eq(ProjectSettings.get_setting("rendering/environment/defaults/default_clear_color"),
		Color("#1a1c2c"))


func test_physics_runs_at_60_ticks() -> void:
	assert_eq(ProjectSettings.get_setting("physics/common/physics_ticks_per_second"), 60)


func test_main_scene_loads() -> void:
	# The editor stores the main scene as a "uid://..." reference; ensure_path turns it into a file path.
	var path := ResourceUID.ensure_path(ProjectSettings.get_setting("application/run/main_scene"))
	assert_eq(path, "res://match/match.tscn")
	var scene := load(path) as PackedScene
	assert_not_null(scene, "main scene should load")
	if scene == null:
		return
	var root := scene.instantiate()
	assert_eq(root.name, &"Match")
	root.free()


func test_pixel_font_is_default_and_crisp() -> void:
	assert_eq(ResourceUID.ensure_path(ProjectSettings.get_setting("gui/theme/custom_font")), FONT_PATH)
	var font := load(FONT_PATH) as FontFile
	assert_not_null(font, "font should load")
	if font == null:
		return
	assert_eq(font.antialiasing, TextServer.FONT_ANTIALIASING_NONE)
	assert_eq(font.hinting, TextServer.HINTING_NONE)
	assert_eq(font.subpixel_positioning, TextServer.SUBPIXEL_POSITIONING_DISABLED)
