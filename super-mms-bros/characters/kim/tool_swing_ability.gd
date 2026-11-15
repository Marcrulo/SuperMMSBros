class_name ToolSwingAbility
extends FighterAbility
## Kim's tool normals (docs/specs/characters/kim.md#kim--handyman): the move's hitbox and hit are
## the move's own (default pipeline); this stretches the body's five attack drawings over the move's
## own frames (a slow axe) and draws the tool swinging in his hand. Presentation only.

const OUTLINE := Color(0.1, 0.11, 0.17)
const WOOD := Color(0.62, 0.4, 0.2)
const STEEL := Color(0.74, 0.77, 0.84)
const STEEL_DARK := Color(0.5, 0.54, 0.62)
const YELLOW := Color(0.95, 0.75, 0.15)
const RED := Color(0.85, 0.15, 0.2)
## The attack drawings of the body: before the strike, the strike, after it.
const PRE_DRAWINGS := 2
const STRIKE_DRAWING := 2
const POST_DRAWINGS := 2


func _numbers() -> ToolSwingData:
	return data as ToolSwingData


func _move_data() -> MoveData:
	return fighter.stats.moveset.get(slot) as MoveData


## True while this ability's move is in progress.
func _swinging() -> bool:
	return fighter.state == Fighter.State.ATTACK and fighter.move == slot


## The body's drawing for this tick: the first two over the startup, the strike over the active
## frames, the last two over the recovery (`frame` = the shared timing's).
func drawing(_animation: String, frame: int) -> int:
	if not _swinging():
		return frame
	var move_data := _move_data()
	var f := fighter.state_frame
	if f <= move_data.startup:
		return clampi(int(float(f - 1) / maxi(move_data.startup, 1) * PRE_DRAWINGS), 0, PRE_DRAWINGS - 1)
	if f <= move_data.startup + move_data.active:
		return STRIKE_DRAWING
	var after := f - move_data.startup - move_data.active - 1
	return STRIKE_DRAWING + 1 + clampi(int(float(after) / maxi(move_data.recovery, 1) * POST_DRAWINGS),
		0, POST_DRAWINGS - 1)


## Where the tool is and how it points on frame `f`: [angle, pivot].
func pose(f: int) -> Array:
	var tool := _numbers()
	var move_data := _move_data()
	if f <= move_data.startup:
		var u := clampf(float(f) / maxi(move_data.startup, 1), 0.0, 1.0)
		u = u * u * (3.0 - 2.0 * u)
		return [lerpf(tool.rest_angle, tool.wind_angle, u), tool.rest_pivot.lerp(tool.wind_pivot, u)]
	if f <= move_data.startup + move_data.active:
		var u := float(f - move_data.startup - 1) / maxi(move_data.active - 1, 1)
		return [lerpf(tool.hit_from_angle, tool.hit_to_angle, u), tool.hit_from_pivot.lerp(tool.hit_to_pivot, u)]
	var u := clampf(float(f - move_data.startup - move_data.active) / maxi(move_data.recovery, 1), 0.0, 1.0)
	return [lerpf(tool.hit_to_angle, tool.rest_angle, u), tool.hit_to_pivot.lerp(tool.rest_pivot, u)]


func draw(visuals: FighterVisuals, _animation: String, _frame: int) -> void:
	if not _swinging():
		return
	var held := pose(fighter.state_frame)
	var f := float(fighter.facing)
	var at: Vector2 = held[1]
	visuals.draw_set_transform(Vector2(at.x * f, at.y), deg_to_rad(held[0]) * f, Vector2(f, 1.0))
	match _numbers().tool:
		&"hammer":
			_draw_hammer(visuals)
		&"axe":
			_draw_axe(visuals)
		&"screwdriver":
			_draw_screwdriver(visuals)
	visuals.draw_set_transform(Vector2.ZERO)


## Along +x from the hand: a thin wooden handle with a small claw hammer's head at the end.
func _draw_hammer(v: FighterVisuals) -> void:
	v.draw_rect(Rect2(-1, -1.5, 11, 3), OUTLINE)
	v.draw_rect(Rect2(0, -0.5, 9, 1), WOOD)
	v.draw_rect(Rect2(8, -4, 4, 7), OUTLINE)
	v.draw_rect(Rect2(9, -3, 2, 5), STEEL)
	v.draw_rect(Rect2(9, -3, 2, 1), Color.WHITE)


## Along +x from the hand: a slim wooden handle with a small steel blade at the end.
func _draw_axe(v: FighterVisuals) -> void:
	v.draw_rect(Rect2(-2, -1.5, 22, 3), OUTLINE)
	v.draw_rect(Rect2(-1, -0.5, 20, 1), WOOD)
	var blade := PackedVector2Array([Vector2(15, -1), Vector2(15, -6), Vector2(20, -8),
		Vector2(21, 1)])
	v.draw_colored_polygon(blade, STEEL)
	v.draw_line(Vector2(20, -8), Vector2(21, 1), Color.WHITE, 1.0)
	var outline := blade.duplicate()
	outline.append(blade[0])
	v.draw_polyline(outline, OUTLINE, 1.0)


## Along +x from the hand: a small yellow handle with a red stripe and a thin steel shaft.
func _draw_screwdriver(v: FighterVisuals) -> void:
	v.draw_rect(Rect2(-1, -2, 7, 4), OUTLINE)
	v.draw_rect(Rect2(0, -1, 5, 2), YELLOW)
	v.draw_rect(Rect2(2, -1, 1, 2), RED)
	v.draw_rect(Rect2(6, -1, 10, 2), OUTLINE)
	v.draw_rect(Rect2(6, -0.5, 9, 1), STEEL)
