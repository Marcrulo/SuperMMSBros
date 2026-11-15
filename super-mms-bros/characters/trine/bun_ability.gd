class_name BunAbility
extends FighterAbility
## Trine's bun pitch (docs/specs/characters/trine.md#trine--bun-pitch): her neutral special uses
## the default windup (the charge), and on the throw's frame `startup` a bun (Bun) leaves her hand,
## flying straight ahead: the charge sets its speed (BunData) and its hit (the move's charged
## damage and knockback). One bun of hers at a time.

## The charge of the last windup, 0…1.
var _charge := 0.0
## True while a bun of hers is still out (as of this tick's spawning).
var _out := false


func _numbers() -> BunData:
	return data as BunData


func reset() -> void:
	_charge = 0.0
	_out = false


## No new windup while her bun is still flying.
func pick_special(_input: FighterInput, choice: StringName) -> StringName:
	if choice == &"neutral_special_charge" and _out:
		return Fighter.NO_MOVE
	return choice


func on_charge_released(charge: float) -> void:
	_charge = charge


func spawn_entities(match_: Match) -> void:
	_out = not match_.get_entities(Bun, fighter.player_index).is_empty()
	var move_data := fighter.stats.moveset.get(slot) as MoveData
	if not (fighter.state == Fighter.State.ATTACK and fighter.move == &"neutral_special"
			and fighter.state_frame == move_data.startup):
		return
	# The charged throw's hit (damage and knockback with the charge added), at the charge's speed.
	var thrown := fighter.projectile_data(fighter.current_move()).duplicate() as MoveData
	var numbers := _numbers()
	thrown.projectile_speed = lerpf(numbers.speed_min, numbers.speed_max, _charge)
	var hand := move_data.hitbox_center
	var at := fighter.global_position \
			+ Vector2(hand.x * fighter.facing, hand.y) * fighter.size_scale()
	var bun := Bun.new()
	match_.add_entity(bun)
	bun.setup(fighter.player_index, fighter.facing, at, thrown, fighter.character_id)
	_out = true
