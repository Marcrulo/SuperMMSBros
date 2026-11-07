class_name Match
extends Node2D
## Runs a match: owns the tick loop and drives every fighter (docs/specs/architecture.md).
## P1 (keyboard) and a dummy; hits are resolved here. Rules (stocks, KOs, phases) come in M7.

## When on, the Match steps once per physics frame. Tests turn it off and call step() themselves.
@export var auto_step: bool = true

## Ticks since the match started.
var tick: int = 0

var _fighters: Array[Fighter] = []
var _controllers: Array[Controller] = []

@onready var _stage := $Stage as Stage


func _ready() -> void:
	_stage.apply(StageData.load_stage(_stage_id_from_command_line()))
	for child in $Fighters.get_children():
		var fighter := child as Fighter
		fighter.player_index = _fighters.size()
		_fighters.append(fighter)
		# P1 plays from the keyboard; everyone else is the dummy until the CPU arrives (M8).
		if fighter.player_index == 0:
			_controllers.append(KeyboardController.new())
		else:
			_controllers.append(ScriptedController.new())
	reset()


func _physics_process(_delta: float) -> void:
	if auto_step:
		step()


## The stage chosen with `--stage=<id>` (docs/specs/architecture.md#command-line-options).
func _stage_id_from_command_line() -> String:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--stage="):
			return arg.trim_prefix("--stage=")
	return StageData.DEFAULT_ID


## Advances the game by one tick (docs/specs/architecture.md#tick-order).
## Must run inside a physics frame (see Fighter.tick()).
func step() -> void:
	var inputs: Array[FighterInput] = []
	for controller in _controllers:
		inputs.append(controller.get_input(null))
	for i in _fighters.size():
		_fighters[i].tick(inputs[i])
	_resolve_hits()
	_respawn_fighters_out_of_bounds()
	tick += 1


## Collects every hit for this tick, then applies them all, so two fighters can trade. The
## knockback side and the attacker's position are taken while collecting, before anyone turns
## around from being hit.
func _resolve_hits() -> void:
	var hits: Array[Dictionary] = []
	for attacker in _fighters:
		if not attacker.is_hitbox_active():
			continue
		var hitbox := attacker.get_hitbox_rect()
		var data := attacker.current_move()
		for victim in _fighters:
			if victim == attacker or attacker.has_hit(victim.player_index):
				continue
			if hitbox.intersects(victim.get_hurtbox_rect()):
				hits.append({
					"attacker": attacker,
					"victim": victim,
					"move": data,
					"side": attacker.knockback_side(data, victim.get_center()),
					"attacker_x": attacker.global_position.x,
				})
	for hit in hits:
		var victim := hit.victim as Fighter
		(hit.attacker as Fighter).register_hit(victim.player_index)
		victim.take_hit(hit.move, hit.side, hit.attacker_x)


## For now a fighter that leaves the blast zone is put straight back at its spawn point.
## M7 turns this into the full KO rule: stocks, a 60-tick wait and invulnerability.
func _respawn_fighters_out_of_bounds() -> void:
	for i in _fighters.size():
		if not _stage.blast_zone.has_point(_fighters[i].get_center()):
			_fighters[i].spawn_at(_stage.get_spawn_position(i), _stage.get_spawn_facing(i))


## Puts everything back to the start of a match, without reloading the scene.
func reset() -> void:
	tick = 0
	for i in _fighters.size():
		_fighters[i].spawn_at(_stage.get_spawn_position(i), _stage.get_spawn_facing(i))
		_controllers[i].reset()


func get_fighter(player_index: int) -> Fighter:
	return _fighters[player_index]


func get_controller(player_index: int) -> Controller:
	return _controllers[player_index]


func set_controller(player_index: int, controller: Controller) -> void:
	_controllers[player_index] = controller
