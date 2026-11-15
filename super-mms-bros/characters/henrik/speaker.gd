class_name Speaker
extends MatchEntity
## One of Henrik's loudspeakers (docs/specs/characters/henrik.md#henrik--guitar): stands beside him
## while he plays and blasts whoever is next to it away to its side on every beat; once his jam is
## over (or ends early) it sinks into the floor and is gone. Not solid, can't be hit. Added by
## SpeakerAbility, advanced by the Match; drawing only reads.

## Its picture (docs/specs/characters/henrik.md#henriks-speakers): 2 drawings, drawn at ¾.
const DRAWING := Vector2(24, 32)
const SCALE := 0.75
## Ticks it takes to rise out of the floor when it appears (drawing only).
const RISE_TICKS := 4
const WAVE := Color(1.0, 1.0, 1.0, 0.95)
const WAVE_EDGE := Color(0.1, 0.11, 0.17, 0.6)
## Where the woofer is, from its foot (px, game scale).
const WOOFER := Vector2(0, -8)

var data: SpeakerData
## -1 = left of Henrik (blasts left), 1 = right.
var side: int = 1
## Ticks since it appeared (= his jam tick).
var age: int = 0
## True once it stopped playing: it's sinking.
var sinking := false

var _sink_age: int = 0
## The player indices this blast has hit already.
var _hit: Array[int] = []
var _texture: Texture2D


func setup(owner: int, blasting: int, at: Vector2, speaker_data: SpeakerData,
		character_id: String) -> void:
	owner_index = owner
	side = blasting
	global_position = at
	data = speaker_data
	var path := FighterVisuals.SPRITES_DIR + character_id + "/speaker.png"
	_texture = load(path) as Texture2D if ResourceLoader.exists(path) else null


func behind_fighters() -> bool:
	return true


func removed_with_owner() -> bool:
	return true


## One tick: plays while its owner still jams and the song isn't over, else sinks.
func advance(match_: Match) -> void:
	age += 1
	if data.is_beat(age):
		_hit.clear()
	if not sinking:
		var jam := match_.get_fighter(owner_index).ability(SpeakerAbility) as SpeakerAbility
		if jam == null or not jam.is_jamming() or age >= data.jam_frames:
			sinking = true
	if sinking:
		_sink_age += 1
	queue_redraw()


func is_finished(_match: Match) -> bool:
	return sinking and _sink_age >= data.sink_frames


## True while this beat's blast is out.
func is_blasting() -> bool:
	return not sinking and data.is_blasting(age)


## The blast's hitbox in world coordinates, mirrored to its side.
func get_hitbox_rect() -> Rect2:
	var b := data.blast
	var center := global_position + Vector2(b.hitbox_center.x * side, b.hitbox_center.y)
	return Rect2(center - b.hitbox_size / 2.0, b.hitbox_size)


func collect_hits(match_: Match, hits: Array[Dictionary]) -> void:
	if not is_blasting():
		return
	var box := get_hitbox_rect()
	for victim in match_.get_fighters():
		if victim.player_index == owner_index or victim.player_index in _hit \
				or not victim.can_be_hit():
			continue
		if box.intersects(victim.get_hurtbox_rect()):
			hits.append({
				"victim": victim,
				"move": data.blast,
				"side": side,
				"attacker_x": global_position.x,
				"register": func(index: int) -> void: _hit.append(index),
			})


## How much of it shows above the floor, 0…1 (rising, then sinking).
func shown() -> float:
	if sinking:
		return 1.0 - clampf(float(_sink_age) / data.sink_frames, 0.0, 1.0)
	return clampf(float(age + 1) / RISE_TICKS, 0.0, 1.0)


func _draw() -> void:
	var height := DRAWING.y * shown()
	if _texture != null and height > 0.0:
		# Its top `height` rows, bottom on the floor; mirrored on the left so the side panel is
		# toward Henrik. Drawing 1 (cone out) while blasting.
		var region := Rect2((1 if is_blasting() else 0) * DRAWING.x, 0, DRAWING.x, height)
		var size := region.size * SCALE
		draw_set_transform(Vector2.ZERO, 0.0, Vector2(-side, 1))
		draw_texture_rect_region(_texture, Rect2(-size.x / 2.0, -size.y, size.x, size.y), region)
		draw_set_transform(Vector2.ZERO)
	if is_blasting():
		_draw_waves()
	if FighterVisuals.show_boxes and is_blasting():
		var box := get_hitbox_rect()
		box.position -= global_position
		draw_rect(box, FighterVisuals.HITBOX_ACTIVE_COLOR)


## Three `)` arcs spreading out from the woofer to its side as the blast goes on.
func _draw_waves() -> void:
	var t := float((age - data.first_beat) % data.beat_every) / data.blast_frames  # 0…1
	var reach := data.blast.hitbox_size.x + data.blast.hitbox_center.x - data.blast.hitbox_size.x / 2.0
	var facing := 0.0 if side > 0 else PI
	for i in 3:
		var r := 6.0 + (reach - 6.0) * clampf(t + i * 0.22, 0.0, 1.0) * 0.85
		var half := 0.75 - i * 0.08
		var from := facing - half
		var to := facing + half
		draw_arc(WOOFER, r, from, to, 8, WAVE_EDGE, 3.0)
		draw_arc(WOOFER, r, from, to, 8, WAVE, 1.5)
