class_name PyramidAbility
extends FighterAbility
## Gitte's pyramid up special (docs/specs/characters/gitte.md#gitte--scissors-and-stances): on its
## frame `startup` a pyramid rises out of the floor below if it's in reach and she rides its tip up
## (`pyramid_rise`), popping off the top like a launched up special; with no floor in reach, a weak
## hop instead.

## Where the pyramid she rides rises from: her x, and the top of the floor it comes out of.
var pyramid_origin: Vector2 = Vector2.ZERO
## Feet height when the pyramid started rising (in the air she waits there for the tip).
var _rise_start_y: float = 0.0


func _numbers() -> PyramidData:
	return data as PyramidData


func phases() -> Array[StringName]:
	return [&"pyramid_rise"]


func replaces(move: StringName) -> bool:
	return move == &"up_special"


## True while she rides her pyramid up.
func is_riding() -> bool:
	return fighter.state == Fighter.State.ATTACK and fighter.move == &"pyramid_rise"


## A pyramid up special on its choice frame: a pyramid out of the floor below if it's in reach,
## else a hop.
func spawn_entities(match_: Match) -> void:
	var up := fighter.stats.moveset.up_special
	if not (fighter.state == Fighter.State.ATTACK and fighter.move == &"up_special"
			and not fighter.launched and fighter.state_frame == up.startup):
		return
	var feet := fighter.global_position
	var floor_y := match_.get_stage().floor_below(feet - Vector2(0.0, 1.0), true)
	if floor_y - feet.y > _numbers().reach:  # Also no floor at all (INF).
		_hop()
		return
	_start_rise(floor_y)
	var pyramid := Pyramid.new()
	match_.add_entity(pyramid)
	pyramid.setup(fighter.player_index, Vector2(feet.x, floor_y), _numbers(), fighter.character_id)


## A pyramid rises out of the floor whose top is at `floor_y`, below her: she rides its tip up.
func _start_rise(floor_y: float) -> void:
	pyramid_origin = Vector2(fighter.global_position.x, floor_y)
	_rise_start_y = fighter.global_position.y
	fighter.velocity = Vector2.ZERO
	fighter.clear_hit_victims()
	fighter.move = &"pyramid_rise"
	fighter.state_frame = 0


## No floor in reach for a pyramid: a weak hop, then like a launched up special.
func _hop() -> void:
	fighter.velocity = Vector2(fighter.velocity.x, -_numbers().hop_speed)
	fighter.launched = true


## Where the pyramid's tip is now (after this tick's rise).
func pyramid_tip() -> Vector2:
	return pyramid_origin - Vector2(0.0, _numbers().tip_height(fighter.state_frame))


func move_tick(input: FighterInput) -> bool:
	if fighter.move != &"pyramid_rise":
		return false
	if fighter.state_frame >= _numbers().rise_frames:
		# At the top: pops off the tip.
		fighter.velocity = Vector2(input.move_x * fighter.stats.moveset.up_special.drift_speed,
			-_numbers().pop_speed)
		fighter.move = &"up_special"
		fighter.launched = true
	return true


func phase_data(_move: StringName) -> MoveData:
	return _numbers().tip_hit


## On the pyramid's tip, at the pyramid's own size.
func phase_hitbox(_move: StringName, move_data: MoveData) -> Rect2:
	return Rect2(pyramid_tip() + move_data.hitbox_center - move_data.hitbox_size / 2.0,
		move_data.hitbox_size)


## Feet on the tip, or (in the air) where they were until the tip gets there; moved with physics
## so a ceiling stops her.
func phase_movement(_move: StringName, _input: FighterInput) -> bool:
	var tip := pyramid_origin.y - _numbers().tip_height(fighter.state_frame + 1)
	var target := Vector2(pyramid_origin.x, minf(_rise_start_y, tip))
	fighter.velocity = (target - fighter.global_position) / Fighter.DELTA
	return true


func phase_animation(_move: StringName) -> String:
	return "up_special"


func drawing(_animation: String, frame: int) -> int:
	return 1 if fighter.move == &"pyramid_rise" else frame  # Arms up, riding the pyramid's tip.


func sounds() -> Dictionary:
	return {"start": {&"pyramid_rise": &"burst"}, "pop": [&"pyramid_rise"]}
