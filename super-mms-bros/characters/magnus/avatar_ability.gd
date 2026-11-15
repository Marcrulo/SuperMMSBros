class_name AvatarAbility
extends FighterAbility
## Magnus's elements and Avatar State (docs/specs/characters/magnus.md#the-elements-on-his-card,
## #avatar-state). Each special lights its element when one of its hits lands; with all four lit,
## the next tick he's free he rises (phase `avatar_rise`: frozen, unhittable), then flies freely
## (phase `avatar_fly`: no gravity, contact hits, can't leave the blast zone), then the elements
## go dark. Also draws his element effects (wind arcs, rocks, orbs) and makes the card badge.

enum Element { WATER, FIRE, AIR, EARTH }

## The states he's free to act in (the Avatar State can start).
const FREE: Array[Fighter.State] = [Fighter.State.IDLE, Fighter.State.RUN, Fighter.State.CROUCH,
		Fighter.State.AIR, Fighter.State.HELPLESS]
const OUTLINE := Color(0.1, 0.11, 0.17)
## Each element's color (Element order).
const COLORS: Array[Color] = [Color(0.3, 0.6, 1.0), Color(1.0, 0.5, 0.15),
		Color(0.9, 0.94, 1.0), Color(0.5, 0.68, 0.28)]
const FLAME_CORE := Color(1.0, 0.88, 0.35)
const ROCK := Color(0.52, 0.44, 0.36)
const ROCK_LIGHT := Color(0.66, 0.58, 0.48)
const WIND := Color(1.0, 1.0, 1.0, 0.9)
const WIND_EDGE := Color(0.1, 0.11, 0.17, 0.5)
const AURA := Color(0.7, 0.9, 1.0, 0.18)
## The middle of his body, relative to the feet.
const BODY_MIDDLE := Vector2(0, -16)

## Which elements are lit (Element order).
var lit: Array[bool] = [false, false, false, false]

## The match, kept from the step hooks (to tell a match start from a respawn).
var _match: Match = null
## Victims the move in progress has already been counted for.
var _seen: Array[int] = []
## Ticks before the flight's touch can hit again.
var _rehit_left: int = 0


func _numbers() -> AvatarData:
	return data as AvatarData


func phases() -> Array[StringName]:
	return [&"avatar_rise", &"avatar_fly"]


func light(element: Element) -> void:
	lit[element] = true


func all_lit() -> bool:
	return not (false in lit)


func in_avatar_state() -> bool:
	return fighter.state == Fighter.State.ATTACK \
			and (fighter.move == &"avatar_rise" or fighter.move == &"avatar_fly")


## The element a move of his lights (Air, Earth: the Match's own move hits), or -1.
static func element_of(move: StringName) -> int:
	match move:
		&"up_special":
			return Element.AIR
		&"down_special", &"down_special_dive":
			return Element.EARTH
	return -1


# --- The fighter's tick -----------------------------------------------------------------------


## A spawn at a match start (or reset) darkens the elements; a respawn after a KO keeps them.
func reset() -> void:
	if _match == null or _match.tick == 0:
		lit = [false, false, false, false]
	_seen.clear()
	_rehit_left = 0


## Rise → flight → end, and the start of the Avatar State once he's free with all four lit.
func before_tick(_input: FighterInput) -> void:
	var numbers := _numbers()
	if fighter.state == Fighter.State.ATTACK and fighter.move == &"avatar_rise":
		if fighter.state_frame >= numbers.rise_frames:
			fighter.move = &"avatar_fly"
			fighter.state_frame = 0
			_start_fresh()
	elif fighter.state == Fighter.State.ATTACK and fighter.move == &"avatar_fly":
		if fighter.state_frame >= numbers.fly_frames:
			_end()
	elif all_lit() and fighter.state in FREE:
		fighter.move = &"avatar_rise"
		fighter.state = Fighter.State.ATTACK
		fighter.state_frame = 0
		fighter.velocity = Vector2.ZERO
		fighter.ledge = null
		fighter.stop_fast_fall()
		_start_fresh()


func _start_fresh() -> void:
	fighter.clear_hit_victims()
	_seen.clear()
	_rehit_left = 0


## Back to normal (phase_finished() then ends the flight): air options back, elements dark.
func _end() -> void:
	lit = [false, false, false, false]
	fighter.jumps_left = fighter.stats.max_air_jumps
	fighter.up_special_available = true
	fighter.air_dodge_available = true
	fighter.launched = false
	fighter.stop_fast_fall()


func on_move_started(_move: StringName) -> void:
	_seen.clear()


func phase_finished(move: StringName) -> bool:
	return move == &"avatar_fly" and fighter.state_frame >= _numbers().fly_frames


## The flight's touch hit; the rise has none.
func phase_data(move: StringName) -> MoveData:
	return _numbers().fly_hit if move == &"avatar_fly" else null


## Flying: velocity moves toward the held direction × fly_speed (or to a stop), no gravity; he
## faces the way he flies sideways.
func phase_movement(move: StringName, input: FighterInput) -> bool:
	if move != &"avatar_fly":
		return false
	var numbers := _numbers()
	var aim := Vector2(input.move_x, 0.0)
	if input.up_held:
		aim.y = -1.0
	elif input.down_held:
		aim.y = 1.0
	var target := aim.normalized() * numbers.fly_speed if aim != Vector2.ZERO else Vector2.ZERO
	fighter.velocity = fighter.velocity.move_toward(target, numbers.fly_accel * Fighter.DELTA)
	if input.move_x != 0.0:
		fighter.facing = 1 if input.move_x > 0.0 else -1
	return true


## Frozen during the rise (no physics).
func places_fighter() -> bool:
	return fighter.state == Fighter.State.ATTACK and fighter.move == &"avatar_rise"


func place() -> void:
	fighter.velocity = Vector2.ZERO


func left_floor_in_move() -> bool:
	return in_avatar_state()


func on_floor_in_move(_input: FighterInput) -> bool:
	return in_avatar_state()


func can_be_hit() -> bool:
	return not in_avatar_state()


# --- The Match's step -------------------------------------------------------------------------


## While flying he stays edge_margin inside the blast zone.
func after_ledges(match_: Match) -> void:
	_match = match_
	if not (fighter.state == Fighter.State.ATTACK and fighter.move == &"avatar_fly"):
		return
	var zone := match_.get_stage().blast_zone.grow(-_numbers().edge_margin)
	var at := fighter.global_position
	var kept := Vector2(clampf(at.x, zone.position.x, zone.end.x),
			clampf(at.y, zone.position.y, zone.end.y))
	if kept.x != at.x:
		fighter.velocity.x = 0.0
	if kept.y != at.y:
		fighter.velocity.y = 0.0
	fighter.global_position = kept


## A hit of his up or down special that landed this tick (not blocked) lights its element; the
## flight's touch can hit again rehit_frames ticks after it hit.
func end_step(match_: Match) -> void:
	_match = match_
	if fighter.state != Fighter.State.ATTACK:
		_seen.clear()
		_rehit_left = 0
		return
	var flying := fighter.move == &"avatar_fly"
	for victim in match_.get_fighters():
		var index := victim.player_index
		if victim == fighter or not fighter.has_hit(index) or index in _seen:
			continue
		_seen.append(index)
		if flying:
			_rehit_left = _numbers().rehit_frames
		var element := element_of(fighter.move)
		var blocked := victim.state == Fighter.State.SHIELD \
				or victim.state == Fighter.State.SHIELD_BREAK
		if element >= 0 and not blocked:
			light(element as Element)
	if flying and _rehit_left > 0:
		_rehit_left -= 1
		if _rehit_left == 0:
			fighter.clear_hit_victims()
			_seen.clear()


# --- Presentation -----------------------------------------------------------------------------


func phase_animation(_move: StringName) -> String:
	return "fall"


## His avatar.png strip (2 drawings: the rise, the flight), when it exists.
func strip(textures: Dictionary) -> Array:
	if not in_avatar_state() or not textures.has("avatar"):
		return []
	return [textures["avatar"], fighter.facing, 2, 0 if fighter.move == &"avatar_rise" else 1]


func draw(visuals: FighterVisuals, _animation: String, _frame: int) -> void:
	if fighter.state != Fighter.State.ATTACK:
		return
	var s := fighter.size_scale()
	var moves := fighter.stats.moveset
	match fighter.move:
		&"up_special":
			if moves.up_special.is_active_frame(fighter.state_frame):
				_draw_wind(visuals, s)
		&"down_special":
			if moves.down_special.is_active_frame(fighter.state_frame):
				_draw_rocks(visuals, s)
		&"avatar_rise", &"avatar_fly":
			_draw_orbs(visuals, s)


## Pale wind arcs swirling round him.
func _draw_wind(visuals: FighterVisuals, s: float) -> void:
	var t := fighter.state_frame - fighter.stats.moveset.up_special.startup
	var middle := BODY_MIDDLE * s
	for i in 3:
		var radius := (12.0 + i * 7.0 + t * 0.8) * s
		var start := t * 0.35 + i * TAU / 3.0
		visuals.draw_arc(middle, radius, start, start + 1.6, 8, WIND_EDGE, 3.0)
		visuals.draw_arc(middle, radius, start, start + 1.6, 8, WIND, 1.5)


## Rocks jutting up out of the floor on both sides, rising over the first active frames.
func _draw_rocks(visuals: FighterVisuals, s: float) -> void:
	var down := fighter.stats.moveset.down_special
	var t := clampf(float(fighter.state_frame - down.startup) / 3.0, 0.0, 1.0)
	for side: float in [-1.0, 1.0]:
		for rock: Vector3 in [Vector3(12, 5, 10), Vector3(21, 6, 14), Vector3(30, 4, 8)]:
			var x := rock.x * side * s
			var half := rock.y * s
			var top := -rock.z * t * s
			visuals.draw_colored_polygon(PackedVector2Array([Vector2(x - half - 1, 1),
				Vector2(x - 1, top - 1), Vector2(x + half + 1, 1)]), OUTLINE)
			visuals.draw_colored_polygon(PackedVector2Array([Vector2(x - half, 0),
				Vector2(x - 1, top), Vector2(x + half, 0)]), ROCK)
			visuals.draw_line(Vector2(x - 1, top + 1), Vector2(x - half * 0.5, -1), ROCK_LIGHT)


## A faint glow round him and the four element orbs circling him; during the rise they appear
## one by one.
func _draw_orbs(visuals: FighterVisuals, s: float) -> void:
	var numbers := _numbers()
	var middle := BODY_MIDDLE * s
	visuals.draw_circle(middle, 20.0 * s, AURA)
	var ticks := fighter.state_frame
	if fighter.move == &"avatar_fly":
		ticks += numbers.rise_frames
	var turn := TAU * ticks / float(numbers.orbit_ticks)
	for element: int in Element.values():
		if fighter.move == &"avatar_rise" \
				and fighter.state_frame < element * numbers.rise_frames / 4:
			continue
		var angle := turn + element * TAU / 4.0
		var at := middle + Vector2(cos(angle), sin(angle)) * numbers.orbit_radius * s
		_draw_orb(visuals, element, at)


static func _draw_orb(canvas: CanvasItem, element: int, at: Vector2) -> void:
	canvas.draw_circle(at, 3.5, OUTLINE)
	match element:
		Element.WATER:
			canvas.draw_circle(at, 2.5, COLORS[element])
			canvas.draw_rect(Rect2(at + Vector2(-1, -2), Vector2(1, 1)), Color.WHITE)
		Element.FIRE:
			canvas.draw_circle(at, 2.5, COLORS[element])
			canvas.draw_circle(at + Vector2(0, 0.5), 1.2, FLAME_CORE)
		Element.AIR:
			canvas.draw_circle(at, 2.5, COLORS[element])
			canvas.draw_arc(at, 1.5, 0.0, PI * 1.5, 6, OUTLINE, 1.0)
		Element.EARTH:
			canvas.draw_rect(Rect2(at - Vector2(2.5, 2.5), Vector2(5, 5)), COLORS[element])
			canvas.draw_rect(Rect2(at - Vector2(2.5, 2.5), Vector2(5, 1)), ROCK_LIGHT)


func sounds() -> Dictionary:
	return {"start": {&"avatar_rise": &"charge", &"avatar_fly": &"boost"}}


func make_card_badge(_card: PlayerCard) -> Control:
	var badge := ElementBadge.new()
	badge.ability = self
	badge.position = ElementBadge.AT
	return badge
