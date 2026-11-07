class_name Roster
extends Resource
## The playable characters, in select-screen order, and how many slots the screen has; slots past
## the list are locked (docs/specs/menus.md#characters-and-the-roster).

@export var characters: Array[CharacterData] = []
@export var slots: int = 10


## The character in select-screen slot `index` (0-based), or null if that slot is locked.
func character_in_slot(index: int) -> CharacterData:
	return characters[index] if index >= 0 and index < characters.size() else null


## The character with this id, or null.
func find(character_id: String) -> CharacterData:
	for character in characters:
		if character.id == character_id:
			return character
	return null
