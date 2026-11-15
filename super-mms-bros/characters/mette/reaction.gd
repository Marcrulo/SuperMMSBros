class_name Reaction
extends MatchEntity
## A reaction of two of Mette's potions (docs/specs/characters/mette.md#mette--potions), set off
## by a splash onto a puddle of another colour: steam (red + blue) blows fighters upward, an
## explosion (red + green) launches them away, a foam pillar (blue + green) rises and its top is a
## pass-through platform. It hits everyone, Mette too, each once. Advanced by the Match one tick at
## a time; drawing only reads.

enum Kind { STEAM, EXPLOSION, FOAM }

## The stage's pass-through platform layer (docs/specs/architecture.md#collision-layers).
const PLATFORM_LAYER := 2
## The foam platform's thickness (as the stage's pass-through platforms).
const PLATFORM_THICKNESS := 4.0

var kind: Kind
var data: PotionData
## Ticks since it was set off.
var age: int = 0
## Player indexes it has hit (or popped up).
var _hit: Array[int] = []
## The foam pillar's top: a one-way StaticBody2D, solid only while fully risen.
var _platform: StaticBody2D
var _platform_shape: CollisionShape2D


## The reaction of a puddle of colour `a` and a splash of colour `b` (any order; never the same).
static func kind_for(a: PotionAbility.Potion, b: PotionAbility.Potion) -> Kind:
	var both := [a, b]
	if PotionAbility.Potion.RED in both:
		return Kind.STEAM if PotionAbility.Potion.BLUE in both else Kind.EXPLOSION
	return Kind.FOAM


func setup(owner: int, at: Vector2, reaction: Kind, potion_data: PotionData) -> void:
	owner_index = owner
	global_position = at
	kind = reaction
	data = potion_data
	if kind == Kind.FOAM:
		_make_platform()


func behind_fighters() -> bool:
	return kind == Kind.FOAM


func _make_platform() -> void:
	_platform = StaticBody2D.new()
	_platform.collision_layer = 1 << (PLATFORM_LAYER - 1)
	_platform.collision_mask = 0
	_platform_shape = CollisionShape2D.new()
	var box := RectangleShape2D.new()
	box.size = Vector2(data.foam_width, PLATFORM_THICKNESS)
	_platform_shape.shape = box
	_platform_shape.one_way_collision = true
	_platform_shape.position = Vector2(0.0, -data.foam_height + PLATFORM_THICKNESS / 2.0)
	_platform_shape.disabled = true
	_platform.add_child(_platform_shape)
	add_child(_platform)


func advance(_match: Match) -> void:
	age += 1
	if kind == Kind.FOAM:
		_platform_shape.disabled = not is_platform_solid()
	queue_redraw()


func is_finished(_match: Match) -> bool:
	match kind:
		Kind.STEAM:
			return age >= data.steam_frames
		Kind.EXPLOSION:
			return age >= data.blast_frames
	return age >= data.foam_rise + data.foam_stand + data.foam_sink


## The foam pillar's top is solid once it has fully risen, until it starts to shrink.
func is_platform_solid() -> bool:
	return kind == Kind.FOAM and age >= data.foam_rise and age <= data.foam_rise + data.foam_stand


## The foam pillar's height now: rising, standing, then shrinking.
func foam_height_now() -> float:
	if age < data.foam_rise:
		return data.foam_height * age / data.foam_rise
	var sinking := age - data.foam_rise - data.foam_stand
	if sinking <= 0:
		return data.foam_height
	return data.foam_height * maxf(1.0 - float(sinking) / data.foam_sink, 0.0)


## The y of the foam pillar's top when fully risen.
func top_y() -> float:
	return global_position.y - data.foam_height


## Where it acts: steam's column, the explosion's ball, or the foam pillar now (bottom center on
## the floor).
func get_area_rect() -> Rect2:
	var size: Vector2
	match kind:
		Kind.STEAM:
			size = data.steam_size
		Kind.EXPLOSION:
			size = data.blast_size
		_:
			size = Vector2(data.foam_width, maxf(foam_height_now(), 1.0))
	return Rect2(global_position - Vector2(size.x / 2.0, size.y), size)


## The rising foam pops up everyone standing in it, once (no damage, no hitstun).
func interact(match_: Match) -> void:
	if kind != Kind.FOAM or age > data.foam_rise:
		return
	var area := Rect2(global_position - Vector2(data.foam_width / 2.0, data.foam_height),
			Vector2(data.foam_width, data.foam_height))
	for fighter in match_.get_fighters():
		if fighter.player_index in _hit or not fighter.is_on_floor() \
				or fighter.state in Puddle.NOT_STANDING:
			continue
		if area.intersects(fighter.get_hurtbox_rect()):
			_hit.append(fighter.player_index)
			fighter.velocity.y = -data.foam_pop_speed


## Steam and the explosion hit everyone in their area, once each.
func collect_hits(match_: Match, hits: Array[Dictionary]) -> void:
	if kind == Kind.FOAM:
		return
	var move := data.steam_hit if kind == Kind.STEAM else data.blast_hit
	var center := get_area_rect().get_center()
	for victim in match_.get_fighters():
		if victim.player_index in _hit or not victim.can_be_hit():
			continue
		if not get_area_rect().intersects(victim.get_hurtbox_rect()):
			continue
		var side := 0
		if kind == Kind.EXPLOSION:
			side = 1 if victim.get_center().x >= center.x else -1
		hits.append({
			"victim": victim,
			"move": move,
			"side": side,
			"attacker_x": global_position.x,
			"register": func(victim_index: int) -> void: _hit.append(victim_index),
		})


func _draw() -> void:
	match kind:
		Kind.STEAM:
			PotionLook.draw_steam(self, data.steam_size, age, data.steam_frames)
		Kind.EXPLOSION:
			PotionLook.draw_explosion(self, data.blast_size, age, data.blast_frames)
		Kind.FOAM:
			PotionLook.draw_foam(self, data.foam_width, foam_height_now(), age)
	if FighterVisuals.show_boxes:
		var box := get_area_rect()
		box.position -= global_position
		draw_rect(box, FighterVisuals.HITBOX_ACTIVE_COLOR if kind != Kind.FOAM
				else FighterVisuals.HITBOX_IDLE_COLOR)
