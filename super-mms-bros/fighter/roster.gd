class_name Roster
extends Resource
## The characters, in select-screen order, and how many slots the screen has. A slot whose
## character isn't playable yet, or past the list, is locked
## (docs/specs/menus.md#characters-and-the-roster).

@export var characters: Array[CharacterData] = []
@export var slots: int = 10


## The character in select-screen slot `index` (0-based), or null if the slot is empty.
func character_in_slot(index: int) -> CharacterData:
	return characters[index] if index >= 0 and index < characters.size() else null


## True if slot `index` can't be chosen: empty, or its character isn't playable yet.
func is_locked(index: int) -> bool:
	var character := character_in_slot(index)
	return character == null or not character.playable


## The character with this id, or null.
func find(character_id: String) -> CharacterData:
	for character in characters:
		if character.id == character_id:
			return character
	return null
