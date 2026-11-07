class_name Fighter
extends CharacterBody2D
## A fighter: body, movement, moves, shield, damage % and state machine (docs/specs/fighter.md,
## docs/specs/moves.md). The Match advances it one tick at a time with tick(); it has no
## _physics_process of its own.

enum State { IDLE, RUN, CROUCH, AIR, ATTACK, SHIELD, SHIELD_DROP, SHIELD_BREAK, HITSTUN, HELPLESS }

## One tick of game time, in seconds (the game runs at 60 ticks per second).
const DELTA := 1.0 / 60.0
## Collision layer of pass-through platforms (docs/specs/architecture.md#collision-layers).
const STAGE_PLATFORM_LAYER := 2
const MAX_PERCENT := 999.0
## No move in progress.
const NO_MOVE := &""
## Normal attacks end when they land; specials have their own landing rules.
const NORMALS: Array[StringName] = [&"jab", &"down_tilt", &"up_tilt", &"side_tilt"]
## Special phases that end by their own rule, not after total_frames.
const OPEN_ENDED: Array[StringName] = [&"neutral_special_charge", &"down_special_dive", &"up_special"]

@export var stats: FighterStats

## 0 for P1, 1 for P2. Set by the Match.
var player_index: int = 0
## 1 = facing right, -1 = facing left.
var facing: int = 1
var state: State = State.IDLE
## Ticks spent in the current state; 1 on the tick the state is entered.
var state_frame: int = 0
var jumps_left: int = 0
## The move in progress while in ATTACK: a MoveSet property name (e.g. &"jab"), or a special's
## phase (&"neutral_special_charge", &"down_special_dive").
var move: StringName = NO_MOVE
## Damage taken; knockback grows with it.
var percent: float = 0.0
var shield_health: float = 0.0
## Up special can be used once per stay in the air.
var up_special_available: bool = true
## Set by the Match each tick: this fighter's projectile is still out.
var has_projectile: bool = false

## True from a ground jump until the fighter stops rising or releases jump.
var _can_short_hop: bool = false
## Ticks left before pass-through platforms become solid again after dropping through one.
var _drop_through_frames_left: int = 0
## Ticks since down was last pressed (a second press soon after drops through a platform).
var _ticks_since_down_press: int = 1000
## The move in progress has been in the air; a normal attack then ends on landing.
var _move_airborne: bool = false
## Player indexes the move in progress has hit (each move hits a fighter once).
var _hit_victims: Array[int] = []
## How long the current hitstun lasts.
var _hitstun_frames: int = 0
## Ticks the shield can't be lowered or jumped out of, after blocking a hit.
var _block_stun: int = 0
## The neutral special's punch, with its charge applied.
var _charged_punch: MoveData
## Up special has launched (it becomes HELPLESS once it stops rising).
var _launched: bool = false

@onready var _standing_hurtbox := $Hurtbox/Standing as CollisionShape2D
@onready var _crouching_hurtbox := $Hurtbox/Crouching as CollisionShape2D


## The middle of the body, in world coordinates (KO checks, the camera, the CPU).
func get_center() -> Vector2:
	return global_position + ($BodyShape as CollisionShape2D).position


## Where this fighter can be hit, in world coordinates: smaller while crouching.
func get_hurtbox_rect() -> Rect2:
	var shape := _crouching_hurtbox if state == State.CROUCH else _standing_hurtbox
	var size := (shape.shape as RectangleShape2D).size
	return Rect2(shape.global_position - size / 2.0, size)


## The data of the move in progress (the charged punch for the neutral special), or null when
## there's none or the phase has no data of its own (charging, diving).
func current_move() -> MoveData:
	if state != State.ATTACK or move == NO_MOVE:
		return null
	if move == &"neutral_special":
		return _charged_punch
	if move in [&"neutral_special_charge", &"down_special_dive"]:
		return null
	return stats.moveset.get(move) as MoveData


## True on the move's active frames.
func is_hitbox_active() -> bool:
	var data := current_move()
	return data != null and data.is_active_frame(state_frame)


## The move's hitbox in world coordinates, mirrored to the facing side.
func get_hitbox_rect() -> Rect2:
	var data := current_move()
	if data == null:
		return Rect2()
	var center := global_position + Vector2(data.hitbox_center.x * facing, data.hitbox_center.y)
	return Rect2(center - data.hitbox_size / 2.0, data.hitbox_size)


## True on the side special's last startup frame: the Match then adds this fighter's projectile.
func wants_projectile() -> bool:
	return state == State.ATTACK and move == &"side_special" \
			and state_frame == stats.moveset.side_special.startup


func has_hit(victim_index: int) -> bool:
	return victim_index in _hit_victims


## Remembers that the move in progress hit this fighter, so it can't hit them again.
func register_hit(victim_index: int) -> void:
	_hit_victims.append(victim_index)


## Which way `data` launches a victim whose center is at `victim_center`: 1 = right, -1 = left.
func knockback_side(data: MoveData, victim_center: Vector2) -> int:
	if data.direction == MoveData.Direction.AWAY:
		var dx := victim_center.x - get_center().x
		if dx != 0.0:
			return 1 if dx > 0.0 else -1
	return facing


## Gets hit by `data` (docs/specs/moves.md#damage--and-knockback): takes the damage, is launched
## toward `side` with knockback that grows with its %, and is stunned. `attacker_x` is where the
## attacker stood when the hit was collected; the victim turns to face it.
func take_hit(data: MoveData, side: int, attacker_x: float) -> void:
	percent = minf(percent + data.damage, MAX_PERCENT)
	var speed := data.base_knockback + data.knockback_growth * percent
	var angle := deg_to_rad(data.angle_deg)
	velocity = Vector2(cos(angle) * speed * side, -sin(angle) * speed)
	# Set directly, not with _set_state(): a hit during hitstun restarts it.
	state = State.HITSTUN
	state_frame = 0
	_hitstun_frames = maxi(stats.min_hitstun, roundi(speed * stats.hitstun_per_knockback))
	var to_attacker := attacker_x - global_position.x
	if to_attacker != 0.0:
		facing = 1 if to_attacker > 0.0 else -1
	elif side != 0:
		facing = -side
	jumps_left = stats.max_air_jumps
	up_special_available = true
	move = NO_MOVE
	_charged_punch = null
	_launched = false
	_can_short_hop = false


## Blocks `data` with the shield (docs/specs/fighter.md#shield): no damage or knockback, but the
## shield loses health, the shielder is pushed toward `side`, and the shield is held for a while.
func block_hit(data: MoveData, side: int) -> void:
	shield_health -= data.damage * stats.shield_damage_scale
	velocity.x = side * stats.block_pushback
	_block_stun = maxi(4, roundi(data.damage * 0.8))
	if shield_health <= 0.0:
		_break_shield()


## Puts the fighter at a spawn point, standing still: IDLE, 0 %, full shield, jumps and up special
## restored, platforms solid.
func spawn_at(spawn_position: Vector2, spawn_facing: int) -> void:
	global_position = spawn_position
	facing = spawn_facing
	velocity = Vector2.ZERO
	state = State.IDLE
	state_frame = 0
	jumps_left = stats.max_air_jumps
	move = NO_MOVE
	percent = 0.0
	shield_health = stats.shield_max
	up_special_available = true
	has_projectile = false
	_can_short_hop = false
	_drop_through_frames_left = 0
	_ticks_since_down_press = 1000
	_hit_victims.clear()
	_block_stun = 0
	_charged_punch = null
	_launched = false
	set_collision_mask_value(STAGE_PLATFORM_LAYER, true)


## Advances the fighter by one tick. Must run inside a physics frame, because move_and_slide()
## takes its time step from the physics engine (which is 1/60 s there).
func tick(input: FighterInput) -> void:
	assert(Engine.is_in_physics_frame(), "Fighter.tick() must run inside a physics frame")
	_end_finished_state(input)
	match state:
		State.AIR:
			_air_actions(input)
		State.IDLE, State.RUN, State.CROUCH:
			_ground_actions(input)
		State.SHIELD:
			_shield_actions(input)
		State.ATTACK:
			_special_phases(input)
	_update_shield_health()

	_apply_movement(input)

	_update_platform_collision(input)
	move_and_slide()

	_after_move(input)
	_count_down_drop_through()
	_update_platform_collision(input)
	if input.down_pressed:
		_ticks_since_down_press = 0
	_ticks_since_down_press += 1
	state_frame += 1


## Leaves a state whose time is up. Runs first, so the fighter can act that same tick.
func _end_finished_state(input: FighterInput) -> void:
	match state:
		State.ATTACK:
			if move not in OPEN_ENDED and state_frame >= current_move().total_frames():
				move = NO_MOVE
				_set_state(_free_state(input))
		State.HITSTUN:
			if state_frame >= _hitstun_frames:
				_set_state(_free_state(input))
		State.SHIELD_DROP:
			if state_frame >= stats.shield_drop_frames:
				_set_state(_free_state(input))
		State.SHIELD_BREAK:
			if state_frame >= stats.shield_break_frames:
				shield_health = stats.shield_reset_health
				_set_state(_free_state(input))


## The state a fighter that can act is in, given where it is.
func _free_state(input: FighterInput) -> State:
	if not is_on_floor():
		return State.AIR
	if input.down_held:
		return State.CROUCH
	return State.RUN if input.move_x != 0.0 else State.IDLE


## IDLE/RUN/CROUCH, first that applies: attack, special, jump, shield, drop through a platform
## (down pressed twice), crouch, run, stand.
func _ground_actions(input: FighterInput) -> void:
	if input.attack_pressed:
		_start_move(_pick_normal(input), input)
	elif input.special_pressed and _pick_special(input) != NO_MOVE:
		_start_move(_pick_special(input), input)
	elif input.jump_pressed:
		_jump()
	elif input.shield_held and shield_health > 0.0:
		_set_state(State.SHIELD)
	elif _is_double_tap(input) and _is_on_pass_through_platform():
		_drop_through_frames_left = stats.drop_through_frames
		_set_state(State.AIR)
	elif input.down_held:
		_turn_toward(input.move_x)
		_set_state(State.CROUCH)
	elif input.move_x != 0.0:
		_turn_toward(input.move_x)
		_set_state(State.RUN)
	else:
		_set_state(State.IDLE)


## AIR: attack, special, double jump, or cut a ground jump short.
func _air_actions(input: FighterInput) -> void:
	if input.attack_pressed:
		_start_move(_pick_normal(input), input)
	elif input.special_pressed and _pick_special(input) != NO_MOVE:
		_start_move(_pick_special(input), input)
	elif input.jump_pressed and jumps_left > 0:
		velocity.y = -stats.double_jump_velocity
		velocity.x = input.move_x * stats.air_speed
		jumps_left -= 1
		_can_short_hop = false
	elif _can_short_hop:
		if velocity.y >= 0.0:
			_can_short_hop = false
		elif not input.jump_held:
			velocity.y *= stats.short_hop_cut
			_can_short_hop = false


## SHIELD: jump out, or lower it; neither during block stun.
func _shield_actions(input: FighterInput) -> void:
	if _block_stun > 0:
		_block_stun -= 1
	elif input.jump_pressed:
		_jump()
	elif not input.shield_held:
		_set_state(State.SHIELD_DROP)


## Charge release and the up special's launch.
func _special_phases(input: FighterInput) -> void:
	match move:
		&"neutral_special_charge":
			var charge_frames := stats.moveset.neutral_special.charge_frames
			if not input.special_held or state_frame >= charge_frames:
				_release_punch(clampf(float(state_frame) / charge_frames, 0.0, 1.0))
		&"up_special":
			var data := stats.moveset.up_special
			if state_frame == data.startup:
				velocity = Vector2(input.move_x * data.drift_speed, -data.launch_speed)
				_launched = true


## Shield health drains while shielding (breaking at 0) and regrows otherwise.
func _update_shield_health() -> void:
	if state == State.SHIELD:
		shield_health -= stats.shield_drain
		if shield_health <= 0.0:
			_break_shield()
	elif state != State.SHIELD_BREAK:
		shield_health = minf(shield_health + stats.shield_regen, stats.shield_max)


func _break_shield() -> void:
	shield_health = 0.0
	_block_stun = 0
	state = State.SHIELD_BREAK
	state_frame = 0


func _jump() -> void:
	velocity.y = -stats.jump_velocity
	_can_short_hop = true
	_set_state(State.AIR)


## The normal attack for the held direction: up, then down, then sideways, else the jab.
func _pick_normal(input: FighterInput) -> StringName:
	if input.up_held:
		return &"up_tilt"
	if input.down_held:
		return &"down_tilt"
	if input.move_x != 0.0:
		return &"side_tilt"
	return &"jab"


## The special for the held direction, or none when it can't be used now.
func _pick_special(input: FighterInput) -> StringName:
	if input.up_held:
		return &"up_special" if up_special_available else NO_MOVE
	if input.down_held:
		return &"down_special_dive" if state == State.AIR else &"down_special"
	if input.move_x != 0.0:
		return &"side_special" if not has_projectile else NO_MOVE
	return &"neutral_special_charge"


func _start_move(move_name: StringName, input: FighterInput) -> void:
	var on_ground := state != State.AIR
	# A side move on the ground turns toward the held direction first.
	if on_ground and String(move_name).begins_with("side_"):
		_turn_toward(input.move_x)
	if move_name == &"up_special":
		up_special_available = false
		_launched = false
	_move_airborne = not on_ground
	_can_short_hop = false
	_hit_victims.clear()
	move = move_name
	# Set directly: a move always starts at frame 1.
	state = State.ATTACK
	state_frame = 0


## Turns the charge into the punch: a copy of the punch's data with the charge's extra power.
func _release_punch(charge: float) -> void:
	var punch := stats.moveset.neutral_special
	_charged_punch = punch.duplicate() as MoveData
	_charged_punch.damage = punch.damage + punch.charge_damage * charge
	_charged_punch.base_knockback = punch.base_knockback + punch.charge_knockback * charge
	_hit_victims.clear()
	move = &"neutral_special"
	state_frame = 0


func _turn_toward(move_x: float) -> void:
	if move_x != 0.0:
		facing = 1 if move_x > 0.0 else -1


## Steering, friction and gravity for the current state.
func _apply_movement(input: FighterInput) -> void:
	match state:
		State.AIR:
			_steer(input.move_x, stats.air_speed, stats.air_accel, stats.air_friction)
			_apply_gravity()
		State.ATTACK:
			_move_during_attack(input)
		State.HITSTUN:
			# No input. Moving up counts as airborne: on the tick a standing fighter is launched,
			# is_on_floor() is still true from the last move.
			if not is_on_floor() or velocity.y < 0.0:
				_steer(0.0, 0.0, 0.0, stats.hitstun_friction)
				_apply_gravity()
			else:
				_steer(0.0, 0.0, 0.0, stats.ground_friction)
		State.HELPLESS:
			_steer(input.move_x, stats.helpless_air_speed, stats.air_accel, stats.air_friction)
			_apply_gravity()
		State.CROUCH, State.SHIELD, State.SHIELD_DROP, State.SHIELD_BREAK:
			# No walking: slide to a stop.
			_steer(0.0, 0.0, 0.0, stats.ground_friction)
			if not is_on_floor():
				_apply_gravity()
		_:
			_steer(input.move_x, stats.run_speed, stats.ground_accel, stats.ground_friction)
			if not is_on_floor():
				_apply_gravity()


func _move_during_attack(input: FighterInput) -> void:
	if move == &"down_special_dive":
		velocity = Vector2(0.0, stats.moveset.down_special.dive_speed)
	elif move == &"up_special" and _launched:
		_steer(input.move_x, stats.moveset.up_special.drift_speed, stats.air_accel, stats.air_friction)
		_apply_gravity()
	elif is_on_floor() and velocity.y >= 0.0:
		# A move on the ground doesn't steer: slide to a stop.
		_steer(0.0, 0.0, 0.0, stats.ground_friction)
	else:
		_steer(input.move_x, stats.air_speed, stats.air_accel, stats.air_friction)
		_apply_gravity()


## Moves horizontal speed toward `move_x × top_speed` at `accel`, or toward 0 at `friction`.
func _steer(move_x: float, top_speed: float, accel: float, friction: float) -> void:
	if move_x != 0.0:
		velocity.x = move_toward(velocity.x, move_x * top_speed, accel * DELTA)
	else:
		velocity.x = move_toward(velocity.x, 0.0, friction * DELTA)


func _apply_gravity() -> void:
	velocity.y = minf(velocity.y + stats.gravity * DELTA, stats.max_fall_speed)


## Landing, walking off ledges and the specials' air rules, decided from where move_and_slide()
## left the fighter.
func _after_move(input: FighterInput) -> void:
	match state:
		State.AIR, State.HELPLESS:
			if is_on_floor():
				_land(input)
		State.ATTACK:
			_after_move_in_attack(input)
		State.HITSTUN:
			pass  # Lands on platforms like anyone, but stays stunned.
		State.IDLE, State.RUN, State.CROUCH:
			if not is_on_floor():
				# Walked off a ledge: the double jump is still there.
				_set_state(State.AIR)


func _after_move_in_attack(input: FighterInput) -> void:
	if not is_on_floor():
		_move_airborne = true
		# Up special: helpless once the launch stops rising.
		if move == &"up_special" and _launched and velocity.y >= 0.0:
			move = NO_MOVE
			_set_state(State.HELPLESS)
		return
	if move == &"down_special_dive":
		# The dive lands into the burst, from its first frame.
		jumps_left = stats.max_air_jumps
		up_special_available = true
		_hit_victims.clear()
		move = &"down_special"
		state_frame = 0
	elif _move_airborne and (move in NORMALS or (move == &"up_special" and _launched)):
		# A normal attack (or a launched up special) ends on landing: no landing lag.
		move = NO_MOVE
		_land(input)


func _land(input: FighterInput) -> void:
	jumps_left = stats.max_air_jumps
	up_special_available = true
	_can_short_hop = false
	_launched = false
	_set_state(_free_state(input))


## Down pressed again within drop_double_tap_frames of the last press.
func _is_double_tap(input: FighterInput) -> bool:
	return input.down_pressed and _ticks_since_down_press <= stats.drop_double_tap_frames


func _count_down_drop_through() -> void:
	if _drop_through_frames_left > 0:
		_drop_through_frames_left -= 1


## Pass-through platforms are ignored for a while after dropping through one, and while falling
## with down held (in the air, during a move in the air, and while helpless). Runs before the move
## (so this tick's input counts) and after it (so the mask is right between ticks).
func _update_platform_collision(input: FighterInput) -> void:
	var airborne := state == State.AIR or state == State.HELPLESS \
			or (state == State.ATTACK and not is_on_floor())
	var ignore := _drop_through_frames_left > 0 or (airborne and input.down_held)
	set_collision_mask_value(STAGE_PLATFORM_LAYER, not ignore)


## True if the fighter stands on a pass-through platform (not on solid ground).
func _is_on_pass_through_platform() -> bool:
	if not is_on_floor():
		return false
	# Look 1 px down, colliding with pass-through platforms only.
	var saved_mask := collision_mask
	collision_mask = 0
	set_collision_mask_value(STAGE_PLATFORM_LAYER, true)
	var platform_below := test_move(global_transform, Vector2(0, 1))
	collision_mask = saved_mask
	return platform_below


func _set_state(new_state: State) -> void:
	if new_state != state:
		state = new_state
		state_frame = 0
