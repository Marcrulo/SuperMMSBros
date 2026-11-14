class_name GrabAbility
extends FighterAbility
## A command grab (docs/specs/characters/mads.md#mads--grappler): its move's hitbox is a grab box
## that catches the first fighter it touches that can be hit, shield or not, and never hits. A
## catch starts the throw (`grab_throw`): the held fighter is carried round the grab's path, Mads
## turns round with them overhead, and slams them down behind him. Neither can be hit meanwhile.

## The throw strip (fighter_grab_throw.png): the last tick of each drawing but the last (catch,
## lift, overhead, turned round, slam; then straightening up).
const THROW_ENDS: Array[int] = [3, 8, 14, 18, 30]
const THROW_DRAWINGS := 6


func _numbers() -> GrabData:
	return data as GrabData


func phases() -> Array[StringName]:
	return [&"grab_throw"]


func pick_special(input: FighterInput, choice: StringName) -> StringName:
	if Fighter.special_direction(input) == slot:
		return slot  # A grab: no projectile to wait for.
	return choice


func replaces(move: StringName) -> bool:
	return move == slot  # No projectile.


## The grab box is out now.
func is_grab_box() -> bool:
	var move_data := fighter.current_move()
	return fighter.move == slot and move_data != null and move_data.is_active_frame(fighter.state_frame)


func can_be_hit() -> bool:
	return not (fighter.state == Fighter.State.ATTACK and fighter.move == &"grab_throw")


## Catches the first fighter its grab box touches that can be hit.
func resolve_contacts(match_: Match) -> void:
	if not is_grab_box():
		return
	var box := fighter.get_hitbox_rect()
	for victim in match_.get_fighters():
		if victim != fighter and victim.can_be_hit() and box.intersects(victim.get_hurtbox_rect()):
			_start_throw(victim)
			break


func _start_throw(victim: Fighter) -> void:
	fighter.throwing = victim
	fighter.throw_facing = fighter.facing
	fighter.move = &"grab_throw"
	fighter.state_frame = 0
	victim.become_held(fighter)


## The throw in progress: the held fighter is carried round its arc, and slammed on the slam frame.
func advance_held(match_: Match) -> bool:
	if fighter.state != Fighter.State.ATTACK or fighter.move != &"grab_throw":
		return false
	var victim := fighter.throwing
	if fighter.state_frame >= _numbers().turn_frame:
		fighter.facing = -fighter.throw_facing  # Turned round with the victim overhead.
	if fighter.state_frame >= _numbers().slam_frame:
		_slam()
		match_.fighter_hit.emit(victim.player_index)
	else:
		victim.global_position = throw_position(fighter.state_frame)
	return true


## Where the held fighter's feet are on throw frame `frame`: the middle of its body follows the
## grab's path (in the thrower's grip).
func throw_position(frame: int) -> Vector2:
	var grab := _numbers()
	var t := clampf(float(frame) / grab.slam_frame, 0.0, 1.0) * (grab.path.size() - 1)
	var i := mini(int(t), grab.path.size() - 2)
	var middle := grab.path[i].lerp(grab.path[i + 1], t - i)
	return fighter.global_position + Vector2(middle.x * fighter.throw_facing, middle.y + grab.held_middle)


## The slam: the held fighter lands behind, is launched away, and Mads turns round.
func _slam() -> void:
	var grab := _numbers()
	var victim := fighter.throwing
	fighter.throwing = null
	victim.held_by = null
	# On the floor (his feet line) where the path ends.
	victim.global_position = fighter.global_position + Vector2(grab.path[-1].x * fighter.throw_facing, 0.0)
	victim.take_hit(grab.slam_hit, -fighter.throw_facing, fighter.global_position.x)
	fighter.hit_dealt(victim)
	fighter.facing = -fighter.throw_facing


func phase_finished(_move: StringName) -> bool:
	return fighter.state_frame >= _numbers().throw_frames


## Stands (or hangs in the air) while throwing.
func phase_movement(_move: StringName, _input: FighterInput) -> bool:
	fighter.velocity = Vector2.ZERO
	return true


func phase_animation(_move: StringName) -> String:
	return String(slot)


func strip(textures: Dictionary) -> Array:
	if fighter.state != Fighter.State.ATTACK or fighter.move != &"grab_throw" \
			or not textures.has("grab_throw"):
		return []
	return [textures["grab_throw"], fighter.facing, THROW_DRAWINGS, throw_frame(fighter.state_frame)]


## Turned over round the middle of the body as he swings it (head first over him).
func held_pose(victim: Fighter) -> Array:
	var turn := fighter.throw_facing * -held_turn(victim.state_frame, _numbers())
	var middle := Vector2(0.0, -_numbers().held_middle)
	return [turn, middle - middle.rotated(turn)]


## Which drawing of the throw strip to show `ticks` ticks into the throw: the last tick of each
## drawing in THROW_ENDS.
static func throw_frame(ticks: int) -> int:
	for i in THROW_ENDS.size():
		if ticks <= THROW_ENDS[i]:
			return i
	return THROW_ENDS.size()


## How far a held fighter is turned over (radians), `ticks` ticks into the throw: half a turn by
## the slam.
static func held_turn(ticks: int, grab: GrabData) -> float:
	return PI * clampf(float(ticks) / grab.slam_frame, 0.0, 1.0)
