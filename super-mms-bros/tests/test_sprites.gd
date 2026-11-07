extends GutTest
## The fighter's sprite strips match docs/specs/art-guide.md: 48×48 frames, side by side.

const DIR := "res://assets/fighters/default/"
## Drawings per animation, from the art guide's table.
const FRAMES := {
	"idle": 4, "run": 6, "crouch": 2, "jump": 2, "fall": 2, "helpless": 2, "shield": 1,
	"dizzy": 2, "hurt": 2, "jab": 5, "down_tilt": 5, "up_tilt": 5, "side_tilt": 5,
	"neutral_special_charge": 2, "neutral_special": 4, "down_special_dive": 1,
	"down_special": 5, "side_special": 4, "up_special": 3,
}


func test_every_animation_strip_has_its_frames() -> void:
	for animation: String in FRAMES:
		var path := DIR + "fighter_%s.png" % animation
		assert_true(ResourceLoader.exists(path), "missing %s" % path)
		if not ResourceLoader.exists(path):
			continue
		var texture := load(path) as Texture2D
		assert_eq(texture.get_size(), Vector2(48 * FRAMES[animation], 48), animation)


func test_projectile_strip() -> void:
	var texture := load(DIR + "projectile.png") as Texture2D
	assert_eq(texture.get_size(), Vector2(36, 12))
