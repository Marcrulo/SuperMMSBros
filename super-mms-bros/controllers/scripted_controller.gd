class_name ScriptedController
extends Controller
## Plays back a fixed list of inputs, one per tick, then empty input.
## With an empty list it does nothing at all (the training dummy). Used by tests.

var _inputs: Array[FighterInput] = []
var _next: int = 0


func _init(inputs: Array[FighterInput] = []) -> void:
	_inputs = inputs


func get_input(_state: RefCounted) -> FighterInput:
	if _next >= _inputs.size():
		return FighterInput.new()
	var input := _inputs[_next]
	_next += 1
	return input


func reset() -> void:
	_next = 0
