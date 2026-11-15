class_name BannerAbility
extends FighterAbility
## Pia's Leverkusen banner (docs/specs/characters/pia.md#up-special--leverkusen-banner): on the
## ground and not during the cooldown, her up special holds up a banner (`banner`, the move's own
## frames, no hitbox, she stays put). While it's up (after `raise_frames`, until the move's startup
## ends) every other fighter within `radius` px is stunned until it goes down. When it ends (or is
## stopped), whoever it still holds is let go and she can't raise it again for `cooldown_frames`.

## Drawings of her up_special strip: raising, held (wave A), held (wave B), lowering.
const RAISING := 0
const LOWERING := 3
## Ticks between the cloth's two waves.
const WAVE_TICKS := 8

## Ticks left before she can raise the banner again.
var banner_cooldown: int = 0

## Fighters this banner has stunned (they're dizzy until it goes down).
var _stunned: Array[Fighter] = []
## True from the tick the banner starts until the step after it ends.
var _raised: bool = false
## Her last frame of it seen at the end of a step.
var _last_frame: int = 0


func _numbers() -> BannerData:
	return data as BannerData


func _move() -> MoveData:
	return fighter.stats.moveset.get(slot) as MoveData


func phases() -> Array[StringName]:
	return [&"banner"]


func reset() -> void:
	banner_cooldown = 0
	_stunned.clear()
	_raised = false
	_last_frame = 0


func before_tick(_input: FighterInput) -> void:
	banner_cooldown = maxi(banner_cooldown - 1, 0)


func pick_special(input: FighterInput, choice: StringName) -> StringName:
	if Fighter.special_direction(input) != slot:
		return choice
	if fighter.state != Fighter.State.AIR and banner_cooldown == 0:
		return &"banner"  # On the ground only, not during the cooldown.
	return Fighter.NO_MOVE


func replaces(move: StringName) -> bool:
	return move == slot


func on_move_started(move: StringName) -> void:
	if move == &"banner":
		_raised = true
		_last_frame = 0


func move_tick(_input: FighterInput) -> bool:
	return fighter.move == &"banner"


## Its move's own frames (no hitbox).
func phase_data(_move_name: StringName) -> MoveData:
	return _move()


func phase_finished(_move_name: StringName) -> bool:
	return fighter.state_frame >= _move().total_frames()


## True on the frames the banner is up (it stuns).
func is_up() -> bool:
	return fighter.state == Fighter.State.ATTACK and fighter.move == &"banner" \
		and fighter.state_frame > _numbers().raise_frames \
		and fighter.state_frame <= _move().startup


# --- The Match's step -------------------------------------------------------------------------


## At the end of the step (state_frame = the frame she's on): stun whoever is in range, or, once
## it's over, let go and start the cooldown.
func end_step(match_: Match) -> void:
	if not _raised:
		return
	if fighter.state == Fighter.State.ATTACK and fighter.move == &"banner":
		_last_frame = fighter.state_frame
		if is_up():
			_stun_in_range(match_)
		return
	# It ended, or a hit (or a KO) stopped it.
	if _last_frame < _move().startup:
		for victim in _stunned:
			if victim.state == Fighter.State.SHIELD_BREAK:
				victim.stun(1)  # Cut short: let go.
	_stunned.clear()
	_raised = false
	banner_cooldown = _numbers().cooldown_frames


func _stun_in_range(match_: Match) -> void:
	# Stunned on frame f, free on the frame after the last one up.
	var ticks := _move().startup - fighter.state_frame
	if ticks < 1:
		return
	var center := fighter.get_center()
	for victim in match_.get_fighters():
		if victim == fighter or not victim.can_be_hit():
			continue
		if victim.state in [Fighter.State.HITSTUN, Fighter.State.SHIELD_BREAK]:
			continue
		if victim.get_center().distance_to(center) > _numbers().radius:
			continue
		victim.stun(ticks)
		if victim not in _stunned:
			_stunned.append(victim)


# --- Presentation (only reads) ----------------------------------------------------------------


func phase_animation(_move_name: StringName) -> String:
	return String(slot)


func drawing(_animation: String, frame: int) -> int:
	if fighter.move != &"banner":
		return frame
	return banner_frame(fighter.state_frame, _numbers().raise_frames, _move().startup)


## Which drawing of the banner strip to show `ticks` ticks into it: raising up to `raise_frames`,
## then the cloth waving every WAVE_TICKS until `held_until`, then lowering.
static func banner_frame(ticks: int, raise_frames: int, held_until: int) -> int:
	if ticks <= raise_frames:
		return RAISING
	if ticks > held_until:
		return LOWERING
	return 1 + ((ticks - raise_frames - 1) / WAVE_TICKS) % 2
