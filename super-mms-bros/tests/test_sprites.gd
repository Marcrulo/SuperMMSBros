extends GutTest
## Every character's sprite strips match docs/specs/art-guide.md: 48×48 (or 64×64) frames, side by
## side, in assets/fighters/<id>/; one frame size per character.

const DIR := "res://assets/fighters/"
## Drawings per animation, from the art guide's table.
const FRAMES := {
	"idle": 4, "run": 6, "crouch": 2, "jump": 2, "fall": 2, "helpless": 2, "shield": 1,
	"dizzy": 2, "hurt": 2, "jab": 5, "down_tilt": 5, "up_tilt": 5, "side_tilt": 5,
	"neutral_special_charge": 2, "neutral_special": 4, "down_special_dive": 1,
	"down_special": 5, "side_special": 4, "up_special": 3,
	"neutral_air": 5, "forward_air": 5, "back_air": 5, "up_air": 5, "down_air": 5,
	"spot_dodge": 3, "roll": 4, "air_dodge": 2, "ledge": 2, "ledge_climb": 3,
}


func test_every_character_has_every_strip() -> void:
	for character in Game.roster().characters:
		var size := Vector2.ZERO
		for animation: String in FRAMES:
			var path := DIR + "%s/fighter_%s.png" % [character.id, animation]
			assert_true(ResourceLoader.exists(path), "missing %s" % path)
			if not ResourceLoader.exists(path):
				continue
			var texture := load(path) as Texture2D
			if size == Vector2.ZERO:
				size = Vector2(texture.get_width() / FRAMES[animation], texture.get_height())
				assert_true(size.y in [48.0, 64.0] or size.y > 64.0 and size.x > 64.0,
					"%s frame size %s" % [character.id, size])
			assert_eq(texture.get_size(), Vector2(size.x * FRAMES[animation], size.y), path)


## 64×64 frames, or a bigger canvas for a character with a weapon (art guide: weapons).
func test_every_character_is_in_the_64_px_style() -> void:
	for character in Game.roster().characters:
		var texture := load(DIR + "%s/fighter_idle.png" % character.id) as Texture2D
		var weapon: bool = character.id in ["slot_06", "slot_02"]  # Henrik's guitar, Gitte's scissors
		var canvas := Vector2(112, 80) if weapon else Vector2(64, 64)
		assert_eq(texture.get_size(), Vector2(canvas.x * 4, canvas.y), character.id)


func test_every_character_has_a_stock_icon() -> void:
	for character in Game.roster().characters:
		var texture := load(DIR + "%s/stock_icon.png" % character.id) as Texture2D
		assert_eq(texture.get_size(), Vector2(8, 8), character.id)


func test_the_placeholder_set_is_gone() -> void:
	assert_false(DirAccess.dir_exists_absolute(DIR + "default"))


func test_projectile_strip_is_shared() -> void:
	var texture := load(DIR + "projectile.png") as Texture2D
	assert_eq(texture.get_size(), Vector2(36, 12))
