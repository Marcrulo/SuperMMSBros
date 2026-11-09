class_name CharacterData
extends Resource
## One playable character (docs/specs/menus.md#characters-and-the-roster).

## The character played when none was chosen (Pia).
const DEFAULT_ID := "slot_01"

## Also the name of its sprite folder, assets/fighters/<id>/.
@export var id: String
@export var display_name: String
## False for a character that's announced on the select screen but can't be played yet.
@export var playable: bool = false
## Its picture on the select screen (optional; without one the screen shows the fighter's head).
@export var portrait: Texture2D
## Its movement and shield numbers, and its move set (empty while it isn't playable).
@export var stats: FighterStats
