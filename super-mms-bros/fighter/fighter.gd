class_name Fighter
extends CharacterBody2D
## A fighter: body, movement, moves, shield, damage % and state machine (docs/specs/fighter.md,
## docs/specs/moves.md). The Match advances it one tick at a time with tick(); it has no
## _physics_process of its own.

enum State {
	IDLE, RUN, CROUCH, AIR, ATTACK, SHIELD, SHIELD_DROP, SHIELD_BREAK, HITSTUN, HELPLESS, KO,
	SPOT_DODGE, ROLL, AIR_DODGE, LEDGE, LEDGE_CLIMB, TRIPPED,
}

## Gitte's stances (docs/specs/moves.md#gitte--scissors-and-stances), in switching order.
enum Stance { PLUS, MINUS, DIVIDE, MULTIPLY }

## One tick of game time, in seconds (the game runs at 60 ticks per second).
const DELTA := 1.0 / 60.0
## Collision layer of pass-through platforms (docs/specs/architecture.md#collision-layers).
const STAGE_PLATFORM_LAYER := 2
const MAX_PERCENT := 999.0
## No move in progress.
const NO_MOVE := &""
## Normal attacks (ground and air) end when they land; specials have their own landing rules.
const NORMALS: Array[StringName] = [&"jab", &"down_tilt", &"up_tilt", &"side_tilt",
		&"neutral_air", &"forward_air", &"back_air", &"up_air", &"down_air"]
## Special phases that end by their own rule, not after total_frames.
const OPEN_ENDED: Array[StringName] = [&"neutral_special_charge", &"down_special_dive", &"up_special",
		&"vine_pull", &"vine_swing", &"pyramid_rise"]
## The vine up special's phases (docs/specs/moves.md#fidusen--banana-book-vine).
const VINE_PHASES: Array[StringName] = [&"vine_pull", &"vine_swing"]
## Grounded states a banana peel can't trip.
const UNTRIPPABLE: Array[State] = [State.LEDGE, State.LEDGE_CLIMB, State.KO, State.TRIPPED]

@export var stats: FighterStats

## 0 for P1, 1 for P2. Set by the Match.
var player_index: int = 0
## Which character this is (its sprites are in assets/fighters/<id>/); set by the Match.
var character_id: String = CharacterData.DEFAULT_ID
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
## Set by the Match each tick: this fighter's summoned hand is still out.
var has_hand: bool = false
## Lives left; the Match takes one on a KO.
var stocks: int = 0
## Ticks left in which the fighter can't be hit (after respawning). Counted down by the Match.
var invulnerable_frames: int = 0
## The air dodge can be used once per stay in the air.
var air_dodge_available: bool = true
## The ledge the fighter hangs from or climbs up (or is pulled to by a vine), or null.
var ledge: Ledge = null
## Where the vine hangs from while swinging (the ledge corner while pulled to one).
var vine_anchor: Vector2 = Vector2.ZERO
## Where the pyramid she rides rises from: her x, and the top of the floor it comes out of.
var pyramid_origin: Vector2 = Vector2.ZERO
## The stance (only for a fighter whose down special has `stances`); + at every spawn. Setting it
## resizes the body.
var stance: Stance = Stance.PLUS:
	set(value):
		stance = value
		if is_node_ready():
			_apply_size()

## True from a ground jump until the fighter stops rising or releases jump.
var _can_short_hop: bool = false
## Fast-falling: falls at fast_fall_speed until landing, a double jump, a hit or an up special.
var _fast_falling: bool = false
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
## Which way the roll in progress goes: -1 left, 1 right.
var _roll_direction: int = 0
## Ticks left before a ledge can be grabbed again, after leaving one.
var _ledge_regrab_left: int = 0
## The next ledge grab gives intangibility: true after touching the ground, a hit or a spawn.
var _ledge_intangibility_earned: bool = true
## The current ledge grab gave intangibility.
var _ledge_intangible: bool = false
## Down was held on the last tick (a fighter holding down doesn't grab ledges).
var _down_held: bool = false
## Where a vine pull started, and how long the current trip lasts.
var _vine_from: Vector2 = Vector2.ZERO
var _trip_frames: int = 0
## Feet height when the pyramid started rising (in the air she waits there for the tip).
var _rise_start_y: float = 0.0

@onready var _body_shape := $BodyShape as CollisionShape2D
@onready var _body_offset := _body_shape.position
@onready var _standing_hurtbox := $Hurtbox/Standing as CollisionShape2D
@onready var _crouching_hurtbox := $Hurtbox/Crouching as CollisionShape2D


## The middle of the body, in world coordinates (KO checks, the camera, the CPU).
func get_center() -> Vector2:
	return global_position + ($BodyShape as CollisionShape2D).position


## Where this fighter can be hit, in world coordinates: smaller while crouching.
func get_hurtbox_rect() -> Rect2:
	var low := state == State.CROUCH or state == State.TRIPPED
	var shape := _crouching_hurtbox if low else _standing_hurtbox
	var s := size_scale()
	var size := (shape.shape as RectangleShape2D).size * s
	var center := global_position + (shape.global_position - global_position) * s
	return Rect2(center - size / 2.0, size)


## The stance numbers, or null for a fighter without stances.
func stance_data() -> StanceData:
	return stats.moveset.down_special.stances


## How big the fighter is (÷ small, × large; 1 otherwise): body, hurtbox, hitboxes and sprite
## scale from the feet.
func size_scale() -> float:
	var data := stance_data()
	if data == null:
		return 1.0
	match stance:
		Stance.DIVIDE:
			return data.small_scale
		Stance.MULTIPLY:
			return data.large_scale
	return 1.0


## Run and air speed ×this (÷ is faster).
func speed_scale() -> float:
	var data := stance_data()
	return data.small_speed if data != null and stance == Stance.DIVIDE else 1.0


## A move's hit values as this fighter deals them: × makes specials hit harder.
func boosted(data: MoveData, special: bool) -> MoveData:
	var stances := stance_data()
	if stances == null or not special or stance != Stance.MULTIPLY:
		return data
	var copy := data.duplicate() as MoveData
	copy.damage = data.damage * stances.large_special
	copy.base_knockback = data.base_knockback * stances.large_special
	return copy


## A projectile's hit values when thrown now: + makes it hurt more, × (a special) too.
func projectile_data(data: MoveData) -> MoveData:
	var copy := boosted(data, true)
	var stances := stance_data()
	if stances != null and stance == Stance.PLUS:
		copy = copy.duplicate() as MoveData
		copy.damage = data.damage * stances.projectile_damage
	return copy


## The share of a normal attack's damage that heals this fighter (− stance), else 0.
func lifesteal() -> float:
	var data := stance_data()
	return data.lifesteal if data != null and stance == Stance.MINUS else 0.0


## Scales the body shape to the stance's size (from the feet).
func _apply_size() -> void:
	var s := size_scale()
	_body_shape.scale = Vector2(s, s)
	_body_shape.position = _body_offset * s


## False while KO'd, invulnerable or intangible.
func can_be_hit() -> bool:
	return state != State.KO and invulnerable_frames == 0 and not is_intangible()


## On a dodge's intangible frames, early in a ledge grab (if earned) and while climbing up, hits
## pass through the fighter (docs/specs/fighter.md#dodges).
func is_intangible() -> bool:
	match state:
		State.SPOT_DODGE:
			return _between(state_frame, stats.spot_dodge_intangible_start, stats.spot_dodge_intangible_end)
		State.ROLL:
			return _between(state_frame, stats.roll_intangible_start, stats.roll_intangible_end)
		State.AIR_DODGE:
			return _between(state_frame, stats.air_dodge_intangible_start, stats.air_dodge_intangible_end)
		State.LEDGE:
			return _ledge_intangible and state_frame <= stats.ledge_intangible_frames
		State.LEDGE_CLIMB:
			return true
	return false


static func _between(frame: int, first: int, last: int) -> bool:
	return frame >= first and frame <= last


## True if the fighter may grab `target` now (docs/specs/fighter.md#ledge): airborne and falling
## (or in a launched up special), not holding down, not just off a ledge, on the outer side of
## the corner, with the corner inside its grab box. The Match checks who else holds it.
func can_grab_ledge(target: Ledge) -> bool:
	if _ledge_regrab_left > 0 or _down_held or is_on_floor():
		return false
	var able := false
	match state:
		State.AIR, State.HELPLESS, State.AIR_DODGE:
			able = velocity.y >= 0.0
		State.ATTACK:
			able = move == &"up_special" and _launched
	if not able or (global_position.x - target.point.x) * target.side < 0.0:
		return false
	var box := stats.ledge_grab_box
	var s := size_scale()
	return Rect2(box.position * s, box.size * s).has_point(target.point - global_position)


## Hangs from `target`: snaps below the corner facing the stage, stops, and gets the double jump,
## up special and air dodge back. Called by the Match after the fighters moved, so this tick
## counts as the first frame of LEDGE.
func grab_ledge(target: Ledge) -> void:
	ledge = target
	global_position = _hang_position()
	velocity = Vector2.ZERO
	facing = -target.side
	state = State.LEDGE
	state_frame = 1
	move = NO_MOVE
	_charged_punch = null
	_launched = false
	_fast_falling = false
	_can_short_hop = false
	jumps_left = stats.max_air_jumps
	up_special_available = true
	air_dodge_available = true
	_ledge_intangible = _ledge_intangibility_earned
	_ledge_intangibility_earned = false


## Knocked out by the Match (it left the blast zone): stops, cancels everything and waits, hidden,
## until the Match respawns it with spawn_at().
func knock_out() -> void:
	state = State.KO
	state_frame = 0
	velocity = Vector2.ZERO
	move = NO_MOVE
	_charged_punch = null
	_launched = false
	_hit_victims.clear()
	ledge = null


## The data of the move in progress (the charged punch for the neutral special), or null when
## there's none or the phase has no data of its own (charging).
func current_move() -> MoveData:
	if state != State.ATTACK or move == NO_MOVE:
		return null
	if move == &"neutral_special":
		# The charged punch, or a summon's own data (it has no charge).
		return _charged_punch if _charged_punch != null else stats.moveset.neutral_special
	if move == &"neutral_special_charge" or move in VINE_PHASES:
		return null
	if move == &"pyramid_rise":
		return stats.moveset.up_special.pyramid.tip_hit
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
	if move == &"pyramid_rise":
		# On the pyramid's tip, at the pyramid's own size.
		return Rect2(pyramid_tip() + data.hitbox_center - data.hitbox_size / 2.0, data.hitbox_size)
	var s := size_scale()
	var center := global_position + Vector2(data.hitbox_center.x * facing, data.hitbox_center.y) * s
	return Rect2(center - data.hitbox_size * s / 2.0, data.hitbox_size * s)


## True on the side special's last startup frame: the Match then adds this fighter's projectile.
func wants_projectile() -> bool:
	return state == State.ATTACK and move == &"side_special" \
			and state_frame == stats.moveset.side_special.startup


## True on a summoning neutral special's last startup frame: the Match then adds the hand.
func wants_hand() -> bool:
	var summon := stats.moveset.neutral_special
	return state == State.ATTACK and move == &"neutral_special" and summon.hand != null \
			and state_frame == summon.startup


## True on a peel-placing down special's last startup frame: the Match then adds a peel.
func wants_peel() -> bool:
	var data := stats.moveset.down_special
	return state == State.ATTACK and move == &"down_special" and data.peel != null \
			and state_frame == data.startup


## True on a vine up special's last startup frame: the Match then starts a pull or a swing.
func wants_vine() -> bool:
	var data := stats.moveset.up_special
	return state == State.ATTACK and move == &"up_special" and data.vine != null \
			and not _launched and state_frame == data.startup


## The vine reaches `target`: pulled in a straight line to hanging from it (then grabs it).
func start_vine_pull(target: Ledge) -> void:
	ledge = target
	vine_anchor = target.point
	_vine_from = global_position
	velocity = Vector2.ZERO
	move = &"vine_pull"
	state_frame = 0


## A vine from straight above: swings forward on it, then lets go.
func start_vine_swing() -> void:
	vine_anchor = global_position + Vector2(0.0, -stats.moveset.up_special.vine.length)
	move = &"vine_swing"
	state_frame = 0


## True on a pyramid up special's last startup frame: the Match then raises a pyramid or hops.
func wants_pyramid() -> bool:
	var data := stats.moveset.up_special
	return state == State.ATTACK and move == &"up_special" and data.pyramid != null \
			and not _launched and state_frame == data.startup


## A pyramid rises out of the floor whose top is at `floor_y`, below her: she rides its tip up.
func start_pyramid(floor_y: float) -> void:
	pyramid_origin = Vector2(global_position.x, floor_y)
	_rise_start_y = global_position.y
	velocity = Vector2.ZERO
	_hit_victims.clear()
	move = &"pyramid_rise"
	state_frame = 0


## No floor in reach for a pyramid: a weak hop, then like a launched up special.
func start_pyramid_hop() -> void:
	velocity = Vector2(velocity.x, -stats.moveset.up_special.pyramid.hop_speed)
	_launched = true


## True while she rides her pyramid up.
func is_riding_pyramid() -> bool:
	return state == State.ATTACK and move == &"pyramid_rise"


## Where the pyramid's tip is now (after this tick's rise).
func pyramid_tip() -> Vector2:
	var height := stats.moveset.up_special.pyramid.tip_height(state_frame)
	return pyramid_origin - Vector2(0.0, height)


## True if a banana peel can trip this fighter now: on the ground, hittable, not hanging or down.
func can_trip() -> bool:
	return is_on_floor() and state not in UNTRIPPABLE and can_be_hit()


## Slips on a banana peel: takes its damage, stops, and lies on the floor for its ticks.
func trip(peel: PeelData) -> void:
	percent = minf(percent + peel.damage, MAX_PERCENT)
	velocity.x = 0.0
	state = State.TRIPPED
	state_frame = 0
	_trip_frames = peel.trip_frames
	move = NO_MOVE
	_charged_punch = null
	_launched = false
	_fast_falling = false
	_can_short_hop = false


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
	if velocity.y > 0.0 and is_on_floor():
		# A spike on a standing fighter bounces it up instead of driving it into the floor.
		velocity.y = -velocity.y
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
	air_dodge_available = true
	_ledge_intangibility_earned = true
	if ledge != null:
		ledge = null
		_ledge_regrab_left = stats.ledge_regrab_frames
	_fast_falling = false
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
	invulnerable_frames = 0
	jumps_left = stats.max_air_jumps
	move = NO_MOVE
	percent = 0.0
	shield_health = stats.shield_max
	up_special_available = true
	has_projectile = false
	_can_short_hop = false
	_fast_falling = false
	_drop_through_frames_left = 0
	_ticks_since_down_press = 1000
	_hit_victims.clear()
	_block_stun = 0
	_charged_punch = null
	_launched = false
	air_dodge_available = true
	ledge = null
	_ledge_regrab_left = 0
	_ledge_intangibility_earned = true
	_ledge_intangible = false
	_down_held = false
	stance = Stance.PLUS
	set_collision_mask_value(STAGE_PLATFORM_LAYER, true)


## Advances the fighter by one tick. Must run inside a physics frame, because move_and_slide()
## takes its time step from the physics engine (which is 1/60 s there).
func tick(input: FighterInput) -> void:
	assert(Engine.is_in_physics_frame(), "Fighter.tick() must run inside a physics frame")
	if state == State.KO:
		return
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
		State.LEDGE:
			_ledge_actions(input)
	_update_shield_health()

	if state == State.LEDGE or state == State.LEDGE_CLIMB or _is_vine_pulled():
		# Hanging, climbing and being pulled to a ledge are placed directly, without physics.
		_hold_ledge()
	else:
		_apply_movement(input)
		_update_platform_collision(input)
		move_and_slide()
		_after_move(input)
		if is_on_floor():
			_ledge_intangibility_earned = true
	_count_down_drop_through()
	_update_platform_collision(input)
	_ledge_regrab_left = maxi(_ledge_regrab_left - 1, 0)
	_down_held = input.down_held
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
		State.TRIPPED:
			if state_frame >= _trip_frames:
				_set_state(_free_state(input))
		State.SHIELD_DROP:
			if state_frame >= stats.shield_drop_frames:
				_set_state(_free_state(input))
		State.SHIELD_BREAK:
			if state_frame >= stats.shield_break_frames:
				shield_health = stats.shield_reset_health
				_set_state(_free_state(input))
		State.SPOT_DODGE:
			if state_frame >= stats.spot_dodge_frames:
				_set_state(_after_dodge_state(input))
		State.ROLL:
			if state_frame >= stats.roll_frames:
				velocity.x = 0.0
				facing = -_roll_direction
				_set_state(_after_dodge_state(input))
		State.AIR_DODGE:
			if state_frame >= stats.air_dodge_frames:
				_set_state(State.AIR)
		State.LEDGE:
			if state_frame >= stats.ledge_max_hang:
				_let_go()
		State.LEDGE_CLIMB:
			if state_frame >= stats.ledge_climb_frames:
				ledge = null
				_set_state(State.IDLE)


## After a ground dodge: back to the shield if it's still held, else free.
func _after_dodge_state(input: FighterInput) -> State:
	if input.shield_held and shield_health > 0.0 and is_on_floor():
		return State.SHIELD
	return _free_state(input)


## The state a fighter that can act is in, given where it is.
func _free_state(input: FighterInput) -> State:
	if not is_on_floor():
		return State.AIR
	if input.down_held:
		return State.CROUCH
	return State.RUN if input.move_x != 0.0 else State.IDLE


## IDLE/RUN/CROUCH, first that applies: attack, special, drop through a platform (jump with down
## held), jump, shield, drop through a platform (down pressed twice), crouch, run, stand.
func _ground_actions(input: FighterInput) -> void:
	if input.attack_pressed:
		_start_move(_pick_normal(input), input)
	elif input.special_pressed and _pick_special(input) != NO_MOVE:
		_start_move(_pick_special(input), input)
	elif input.jump_pressed and input.down_held and _is_on_pass_through_platform():
		_drop_through()
	elif input.jump_pressed:
		_jump()
	elif input.shield_held and shield_health > 0.0:
		if not _try_dodge(input):
			_set_state(State.SHIELD)
	elif _is_double_tap(input) and _is_on_pass_through_platform():
		_drop_through()
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
		velocity.x = input.move_x * stats.air_speed * speed_scale()
		jumps_left -= 1
		_fast_falling = false
		_can_short_hop = false
	elif input.shield_pressed and air_dodge_available:
		_start_air_dodge(input)
	elif _can_short_hop:
		if velocity.y >= 0.0:
			_can_short_hop = false
		elif not input.jump_held:
			velocity.y *= stats.short_hop_cut
			_can_short_hop = false


## SHIELD: jump out, dodge, or lower it; none of them during block stun.
func _shield_actions(input: FighterInput) -> void:
	if _block_stun > 0:
		_block_stun -= 1
	elif input.jump_pressed:
		_jump()
	elif _try_dodge(input):
		pass
	elif not input.shield_held:
		_set_state(State.SHIELD_DROP)


## A side pressed rolls that way; down pressed spot dodges. True if a dodge started.
func _try_dodge(input: FighterInput) -> bool:
	if input.side_pressed != 0:
		_roll_direction = input.side_pressed
		_set_state(State.ROLL)
		return true
	if input.down_pressed:
		_set_state(State.SPOT_DODGE)
		return true
	return false


## Air dodge: a burst toward the held direction, or a stop in place with none.
func _start_air_dodge(input: FighterInput) -> void:
	air_dodge_available = false
	_fast_falling = false
	_can_short_hop = false
	var direction := Vector2(input.move_x, 0.0)
	if input.up_held:
		direction.y = -1.0
	elif input.down_held:
		direction.y = 1.0
	velocity = direction.normalized() * stats.air_dodge_speed
	_set_state(State.AIR_DODGE)


## LEDGE: ledge jump, get up (up or toward the stage), or let go (down or away).
func _ledge_actions(input: FighterInput) -> void:
	if input.jump_pressed:
		_leave_ledge()
		velocity = Vector2(input.move_x * stats.air_speed * speed_scale(), -stats.jump_velocity)
		_set_state(State.AIR)
	elif input.up_pressed or input.side_pressed == -ledge.side:
		_set_state(State.LEDGE_CLIMB)
	elif input.down_pressed or input.side_pressed == ledge.side:
		_let_go()


func _leave_ledge() -> void:
	ledge = null
	_ledge_regrab_left = stats.ledge_regrab_frames


func _let_go() -> void:
	_leave_ledge()
	velocity = Vector2.ZERO
	_set_state(State.AIR)


## Where the feet are while hanging from the ledge.
func _hang_position() -> Vector2:
	var offset := stats.ledge_hang_offset * size_scale()
	return ledge.point + Vector2(offset.x * ledge.side, offset.y)


## Hanging: held below the corner. Climbing: up to the corner's height in the first half, then
## onto the stage, ending ledge_climb_inset in from the corner on the last frame.
func _hold_ledge() -> void:
	velocity = Vector2.ZERO
	var hang := _hang_position()
	if _is_vine_pulled():
		var pull := float(state_frame + 1) / stats.moveset.up_special.vine.pull_frames
		global_position = _vine_from.lerp(hang, minf(pull, 1.0))
		if pull >= 1.0:
			grab_ledge(ledge)
		return
	if state == State.LEDGE:
		global_position = hang
		return
	# This tick's frame of the climb (state_frame counts up at the end of the tick).
	var t := clampf(float(state_frame + 1) / stats.ledge_climb_frames, 0.0, 1.0)
	var top := Vector2(hang.x, ledge.point.y)
	var end := ledge.point + Vector2(-ledge.side * stats.ledge_climb_inset, 0.0)
	if t <= 0.5:
		global_position = hang.lerp(top, t * 2.0)
	else:
		global_position = top.lerp(end, (t - 0.5) * 2.0)


## Charge release and the up special's launch.
func _special_phases(input: FighterInput) -> void:
	match move:
		&"neutral_special_charge":
			var charge_frames := stats.moveset.neutral_special.charge_frames
			if not input.special_held or state_frame >= charge_frames:
				_release_punch(clampf(float(state_frame) / charge_frames, 0.0, 1.0))
		&"up_special":
			var data := stats.moveset.up_special
			if data.vine == null and data.pyramid == null and state_frame == data.startup:
				velocity = Vector2(input.move_x * data.drift_speed, -data.launch_speed)
				_launched = true
		&"down_special":
			var data := stats.moveset.down_special
			# On its frame `startup` (state_frame counts up at the end of the tick).
			if data.stances != null and state_frame + 1 == data.startup:
				stance = ((stance + 1) % Stance.size()) as Stance
		&"pyramid_rise":
			var pyramid := stats.moveset.up_special.pyramid
			if state_frame >= pyramid.rise_frames:
				# At the top: pops off the tip.
				velocity = Vector2(input.move_x * stats.moveset.up_special.drift_speed,
					-pyramid.pop_speed)
				move = &"up_special"
				_launched = true
		&"vine_swing":
			var vine := stats.moveset.up_special.vine
			if state_frame >= vine.swing_frames:
				# Let go with the swing's speed, along the arc's tangent.
				var angle := deg_to_rad(vine.swing_degrees)
				velocity = vine.length * vine.swing_speed() * Vector2(cos(angle) * facing, -sin(angle))
				move = &"up_special"
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


## The normal attack for the held direction: up, then down, then sideways, else the jab; in the
## air the aerials, with sideways split into forward and back (facing doesn't turn in the air).
func _pick_normal(input: FighterInput) -> StringName:
	if state == State.AIR:
		if input.up_held:
			return &"up_air"
		if input.down_held:
			return &"down_air"
		if input.move_x != 0.0:
			return &"forward_air" if signf(input.move_x) == facing else &"back_air"
		return &"neutral_air"
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
		if stats.moveset.down_special.peel != null or stance_data() != null:
			return &"down_special"  # Places a banana peel / switches stance, also in the air.
		return &"down_special_dive" if state == State.AIR else &"down_special"
	if input.move_x != 0.0:
		return &"side_special" if not has_projectile else NO_MOVE
	if stats.moveset.neutral_special.hand != null:
		# A summon: no charge, one hand at a time.
		return &"neutral_special" if not has_hand else NO_MOVE
	return &"neutral_special_charge"


func _start_move(move_name: StringName, input: FighterInput) -> void:
	var on_ground := state != State.AIR
	# A side move on the ground turns toward the held direction first; the side special does in the
	# air too, so it always fires where the player holds.
	if (on_ground and String(move_name).begins_with("side_")) or move_name == &"side_special":
		_turn_toward(input.move_x)
	if move_name == &"up_special":
		up_special_available = false
		_launched = false
		_fast_falling = false
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
			_steer(input.move_x, stats.air_speed * speed_scale(), stats.air_accel, stats.air_friction)
			_fall(input)
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
		State.ROLL:
			velocity.x = _roll_direction * stats.roll_speed
			if not _floor_ahead():
				velocity.x = 0.0
			if not is_on_floor():
				_apply_gravity()
		State.AIR_DODGE:
			velocity = velocity.move_toward(Vector2.ZERO, stats.air_dodge_friction * DELTA)
		State.CROUCH, State.SHIELD, State.SHIELD_DROP, State.SHIELD_BREAK, State.SPOT_DODGE, \
				State.TRIPPED:
			# No walking: slide to a stop.
			_steer(0.0, 0.0, 0.0, stats.ground_friction)
			if not is_on_floor():
				_apply_gravity()
		_:
			_steer(input.move_x, stats.run_speed * speed_scale(), stats.ground_accel,
				stats.ground_friction)
			if not is_on_floor():
				_apply_gravity()


func _move_during_attack(input: FighterInput) -> void:
	if move == &"pyramid_rise":
		# Feet on the tip, or (in the air) where they were until the tip gets there; moved with
		# physics so a ceiling stops her.
		var tip := pyramid_origin.y - stats.moveset.up_special.pyramid.tip_height(state_frame + 1)
		var target := Vector2(pyramid_origin.x, minf(_rise_start_y, tip))
		velocity = (target - global_position) / DELTA
	elif move == &"vine_swing":
		# Along the arc below the anchor, moved with physics so floors and walls stop it.
		var vine := stats.moveset.up_special.vine
		var angle := minf(state_frame + 1, vine.swing_frames) * vine.swing_speed() * DELTA
		var target := vine_anchor + vine.length * Vector2(sin(angle) * facing, cos(angle))
		velocity = (target - global_position) / DELTA
	elif move == &"down_special_dive":
		velocity = Vector2(0.0, stats.moveset.down_special.dive_speed)
	elif move == &"up_special" and _launched:
		_steer(input.move_x, stats.moveset.up_special.drift_speed, stats.air_accel, stats.air_friction)
		_apply_gravity()
	elif is_on_floor() and velocity.y >= 0.0:
		# A move on the ground doesn't steer: slide to a stop.
		_steer(0.0, 0.0, 0.0, stats.ground_friction)
	elif move in NORMALS:
		_steer(input.move_x, stats.air_speed * speed_scale(), stats.air_accel, stats.air_friction)
		_fall(input)
	else:
		_steer(input.move_x, stats.air_speed * speed_scale(), stats.air_accel, stats.air_friction)
		_apply_gravity()


## Moves horizontal speed toward `move_x × top_speed` at `accel`, or toward 0 at `friction`.
func _steer(move_x: float, top_speed: float, accel: float, friction: float) -> void:
	if move_x != 0.0:
		velocity.x = move_toward(velocity.x, move_x * top_speed, accel * DELTA)
	else:
		velocity.x = move_toward(velocity.x, 0.0, friction * DELTA)


## Falling in AIR and during air attacks: holding down once falling starts a fast fall (not on the
## tick of a drop-through), which then holds the fall at fast_fall_speed; otherwise normal gravity.
func _fall(input: FighterInput) -> void:
	var dropping_now := _drop_through_frames_left == stats.drop_through_frames
	if not _fast_falling and input.down_held and velocity.y >= 0.0 and not dropping_now:
		_fast_falling = true
	if _fast_falling:
		velocity.y = stats.fast_fall_speed
	else:
		_apply_gravity()


## True if, after this tick's horizontal move, the fighter would still stand on something (a
## roll stops at the edge instead of rolling off).
func _floor_ahead() -> bool:
	var ahead := global_transform.translated(Vector2(velocity.x * DELTA, 0.0))
	return test_move(ahead, Vector2(0.0, 2.0))


func _apply_gravity() -> void:
	velocity.y = minf(velocity.y + stats.gravity * DELTA, stats.max_fall_speed)


## Landing, walking off ledges and the specials' air rules, decided from where move_and_slide()
## left the fighter.
func _after_move(input: FighterInput) -> void:
	match state:
		State.AIR, State.HELPLESS, State.AIR_DODGE:
			if is_on_floor():
				_land(input)
		State.ATTACK:
			_after_move_in_attack(input)
		State.HITSTUN, State.TRIPPED:
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
	_fast_falling = false
	jumps_left = stats.max_air_jumps
	up_special_available = true
	air_dodge_available = true
	_can_short_hop = false
	_launched = false
	_set_state(_free_state(input))


## Fall through the pass-through platform the fighter stands on.
func _drop_through() -> void:
	_drop_through_frames_left = stats.drop_through_frames
	_set_state(State.AIR)


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
	var airborne := state == State.AIR or state == State.HELPLESS or state == State.AIR_DODGE \
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


func _is_vine_pulled() -> bool:
	return state == State.ATTACK and move == &"vine_pull"


func _set_state(new_state: State) -> void:
	if new_state != state:
		state = new_state
		state_frame = 0
