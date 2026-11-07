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


func test_specials_match_the_spec() -> void:
	var moves := (load("res://fighter/default_stats.tres") as FighterStats).moveset
	var neutral := moves.neutral_special as MoveData
	assert_eq([neutral.startup, neutral.active, neutral.recovery], [3, 4, 18])
	assert_eq(neutral.hitbox_center, Vector2(16, -13))
	assert_eq(neutral.hitbox_size, Vector2(16, 12))
	assert_eq([neutral.damage, neutral.base_knockback, neutral.knockback_growth, neutral.angle_deg], [8.0, 200.0, 2.0, 38.0])
	assert_eq([neutral.charge_frames, neutral.charge_damage, neutral.charge_knockback], [60, 14.0, 200.0])
	var down := moves.down_special as MoveData
	assert_eq([down.startup, down.active, down.recovery], [10, 6, 20])
	assert_eq(down.hitbox_center, Vector2(0, -9))
	assert_eq(down.hitbox_size, Vector2(56, 18))
	assert_eq([down.damage, down.base_knockback, down.knockback_growth, down.angle_deg], [10.0, 220.0, 1.5, 80.0])
	assert_eq(down.direction, MoveData.Direction.AWAY)
	assert_eq(down.dive_speed, 360.0)
	var side := moves.side_special as MoveData
	assert_eq([side.startup, side.active, side.recovery], [10, 0, 20])
	assert_eq(side.hitbox_center, Vector2(16, -13))
	assert_eq(side.hitbox_size, Vector2(8, 6))
	assert_eq([side.damage, side.base_knockback, side.knockback_growth, side.angle_deg], [5.0, 90.0, 0.5, 30.0])
	assert_eq([side.projectile_speed, side.projectile_lifetime], [240.0, 120])
	var up := moves.up_special as MoveData
	assert_eq([up.startup, up.active, up.recovery], [4, 12, 0])
	assert_eq(up.hitbox_center, Vector2(0, -14))
	assert_eq(up.hitbox_size, Vector2(20, 30))
	assert_eq([up.damage, up.base_knockback, up.knockback_growth, up.angle_deg], [6.0, 150.0, 0.8, 85.0])
	assert_eq(up.direction, MoveData.Direction.AWAY)
	assert_eq([up.launch_speed, up.drift_speed], [360.0, 80.0])


func test_shield_stats() -> void:
	var stats := load("res://fighter/default_stats.tres") as FighterStats
	assert_eq(stats.shield_max, 100.0)
	assert_almost_eq(stats.shield_drain, 0.25, 0.0001)
	assert_almost_eq(stats.shield_regen, 0.15, 0.0001)
	assert_almost_eq(stats.shield_damage_scale, 1.5, 0.0001)
	assert_eq(stats.shield_drop_frames, 7)
	assert_eq(stats.shield_break_frames, 120)
	assert_eq(stats.shield_reset_health, 30.0)
	assert_eq(stats.block_pushback, 60.0)
	assert_eq(stats.helpless_air_speed, 54.0)
