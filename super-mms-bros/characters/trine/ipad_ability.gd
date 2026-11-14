class_name IpadAbility
extends FighterAbility
## Trine's iPad break (docs/specs/characters/trine.md#trine--ipad-break): her down special (ground
## only) sits her down on its frame `startup`; she watches (`ipad_watch`), healing every
## `heal_every` ticks, until down is let go or `watch_frames` pass, then gets up (`ipad_stand`, the
## down special's recovery). If the floor goes from under her, she stops and falls.

## Watching: ticks per drawing (2 and 3 alternate), how long one watch-and-sip round lasts and how
## much of it is the sip (drawing 4).
const WATCH_TICKS := 15
const SIP_CYCLE := 60
const SIP_TICKS := 30


func _numbers() -> IpadData:
	return data as IpadData


func phases() -> Array[StringName]:
	return [&"ipad_watch", &"ipad_stand"]


func pick_special(input: FighterInput, choice: StringName) -> StringName:
	if Fighter.special_direction(input) == slot:
		return slot if fighter.state != Fighter.State.AIR else Fighter.NO_MOVE  # On the ground only.
	return choice


func move_tick(input: FighterInput) -> bool:
	if fighter.move == slot:
		# On its frame `startup` (state_frame counts up at the end of the tick).
		if fighter.state_frame + 1 == (fighter.stats.moveset.get(slot) as MoveData).startup:
			fighter.move = &"ipad_watch"  # Seated: starts watching.
			fighter.state_frame = 0
		return true
	if fighter.move == &"ipad_watch":
		if not input.down_held:
			_stand_up()
		else:
			if fighter.state_frame > 0 and fighter.state_frame % _numbers().heal_every == 0:
				fighter.percent = maxf(fighter.percent - _numbers().heal, 0.0)
			if fighter.state_frame >= _numbers().watch_frames:
				_stand_up()
		return true
	return false


func _stand_up() -> void:
	fighter.move = &"ipad_stand"
	fighter.state_frame = 0


func phase_finished(move: StringName) -> bool:
	return move == &"ipad_stand" \
			and fighter.state_frame >= (fighter.stats.moveset.get(slot) as MoveData).recovery


## The floor went from under her: she stops sitting and falls.
func left_floor_in_move() -> bool:
	if fighter.move != slot and fighter.move not in phases():
		return false
	fighter.move = Fighter.NO_MOVE
	fighter.set_state(Fighter.State.AIR)
	return true


func phase_animation(_move: StringName) -> String:
	return String(slot)


func drawing(animation: String, frame: int) -> int:
	if animation != String(slot):
		return frame
	return ipad_frame(fighter.move, fighter.state_frame)


func draw(visuals: FighterVisuals, _animation: String, _frame: int) -> void:
	if fighter.state == Fighter.State.ATTACK and fighter.move == &"ipad_watch":
		for age in heal_plus_ages(_numbers(), fighter.state_frame):
			visuals.draw_heal_plus(age)


## Which drawing of the down_special strip the iPad break shows, `ticks` ticks into `phase`:
## bending down then seated (0, 1); watching: 1 and 2 alternating, then a sip of coffee (3) at the
## end of every round; getting up (4).
static func ipad_frame(phase: StringName, ticks: int) -> int:
	match phase:
		&"ipad_watch":
			var t := maxi(ticks - 1, 0) % SIP_CYCLE
			if t >= SIP_CYCLE - SIP_TICKS:
				return 3
			return 1 + (t / WATCH_TICKS) % 2
		&"ipad_stand":
			return 4
	return 0 if ticks <= 5 else 1


## How many ticks ago each heal "+" still showing appeared, oldest first, `ticks` ticks into
## watching (a heal every `ipad.heal_every` ticks).
static func heal_plus_ages(ipad: IpadData, ticks: int) -> Array[int]:
	var ages: Array[int] = []
	var heal := (ticks / ipad.heal_every) * ipad.heal_every
	while heal >= ipad.heal_every and ticks - heal < FighterVisuals.HEAL_PLUS_TICKS:
		ages.push_front(ticks - heal)
		heal -= ipad.heal_every
	return ages
