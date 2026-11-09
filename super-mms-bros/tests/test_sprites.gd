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
		var size := 0
		for animation: String in FRAMES:
			var path := DIR + "%s/fighter_%s.png" % [character.id, animation]
			assert_true(ResourceLoader.exists(path), "missing %s" % path)
			if not ResourceLoader.exists(path):
				continue
			var texture := load(path) as Texture2D
			if size == 0:
				size = int(texture.get_height())
				assert_has([48, 64], size, "%s frame size" % character.id)
			assert_eq(texture.get_size(), Vector2(size * FRAMES[animation], size), path)


func test_michael_bech_is_in_the_64_px_style() -> void:
	var texture := load(DIR + "slot_05/fighter_idle.png") as Texture2D
	assert_eq(texture.get_size(), Vector2(64 * 4, 64))


func test_every_character_has_a_stock_icon() -> void:
	for character in Game.roster().characters:
		var texture := load(DIR + "%s/stock_icon.png" % character.id) as Texture2D
		assert_eq(texture.get_size(), Vector2(8, 8), character.id)


func test_the_placeholder_set_is_gone() -> void:
	assert_false(DirAccess.dir_exists_absolute(DIR + "default"))


func test_projectile_strip_is_shared() -> void:
	var texture := load(DIR + "projectile.png") as Texture2D
	assert_eq(texture.get_size(), Vector2(36, 12))
