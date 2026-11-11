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

## Match rules (docs/specs/match-and-stage.md#kos-stocks-and-respawn), in ticks.
const STOCKS := 3
const RESPAWN_FRAMES := 60
const INVULNERABLE_FRAMES := 120

## When on, the Match steps once per physics frame. Tests turn it off and call step() themselves.
@export var auto_step: bool = true

## Ticks since the match started.
var tick: int = 0

var _fighters: Array[Fighter] = []
var _controllers: Array[Controller] = []
## Projectiles in flight, in the order they were fired.
var _projectiles: Array[Projectile] = []
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
		fighter.stats = character.stats
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
	_grab_ledges()
	_advance_projectiles()
	_spawn_projectiles()
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
		projectile.advance()
		if projectile.is_expired(_stage.blast_zone):
			_remove_projectile(projectile)


## Adds a projectile for every fighter whose side special reached its spawn frame this tick.
func _spawn_projectiles() -> void:
	for fighter in _fighters:
		if not fighter.wants_projectile():
			continue
		var data := fighter.stats.moveset.side_special
		var projectile := Projectile.new()
		$Projectiles.add_child(projectile)
		var offset := Vector2(data.hitbox_center.x * fighter.facing, data.hitbox_center.y)
		projectile.setup(fighter.player_index, fighter.facing, fighter.global_position + offset, data)
		_projectiles.append(projectile)


func _remove_projectile(projectile: Projectile) -> void:
	_projectiles.erase(projectile)
	projectile.queue_free()


## Collects every hit for this tick — moves and projectiles — then applies them all, so two
## fighters can trade. A shielding victim blocks instead. The knockback side and the attacker's
## position are taken while collecting, before anyone turns
## around from being hit.
func _resolve_hits() -> void:
	var hits: Array[Dictionary] = []
	for attacker in _fighters:
		if not attacker.is_hitbox_active():
			continue
		var hitbox := attacker.get_hitbox_rect()
		var data := attacker.current_move()
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
				})
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
	for hit in hits:
		var victim := hit.victim as Fighter
		if hit.has("attacker"):
			(hit.attacker as Fighter).register_hit(victim.player_index)
		else:
			_remove_projectile(hit.projectile)
		if victim.state == Fighter.State.SHIELD:
			victim.block_hit(hit.move, hit.side)
			fighter_blocked.emit(victim.player_index)
		else:
			victim.take_hit(hit.move, hit.side, hit.attacker_x)
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
			var projectile := _projectile_of(i)
			if projectile != null:
				_remove_projectile(projectile)
			_respawn_frames_left[i] = RESPAWN_FRAMES
			fighter_ko.emit(i)


func _advance_timers() -> void:
	for i in _fighters.size():
		_respawn_frames_left[i] = maxi(_respawn_frames_left[i] - 1, 0)
		_fighters[i].invulnerable_frames = maxi(_fighters[i].invulnerable_frames - 1, 0)


## Puts everything back to the start of a match, without reloading the scene.
func reset() -> void:
	tick = 0
	for projectile in _projectiles.duplicate():
		_remove_projectile(projectile)
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
