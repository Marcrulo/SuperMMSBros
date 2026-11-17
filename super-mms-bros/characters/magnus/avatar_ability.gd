class_name AvatarAbility
extends FighterAbility
## Magnus's elements and Avatar State (docs/specs/characters/magnus.md#the-elements-on-his-card,
## #avatar-state). Each special lights its element when one of its hits lands; with all four lit,
## the next tick he's free he rises (phase `avatar_rise`: frozen, unhittable), then flies freely
## (phase `avatar_fly`: no gravity, contact hits, can't leave the blast zone), then the elements
## go dark. Also draws his element effects (wind arcs, rocks, the elements swirling round him in
## the Avatar State) and makes the card badge.

enum Element { WATER, FIRE, AIR, EARTH }

## The states he's free to act in (the Avatar State can start).
const FREE: Array[Fighter.State] = [Fighter.State.IDLE, Fighter.State.RUN, Fighter.State.DASH,
		Fighter.State.SPRINT, Fighter.State.CROUCH, Fighter.State.AIR, Fighter.State.HELPLESS]
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
## His eye glow: halo and core colors, its pulse (ticks per cycle) and the rise's fade-in (ticks).
const EYE_HALO := Color(0.6, 0.95, 1.0, 0.55)
const EYE_CORE := Color(0.92, 1.0, 1.0, 1.0)
const EYE_PULSE_TICKS := 20
const EYE_FADE_IN := 15
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
			_draw_front(visuals, s)


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


## Where his eyes are now (relative to the feet, at his facing and size), or none outside the
## Avatar State.
func eye_points() -> PackedVector2Array:
	var points := PackedVector2Array()
	if not in_avatar_state():
		return points
	var eyes := _numbers().rise_eyes if fighter.move == &"avatar_rise" else _numbers().fly_eyes
	for eye in eyes:
		points.append(Vector2(eye.x * fighter.facing, eye.y) * fighter.size_scale())
	return points


## A glow over each eye: a soft halo and a bright core, pulsing; fading in during the rise.
func _draw_eye_glow(visuals: FighterVisuals, s: float) -> void:
	var strength := 1.0
	if fighter.move == &"avatar_rise":
		strength = clampf(fighter.state_frame / float(EYE_FADE_IN), 0.0, 1.0)
	var pulse := 0.5 + 0.5 * sin(TAU * fighter.state_frame / float(EYE_PULSE_TICKS))
	for eye in eye_points():
		var halo := EYE_HALO
		halo.a *= strength * (0.7 + 0.3 * pulse)
		visuals.draw_circle(eye, (2.5 + 0.8 * pulse) * s, halo)
		var core := EYE_CORE
		core.a *= strength
		visuals.draw_circle(eye, 1.1 * s, core)


## The elements' rings: [long radius (× orbit_radius), short radius (px), tilt (radians), turns
## per orbit_ticks, starting angle], in Element order.
const RINGS: Array[Array] = [[1.0, 8.0, -0.45, 1.0, 0.0], [1.0, 8.0, 0.5, 1.0, PI],
		[1.25, 6.0, 0.12, 1.4, PI / 2.0], [0.95, 10.0, -0.08, 0.5, 0.0]]
## A ribbon's trail: how far round its ring it reaches (radians) and its samples.
const TRAIL := PI * 1.3
const TRAIL_SAMPLES := 30
## Ticks between the elements appearing during the rise, and how long each takes to grow in.
const APPEAR_TICKS := 15
const GROW_TICKS := 12
const ROCKS := 6
const WATER_CORE := Color(0.72, 0.92, 1.0)
const WATER_EDGE := Color(0.08, 0.2, 0.45)
const FIRE_EDGE := Color(0.45, 0.08, 0.05)
const FIRE_BODY := Color(0.95, 0.38, 0.1)
const AIR := Color(1.0, 1.0, 1.0, 0.9)
const AIR_EDGE := Color(0.45, 0.6, 0.78, 0.55)
const ROCK_DARK := Color(0.3, 0.25, 0.21)


## Behind him: the faint glow and the far side of the elements' rings.
func draw_behind(visuals: FighterVisuals, _animation: String, _frame: int) -> void:
	if not in_avatar_state():
		return
	var s := fighter.size_scale()
	visuals.draw_circle(BODY_MIDDLE * s, 20.0 * s, AURA)
	_draw_elements(visuals, s, false)


## In front of him: his glowing eyes and the near side of the elements' rings.
func _draw_front(visuals: FighterVisuals, s: float) -> void:
	_draw_eye_glow(visuals, s)
	_draw_elements(visuals, s, true)


## Ticks since the Avatar State began.
func _avatar_ticks() -> int:
	if fighter.move == &"avatar_fly":
		return fighter.state_frame + _numbers().rise_frames
	return fighter.state_frame


## How far an element has appeared (0…1): during the rise one after another, then all of it.
func _grown(element: int) -> float:
	return clampf(float(_avatar_ticks() - element * APPEAR_TICKS) / GROW_TICKS, 0.0, 1.0)


## A point on an element's ring at angle `phi` (relative to the feet, at size `s`).
func _ring_point(element: int, phi: float, s: float) -> Vector2:
	var ring: Array = RINGS[element]
	var p := Vector2(cos(phi) * _numbers().orbit_radius * ring[0], sin(phi) * ring[1])
	return (BODY_MIDDLE + p.rotated(ring[2])) * s


## Where an element's head is on its ring now (radians).
func _head_angle(element: int) -> float:
	var ring: Array = RINGS[element]
	return ring[4] + TAU * ring[3] * _avatar_ticks() / float(_numbers().orbit_ticks)


## The near (front) or far (behind) side of all four elements.
func _draw_elements(visuals: FighterVisuals, s: float, front: bool) -> void:
	for element: int in [Element.AIR, Element.EARTH, Element.WATER, Element.FIRE]:
		var grown := _grown(element)
		if grown <= 0.0:
			continue
		if element == Element.EARTH:
			_draw_rocks_ring(visuals, s, front, grown)
		else:
			_draw_ribbon(visuals, element, s, front, grown)


## A ribbon's samples, head first: [[point, angle, 0…1 along the trail], …], on one side only.
func _trail(element: int, s: float, front: bool, grown: float) -> Array:
	var head := _head_angle(element)
	var samples := []
	for i in TRAIL_SAMPLES:
		var k := i / float(TRAIL_SAMPLES - 1)
		var phi := head - k * TRAIL * grown
		if (sin(phi) > 0.0) == front:
			samples.append([_ring_point(element, phi, s), phi, k])
	return samples


func _draw_ribbon(visuals: FighterVisuals, element: int, s: float, front: bool,
		grown: float) -> void:
	var t := _avatar_ticks()
	var samples := _trail(element, s, front, grown)
	match element:
		Element.WATER:
			for pass_i in 3:
				for sample: Array in samples:
					var k: float = sample[2]
					var ripple := 1.0 + 0.3 * sin(sample[1] * 6.0 - t * 0.5)
					var width := 2.4 * pow(1.0 - k, 0.7) * ripple * grown * s
					var at: Vector2 = sample[0]
					match pass_i:
						0: visuals.draw_circle(at, width + 0.8 * s, WATER_EDGE)
						1: visuals.draw_circle(at, width, COLORS[Element.WATER])
						2: visuals.draw_circle(at + Vector2(0, -0.4 * s), width * 0.35, WATER_CORE)
			for i in samples.size():
				if (i + t / 2) % 7 == 0:
					visuals.draw_rect(Rect2(samples[i][0] + Vector2(-0.5, -1.5) * s,
						Vector2(1, 1) * s), Color.WHITE)
		Element.FIRE:
			for i in samples.size():
				# Flickering tongues streaming off the tail, outward from the ring.
				var k: float = samples[i][2]
				if k < 0.15 or i % 3 != (t / 3) % 3:
					continue
				var at: Vector2 = samples[i][0]
				var out := (at - BODY_MIDDLE * s).normalized()
				var flick := 2.0 + 2.0 * absf(sin(i * 1.7 + t * 0.9))
				var tip := at + out * flick * (1.2 - k) * s
				var side := out.orthogonal() * 1.2 * s
				visuals.draw_colored_polygon(PackedVector2Array([at - side, tip, at + side]),
					FIRE_BODY)
			for pass_i in 3:
				for sample: Array in samples:
					var k: float = sample[2]
					var flicker := 1.0 + 0.2 * sin(sample[1] * 9.0 + t * 1.3)
					var width := 2.7 * pow(1.0 - k, 0.6) * flicker * grown * s
					var at: Vector2 = sample[0]
					match pass_i:
						0: visuals.draw_circle(at, width + 0.8 * s, FIRE_EDGE)
						1: visuals.draw_circle(at, width, FIRE_BODY)
						2:
							if k < 0.7:
								visuals.draw_circle(at, width * 0.5, FLAME_CORE)
		Element.AIR:
			# Two thin see-through streaks breaking into dashes.
			for i in samples.size() - 1:
				if (i + t / 2) % 5 == 0:
					continue
				var k: float = samples[i][2]
				var fade := (1.0 - k) * grown
				var color := AIR
				color.a *= fade
				var edge := AIR_EDGE
				edge.a *= fade
				for lane: float in [-1.5, 1.5]:
					var shift := Vector2(0, lane) * s
					var a: Vector2 = samples[i][0] + shift
					var b: Vector2 = samples[i + 1][0] + shift
					visuals.draw_line(a, b, edge, 2.6 * s)
					visuals.draw_line(a, b, color, 1.0 * s)


## Chunky rocks floating round him on their own ring, tumbling and bobbing; they lift into place.
func _draw_rocks_ring(visuals: FighterVisuals, s: float, front: bool, grown: float) -> void:
	var t := _avatar_ticks()
	var head := _head_angle(Element.EARTH)
	for j in ROCKS:
		var phi := head + j * TAU / ROCKS
		if (sin(phi) > 0.0) != front:
			continue
		var bob := sin(t * 0.1 + j * 1.3) * 1.5 + (1.0 - grown) * 12.0
		var at := _ring_point(Element.EARTH, phi, s) + Vector2(0, bob) * s
		var size := (2.2 + (j % 3) * 0.8) * s
		var spin := t * 0.08 * (1.0 if j % 2 == 0 else -1.0) + j
		var points := PackedVector2Array()
		for v in 5:
			var r := size * (0.8 + 0.4 * absf(sin(j * 3.1 + v * 2.3)))
			points.append(at + Vector2(r, 0).rotated(spin + v * TAU / 5.0))
		var edge := PackedVector2Array()
		for p in points:
			edge.append(at + (p - at) * (1.0 + 0.9 * s / size))
		visuals.draw_colored_polygon(edge, OUTLINE)
		visuals.draw_colored_polygon(points, ROCK)
		visuals.draw_colored_polygon(PackedVector2Array([points[0], points[1], at]), ROCK_LIGHT)
		visuals.draw_colored_polygon(PackedVector2Array([points[3], points[4], at]), ROCK_DARK)


func sounds() -> Dictionary:
	return {"start": {&"avatar_rise": &"charge", &"avatar_fly": &"boost"}}


func make_card_badge(_card: PlayerCard) -> Control:
	var badge := ElementBadge.new()
	badge.ability = self
	badge.position = ElementBadge.AT
	return badge
