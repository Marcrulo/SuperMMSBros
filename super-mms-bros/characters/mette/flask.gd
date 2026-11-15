class_name Flask
extends MatchEntity
## A flask of potion thrown by Mette (docs/specs/characters/mette.md#mette--potions): flies in an
## arc and shatters on a floor, a fighter or a shield; its potion splashes onto the floor below
## (Puddle.splash). Added by PotionAbility, advanced by the Match one tick at a time; drawing only
## reads.

const DELTA := 1.0 / 60.0
## Spin while flying, radians per tick (presentation).
const SPIN := 0.35

var potion: PotionAbility.Potion
var velocity: Vector2
## Ticks since it left her hand.
var age: int = 0
var data: PotionData
## Its hit (her side special's values).
var hit: MoveData
## Set once it has shattered (the Match then removes it).
var shattered := false


func setup(owner: int, at: Vector2, flying: Vector2, contents: PotionAbility.Potion,
		potion_data: PotionData, move_data: MoveData) -> void:
	owner_index = owner
	global_position = at
	velocity = flying
	potion = contents
	data = potion_data
	hit = move_data


## One tick: falls with gravity; shatters when it comes down onto a floor's top.
func advance(match_: Match) -> void:
	age += 1
	var before := global_position
	velocity.y += data.flask_gravity * DELTA
	global_position += velocity * DELTA
	var floor_y := match_.get_stage().floor_below(before, true)
	if velocity.y > 0.0 and global_position.y >= floor_y:
		global_position.y = floor_y
		_shatter(match_)
	queue_redraw()


func is_finished(match_: Match) -> bool:
	return shattered or age >= data.flask_lifetime \
			or not match_.get_stage().blast_zone.has_point(global_position)


func removed_with_owner() -> bool:
	return true


func get_hitbox_rect() -> Rect2:
	return Rect2(global_position - data.flask_size / 2.0, data.flask_size)


## Hits the first other fighter it touches (a shield blocks it); either way it shatters.
func collect_hits(match_: Match, hits: Array[Dictionary]) -> void:
	if shattered:
		return
	for victim in match_.get_fighters():
		if victim.player_index == owner_index or not victim.can_be_hit():
			continue
		if get_hitbox_rect().intersects(victim.get_hurtbox_rect()):
			hits.append({
				"victim": victim,
				"move": hit,
				"side": 1 if velocity.x >= 0.0 else -1,
				"attacker_x": global_position.x,
				"register": func(_victim_index: int) -> void:
					_shatter(match_)
					match_.remove_entity(self),
			})
			return


## Its potion falls onto the floor below, if one is close enough.
func _shatter(match_: Match) -> void:
	if shattered:
		return
	shattered = true
	var floor_y := match_.get_stage().floor_below(global_position, true)
	if floor_y - global_position.y <= data.splash_reach:
		Puddle.splash(match_, owner_index, Vector2(global_position.x, floor_y), potion, data)


func _draw() -> void:
	draw_set_transform(Vector2.ZERO, age * SPIN * signf(velocity.x), Vector2.ONE)
	PotionLook.draw_flask(self, potion)
	draw_set_transform(Vector2.ZERO)
	if FighterVisuals.show_boxes:
		var box := get_hitbox_rect()
		box.position -= global_position
		draw_rect(box, FighterVisuals.HITBOX_ACTIVE_COLOR)
