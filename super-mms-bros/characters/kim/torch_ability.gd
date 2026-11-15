class_name TorchAbility
extends FighterAbility
## Kim's torch (docs/specs/characters/kim.md#kim--handyman): his side special is a small
## flamethrower. It's the move's own hitbox for its active frames (no projectile), made to hit
## the same fighter again every `hit_interval` ticks.

const OUTLINE := Color(0.1, 0.11, 0.17)
const GRIP := Color(0.2, 0.21, 0.26)
const STEEL := Color(0.74, 0.77, 0.84)
const STEEL_DARK := Color(0.5, 0.54, 0.62)
const RED := Color(0.85, 0.15, 0.2)
const TANK := Color(0.93, 0.94, 0.96)
const TANK_SHADE := Color(0.72, 0.76, 0.84)
const BRASS := Color(0.85, 0.65, 0.2)
const FLAME := Color(1.0, 0.55, 0.12)
const FLAME_CORE := Color(1.0, 0.9, 0.35)
## The torch in his hands (relative to the feet, facing right), and where the propane tank stands
## on the floor behind him.
const HELD := Vector2(7, -14)
const TANK_AT := -17.0
const WAND := 14.0


func _numbers() -> TorchData:
	return data as TorchData


func replaces(move: StringName) -> bool:
	return move == &"side_special"  # No projectile.


## Forgets who the flame hit every `hit_interval` ticks, so it hits them again.
func move_tick(_input: FighterInput) -> bool:
	if fighter.move != slot:
		return false
	var since := fighter.state_frame - (fighter.stats.moveset.get(slot) as MoveData).startup
	if since > 0 and since % _numbers().hit_interval == 0:
		fighter.clear_hit_victims()
	return false


## A rectangle given in facing-right coordinates, mirrored to his facing side.
func _r(x: float, y: float, w: float, h: float) -> Rect2:
	var f := float(fighter.facing)
	return Rect2(minf(x * f, (x + w) * f), y, w, h)


## The torch for the whole move: a black grip, a long steel wand and a burner head with a red tip
## in his hands, a hose to a white propane tank (on the floor behind him, or on his back in the
## air), and the flame flickering along the hitbox while it's out.
func draw(visuals: FighterVisuals, _animation: String, _frame: int) -> void:
	if fighter.state != Fighter.State.ATTACK or fighter.move != slot:
		return
	var f := float(fighter.facing)
	var move_data := fighter.stats.moveset.get(slot) as MoveData
	var at := Vector2(HELD.x * f, HELD.y)
	# The propane tank: standing on the floor, or carried on his back in the air.
	var tank_x: float = TANK_AT
	var tank_y: float = -9.0
	if not fighter.is_on_floor():
		tank_x = -11.0
		tank_y = -24.0
	visuals.draw_rect(_r(tank_x - 1.0, tank_y - 1.0, 7, 10), OUTLINE)
	visuals.draw_rect(_r(tank_x, tank_y, 5, 8), TANK)
	visuals.draw_rect(_r(tank_x + 3.0, tank_y, 2, 8), TANK_SHADE)
	visuals.draw_rect(_r(tank_x + 1.0, tank_y - 2.0, 3, 1), BRASS)
	# The hose from the tank's valve to the grip.
	var hose := Hose.curve(Vector2((tank_x + 3.0) * f, tank_y - 2.0),
		Vector2((tank_x + HELD.x) / 2.0 * f, 3.0), Vector2((HELD.x - 2.0) * f, HELD.y + 1.0))
	visuals.draw_polyline(hose, OUTLINE, 2.0)
	visuals.draw_polyline(hose, GRIP, 1.0)
	# Grip, wand, burner head, red tip.
	visuals.draw_rect(_r(HELD.x - 2.0, at.y - 1.5, 5, 3), OUTLINE)
	visuals.draw_rect(_r(HELD.x - 1.0, at.y - 0.5, 3, 1), GRIP)
	visuals.draw_rect(_r(HELD.x + 3.0, at.y - 1.0, WAND - 5.0, 2), OUTLINE)
	visuals.draw_rect(_r(HELD.x + 3.0, at.y - 0.5, WAND - 5.0, 1), STEEL)
	visuals.draw_rect(_r(HELD.x + WAND - 2.0, at.y - 2.0, 4, 4), OUTLINE)
	visuals.draw_rect(_r(HELD.x + WAND - 1.0, at.y - 1.0, 2, 2), STEEL)
	visuals.draw_rect(_r(HELD.x + WAND + 2.0, at.y - 1.0, 1, 2), RED)
	if not move_data.is_active_frame(fighter.state_frame):
		return
	var hitbox := fighter.hitbox_rect_of(move_data)
	hitbox.position -= fighter.global_position
	var mouth := (HELD.x + WAND + 3.0) * f
	var length := absf(hitbox.end.x - mouth if f > 0.0 else mouth - hitbox.position.x)
	var flicker := 0.85 + 0.15 * sin(fighter.state_frame * 1.9)
	var reach := length * flicker
	var half := hitbox.size.y / 2.0
	# Three tongues of flame, wider near the nozzle, the core hotter and shorter.
	for layer in 2:
		var color := FLAME if layer == 0 else FLAME_CORE
		var scale := 1.0 if layer == 0 else 0.55
		var points := PackedVector2Array()
		var steps := 6
		for i in steps + 1:
			var t := float(i) / steps
			var wobble := sin(fighter.state_frame * 0.9 + t * 7.0) * 1.2
			var width := half * scale * (0.35 + 0.65 * sin(t * PI * 0.9 + 0.3))
			points.append(Vector2(mouth + f * reach * scale * t, at.y - width + wobble))
		for i in range(steps, -1, -1):
			var t := float(i) / steps
			var wobble := sin(fighter.state_frame * 0.9 + t * 7.0) * 1.2
			var width := half * scale * (0.35 + 0.65 * sin(t * PI * 0.9 + 0.3))
			points.append(Vector2(mouth + f * reach * scale * t, at.y + width + wobble))
		visuals.draw_colored_polygon(points, color)
