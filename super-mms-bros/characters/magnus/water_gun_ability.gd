class_name WaterGunAbility
extends FighterAbility
## Magnus's water gun (docs/specs/characters/magnus.md#neutral-special--water-gun-water): his
## neutral special (no charge, also in the air) shoots a short stream of droplets straight ahead,
## one every `interval` ticks (phase `water_gun`).

## The index of the next droplet to shoot.
var _next: int = 0


func _numbers() -> WaterGunData:
	return data as WaterGunData


func _move_data() -> MoveData:
	return fighter.stats.moveset.get(slot) as MoveData


func phases() -> Array[StringName]:
	return [&"water_gun"]


func reset() -> void:
	_next = 0


func pick_special(input: FighterInput, choice: StringName) -> StringName:
	return &"water_gun" if Fighter.special_direction(input) == slot else choice


func on_move_started(move: StringName) -> void:
	if move == &"water_gun":
		_next = 0


## Its move's own frames (no hitbox of its own).
func phase_data(_move: StringName) -> MoveData:
	return _move_data()


## The frame the last droplet leaves on.
func _last_frame() -> int:
	return _move_data().startup + (_numbers().drops - 1) * _numbers().interval


func phase_finished(_move: StringName) -> bool:
	return fighter.state_frame >= _last_frame() + _move_data().recovery


## The next droplet leaves his front hand when its frame comes.
func spawn_entities(match_: Match) -> void:
	if not (fighter.state == Fighter.State.ATTACK and fighter.move == &"water_gun"):
		return
	var move_data := _move_data()
	if _next >= _numbers().drops \
			or fighter.state_frame < move_data.startup + _next * _numbers().interval:
		return
	var hand := move_data.hitbox_center
	var at := fighter.global_position \
			+ Vector2(hand.x * fighter.facing, hand.y) * fighter.size_scale()
	var drop := Droplet.new()
	match_.add_entity(drop)
	drop.setup(fighter.player_index, fighter.facing, at, fighter.projectile_data(move_data),
			_landed)
	_next += 1


func _landed(_victim: Fighter) -> void:
	var avatar := fighter.ability(AvatarAbility) as AvatarAbility
	if avatar != null:
		avatar.light(AvatarAbility.Element.WATER)


# --- Presentation -----------------------------------------------------------------------------


## His side special drawings: wind up, arms thrust out for the stream, then the recovery.
func phase_animation(_move: StringName) -> String:
	return "side_special"


func drawing(_animation: String, frame: int) -> int:
	if fighter.move != &"water_gun":
		return frame
	var now := fighter.state_frame
	var startup := _move_data().startup
	if now < startup / 2:
		return 0
	if now < startup:
		return 1
	return 2 if now <= _last_frame() else 3


func sounds() -> Dictionary:
	return {"start": {&"water_gun": &"zap"}}
