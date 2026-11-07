extends GutTest
## The normal attacks' data matches docs/specs/moves.md.

# name: [startup, active, recovery, center, size, damage, base, growth, angle, direction]
const NORMALS := {
	"jab": [4, 3, 12, Vector2(15, -13), Vector2(14, 10), 3.0, 120.0, 0.8, 40.0, MoveData.Direction.FACING],
	"down_tilt": [5, 3, 12, Vector2(14, -3), Vector2(18, 6), 6.0, 130.0, 1.0, 75.0, MoveData.Direction.FACING],
	"up_tilt": [5, 4, 14, Vector2(2, -31), Vector2(24, 12), 7.0, 160.0, 1.2, 90.0, MoveData.Direction.AWAY],
	"side_tilt": [7, 3, 16, Vector2(19, -12), Vector2(18, 8), 9.0, 180.0, 1.6, 35.0, MoveData.Direction.FACING],
}
const TOTALS := {"jab": 19, "down_tilt": 20, "up_tilt": 23, "side_tilt": 26}


func test_normals_match_the_spec() -> void:
	var stats := load("res://fighter/default_stats.tres") as FighterStats
	assert_not_null(stats.moveset, "the default stats have a move set")
	for name: String in NORMALS:
		var move := stats.moveset.get(name) as MoveData
		assert_not_null(move, name)
		if move == null:
			continue
		var expected: Array = NORMALS[name]
		assert_eq(move.startup, expected[0], name + " startup")
		assert_eq(move.active, expected[1], name + " active")
		assert_eq(move.recovery, expected[2], name + " recovery")
		assert_eq(move.hitbox_center, expected[3], name + " hitbox center")
		assert_eq(move.hitbox_size, expected[4], name + " hitbox size")
		assert_eq(move.damage, expected[5], name + " damage")
		assert_eq(move.base_knockback, expected[6], name + " base knockback")
		assert_almost_eq(move.knockback_growth, expected[7], 0.0001, name + " growth")
		assert_eq(move.angle_deg, expected[8], name + " angle")
		assert_eq(move.direction, expected[9], name + " direction")
		assert_eq(move.total_frames(), TOTALS[name], name + " total frames")


func test_hitstun_stats() -> void:
	var stats := load("res://fighter/default_stats.tres") as FighterStats
	assert_almost_eq(stats.hitstun_per_knockback, 0.06, 0.0001)
	assert_eq(stats.min_hitstun, 6)
	assert_eq(stats.hitstun_friction, 300.0)
