class_name Match
extends Node2D
## Runs a match: owns the tick loop and drives every fighter (docs/specs/architecture.md).
## M2: one keyboard-controlled fighter on the stage. Rules (stocks, KOs, phases) come in M4.

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
		_controllers.append(KeyboardController.new())
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
	tick += 1


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
