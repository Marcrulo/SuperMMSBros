class_name Match
extends Node2D
## Runs a match: owns the tick loop and drives every fighter (docs/specs/architecture.md).
## P1 (keyboard) and a dummy; hits, KOs, stocks and respawns are resolved here. Phases, the win
## condition and the result come in M7. The fighters' abilities (docs/specs/architecture.md#abilities)
## and the entities they add are called at fixed points of the step.

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
## An entity of fighter `player_index` asks for a sound from that fighter (a summoned hand landing;
## docs/specs/sound.md).
signal owner_sound(player_index: int, sound: StringName)

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
## The abilities' entities (hands, peels, pyramids…), in the order they were added.
var _entities: Array[MatchEntity] = []
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
	for i in _fighters.size():
		_fighters[i].tick(inputs[i])
	_advance_held()
	_grab_ledges()
	for fighter in _fighters:
		for ability in fighter.abilities:
			ability.after_ledges(self)
	_advance_projectiles()
	_spawn_projectiles()
	_advance_entities()
	for fighter in _fighters:
		for ability in fighter.abilities:
			ability.spawn_entities(self)
	for entity in _entities.duplicate():
		if not entity.removed:
			entity.interact(self)
	for fighter in _fighters:
		for ability in fighter.abilities:
			ability.resolve_contacts(self)
	_resolve_hits()
	_check_kos_and_respawns()
	_advance_timers()
	tick += 1
	stepped.emit()


## Every fighter holding someone (an ability's throw or reel) moves them on; one whose ability
## doesn't (the move ended) lets go.
func _advance_held() -> void:
	for holder in _fighters:
		if holder.throwing == null:
			continue
		var moved := false
		for ability in holder.abilities:
			if ability.advance_held(self):
				moved = true
				break
		if not moved:
			holder.release_held()


## Every fighter that can grab a ledge nobody else holds grabs it, P1 first
## (docs/specs/fighter.md#ledge).
func _grab_ledges() -> void:
	for fighter in _fighters:
		for ledge in _stage.get_ledges():
			if not is_ledge_held(ledge) and fighter.can_grab_ledge(ledge):
				fighter.grab_ledge(ledge)
				break


## True if a fighter hangs from `ledge` (or is pulled to it).
func is_ledge_held(ledge: Ledge) -> bool:
	for fighter in _fighters:
		if fighter.ledge == ledge:
			return true
	return false


func get_stage() -> Stage:
	return _stage


func get_fighters() -> Array[Fighter]:
	return _fighters


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
## see, else a random angle in its cone (docs/specs/moves.md#side-special--projectile).
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


## Adds an ability's entity: drawn behind the fighters or in front, advanced from next tick on.
func add_entity(entity: MatchEntity) -> void:
	var layer := $BehindFighters if entity.behind_fighters() else $Projectiles
	layer.add_child(entity)
	_entities.append(entity)


func remove_entity(entity: MatchEntity) -> void:
	entity.removed = true
	_entities.erase(entity)
	entity.queue_free()


## The entities still in the match, in the order they were added: all, or those of class `type`
## (e.g. Peel), and of fighter `owner_index` (-1 = anyone's).
func get_entities(type: Script = null, owner_index: int = -1) -> Array[MatchEntity]:
	var found: Array[MatchEntity] = []
	for entity in _entities:
		if (type == null or is_instance_of(entity, type)) \
				and (owner_index == -1 or entity.owner_index == owner_index):
			found.append(entity)
	return found


## Every entity moves one tick; the finished ones are removed.
func _advance_entities() -> void:
	for entity in _entities.duplicate():
		entity.advance(self)
		if entity.is_finished(self):
			remove_entity(entity)


## Collects every hit for this tick — moves, the abilities' own hits, projectiles and entities —
## then applies them all, so two fighters can trade. A shielding victim blocks instead. The
## knockback side and the attacker's position are taken while collecting, before anyone turns
## around from being hit. Each hit is a Dictionary: victim, move (MoveData), side, attacker_x,
## register (Callable(victim_index): remembers the hit), and optionally landed
## (Callable(victim) after an unblocked hit) and attacker (a fighter's own move: lifesteal).
func _resolve_hits() -> void:
	var hits: Array[Dictionary] = []
	for attacker in _fighters:
		if not attacker.is_hitbox_active() or attacker.is_grab_box():
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
					"register": attacker.register_hit,
				})
	for fighter in _fighters:
		for ability in fighter.abilities:
			ability.collect_hits(self, hits)
	for projectile in _projectiles:
		for victim in _fighters:
			if victim.player_index == projectile.owner_index or not victim.can_be_hit():
				continue
			if projectile.get_hitbox_rect().intersects(victim.get_hurtbox_rect()):
				hits.append({
					"victim": victim,
					"move": projectile.data,
					"side": projectile.direction,
					"attacker_x": projectile.global_position.x,
					"register": func(_victim_index: int) -> void: _remove_projectile(projectile),
				})
				break
	for entity in _entities:
		entity.collect_hits(self, hits)
	for hit in hits:
		var victim := hit.victim as Fighter
		(hit.register as Callable).call(victim.player_index)
		if victim.state == Fighter.State.SHIELD:
			victim.block_hit(hit.move, hit.side)
			fighter_blocked.emit(victim.player_index)
		else:
			victim.take_hit(hit.move, hit.side, hit.attacker_x)
			if hit.has("landed"):
				(hit.landed as Callable).call(victim)
			if hit.get("normal", false):
				# A normal attack that lands can heal the attacker (an ability's lifesteal).
				var attacker := hit.attacker as Fighter
				var heal: float = (hit.move as MoveData).damage * attacker.lifesteal()
				attacker.percent = maxf(attacker.percent - heal, 0.0)
			fighter_hit.emit(victim.player_index)


## A fighter whose center leaves the blast zone is KO'd: one stock less, its projectile gone (and
## the entities that go with it), and (with stocks left) back at its spawn point RESPAWN_FRAMES
## ticks later, invulnerable for a while.
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
			for entity in get_entities(null, i):
				if entity.removed_with_owner():
					remove_entity(entity)
			_respawn_frames_left[i] = RESPAWN_FRAMES
			fighter_ko.emit(i)


func _advance_timers() -> void:
	for i in _fighters.size():
		_respawn_frames_left[i] = maxi(_respawn_frames_left[i] - 1, 0)
		_fighters[i].invulnerable_frames = maxi(_fighters[i].invulnerable_frames - 1, 0)
	for fighter in _fighters:
		for ability in fighter.abilities:
			ability.end_step(self)


## Puts everything back to the start of a match, without reloading the scene.
func reset(new_seed: int = -1) -> void:
	tick = 0
	seed_value = new_seed if new_seed != -1 else _seed_from_options()
	rng.seed = seed_value
	for projectile in _projectiles.duplicate():
		_remove_projectile(projectile)
	for entity in _entities.duplicate():
		remove_entity(entity)
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
