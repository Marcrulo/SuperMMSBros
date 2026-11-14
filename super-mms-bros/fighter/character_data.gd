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
## Its own move set, used instead of the one in `stats` (optional; docs/specs/moves.md#character-move-sets).
@export var moveset: MoveSet
## Where the neutral special's charge glow is drawn (relative to the feet, facing right).
@export var charge_glow := Vector2(7, -14)
## Colors of the ropes/vines the game draws for this character (jump ropes, the rope up special);
## empty = the defaults.
@export var rope_colors: PackedColorArray = PackedColorArray()

## The stats with its own move set applied (made once).
var _fighter_stats: FighterStats


## The stats a fighter playing this character uses: `stats`, or a copy of it with `moveset`.
func fighter_stats() -> FighterStats:
	if moveset == null or stats == null:
		return stats
	if _fighter_stats == null:
		_fighter_stats = stats.duplicate() as FighterStats
		_fighter_stats.moveset = moveset
	return _fighter_stats
