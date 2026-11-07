class_name Fighter
extends CharacterBody2D
## A fighter: body, movement and state machine (docs/specs/fighter.md).
## The Match advances it one tick at a time with tick(); it has no _physics_process of its own.

enum State { IDLE, RUN, AIR }

## One tick of game time, in seconds (the game runs at 60 ticks per second).
const DELTA := 1.0 / 60.0
## Collision layer of pass-through platforms (docs/specs/architecture.md#collision-layers).
const STAGE_PLATFORM_LAYER := 2

@export var stats: FighterStats

## 0 for P1, 1 for P2. Set by the Match.
var player_index: int = 0
## 1 = facing right, -1 = facing left.
var facing: int = 1
var state: State = State.IDLE
## Ticks spent in the current state; 1 on the tick the state is entered.
var state_frame: int = 0
var jumps_left: int = 0

## True from a ground jump until the fighter stops rising or releases jump.
var _can_short_hop: bool = false
## Ticks left before pass-through platforms become solid again after dropping through one.
var _drop_through_frames_left: int = 0


## The middle of the body, in world coordinates (KO checks, the camera, the CPU).
func get_center() -> Vector2:
	return global_position + ($BodyShape as CollisionShape2D).position


## Puts the fighter at a spawn point, standing still: IDLE, jumps restored, platforms solid.
func spawn_at(spawn_position: Vector2, spawn_facing: int) -> void:
	global_position = spawn_position
	facing = spawn_facing
	velocity = Vector2.ZERO
	state = State.IDLE
	state_frame = 0
	jumps_left = stats.max_air_jumps
	_can_short_hop = false
	_drop_through_frames_left = 0
	set_collision_mask_value(STAGE_PLATFORM_LAYER, true)


## Advances the fighter by one tick. Must run inside a physics frame, because move_and_slide()
## takes its time step from the physics engine (which is 1/60 s there).
func tick(input: FighterInput) -> void:
	assert(Engine.is_in_physics_frame(), "Fighter.tick() must run inside a physics frame")
	if state == State.AIR:
		_air_actions(input)
	else:
		_ground_actions(input)

	if state == State.AIR:
		_steer(input.move_x, stats.air_speed, stats.air_accel, stats.air_friction)
	else:
		_steer(input.move_x, stats.run_speed, stats.ground_accel, stats.ground_friction)
	if state == State.AIR or not is_on_floor():
		velocity.y = minf(velocity.y + stats.gravity * DELTA, stats.max_fall_speed)

	_update_platform_collision(input)
	move_and_slide()

	_after_move(input)
	_count_down_drop_through()
	_update_platform_collision(input)
	state_frame += 1


## IDLE/RUN: jump, drop through a platform, or run/stand.
func _ground_actions(input: FighterInput) -> void:
	if input.jump_pressed:
		velocity.y = -stats.jump_velocity
		_can_short_hop = true
		_set_state(State.AIR)
	elif input.down_pressed and _is_on_pass_through_platform():
		_drop_through_frames_left = stats.drop_through_frames
		_set_state(State.AIR)
	elif input.move_x != 0.0:
		facing = 1 if input.move_x > 0.0 else -1
		_set_state(State.RUN)
	else:
		_set_state(State.IDLE)


## AIR: double jump, or cut a ground jump short.
func _air_actions(input: FighterInput) -> void:
	if input.jump_pressed and jumps_left > 0:
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


## Moves horizontal speed toward `move_x × top_speed` at `accel`, or toward 0 at `friction`.
func _steer(move_x: float, top_speed: float, accel: float, friction: float) -> void:
	if move_x != 0.0:
		velocity.x = move_toward(velocity.x, move_x * top_speed, accel * DELTA)
	else:
		velocity.x = move_toward(velocity.x, 0.0, friction * DELTA)


## Landing and walking off ledges, decided from where move_and_slide() left the fighter.
func _after_move(input: FighterInput) -> void:
	if state == State.AIR:
		if is_on_floor():
			jumps_left = stats.max_air_jumps
			_can_short_hop = false
			_set_state(State.RUN if input.move_x != 0.0 else State.IDLE)
	elif not is_on_floor():
		# Walked off a ledge: the double jump is still there.
		_set_state(State.AIR)


func _count_down_drop_through() -> void:
	if _drop_through_frames_left > 0:
		_drop_through_frames_left -= 1


## Pass-through platforms are ignored for a while after dropping through one, and in the air
## while down is held. Runs before the move (so this tick's input counts) and after it (so the
## mask is right for anyone reading the fighter between ticks).
func _update_platform_collision(input: FighterInput) -> void:
	var ignore := _drop_through_frames_left > 0 or (state == State.AIR and input.down_held)
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
