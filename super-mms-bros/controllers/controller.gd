class_name Controller
extends RefCounted
## Base class for whatever plays a fighter: the keyboard, a test script, later the CPU.
## Each tick the Match asks every fighter's controller for one FighterInput.


## Returns this tick's input. `state` will be the game-state snapshot (Match.get_state(), added in
## M4); until then the Match passes null.
func get_input(_state: RefCounted) -> FighterInput:
	return FighterInput.new()


## Forgets anything remembered from the previous match.
func reset() -> void:
	pass
