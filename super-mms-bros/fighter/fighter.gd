class_name Fighter
extends CharacterBody2D
## A fighter: body, movement and state machine (docs/specs/fighter.md).
## The Match advances it one tick at a time with tick(); it has no _physics_process of its own.

enum State { IDLE, RUN, AIR }

## One tick of game time, in seconds (the game runs at 60 ticks per second).
const DELTA := 1.0 / 60.0

@export var stats: FighterStats

## 0 for P1, 1 for P2. Set by the Match.
var player_index: int = 0
## 1 = facing right, -1 = facing left.
var facing: int = 1
var state: State = State.IDLE
## Ticks spent in the current state; 1 on the tick the state is entered.
var state_frame: int = 0
var jumps_left: int = 0


## Puts the fighter at a spawn point, standing still: IDLE, jumps restored.
func spawn_at(spawn_position: Vector2, spawn_facing: int) -> void:
	global_position = spawn_position
	facing = spawn_facing
	velocity = Vector2.ZERO
	state = State.IDLE
	state_frame = 0
	jumps_left = stats.max_air_jumps


## Advances the fighter by one tick. Must run inside a physics frame, because move_and_slide()
## takes its time step from the physics engine (which is 1/60 s there).
func tick(input: FighterInput) -> void:
	assert(Engine.is_in_physics_frame(), "Fighter.tick() must run inside a physics frame")
	if state != State.AIR:
		_ground_actions(input)

	if state == State.AIR:
		_steer(input.move_x, stats.air_speed, stats.air_accel, stats.air_friction)
	else:
		_steer(input.move_x, stats.run_speed, stats.ground_accel, stats.ground_friction)
	if state == State.AIR or not is_on_floor():
		velocity.y = minf(velocity.y + stats.gravity * DELTA, stats.max_fall_speed)

	move_and_slide()

	_after_move(input)
	state_frame += 1


## IDLE/RUN: run or stand.
func _ground_actions(input: FighterInput) -> void:
	if input.move_x != 0.0:
		facing = 1 if input.move_x > 0.0 else -1
		_set_state(State.RUN)
	else:
		_set_state(State.IDLE)


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
			_set_state(State.RUN if input.move_x != 0.0 else State.IDLE)
	elif not is_on_floor():
		_set_state(State.AIR)


func _set_state(new_state: State) -> void:
	if new_state != state:
		state = new_state
		state_frame = 0
