class_name SongAbility
extends FighterAbility
## Nina's lullaby (docs/specs/characters/nina.md#down-special--lullaby): her down special, on the
## ground or in the air, is a song (phase `song`). She stands still (hovering in the air), and while
## the song is out every other fighter within its radius falls asleep — shield or not — once per
## song. Sleep is the shared stun (Fighter.stun()); a SleepMark shows the "z"s.

## A new note leaves her mouth every this many ticks while the song is out.
const NOTE_EVERY := 5
## Ticks a note takes to float out to the song's radius.
const NOTE_LIFE := 30
## The notes' colors (pink, sky, butter, mint) and their outline.
const NOTE_COLORS: Array[Color] = [Color("#ff9ad5"), Color("#8fd3ff"), Color("#ffe27a"),
	Color("#9ff0b8")]
const NOTE_OUTLINE := Color(0.1, 0.11, 0.17)
## A note's pixels (x, y, w, h) around its center, at 1 game px each: the head (bottom left), the
## stem (right of it, going up) and the flag (off the stem's top).
const NOTE_RECTS: Array[Rect2] = [Rect2(-3, 1, 4, 2), Rect2(-2, 0, 2, 1), Rect2(-2, 3, 2, 1),
	Rect2(0, -5, 1, 6), Rect2(1, -5, 1, 1), Rect2(2, -4, 1, 2)]

## The arc the notes spread over (radians, centred straight up).
const ARC := PI + 0.6
## The singing drawings in turn while the song is out.
const SWAY: Array[int] = [1, 2, 3, 2]

## Player indexes this song has already put to sleep.
var _slept: Array[int] = []


func _numbers() -> SongData:
	return data as SongData


func _move_data() -> MoveData:
	return fighter.stats.moveset.get(slot) as MoveData


func _singing() -> bool:
	return fighter.state == Fighter.State.ATTACK and fighter.move == &"song"


func phases() -> Array[StringName]:
	return [&"song"]


func reset() -> void:
	_slept.clear()


## Down+B sings, on the ground and in the air.
func pick_special(input: FighterInput, choice: StringName) -> StringName:
	if Fighter.special_direction(input) != slot:
		return choice
	return &"song"


func on_move_started(move: StringName) -> void:
	if move == &"song":
		_slept.clear()


## Its move's own frames (no hitbox).
func phase_data(_move: StringName) -> MoveData:
	return _move_data()


func phase_finished(_move: StringName) -> bool:
	return fighter.state_frame >= _move_data().total_frames()


## No steering: she slides to a stop; in the air she sinks no faster than hover_fall_speed.
func phase_movement(_move: StringName, _input: FighterInput) -> bool:
	var stats := fighter.stats
	var on_floor := fighter.is_on_floor() and fighter.velocity.y >= 0.0
	var friction := stats.ground_friction if on_floor else stats.air_friction
	fighter.velocity.x = move_toward(fighter.velocity.x, 0.0, friction * Fighter.DELTA)
	fighter.velocity.y = minf(fighter.velocity.y + stats.gravity * Fighter.DELTA,
			_numbers().hover_fall_speed)
	return true


## True on the frames the song is out.
func song_out() -> bool:
	if not _singing():
		return false
	var move_data := _move_data()
	var frame := fighter.state_frame
	return frame >= move_data.startup and frame < move_data.startup + move_data.active


## The song's center in world coordinates.
func voice_point() -> Vector2:
	var voice := _numbers().voice
	return fighter.global_position + Vector2(voice.x * fighter.facing, voice.y) * fighter.size_scale()


## Everyone else the song reaches falls asleep (once per song), with a SleepMark over them.
func spawn_entities(match_: Match) -> void:
	if not song_out():
		return
	var numbers := _numbers()
	var center := voice_point()
	var reach := numbers.radius * fighter.size_scale()
	for victim in match_.get_fighters():
		var index := victim.player_index
		if victim == fighter or index in _slept or not victim.can_be_hit():
			continue
		var box := victim.get_hurtbox_rect()
		var nearest := center.clamp(box.position, box.end)
		if nearest.distance_to(center) > reach:
			continue
		_slept.append(index)
		victim.stun(numbers.sleep_ticks)
		var mark := SleepMark.new()
		match_.add_entity(mark)
		mark.setup(fighter.player_index, victim, numbers.sleep_ticks)


# --- Presentation -----------------------------------------------------------------------------


func phase_animation(_move: StringName) -> String:
	return String(slot)


## The breath in for the startup, then swaying back and forth (drawings 1, 2, 3, 2, …, 10 ticks
## each) while the song is out, then the hands lowering.
func drawing(_animation: String, frame: int) -> int:
	if fighter.move != &"song":
		return frame
	var move_data := _move_data()
	var now := fighter.state_frame
	if now < move_data.startup:
		return 0
	if now < move_data.startup + move_data.active:
		return SWAY[int((now - move_data.startup) / 10.0) % SWAY.size()]
	return 4


## The notes floating out of her mouth to the song's radius (one every NOTE_EVERY ticks while the
## song is out; each lives NOTE_LIFE ticks), fading at the edge.
func draw(visuals: FighterVisuals, _animation: String, _frame: int) -> void:
	if not _singing():
		return
	var move_data := _move_data()
	var now := fighter.state_frame
	var first := move_data.startup
	var last := move_data.startup + move_data.active - 1
	var center := voice_point() - fighter.global_position
	var reach := _numbers().radius * fighter.size_scale()
	var n := 0
	while first + n * NOTE_EVERY <= mini(now, last):
		var age := now - (first + n * NOTE_EVERY)
		if age < NOTE_LIFE:
			_draw_note(visuals, n, age, center, reach)
		n += 1


func _draw_note(visuals: FighterVisuals, n: int, age: int, center: Vector2, reach: float) -> void:
	var t := age / float(NOTE_LIFE)
	# Spread over the upper arc (a little below level on both sides, never into the floor), by
	# the golden ratio, starting upward and to her front.
	var spread := fposmod(0.5 + n * 0.618034, 1.0)
	var angle := -PI / 2.0 + (spread - 0.5) * ARC * fighter.facing
	var out := Vector2(cos(angle), sin(angle))
	var side := Vector2(-out.y, out.x)
	var at := center + out * reach * (0.25 + 0.75 * t) + side * sin(t * TAU * 1.5 + n) * 3.0
	at = at.round()
	var color: Color = NOTE_COLORS[n % NOTE_COLORS.size()]
	var alpha := 1.0 if t < 0.7 else 1.0 - (t - 0.7) / 0.3
	var outline := Color(NOTE_OUTLINE, alpha)
	color.a = alpha
	for rect in NOTE_RECTS:
		visuals.draw_rect(Rect2(at + rect.position - Vector2.ONE, rect.size + Vector2(2, 2)), outline)
	for rect in NOTE_RECTS:
		visuals.draw_rect(Rect2(at + rect.position, rect.size), color)


## Her own sound as the song phase starts (docs/specs/sound.md#character-sounds).
func sounds() -> Dictionary:
	var sound := _numbers().sound
	if sound == null:
		return {}
	return {"start": {&"song": &"nina_sing"}, "streams": {&"nina_sing": sound}}
