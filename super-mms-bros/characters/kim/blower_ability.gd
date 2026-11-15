class_name BlowerAbility
extends FighterAbility
## Kim's leaf blower (docs/specs/characters/kim.md#kim--handyman): his down special (no dive,
## also in the air) winds up for the move's `startup` frames, then a gust pushes whoever it hits
## away for no damage. The hit is the move's own (damage 0, growth 0); this only picks the move,
## also in the air, and draws the blower and the wind.

const OUTLINE := Color(0.1, 0.11, 0.17)
const ENGINE := Color(0.82, 0.16, 0.14)
const ENGINE_LIGHT := Color(0.95, 0.35, 0.28)
const TANK := Color(0.92, 0.93, 0.95)
const TUBE := Color(0.2, 0.21, 0.26)
const TUBE_LIGHT := Color(0.36, 0.38, 0.45)
const BAND := Color(0.85, 0.15, 0.2)
const WIND := Color(1.0, 1.0, 1.0, 0.95)
const WIND_EDGE := Color(0.1, 0.11, 0.17, 0.6)
## The blower in his hands (relative to the feet, facing right), and the backpack on his back.
const HELD := Vector2(7, -16)
const PACK := Vector2(-11, -21)


func _numbers() -> BlowerData:
	return data as BlowerData


func pick_special(input: FighterInput, choice: StringName) -> StringName:
	return slot if Fighter.special_direction(input) == slot else choice  # Never a dive.


## A rectangle given in facing-right coordinates, mirrored to his facing side.
func _r(x: float, y: float, w: float, h: float) -> Rect2:
	var f := float(fighter.facing)
	return Rect2(minf(x * f, (x + w) * f), y, w, h)


## The backpack blower for the whole move: the red engine and white fuel tank on his back, a black
## hose over the shoulder to the tube in his hands (red band near the end), and the wind
## streaming out during the gust.
func draw(visuals: FighterVisuals, _animation: String, _frame: int) -> void:
	if fighter.state != Fighter.State.ATTACK or fighter.move != slot:
		return
	var f := float(fighter.facing)
	var move_data := fighter.stats.moveset.get(slot) as MoveData
	var shake := 0.0 if fighter.state_frame > move_data.startup else float(fighter.state_frame % 2)
	# The backpack: frame, engine, its light edge, the fuel tank below, the carrying handle.
	var y := PACK.y + shake * 0.5
	visuals.draw_rect(_r(PACK.x - 1.0, y - 1.0, 8, 13), OUTLINE)
	visuals.draw_rect(_r(PACK.x, y, 6, 7), ENGINE)
	visuals.draw_rect(_r(PACK.x, y, 6, 1), ENGINE_LIGHT)
	visuals.draw_rect(_r(PACK.x, y + 7.0, 6, 4), TANK)
	visuals.draw_rect(_r(PACK.x + 1.0, y - 2.0, 4, 1), OUTLINE)
	# The hose: from the engine round his side to the handle.
	var hose := Hose.curve(Vector2((PACK.x + 6.0) * f, PACK.y + 3.0),
		Vector2(-1.0 * f, PACK.y + 6.0), Vector2((HELD.x - 1.0) * f, HELD.y))
	visuals.draw_polyline(hose, OUTLINE, 2.0)
	visuals.draw_polyline(hose, TUBE_LIGHT, 1.0)
	# The tube: a handle in his hands, then a slim black tube with a red band near its end.
	var at := Vector2(HELD.x * f, HELD.y + shake * 0.5)
	visuals.draw_rect(_r(HELD.x - 2.0, at.y - 2.0, 16, 4), OUTLINE)
	visuals.draw_rect(_r(HELD.x - 1.0, at.y - 1.0, 14, 2), TUBE)
	visuals.draw_rect(_r(HELD.x - 1.0, at.y - 1.0, 14, 1), TUBE_LIGHT)
	visuals.draw_rect(_r(HELD.x + 9.0, at.y - 1.5, 1, 3), BAND)
	if not move_data.is_active_frame(fighter.state_frame):
		return
	var hitbox := fighter.hitbox_rect_of(move_data)
	hitbox.position -= fighter.global_position
	var lines := _numbers().wind_lines
	for i in lines:
		# Each line streams along the hitbox, in a staggered cycle.
		var row := hitbox.position.y + hitbox.size.y * (i + 0.5) / lines
		var phase := fposmod(float(fighter.state_frame) * 0.12 + i * 0.37, 1.0)
		var start := (hitbox.position.x if f > 0.0 else hitbox.end.x) + f * hitbox.size.x * phase * 0.7
		var from := Vector2(start, row)
		var to := Vector2(start + 14.0 * f, row)
		visuals.draw_line(from, to, WIND_EDGE, 3.0)
		visuals.draw_line(from, to, WIND, 1.5)
