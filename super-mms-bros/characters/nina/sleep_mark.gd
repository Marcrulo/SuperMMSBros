class_name SleepMark
extends MatchEntity
## The "z"s over a fighter Nina's lullaby put to sleep
## (docs/specs/characters/nina.md#down-special--lullaby): follows the sleeper's head and goes when
## it wakes (or its sleep is over). Added by SongAbility; it changes nothing, drawing only reads.

const FONT_SIZE := 7
## Over the head, a little to the side (px, at normal size).
const HEAD := Vector2(6, -36)
## One "z" rises for this many ticks; the three follow each other this far apart.
const RISE_TICKS := 60
const SPACING := 20
## How far a "z" drifts up and to the side over its rise (px).
const RISE := Vector2(10, -24)

## The fighter asleep.
var sleeper: Fighter
## Ticks since it fell asleep.
var age: int = 0
## How long the sleep lasts.
var ticks: int = 0


func setup(owner: int, asleep: Fighter, sleep_ticks: int) -> void:
	owner_index = owner
	sleeper = asleep
	ticks = sleep_ticks
	_follow()


func advance(_match: Match) -> void:
	age += 1
	_follow()
	queue_redraw()


func _follow() -> void:
	global_position = sleeper.global_position + HEAD * sleeper.size_scale()


func is_finished(_match: Match) -> bool:
	return age >= ticks or sleeper.state != Fighter.State.SHIELD_BREAK


## Three "z"s, one after another, each drifting up and to the side, growing and fading.
func _draw() -> void:
	var font := ThemeDB.fallback_font
	for i in 3:
		if age < i * SPACING:
			continue
		var t := posmod(age - i * SPACING, RISE_TICKS) / float(RISE_TICKS)
		var size := FONT_SIZE + roundi(t * 4.0)
		var at := (RISE * t + Vector2(sin(t * TAU) * 1.5, 0.0)).round()
		var alpha := 1.0 if t < 0.6 else 1.0 - (t - 0.6) / 0.4
		font.draw_string_outline(get_canvas_item(), at, "z", HORIZONTAL_ALIGNMENT_LEFT, -1, size,
				2, Color(0.1, 0.11, 0.17, alpha))
		font.draw_string(get_canvas_item(), at, "z", HORIZONTAL_ALIGNMENT_LEFT, -1, size,
				Color(1, 1, 1, alpha))
