class_name PlatformLook
extends Node2D
## Draws the Battlefield's platforms in perspective, in the stage's PlatformStyle
## (docs/specs/match-and-stage.md#platform-look-perspective). Presentation only: collision is
## unchanged. The walkable line runs through the middle of each top face, so fighters stand a
## little toward the back.

## Where the top faces recede toward when there's no camera: the stage's middle.
const STAGE_CENTER_X := 240.0
## How much wider a platform gets per pixel toward the viewer (and narrower per pixel away).
## The same for every platform, like one camera looking at the whole stage.
const PERSPECTIVE := 0.011

## The platform style being drawn. Nothing is drawn without one.
var style: PlatformStyle:
	set(value):
		style = value
		queue_redraw()
## When on, the vanishing x follows the camera; tests turn it off and set vanish_x themselves.
var follow_camera := true
## Shapes skipped because they collapsed to no area (for tests).
var skipped_shapes := 0

## Where the camera looks: top faces recede toward it and side faces turn with it, so panning
## the camera shows the platforms from slightly different angles.
var vanish_x := STAGE_CENTER_X:
	set(value):
		if value != vanish_x:
			vanish_x = value
			queue_redraw()


## Where a point `depth` pixels toward the viewer from the walk line is drawn (negative depth =
## away from the viewer). At depth 0 it's x itself, so top faces match the collision there.
static func perspective_x(x: float, depth: float, vanish: float) -> float:
	return vanish + (x - vanish) * (1.0 + PERSPECTIVE * depth)


## False for a shape that has collapsed to (almost) no area, which Godot can't fill: a side face
## seen exactly edge-on, when the camera looks along a platform's end.
static func is_fillable(points: PackedVector2Array) -> bool:
	return not Geometry2D.triangulate_polygon(points).is_empty()


func _process(_delta: float) -> void:
	if not follow_camera:
		return
	var camera := get_viewport().get_camera_2d()
	vanish_x = camera.get_screen_center_position().x if camera else STAGE_CENTER_X


func _draw() -> void:
	if style == null:
		return
	# x, width (the collision, along the walk line), walk line y, top-face depth behind / in
	# front of the walk line, front-face bands, underside depth, corner blocks.
	_platform(96, 288, 192, 8, 6, style.main_bands, 12, style.quoins if style.has_quoins else null)
	# Shadows of the thin platforms, cast straight down onto the main platform's top face, in the
	# same depth band the platform occupies (4 px behind its walk line to 3 px in front).
	_shadow(132, 72, 192, 4, 3, style.shadow)
	_shadow(276, 72, 192, 4, 3, style.shadow)
	_shadow(204, 72, 192, 4, 3, style.far_shadow)
	_platform(132, 72, 160, 4, 3, style.thin_bands, 0, null)
	_platform(276, 72, 160, 4, 3, style.thin_bands, 0, null)
	_platform(204, 72, 128, 4, 3, style.thin_bands, 0, null)


## `x` at `depth` pixels toward the viewer from the walk line (negative = away from the viewer).
func _x_at(x: float, depth: float) -> float:
	return perspective_x(x, depth, vanish_x)


func _shadow(x: float, width: float, floor_y: float, back: float, front: float,
		color: Color) -> void:
	_polygon(PackedVector2Array([
		Vector2(_x_at(x, front), floor_y + front), Vector2(_x_at(x + width, front), floor_y + front),
		Vector2(_x_at(x + width, -back), floor_y - back), Vector2(_x_at(x, -back), floor_y - back),
	]), color)


func _platform(x: float, width: float, walk_y: float, back: float, front: float,
		bands: Array, under: float, quoins: Variant) -> void:
	var front_y := walk_y + front
	var back_y := walk_y - back
	# The top face matches the collision exactly along the walk line: wider in front of it,
	# narrower behind it. The front face is as wide as the top face's front edge.
	var back_left := _x_at(x, -back)
	var back_right := _x_at(x + width, -back)
	var left := roundf(_x_at(x, front))
	var right := roundf(_x_at(x + width, front))
	width = right - left
	_polygon(PackedVector2Array([
		Vector2(left, front_y), Vector2(right, front_y),
		Vector2(back_right, back_y), Vector2(back_left, back_y),
	]), style.top)
	draw_rect(Rect2(back_left, back_y, back_right - back_left, 1), style.top_edge)
	# Side face: an end is visible only if it faces the middle of the screen, where the "camera" is.
	var face_height := 0.0
	for band: Array in bands:
		face_height += band[1]
	var edge_color: Color = bands[0][2]
	if right < vanish_x:
		_side_face(right, front_y, back_right, back_y, face_height, edge_color)
	elif left > vanish_x:
		_side_face(left, front_y, back_left, back_y, face_height, edge_color)
	# Front face: the style's bands, top to bottom.
	var y := front_y
	var brick_row := 0
	for band: Array in bands:
		var height: float = band[1]
		match band[0]:
			"solid":
				draw_rect(Rect2(left, y, width, height), band[2])
			"brick":
				for row in int(height / 4.0):
					_brick_row(left, width, y + row * 4, brick_row, band[2], band[3], band[4])
					brick_row += 1
			"glass":
				_glass(left, width, y, height, band[2], band[3], band[4])
			"panel":
				_panels(left, width, y, height, band[2], band[3])
		y += height
	if quoins != null:
		_quoins(left, right, front_y, face_height, quoins)
	# Underside, narrowing as it goes down.
	if under > 0.0:
		_polygon(PackedVector2Array([
			Vector2(left, y), Vector2(right, y),
			Vector2(right - 20, y + under), Vector2(left + 20, y + under),
		]), style.under)


## The end of a platform, from the front face's edge back to the top face's back corner.
func _side_face(front_x: float, front_y: float, back_x: float, back_y: float, height: float,
		edge_color: Color) -> void:
	_polygon(PackedVector2Array([
		Vector2(front_x, front_y), Vector2(back_x, back_y),
		Vector2(back_x, back_y + height), Vector2(front_x, front_y + height),
	]), style.side)
	draw_line(Vector2(front_x, front_y), Vector2(back_x, back_y), edge_color)
	draw_line(Vector2(front_x, front_y + height - 1), Vector2(back_x, back_y + height - 1), style.under)


## One row of bricks: 3 px of brick, then a 1 px mortar line; bricks 8 px wide, every other row
## shifted by half a brick.
func _brick_row(left: float, width: float, y: float, row: int, brick: Color, dark: Color,
		mortar: Color) -> void:
	draw_rect(Rect2(left, y, width, 4), mortar)
	var offset := 0.0 if row % 2 == 0 else -4.0
	var column := 0
	var bx := left + offset
	while bx < left + width:
		var x0 := maxf(bx, left)
		var x1 := minf(bx + 7.0, left + width)
		if x1 > x0:
			var color := dark if (column * 7 + row * 3) % 5 == 0 else brick
			draw_rect(Rect2(x0, y, x1 - x0, 3), color)
		bx += 8.0
		column += 1


## A band of windows: blue glass, a light reflection line at the top, thin dark frames every
## 12 px, and a faint diagonal glint in every third pane.
func _glass(left: float, width: float, y: float, height: float, glass: Color, highlight: Color,
		frame: Color) -> void:
	draw_rect(Rect2(left, y, width, height), glass)
	draw_rect(Rect2(left, y, width, 1), highlight)
	var pane := 0
	var fx := left
	while fx < left + width:
		draw_rect(Rect2(fx, y, 1, height), frame)
		if pane % 3 == 1 and height > 3:
			for i in int(height) - 2:
				draw_rect(Rect2(fx + 3 + i, y + height - 2 - i, 1, 1), highlight)
		fx += 12.0
		pane += 1
	draw_rect(Rect2(left + width - 1, y, 1, height), frame)


## Concrete panels with a darker joint every 24 px.
func _panels(left: float, width: float, y: float, height: float, color: Color, seam: Color) -> void:
	draw_rect(Rect2(left, y, width, height), color)
	var sx := left + 24.0
	while sx < left + width:
		draw_rect(Rect2(sx, y, 1, height), seam)
		sx += 24.0


## Sandstone corner blocks at both ends, alternating long and short every 4 px.
func _quoins(left: float, right: float, top: float, height: float, color: Color) -> void:
	var row := 0
	var qy := top + 2.0
	while qy < top + height:
		var length := 6.0 if row % 2 == 0 else 3.0
		var block_height := minf(3.0, top + height - qy)
		draw_rect(Rect2(left, qy, length, block_height), color)
		draw_rect(Rect2(right - length, qy, length, block_height), color)
		qy += 4.0
		row += 1


## Draws a filled shape, skipping one that has collapsed to a line (no area): that happens to a
## side face when the camera looks straight along a platform's end, and Godot can't fill it.
func _polygon(points: PackedVector2Array, color: Color) -> void:
	if not is_fillable(points):
		skipped_shapes += 1
		return
	draw_colored_polygon(points, color)
