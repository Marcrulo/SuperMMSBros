class_name MatchEntity
extends Node2D
## Something a fighter's ability adds to the match (a summoned hand, a banana peel, a pyramid):
## the Match keeps them in one list and advances, hit-tests and removes them all the same way
## (docs/specs/architecture.md#abilities). Drawing only reads.

## Player index of the fighter it belongs to.
var owner_index: int
## Set by the Match when it takes the entity out (it may still exist until the end of the frame).
var removed := false


## True to draw it behind the fighters (else in front, with the projectiles).
func behind_fighters() -> bool:
	return false


## One tick.
func advance(_match: Match) -> void:
	pass


## After every entity moved and the new ones were added (a peel trips someone here).
func interact(_match: Match) -> void:
	pass


## Adds its hits for this tick to `hits` (see Match._resolve_hits()).
func collect_hits(_match: Match, _hits: Array[Dictionary]) -> void:
	pass


## True once it should be taken out.
func is_finished(_match: Match) -> bool:
	return false


## True if it goes when its owner is KO'd.
func removed_with_owner() -> bool:
	return false
