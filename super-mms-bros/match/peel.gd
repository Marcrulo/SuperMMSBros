class_name Peel
extends Node2D
## A banana peel (docs/specs/moves.md#fidusen--banana-book-vine): falls to the floor below, then
## lies there until someone slips on it or its time is up. Owned and advanced by the Match, one
## tick at a time; drawing only reads.

const DELTA := 1.0 / 60.0
const SCALE := 0.75

## Player index of the fighter who placed it (it never trips them).
var owner_index: int
var data: PeelData
## Ticks since it appeared.
var age: int = 0
## Lying on a floor (it can trip someone); false while falling.
var landed := false
## The y of the floor it falls to (INF: none, it falls away).
var floor_y: float = INF

var _texture: Texture2D


func setup(owner: int, at: Vector2, peel_data: PeelData, floor_at: float, character_id: String) -> void:
	owner_index = owner
	global_position = at
	data = peel_data
	floor_y = floor_at
	landed = absf(at.y - floor_at) < 0.5
	if landed:
		global_position.y = floor_at
	var path := FighterVisuals.SPRITES_DIR + character_id + "/peel.png"
	_texture = load(path) as Texture2D if ResourceLoader.exists(path) else null


## One tick: falls until it reaches its floor.
func advance() -> void:
	age += 1
	if not landed:
		global_position.y += data.fall_speed * DELTA
		if global_position.y >= floor_y:
			global_position.y = floor_y
			landed = true
	queue_redraw()


func is_expired(blast_zone: Rect2) -> bool:
	return age >= data.lifetime or not blast_zone.has_point(global_position)


## Where it trips: its size, bottom center at its position.
func get_trip_rect() -> Rect2:
	return Rect2(global_position - Vector2(data.size.x / 2.0, data.size.y), data.size)


func _draw() -> void:
	if _texture != null:
		var size := _texture.get_size() * SCALE
		draw_texture_rect(_texture, Rect2(-size.x / 2.0, -size.y, size.x, size.y), false)
	if FighterVisuals.show_boxes:
		var box := get_trip_rect()
		box.position -= global_position
		draw_rect(box, FighterVisuals.HITBOX_ACTIVE_COLOR)
