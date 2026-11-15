class_name FireballAbility
extends FighterAbility
## Magnus's fireball (docs/specs/characters/magnus.md#side-special--fireball-fire): his side
## special (the default move: turning first, frames from its MoveData) throws a Fireball entity
## instead of the default projectile, one at a time.

## His last fireball (it may be gone already: see _has_fireball()).
var _fireball_out: Fireball = null


func _move_data() -> MoveData:
	return fighter.stats.moveset.get(slot) as MoveData


func replaces(move: StringName) -> bool:
	return move == slot


## Side+B does nothing while his fireball is out.
func pick_special(input: FighterInput, choice: StringName) -> StringName:
	if Fighter.special_direction(input) != slot:
		return choice
	return Fighter.NO_MOVE if _has_fireball() else choice


## True while his fireball is still in the match.
func _has_fireball() -> bool:
	return is_instance_valid(_fireball_out) and not _fireball_out.removed


func reset() -> void:
	_fireball_out = null


func spawn_entities(match_: Match) -> void:
	var move_data := _move_data()
	if not (fighter.state == Fighter.State.ATTACK and fighter.move == slot
			and fighter.state_frame == move_data.startup):
		return
	var at := fighter.global_position + Vector2(move_data.hitbox_center.x * fighter.facing,
			move_data.hitbox_center.y) * fighter.size_scale()
	var ball := Fireball.new()
	match_.add_entity(ball)
	ball.setup(fighter.player_index, fighter.facing, at, fighter.projectile_data(move_data),
			(data as FireballData).flicker_ticks, _landed)
	_fireball_out = ball


func _landed(_victim: Fighter) -> void:
	var avatar := fighter.ability(AvatarAbility) as AvatarAbility
	if avatar != null:
		avatar.light(AvatarAbility.Element.FIRE)
