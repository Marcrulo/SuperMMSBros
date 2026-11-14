class_name VineAbility
extends FighterAbility
## The vine up special (docs/specs/characters/fidusen.md#fidusen--banana-book-vine; Sjippepigen's
## lasso is the same ability, docs/specs/characters/sjippepigen.md#sjippepigen--jump-ropes): on
## its frame `startup`, pulled in a straight line to the nearest free ledge in reach that the
## fighter is beside or below (`vine_pull`); else a lasso that catches the nearest fighter in
## reach and reels them in (`lasso_reel`); else a swing on a vine from straight above
## (`vine_swing`), or a lasso that caught nothing (`lasso_miss`).
## Used by two characters: changing it is a shared change.

## The vine's colors (or the character's rope colors), and where it leaves the hands (relative to
## the feet, facing right).
const VINE := Color(0.24, 0.54, 0.23)
const VINE_DARK := Color(0.1, 0.11, 0.17)
const VINE_HANDS := Vector2(2, -36)

## Where the vine hangs from while swinging (the ledge corner while pulled to one; the caught
## fighter while reeling).
var vine_anchor: Vector2 = Vector2.ZERO
## Where a vine pull started.
var _vine_from: Vector2 = Vector2.ZERO
## Where the lassoed fighter was caught.
var _lasso_from: Vector2 = Vector2.ZERO


func _numbers() -> VineData:
	return data as VineData


func phases() -> Array[StringName]:
	return [&"vine_pull", &"vine_swing", &"lasso_reel", &"lasso_miss"]


func replaces(move: StringName) -> bool:
	return move == &"up_special"


## On its choice frame: a pull, a lasso, a swing or a miss.
func after_ledges(match_: Match) -> void:
	var up := fighter.stats.moveset.up_special
	if not (fighter.state == Fighter.State.ATTACK and fighter.move == &"up_special"
			and not fighter.launched and fighter.state_frame == up.startup):
		return
	var vine := _numbers()
	var best: Ledge = null
	var best_distance := INF
	for ledge in match_.get_stage().get_ledges():
		var distance := fighter.get_center().distance_to(ledge.point)
		var beside := (fighter.global_position.x - ledge.point.x) * ledge.side >= -4.0
		var below := fighter.global_position.y >= ledge.point.y - 4.0
		if distance <= vine.ledge_range and beside and below and not match_.is_ledge_held(ledge) \
				and distance < best_distance:
			best = ledge
			best_distance = distance
	var target := _lasso_target(match_) if best == null else null
	if best != null:
		_start_pull(best)
	elif target != null:
		_start_lasso(target)
	elif vine.swing:
		_start_swing()
	else:
		_start_miss()


## The fighter a lasso catches: the nearest that can be hit and isn't held, within grab_range of
## the thrower's center, in front of it or above (not behind), or null.
func _lasso_target(match_: Match) -> Fighter:
	var vine := _numbers()
	if vine.grab_range <= 0.0:
		return null
	var best: Fighter = null
	var best_distance := INF
	for victim in match_.get_fighters():
		if victim == fighter or not victim.can_be_hit():
			continue
		var offset := victim.get_center() - fighter.get_center()
		var distance := offset.length()
		var behind := offset.x * fighter.facing < -8.0 and offset.y > -8.0
		if distance <= vine.grab_range and not behind and distance < best_distance:
			best = victim
			best_distance = distance
	return best


## The vine reaches `target`: pulled in a straight line to hanging from it (then grabs it).
func _start_pull(target: Ledge) -> void:
	fighter.ledge = target
	vine_anchor = target.point
	_vine_from = fighter.global_position
	fighter.velocity = Vector2.ZERO
	fighter.move = &"vine_pull"
	fighter.state_frame = 0


## The lasso catches `victim`: it's held and reeled in.
func _start_lasso(victim: Fighter) -> void:
	fighter.throwing = victim
	fighter.throw_facing = fighter.facing
	_lasso_from = victim.global_position
	vine_anchor = victim.get_center()  # The rope points at it from the first tick.
	fighter.velocity = Vector2.ZERO
	fighter.move = &"lasso_reel"
	fighter.state_frame = 0
	victim.become_held(fighter)


## Where the lassoed fighter's feet are on reel frame `frame`: in a straight line from where it was
## caught to `reel_to` in front of her.
func lasso_position(frame: int) -> Vector2:
	var vine := _numbers()
	var to := fighter.global_position + Vector2(vine.reel_to.x * fighter.throw_facing, vine.reel_to.y)
	return _lasso_from.lerp(to, clampf(float(frame) / vine.reel_frames, 0.0, 1.0))


## Reeled in: the lassoed fighter is hit away (forward), and she pops up like a launched up special.
func _finish_lasso() -> void:
	var vine := _numbers()
	var victim := fighter.throwing
	fighter.throwing = null
	victim.held_by = null
	victim.global_position = lasso_position(vine.reel_frames)
	victim.take_hit(vine.grab_hit, fighter.throw_facing, fighter.global_position.x)
	fighter.hit_dealt(victim)
	fighter.velocity = Vector2(0.0, -vine.pop_speed)
	fighter.move = &"up_special"
	fighter.launched = true


## The lasso caught nothing: the rope flies out (45° up and forward) and back while she falls.
func _start_miss() -> void:
	vine_anchor = fighter.get_center() + Vector2(fighter.facing, -1.0).normalized() * _numbers().grab_range
	fighter.move = &"lasso_miss"
	fighter.state_frame = 0


## A vine from straight above: swings forward on it, then lets go.
func _start_swing() -> void:
	vine_anchor = fighter.global_position + Vector2(0.0, -_numbers().length)
	fighter.move = &"vine_swing"
	fighter.state_frame = 0


## Reeling in: the caught fighter follows the rope; reeled in, it's hit away.
func advance_held(match_: Match) -> bool:
	if fighter.state != Fighter.State.ATTACK or fighter.move != &"lasso_reel":
		return false
	var victim := fighter.throwing
	if fighter.state_frame >= _numbers().reel_frames:
		_finish_lasso()
		match_.fighter_hit.emit(victim.player_index)
	else:
		victim.global_position = lasso_position(fighter.state_frame)
		vine_anchor = victim.get_center()
	return true


func move_tick(_input: FighterInput) -> bool:
	if fighter.move != &"vine_swing":
		return false
	var vine := _numbers()
	if fighter.state_frame >= vine.swing_frames:
		# Let go with the swing's speed, along the arc's tangent.
		var angle := deg_to_rad(vine.swing_degrees)
		fighter.velocity = vine.length * vine.swing_speed() * Vector2(cos(angle) * fighter.facing, -sin(angle))
		fighter.move = &"up_special"
		fighter.launched = true
	return true


func phase_finished(move: StringName) -> bool:
	return move == &"lasso_miss" and fighter.state_frame >= _numbers().miss_frames


func phase_movement(move: StringName, _input: FighterInput) -> bool:
	match move:
		&"vine_swing":
			# Along the arc below the anchor, moved with physics so floors and walls stop it.
			var vine := _numbers()
			var angle := minf(fighter.state_frame + 1, vine.swing_frames) * vine.swing_speed() * Fighter.DELTA
			var target := vine_anchor + vine.length * Vector2(sin(angle) * fighter.facing, cos(angle))
			fighter.velocity = (target - fighter.global_position) / Fighter.DELTA
			return true
		&"lasso_reel":
			fighter.velocity = Vector2.ZERO  # Hangs in the air (or stands) while reeling in.
			return true
	return false


## Pulled to the ledge: placed directly, without physics; hangs from it once there.
func places_fighter() -> bool:
	return fighter.state == Fighter.State.ATTACK and fighter.move == &"vine_pull"


func place() -> void:
	fighter.velocity = Vector2.ZERO
	var hang := fighter.hang_position()
	var pull := float(fighter.state_frame + 1) / _numbers().pull_frames
	fighter.global_position = _vine_from.lerp(hang, minf(pull, 1.0))
	if pull >= 1.0:
		fighter.grab_ledge(fighter.ledge)


func can_be_hit() -> bool:
	return not (fighter.state == Fighter.State.ATTACK and fighter.move == &"lasso_reel")


func phase_animation(_move: StringName) -> String:
	return "up_special"


func drawing(animation: String, frame: int) -> int:
	if fighter.move in phases():
		return FighterVisuals.ANIMATIONS[animation].ticks.size() - 1  # Arms up, holding the vine.
	return frame


## The vine from the hands to where it hangs: the ledge corner, the caught fighter, or on up past
## the anchor.
func draw(visuals: FighterVisuals, _animation: String, _frame: int) -> void:
	if fighter.state != Fighter.State.ATTACK or fighter.move not in phases():
		return
	var hands := Vector2(VINE_HANDS.x * fighter.facing, VINE_HANDS.y)
	var to := vine_anchor - fighter.global_position
	if fighter.move == &"vine_swing":
		to += (to - hands).normalized() * 400.0
	elif fighter.move == &"lasso_miss":
		# Out and back from her hands, 45° up and forward (moving with her as she falls), reaching
		# furthest halfway through.
		var vine := _numbers()
		var reach := clampf(1.0 - absf(1.0 - 2.0 * fighter.state_frame / float(vine.miss_frames)), 0.0, 1.0)
		to = hands + Vector2(fighter.facing, -1.0).normalized() * vine.grab_range * reach
	var colors := FighterVisuals.rope_colors_for(fighter.character_id)
	visuals.draw_line(hands, to, VINE_DARK, 4.0)
	visuals.draw_line(hands, to, colors[0] if not colors.is_empty() else VINE, 2.0)
