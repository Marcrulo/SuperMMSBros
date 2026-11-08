extends GutTest
## The six stages as data, and Stage.apply() (docs/specs/match-and-stage.md#stages).

const STAGE_SCENE := preload("res://stage/battlefield.tscn")
const NAMES := {
	"mms": "MMS",
	"fc": "Frederiksborgcenteret",
	"slot_sunset": "Frederiksborg Castle Sunset",
	"cafe_station": "Cafe Station",
	"lindevej": "Lindevej",
	"cafe_slotsbio": "Cafe Slotsbio",
}
const STYLES := {
	"mms": "school_brick",
	"fc": "modern",
	"slot_sunset": "castle",
	"cafe_station": "school_brick",
	"lindevej": "white_plaster",
	"cafe_slotsbio": "yellow_plaster",
}


func test_every_stage_loads_with_its_name_background_and_style() -> void:
	for id: String in NAMES:
		var data := StageData.load_stage(id)
		assert_not_null(data, id)
		if data == null:
			continue
		assert_eq(data.id, id)
		assert_eq(data.display_name, NAMES[id])
		assert_eq(data.background.get_size(), Vector2(528, 297), "%s background size" % id)
		assert_eq(data.style.resource_path, "res://stage/styles/%s.tres" % STYLES[id])


func test_light_and_haze() -> void:
	var sunset := StageData.load_stage("slot_sunset")
	assert_eq(sunset.light_color, Color(1.0, 0.85, 0.70))
	assert_eq(sunset.haze_color, Color(0.96, 0.80, 0.60))
	var cafe := StageData.load_stage("cafe_station")
	assert_eq(cafe.light_color, Color(1.0, 0.93, 0.84))
	assert_eq(cafe.haze_color, Color(0.96, 0.85, 0.72))
	for id in ["mms", "fc", "lindevej", "cafe_slotsbio"]:
		var data := StageData.load_stage(id)
		assert_eq(data.light_color, Color.WHITE, id)
		assert_eq(data.haze_color, Color(0.82, 0.87, 0.93), id)


func test_stage_list_without_the_day_castle() -> void:
	assert_eq(StageData.ALL_IDS, ["mms", "fc", "slot_sunset", "cafe_station", "lindevej", "cafe_slotsbio"])
	assert_false(ResourceLoader.exists("res://stage/stages/slot_day.tres"))


func test_unknown_stage_falls_back_to_mms() -> void:
	assert_eq(StageData.load_stage("no_such_stage").id, "mms")


func test_apply_sets_background_light_haze_and_style() -> void:
	var stage: Stage = add_child_autofree(STAGE_SCENE.instantiate())
	var data := StageData.load_stage("slot_sunset")
	stage.apply(data)
	var background := stage.get_node("BackgroundLayer/Background") as Sprite2D
	assert_eq(background.texture, data.background)
	var material := background.material as ShaderMaterial
	assert_eq(material.get_shader_parameter("haze_color"), data.haze_color)
	assert_eq((stage.get_node("Light") as CanvasModulate).color, data.light_color)
	assert_eq(stage.get_node("PlatformLook").style, data.style)
	assert_eq(stage.get_node("PlatformFront").style, data.style)


func test_every_stage_has_the_same_layout() -> void:
	var stage: Stage = add_child_autofree(STAGE_SCENE.instantiate())
	var before := _collision_rects(stage)
	for id: String in NAMES:
		stage.apply(StageData.load_stage(id))
		assert_eq(_collision_rects(stage), before, id)


func _collision_rects(stage: Stage) -> Array[Rect2]:
	var rects: Array[Rect2] = []
	for path in ["MainPlatform", "Platforms/Left", "Platforms/Right", "Platforms/Top"]:
		var shape := stage.get_node(path + "/CollisionShape2D") as CollisionShape2D
		var size := (shape.shape as RectangleShape2D).size
		rects.append(Rect2(shape.global_position - size / 2.0, size))
	return rects
