class_name PotionAbility
extends FighterAbility
## Mette's potions (docs/specs/characters/mette.md#mette--potions): her down special switches the
## potion she holds (red → blue → green → red, red at every spawn); her side special throws a
## flask of it (Flask), one at a time; her neutral special smashes it in front of her (red: damage,
## blue: knockback, green: stun). On her move set, so one ability serves all three specials.

## In switching order: red (acid), blue (ice), green (glue).
enum Potion { RED, BLUE, GREEN }

## Her flask in her hand, while she holds it: [down special drawing, hand], [side special
## drawing before the throw, hand] (from the feet, facing right).
const HOLD_DOWN := [4, Vector2(3, -8)]
const HOLD_SIDE := Vector2(7, -12)
## The smash: the flask in her hand during the wind-up, and where it bursts.
const HOLD_SMASH := Vector2(5, -10)
const BURST := Vector2(16, -16)
## Ticks the burst shows, from the first active frame.
const BURST_TICKS := 8

var potion: Potion = Potion.RED
## Her flask is in flight (updated at the end of every step).
var flask_out := false
## Player indexes the smash in progress has stunned.
var _stunned: Array[int] = []


func _numbers() -> PotionData:
	return data as PotionData


func _move(move: StringName) -> MoveData:
	return fighter.stats.moveset.get(move) as MoveData


func reset() -> void:
	potion = Potion.RED
	flask_out = false


## Neutral: smash (no charge). Down: switch (also in the air, never a dive). Sideways: throw,
## unless her flask is out.
func pick_special(input: FighterInput, choice: StringName) -> StringName:
	match Fighter.special_direction(input):
		&"neutral_special":
			return &"neutral_special"
		&"down_special":
			return &"down_special"
		&"side_special":
			return Fighter.NO_MOVE if flask_out else &"side_special"
	return choice


## Her side special throws a flask, not the default projectile.
func replaces(move: StringName) -> bool:
	return move == &"side_special"


func on_move_started(_move: StringName) -> void:
	_stunned.clear()


## The smash hits as her potion's smash hit.
func modify_hit(move_data: MoveData, special: bool) -> MoveData:
	if not special or fighter.move != &"neutral_special":
		return move_data
	var numbers := _numbers()
	match potion:
		Potion.BLUE:
			return numbers.smash_blue
		Potion.GREEN:
			return numbers.smash_green
	return numbers.smash_red


func move_tick(_input: FighterInput) -> bool:
	if fighter.move != &"down_special":
		return false
	# On its frame `startup` (state_frame counts up at the end of the tick).
	if fighter.state_frame + 1 == _move(&"down_special").startup:
		potion = ((potion + 1) % Potion.size()) as Potion
	return true


## The flask leaves her hand on the side special's frame `startup`.
func spawn_entities(match_: Match) -> void:
	var move_data := _move(&"side_special")
	if not (fighter.state == Fighter.State.ATTACK and fighter.move == &"side_special"
			and fighter.state_frame == move_data.startup):
		return
	var numbers := _numbers()
	var spawn := numbers.flask_spawn
	var at := fighter.global_position \
			+ Vector2(spawn.x * fighter.facing, spawn.y) * fighter.size_scale()
	var angle := deg_to_rad(numbers.flask_angle_deg)
	var velocity := Vector2(cos(angle) * fighter.facing, -sin(angle)) * numbers.flask_speed
	var flask := Flask.new()
	match_.add_entity(flask)
	flask.setup(fighter.player_index, at, velocity, potion, numbers,
			fighter.projectile_data(move_data))
	flask_out = true


## Her flask in flight; a green smash that just landed (not blocked) stuns.
func end_step(match_: Match) -> void:
	flask_out = not match_.get_entities(Flask, fighter.player_index).is_empty()
	if not (fighter.state == Fighter.State.ATTACK and fighter.move == &"neutral_special"
			and potion == Potion.GREEN):
		return
	for victim in match_.get_fighters():
		var index := victim.player_index
		if victim == fighter or index in _stunned or not fighter.has_hit(index):
			continue
		_stunned.append(index)
		if victim.state == Fighter.State.HITSTUN and victim.state_frame == 0:
			victim.stun(_numbers().smash_stun)


## The potion her hand shows: during the down special, the new one from its first frame.
func held_potion() -> Potion:
	if fighter.state == Fighter.State.ATTACK and fighter.move == &"down_special" \
			and fighter.state_frame < _move(&"down_special").startup:
		return ((potion + 1) % Potion.size()) as Potion
	return potion


# --- Presentation -----------------------------------------------------------------------------


## The down special shows one calm drawing (her hand in front, holding the flask up to look); the
## smash uses the punch's drawings timed to its frames: wind-up, smash (active), recovery.
func drawing(animation: String, frame: int) -> int:
	if animation == "down_special" and fighter.move == &"down_special":
		return HOLD_DOWN[0]
	if animation == "neutral_special" and fighter.move == &"neutral_special":
		var smash := _move(&"neutral_special")
		var f := fighter.state_frame
		if f <= smash.startup:
			return 0
		if f <= smash.startup + smash.active:
			return 1
		return 2 if f <= smash.startup + smash.active + smash.recovery / 2 else 3
	return frame


## The flask in her front hand during the down special (only the new colour), the side special
## until the throw and the smash until it bursts; then the burst.
func draw(visuals: FighterVisuals, _animation: String, _frame: int) -> void:
	if fighter.state != Fighter.State.ATTACK:
		return
	var f := float(fighter.facing)
	var hand: Vector2
	if fighter.move == &"down_special":
		hand = HOLD_DOWN[1]
	elif fighter.move == &"side_special" and fighter.state_frame < _move(&"side_special").startup:
		hand = HOLD_SIDE
	elif fighter.move == &"neutral_special":
		var since := fighter.state_frame - _move(&"neutral_special").startup
		if since <= 0:
			hand = HOLD_SMASH
		elif since <= BURST_TICKS:
			visuals.draw_set_transform(Vector2(BURST.x * f, BURST.y), 0.0, Vector2(f, 1.0))
			PotionLook.draw_burst(visuals, potion, since, BURST_TICKS)
			visuals.draw_set_transform(Vector2.ZERO)
			return
		else:
			return
	else:
		return
	visuals.draw_set_transform(Vector2(hand.x * f, hand.y), 0.0, Vector2(f, 1.0))
	PotionLook.draw_flask(visuals, held_potion())
	visuals.draw_set_transform(Vector2.ZERO)


## The potion she holds on the portrait's bottom-right corner.
func make_card_badge(card: PlayerCard) -> Control:
	var badge := PotionBadge.new()
	badge.ability = self
	badge.border = card.player_color
	var portrait := card.portrait_rect()
	badge.position = portrait.end - Vector2(PotionBadge.SIZE, PotionBadge.SIZE) + Vector2(2, 2)
	return badge
