class_name CakeAbility
extends FighterAbility
## Pia's cake (docs/specs/characters/pia.md#neutral-special--cake): on the ground and not during
## the cooldown, her special eats a slice (`cake`, the move's own frames, no hitbox): she heals on
## frame `heal_frame`, then can't eat again for `cooldown_frames` ticks (0 at every spawn).

## The cake strip (her special's drawings): the last tick of each stretch and the drawing shown in
## it (taking it out, bite, chew, bite, chew); after that, happy (3).
const CAKE_ENDS: Array[int] = [10, 19, 28, 37, 45]
const CAKE_DRAWINGS: Array[int] = [0, 1, 2, 1, 2]

## Ticks left before she can eat cake again.
var cake_cooldown: int = 0


func _numbers() -> CakeData:
	return data as CakeData


func phases() -> Array[StringName]:
	return [&"cake"]


func reset() -> void:
	cake_cooldown = 0


func before_tick(_input: FighterInput) -> void:
	cake_cooldown = maxi(cake_cooldown - 1, 0)


func pick_special(input: FighterInput, choice: StringName) -> StringName:
	if Fighter.special_direction(input) != slot:
		return choice
	if fighter.state != Fighter.State.AIR and cake_cooldown == 0:
		return &"cake"  # On the ground only, not during the cooldown.
	return Fighter.NO_MOVE


func move_tick(_input: FighterInput) -> bool:
	if fighter.move != &"cake":
		return false
	if fighter.state_frame + 1 == _numbers().heal_frame:
		fighter.percent = maxf(fighter.percent - _numbers().heal, 0.0)  # The last bite of cake.
		cake_cooldown = _numbers().cooldown_frames
	return true


## Its move's own frames (no hitbox).
func phase_data(_move: StringName) -> MoveData:
	return fighter.stats.moveset.get(slot) as MoveData


func phase_finished(_move: StringName) -> bool:
	return fighter.state_frame >= phase_data(&"cake").total_frames()


func phase_animation(_move: StringName) -> String:
	return String(slot)


func drawing(_animation: String, frame: int) -> int:
	return cake_frame(fighter.state_frame) if fighter.move == &"cake" else frame


## The heal "+" after the last bite.
func draw(visuals: FighterVisuals, _animation: String, _frame: int) -> void:
	if fighter.state != Fighter.State.ATTACK or fighter.move != &"cake":
		return
	var since := fighter.state_frame - _numbers().heal_frame
	if since >= 0 and since < FighterVisuals.HEAL_PLUS_TICKS:
		visuals.draw_heal_plus(since)


## Which drawing of the cake strip to show `ticks` ticks into it.
static func cake_frame(ticks: int) -> int:
	for i in CAKE_ENDS.size():
		if ticks <= CAKE_ENDS[i]:
			return CAKE_DRAWINGS[i]
	return 3
