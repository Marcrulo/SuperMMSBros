class_name Match
extends Node2D
## Runs a match: owns the tick loop and drives every fighter (docs/specs/architecture.md).
## P1 (keyboard) and a dummy; hits, KOs, stocks and respawns are resolved here. Phases, the win
## condition and the result come in M7.

## A fighter took a hit (not a blocked one). The HUD bumps its card.
signal fighter_hit(player_index: int)
## A hit landed on a fighter's shield (docs/specs/sound.md).
signal fighter_blocked(player_index: int)
## The end of every step(): one tick of the match is done (presentation reads it, per tick).
signal stepped
## A fighter left the blast zone and lost a stock.
signal fighter_ko(player_index: int)
## A KO'd fighter with stocks left came back at its spawn point.
signal fighter_respawned(player_index: int)
## A summoned hand reached the floor (its owner's index; docs/specs/sound.md).
signal hand_landed(player_index: int)

## Match rules (docs/specs/match-and-stage.md#kos-stocks-and-respawn), in ticks.
const STOCKS := 3
const RESPAWN_FRAMES := 60
const INVULNERABLE_FRAMES := 120

## When on, the Match steps once per physics frame. Tests turn it off and call step() themselves.
@export var auto_step: bool = true

## Ticks since the match started.
var tick: int = 0
## The match's one RNG (docs/specs/architecture.md rule 6) and its seed; set by reset().
var rng := RandomNumberGenerator.new()
var seed_value: int = 0

var _fighters: Array[Fighter] = []
var _controllers: Array[Controller] = []
## Projectiles in flight, in the order they were fired.
var _projectiles: Array[Projectile] = []
## Summoned hands, in the order they appeared.
var _hands: Array[Hand] = []
## Banana peels, in the order they were placed.
var _peels: Array[Peel] = []
## Gitte's pyramids (rising or sinking), in the order they appeared.
var _pyramids: Array[Pyramid] = []
## Per fighter: ticks until a KO'd fighter respawns (0 = not waiting).
var _respawn_frames_left: Array[int] = []

@onready var _stage := $Stage as Stage


func _ready() -> void:
	var stage_data := StageData.load_stage(_chosen_stage_id())
	_stage.apply(stage_data)
	_play_music(stage_data)
	for child in $Fighters.get_children():
		var fighter := child as Fighter
		fighter.player_index = _fighters.size()
		# Each player plays their character from the menus (docs/specs/menus.md).
		var character := Game.character() if fighter.player_index == 0 else Game.p2_character()
		fighter.character_id = character.id
		fighter.stats = character.fighter_stats()
		_fighters.append(fighter)
		# P1 plays from the keyboard; everyone else is the dummy until the CPU arrives (M8).
		if fighter.player_index == 0:
			_controllers.append(KeyboardController.new())
		else:
			_controllers.append(ScriptedController.new())
	reset()
	($HUD as Hud).setup(self, _fighters)


func _physics_process(_delta: float) -> void:
	if auto_step:
		step()


## Loops the stage's music, if it has a track. Presentation only.
func _play_music(stage_data: StageData) -> void:
	var player := $Music as AudioStreamPlayer
	player.stream = stage_data.load_music()
	if player.stream != null:
		player.play()


## The stage to play: `--stage=<id>` (docs/specs/architecture.md#command-line-options), else the
## one chosen on the stage select (docs/specs/menus.md), else the default.
func _chosen_stage_id() -> String:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--stage="):
			return arg.trim_prefix("--stage=")
	return Game.stage_id if Game.stage_id != "" else StageData.DEFAULT_ID


## `--seed=N`, else a new random seed.
func _seed_from_options() -> int:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--seed="):
			return int(arg.trim_prefix("--seed="))
	return randi()


## Advances the game by one tick (docs/specs/architecture.md#tick-order).
## Must run inside a physics frame (see Fighter.tick()).
func step() -> void:
	var inputs: Array[FighterInput] = []
	for controller in _controllers:
		inputs.append(controller.get_input(null))
	for fighter in _fighters:
		fighter.has_projectile = _projectile_of(fighter.player_index) != null
		fighter.has_hand = _hand_of(fighter.player_index) != null
	for i in _fighters.size():
		_fighters[i].tick(inputs[i])
	_advance_throws()
	_grab_ledges()
	_start_vines()
	_advance_pyramids()
	_start_pyramids()
	_advance_projectiles()
	_spawn_projectiles()
	_advance_hands()
	_spawn_hands()
	_advance_peels()
	_spawn_peels()
	_trip_on_peels()
	_resolve_grabs()
	_resolve_hits()
	_check_kos_and_respawns()
	_advance_timers()
	tick += 1
	stepped.emit()


## Every fighter that can grab a ledge nobody else holds grabs it, P1 first
## (docs/specs/fighter.md#ledge).
func _grab_ledges() -> void:
	for fighter in _fighters:
		for ledge in _stage.get_ledges():
			if not _is_ledge_held(ledge) and fighter.can_grab_ledge(ledge):
				fighter.grab_ledge(ledge)
				break


func _is_ledge_held(ledge: Ledge) -> bool:
	for fighter in _fighters:
		if fighter.ledge == ledge:
			return true
	return false


func get_projectiles() -> Array[Projectile]:
	return _projectiles


func _projectile_of(player_index: int) -> Projectile:
	for projectile in _projectiles:
		if projectile.owner_index == player_index:
			return projectile
	return null


## Moves every projectile one tick and removes the ones past their lifetime or out of bounds.
func _advance_projectiles() -> void:
	for projectile in _projectiles.duplicate():
		var before: Vector2 = projectile.global_position
		projectile.advance()
		# A thrown one (with gravity) is gone when it lands on the main platform (it passes
		# through the pass-through platforms).
		var landed: bool = projectile.data.projectile_gravity > 0.0 \
				and projectile.global_position.y >= _stage.floor_below(before)
		if landed or projectile.is_expired(_stage.blast_zone):
			_remove_projectile(projectile)


## Adds a projectile for every fighter whose side special reached its spawn frame this tick.
func _spawn_projectiles() -> void:
	for fighter in _fighters:
		if not fighter.wants_projectile():
			continue
		var data := fighter.stats.moveset.side_special
		var offset := Vector2(data.hitbox_center.x * fighter.facing, data.hitbox_center.y)
		var at := fighter.global_position + offset * fighter.size_scale()
		var angle := _kick_angle(fighter, at, data)
		var thrown := fighter.projectile_data(data)
		# A volley: the first straight at `angle`, the others fanned out above and below it.
		for i in maxi(data.projectile_count, 1):
			var fan := ceili(i / 2.0) * data.projectile_spread_deg * (1 if i % 2 == 1 else -1)
			var projectile := Projectile.new()
			$Projectiles.add_child(projectile)
			projectile.setup(fighter.player_index, fighter.facing, at, thrown, angle + fan,
				fighter.character_id)
			_projectiles.append(projectile)


## A projectile's flight angle: straight ahead, or (an aimed one) at the nearest fighter it can
## see, else a random angle in its cone (docs/specs/characters/michael.md#michael-bech--football).
func _kick_angle(fighter: Fighter, at: Vector2, data: MoveData) -> float:
	if data.aim_cone_deg <= 0.0:
		return data.projectile_angle_deg
	var targets: Array[Vector2] = []
	for other in _fighters:
		if other != fighter and other.state != Fighter.State.KO:
			targets.append(other.get_center())
	var angle := Projectile.aim_angle(at, fighter.facing, targets, data.aim_cone_deg, data.aim_range)
	return angle if not is_nan(angle) else rng.randf_range(-data.aim_cone_deg, data.aim_cone_deg)


func _remove_projectile(projectile: Projectile) -> void:
	_projectiles.erase(projectile)
	projectile.queue_free()


func get_hands() -> Array[Hand]:
	return _hands


func _hand_of(player_index: int) -> Hand:
	for hand in _hands:
		if hand.owner_index == player_index:
			return hand
	return null


## Moves every hand one tick (hover, slam, impact); removes the finished ones and those that fell
## out of the blast zone.
func _advance_hands() -> void:
	for hand in _hands.duplicate():
		if hand.advance():
			hand_landed.emit(hand.owner_index)
		if hand.finished or not _stage.blast_zone.has_point(hand.global_position):
			_remove_hand(hand)


## Adds a hand for every fighter whose summon reached its spawn frame this tick.
func _spawn_hands() -> void:
	for fighter in _fighters:
		if not fighter.wants_hand():
			continue
		var data := fighter.stats.moveset.neutral_special.hand
		var at := fighter.global_position + Vector2(data.offset.x * fighter.facing, data.offset.y)
		var hand := Hand.new()
		$Projectiles.add_child(hand)
		hand.setup(fighter.player_index, fighter.facing, at, data, _stage.floor_below(at),
			fighter.character_id)
		_hands.append(hand)


func _remove_hand(hand: Hand) -> void:
	_hands.erase(hand)
	hand.queue_free()


## A vine up special on its choice frame: pulled to the nearest free ledge in reach that the
## fighter is beside or below, else a swing (docs/specs/characters/fidusen.md#fidusen--banana-book-vine).
func _start_vines() -> void:
	for fighter in _fighters:
		if not fighter.wants_vine():
			continue
		var vine := fighter.stats.moveset.up_special.vine
		var best: Ledge = null
		var best_distance := INF
		for ledge in _stage.get_ledges():
			var distance := fighter.get_center().distance_to(ledge.point)
			var beside := (fighter.global_position.x - ledge.point.x) * ledge.side >= -4.0
			var below := fighter.global_position.y >= ledge.point.y - 4.0
			if distance <= vine.ledge_range and beside and below and not _is_ledge_held(ledge) \
					and distance < best_distance:
				best = ledge
				best_distance = distance
		var target := _lasso_target(fighter, vine) if best == null else null
		if best != null:
			fighter.start_vine_pull(best)
		elif target != null:
			fighter.start_lasso(target)
		elif vine.swing:
			fighter.start_vine_swing()
		else:
			fighter.start_lasso_miss()


## The fighter a lasso catches: the nearest that can be hit and isn't held, within the vine's
## grab_range of the thrower's center, in front of it or above (not behind), or null.
func _lasso_target(fighter: Fighter, vine: VineData) -> Fighter:
	if vine.grab_range <= 0.0:
		return null
	var best: Fighter = null
	var best_distance := INF
	for victim in _fighters:
		if victim == fighter or not victim.can_be_hit():
			continue
		var offset := victim.get_center() - fighter.get_center()
		var distance := offset.length()
		var behind := offset.x * fighter.facing < -8.0 and offset.y > -8.0
		if distance <= vine.grab_range and not behind and distance < best_distance:
			best = victim
			best_distance = distance
	return best


func get_pyramids() -> Array[Pyramid]:
	return _pyramids


## Every pyramid rises while its owner rides it, else sinks; the sunk ones are removed.
func _advance_pyramids() -> void:
	for pyramid in _pyramids.duplicate():
		pyramid.advance(_fighters[pyramid.owner_index].is_riding_pyramid())
		if pyramid.finished:
			_remove_pyramid(pyramid)


## A pyramid up special on its choice frame: a pyramid out of the floor below if it's in reach,
## else a hop (docs/specs/characters/gitte.md#gitte--scissors-and-stances).
func _start_pyramids() -> void:
	for fighter in _fighters:
		if not fighter.wants_pyramid():
			continue
		var data := fighter.stats.moveset.up_special.pyramid
		var feet := fighter.global_position
		var floor_y := _stage.floor_below(feet - Vector2(0.0, 1.0), true)
		if floor_y - feet.y > data.reach:  # Also no floor at all (INF).
			fighter.start_pyramid_hop()
			continue
		fighter.start_pyramid(floor_y)
		var pyramid := Pyramid.new()
		$Pyramids.add_child(pyramid)
		pyramid.setup(fighter.player_index, Vector2(feet.x, floor_y), data, fighter.character_id)
		_pyramids.append(pyramid)


func _remove_pyramid(pyramid: Pyramid) -> void:
	_pyramids.erase(pyramid)
	pyramid.queue_free()


func get_peels() -> Array[Peel]:
	return _peels


## Peels fall to their floor and age; the expired ones and those out of the blast zone go.
func _advance_peels() -> void:
	for peel in _peels.duplicate():
		peel.advance()
		if peel.is_expired(_stage.blast_zone):
			_remove_peel(peel)


## A peel for every fighter whose down special reached its frame; past max_out, the oldest goes.
func _spawn_peels() -> void:
	for fighter in _fighters:
		if not fighter.wants_peel():
			continue
		var data := fighter.stats.moveset.down_special.peel
		var at := fighter.global_position + Vector2(8.0 * fighter.facing, 0.0)
		var peel := Peel.new()
		$Projectiles.add_child(peel)
		peel.setup(fighter.player_index, at, data, _stage.floor_below(at, true), fighter.character_id)
		_peels.append(peel)
		var own := _peels.filter(func(p: Peel) -> bool: return p.owner_index == fighter.player_index)
		if own.size() > data.max_out:
			_remove_peel(own[0])


## A landed peel trips the first other fighter on the ground that touches it, and is gone.
func _trip_on_peels() -> void:
	for peel in _peels.duplicate():
		if not peel.landed:
			continue
		for victim in _fighters:
			if victim.player_index == peel.owner_index or not victim.can_trip():
				continue
			if peel.get_trip_rect().intersects(victim.get_hurtbox_rect()):
				victim.trip(peel.data)
				fighter_hit.emit(victim.player_index)
				_remove_peel(peel)
				break


func _remove_peel(peel: Peel) -> void:
	_peels.erase(peel)
	peel.queue_free()


## Command grabs (docs/specs/characters/mads.md#mads--grappler): a grab box catches the first fighter it
## touches that can be hit, shield or not, and starts the throw. P1 first.
func _resolve_grabs() -> void:
	for attacker in _fighters:
		if attacker.active_grab() == null:
			continue
		var box := attacker.get_hitbox_rect()
		for victim in _fighters:
			if victim != attacker and victim.can_be_hit() and box.intersects(victim.get_hurtbox_rect()):
				attacker.start_throw(victim)
				break


## Throws in progress: the held fighter is carried round its arc, and slammed on the slam frame.
func _advance_throws() -> void:
	for thrower in _fighters:
		if thrower.throwing == null:
			continue
		var victim := thrower.throwing
		if thrower.state == Fighter.State.ATTACK and thrower.move == &"lasso_reel":
			if thrower.state_frame >= thrower.stats.moveset.up_special.vine.reel_frames:
				thrower.finish_lasso()
				fighter_hit.emit(victim.player_index)
			else:
				victim.global_position = thrower.lasso_position(thrower.state_frame)
				thrower.vine_anchor = victim.get_center()
			continue
		if thrower.state != Fighter.State.ATTACK or thrower.move != &"grab_throw":
			thrower.release_held()
			continue
		var grab := thrower.stats.moveset.side_special.grab
		if thrower.state_frame >= grab.turn_frame:
			thrower.facing = -thrower.throw_facing  # Turned round with the victim overhead.
		if thrower.state_frame >= grab.slam_frame:
			thrower.slam()
			fighter_hit.emit(victim.player_index)
		else:
			victim.global_position = thrower.throw_position(thrower.state_frame)


## Collects every hit for this tick — moves and projectiles — then applies them all, so two
## fighters can trade. A shielding victim blocks instead. The knockback side and the attacker's
## position are taken while collecting, before anyone turns
## around from being hit.
func _resolve_hits() -> void:
	var hits: Array[Dictionary] = []
	for attacker in _fighters:
		if not attacker.is_hitbox_active() or attacker.active_grab() != null:
			continue  # (A grab box never hits.)
		var hitbox := attacker.get_hitbox_rect()
		var normal := attacker.move in Fighter.NORMALS
		var data := attacker.boosted(attacker.current_move(), not normal)
		for victim in _fighters:
			if victim == attacker or not victim.can_be_hit() or attacker.has_hit(victim.player_index):
				continue
			if hitbox.intersects(victim.get_hurtbox_rect()):
				hits.append({
					"attacker": attacker,
					"victim": victim,
					"move": data,
					"side": attacker.knockback_side(data, victim.get_center()),
					"attacker_x": attacker.global_position.x,
					"normal": normal,
				})
	for owner in _fighters:
		if not owner.ropes_active():
			continue
		for victim in _fighters:
			if victim == owner or not victim.can_be_hit() or victim.rope_immune_frames > 0:
				continue
			# At most one rope hit per fighter per tick (the first rope whose tip touches).
			for i in owner.ropes().count:
				if owner.rope_can_hit(i, victim.player_index) \
						and owner.rope_box(i).intersects(victim.get_hurtbox_rect()):
					var dx := victim.get_center().x - owner.get_center().x
					hits.append({
						"rope_owner": owner,
						"rope": i,
						"victim": victim,
						"move": owner.rope_hit(),
						"side": owner.facing if is_zero_approx(dx) else int(signf(dx)),
						"attacker_x": owner.global_position.x,
					})
					break
	for projectile in _projectiles:
		for victim in _fighters:
			if victim.player_index == projectile.owner_index or not victim.can_be_hit():
				continue
			if projectile.get_hitbox_rect().intersects(victim.get_hurtbox_rect()):
				hits.append({
					"projectile": projectile,
					"victim": victim,
					"move": projectile.data,
					"side": projectile.direction,
					"attacker_x": projectile.global_position.x,
				})
				break
	for hand in _hands:
		var hitbox := hand.get_hitbox_rect()
		for victim in _fighters:
			if victim.player_index == hand.owner_index or not victim.can_be_hit() \
					or hand.has_hit(victim.player_index):
				continue
			if hitbox.intersects(victim.get_hurtbox_rect()):
				var dx := victim.get_center().x - hand.global_position.x
				hits.append({
					"hand": hand,
					"victim": victim,
					"move": hand.current_hit(),
					"side": hand.facing if is_zero_approx(dx) else int(signf(dx)),
					"attacker_x": hand.global_position.x,
				})
	for hit in hits:
		var victim := hit.victim as Fighter
		if hit.has("attacker"):
			(hit.attacker as Fighter).register_hit(victim.player_index)
		elif hit.has("rope_owner"):
			(hit.rope_owner as Fighter).register_rope_hit(hit.rope, victim.player_index)
		elif hit.has("hand"):
			(hit.hand as Hand).register_hit(victim.player_index)
		else:
			_remove_projectile(hit.projectile)
		if victim.state == Fighter.State.SHIELD:
			victim.block_hit(hit.move, hit.side)
			fighter_blocked.emit(victim.player_index)
		else:
			victim.take_hit(hit.move, hit.side, hit.attacker_x)
			if hit.has("rope_owner"):
				# Hurt by a rope: no more rope hits for a while (so they can't be stacked).
				victim.rope_immune_frames = (hit.rope_owner as Fighter).ropes().immune_frames
			if hit.get("normal", false):
				# − stance: a normal attack that lands heals the attacker.
				var attacker := hit.attacker as Fighter
				var heal: float = (hit.move as MoveData).damage * attacker.lifesteal()
				attacker.percent = maxf(attacker.percent - heal, 0.0)
			fighter_hit.emit(victim.player_index)


## A fighter whose center leaves the blast zone is KO'd: one stock less, its projectile gone, and
## (with stocks left) back at its spawn point RESPAWN_FRAMES ticks later, invulnerable for a while.
func _check_kos_and_respawns() -> void:
	for i in _fighters.size():
		var fighter := _fighters[i]
		if fighter.state == Fighter.State.KO:
			if _respawn_frames_left[i] == 0 and fighter.stocks > 0:
				fighter.spawn_at(_stage.get_spawn_position(i), _stage.get_spawn_facing(i))
				fighter.invulnerable_frames = INVULNERABLE_FRAMES
				fighter_respawned.emit(i)
		elif not _stage.blast_zone.has_point(fighter.get_center()):
			fighter.stocks -= 1
			fighter.knock_out()
			for projectile in _projectiles.duplicate():
				if projectile.owner_index == i:
					_remove_projectile(projectile)
			var hand := _hand_of(i)
			if hand != null:
				_remove_hand(hand)
			_respawn_frames_left[i] = RESPAWN_FRAMES
			fighter_ko.emit(i)


func _advance_timers() -> void:
	for i in _fighters.size():
		_respawn_frames_left[i] = maxi(_respawn_frames_left[i] - 1, 0)
		_fighters[i].invulnerable_frames = maxi(_fighters[i].invulnerable_frames - 1, 0)
		_fighters[i].rope_immune_frames = maxi(_fighters[i].rope_immune_frames - 1, 0)


## Puts everything back to the start of a match, without reloading the scene.
func reset(new_seed: int = -1) -> void:
	tick = 0
	seed_value = new_seed if new_seed != -1 else _seed_from_options()
	rng.seed = seed_value
	for projectile in _projectiles.duplicate():
		_remove_projectile(projectile)
	for hand in _hands.duplicate():
		_remove_hand(hand)
	for peel in _peels.duplicate():
		_remove_peel(peel)
	for pyramid in _pyramids.duplicate():
		_remove_pyramid(pyramid)
	_respawn_frames_left.clear()
	for i in _fighters.size():
		_fighters[i].spawn_at(_stage.get_spawn_position(i), _stage.get_spawn_facing(i))
		_fighters[i].stocks = STOCKS
		_respawn_frames_left.append(0)
		_controllers[i].reset()


func get_fighter(player_index: int) -> Fighter:
	return _fighters[player_index]


func get_controller(player_index: int) -> Controller:
	return _controllers[player_index]


func set_controller(player_index: int, controller: Controller) -> void:
	_controllers[player_index] = controller
