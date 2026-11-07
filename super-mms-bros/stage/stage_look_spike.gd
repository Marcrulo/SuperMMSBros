extends Node2D
## THROWAWAY SPIKE: draws the "perspective brick" platform look, to try it in the game.
## Not part of the design yet; the real version comes from the stage spec once it's agreed.
## The walkable line (collision) is unchanged; the drawing puts it behind the middle of the
## top face, so fighters stand a little toward the back.

const TOP_COLOR := Color("#8a8f99")
const TOP_BACK_EDGE := Color("#b4b9c2")
const TRIM_COLOR := Color("#f4f4f4")
const BRICK_COLOR := Color("#d9653a")
const BRICK_DARK := Color("#b04e30")
const MORTAR_COLOR := Color("#e9d3b8")
const DARK_BAND := Color("#474a55")
const UNDER_COLOR := Color("#2b2d36")
## A platform's end, turned away from the light: shaded brick.
const SIDE_COLOR := Color("#9c4329")
## The thin platforms' shadows on the main platform's top face (light from straight above).
const SHADOW_COLOR := Color("#6c717b")
## The top platform is higher up, so its shadow is fainter.
const FAR_SHADOW_COLOR := Color("#7b808a")
## Where the top faces recede toward when there's no camera: the stage's middle.
const STAGE_CENTER_X := 240.0
## How much wider a platform gets per pixel toward the viewer (and narrower per pixel away).
## The same for every platform, like one camera looking at the whole stage.
const PERSPECTIVE := 0.011


## Where the camera looks: top faces recede toward it and side faces turn with it, so panning
## the camera shows the platforms from slightly different angles.
var _vanish_x := STAGE_CENTER_X


func _process(_delta: float) -> void:
	var camera := get_viewport().get_camera_2d()
	var vanish := camera.get_screen_center_position().x if camera else STAGE_CENTER_X
	if vanish != _vanish_x:
		_vanish_x = vanish
		queue_redraw()


func _draw() -> void:
	# x, width (the collision, along the walk line), walk line y, top-face depth behind / in
	# front of the walk line, rows of bricks, underside depth.
	_platform(96, 288, 192, 8, 6, 3, 12)
	# Shadows of the thin platforms, cast straight down onto the main platform's top face, in the
	# same depth band the platform occupies (4 px behind its walk line to 3 px in front).
	_shadow(132, 72, 192, 4, 3, SHADOW_COLOR)
	_shadow(276, 72, 192, 4, 3, SHADOW_COLOR)
	_shadow(204, 72, 192, 4, 3, FAR_SHADOW_COLOR)
	_platform(132, 72, 160, 4, 3, 1, 0)
	_platform(276, 72, 160, 4, 3, 1, 0)
	_platform(204, 72, 128, 4, 3, 1, 0)


## `x` at `depth` pixels toward the viewer from the walk line (negative = away from the viewer).
func _x_at(x: float, depth: float) -> float:
	return _vanish_x + (x - _vanish_x) * (1.0 + PERSPECTIVE * depth)


func _shadow(x: float, width: float, floor_y: float, back: float, front: float,
		color: Color) -> void:
	draw_colored_polygon(PackedVector2Array([
		Vector2(_x_at(x, front), floor_y + front), Vector2(_x_at(x + width, front), floor_y + front),
		Vector2(_x_at(x + width, -back), floor_y - back), Vector2(_x_at(x, -back), floor_y - back),
	]), color)


func _platform(x: float, width: float, walk_y: float, back: float, front: float,
		brick_rows: int, under: float) -> void:
	var front_y := walk_y + front
	var back_y := walk_y - back
	# The top face matches the collision exactly along the walk line: wider in front of it,
	# narrower behind it. The front face is as wide as the top face's front edge.
	var back_left := _x_at(x, -back)
	var back_right := _x_at(x + width, -back)
	var left := roundf(_x_at(x, front))
	var right := roundf(_x_at(x + width, front))
	width = right - left
	draw_colored_polygon(PackedVector2Array([
		Vector2(left, front_y), Vector2(right, front_y),
		Vector2(back_right, back_y), Vector2(back_left, back_y),
	]), TOP_COLOR)
	draw_rect(Rect2(back_left, back_y, back_right - back_left, 1), TOP_BACK_EDGE)
	# Side face: an end is visible only if it faces the middle of the screen, where the "camera" is.
	var face_height := 16.0 if brick_rows > 1 else 6.0
	if right < _vanish_x:
		_side_face(right, front_y, back_right, back_y, face_height)
	elif left > _vanish_x:
		_side_face(left, front_y, back_left, back_y, face_height)
	# Front face: white trim, bricks, dark band.
	var y := front_y
	draw_rect(Rect2(left, y, width, 2 if brick_rows > 1 else 1), TRIM_COLOR)
	y += 2 if brick_rows > 1 else 1
	for row in brick_rows:
		_brick_row(left, width, y, row)
		y += 4
	draw_rect(Rect2(left, y, width, 2 if brick_rows > 1 else 1), DARK_BAND)
	y += 2 if brick_rows > 1 else 1
	# Underside, narrowing as it goes down.
	if under > 0.0:
		draw_colored_polygon(PackedVector2Array([
			Vector2(left, y), Vector2(right, y),
			Vector2(right - 20, y + under), Vector2(left + 20, y + under),
		]), UNDER_COLOR)


## The end of a platform, from the front face's edge back to the top face's back corner.
func _side_face(front_x: float, front_y: float, back_x: float, back_y: float, height: float) -> void:
	draw_colored_polygon(PackedVector2Array([
		Vector2(front_x, front_y), Vector2(back_x, back_y),
		Vector2(back_x, back_y + height), Vector2(front_x, front_y + height),
	]), SIDE_COLOR)
	draw_line(Vector2(front_x, front_y), Vector2(back_x, back_y), TRIM_COLOR)
	draw_line(Vector2(front_x, front_y + height - 1), Vector2(back_x, back_y + height - 1), DARK_BAND)


## One row of bricks: 3 px of brick, then a 1 px mortar line; bricks 8 px wide, every other row
## shifted by half a brick.
func _brick_row(left: float, width: float, y: float, row: int) -> void:
	draw_rect(Rect2(left, y, width, 4), MORTAR_COLOR)
	var offset := 0.0 if row % 2 == 0 else -4.0
	var column := 0
	var bx := left + offset
	while bx < left + width:
		var x0 := maxf(bx, left)
		var x1 := minf(bx + 7.0, left + width)
		if x1 > x0:
			var color := BRICK_DARK if (column * 7 + row * 3) % 5 == 0 else BRICK_COLOR
			draw_rect(Rect2(x0, y, x1 - x0, 3), color)
		bx += 8.0
		column += 1
