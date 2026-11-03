extends GutTest
## Starting movement values from docs/specs/fighter.md#stats.

const STATS_PATH := "res://fighter/default_stats.tres"


func test_default_stats_load_as_fighter_stats() -> void:
	assert_true(load(STATS_PATH) is FighterStats)


func test_default_stats_match_the_spec() -> void:
	var stats := load(STATS_PATH) as FighterStats
	assert_not_null(stats, "default stats should load")
	if stats == null:
		return
	assert_eq(stats.run_speed, 100.0)
	assert_eq(stats.ground_accel, 1200.0)
	assert_eq(stats.ground_friction, 1200.0)
	assert_eq(stats.air_speed, 90.0)
	assert_eq(stats.air_accel, 400.0)
	assert_eq(stats.air_friction, 150.0)
	assert_eq(stats.gravity, 600.0)
	assert_eq(stats.max_fall_speed, 250.0)
	assert_eq(stats.jump_velocity, 240.0)
	assert_eq(stats.double_jump_velocity, 219.0)
	assert_eq(stats.short_hop_cut, 0.5)
	assert_eq(stats.max_air_jumps, 1)
	assert_eq(stats.drop_through_frames, 10)
