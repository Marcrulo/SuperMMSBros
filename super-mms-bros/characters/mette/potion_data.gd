class_name PotionData
extends AbilityData
## Mette's potions (docs/specs/characters/mette.md#mette--potions): the flask, the smash, the
## puddles and the reactions. On her move set (one ability for her neutral, down and side
## specials); the flask's hit is her side special's own MoveData.

@export_group("Flask")
## Where it leaves her hand (from the feet, facing right), its speed, angle upward and gravity.
@export var flask_spawn: Vector2
@export var flask_speed: float
@export var flask_angle_deg: float
@export var flask_gravity: float
## Its hitbox (centered on it) and ticks before it's gone.
@export var flask_size: Vector2
@export var flask_lifetime: int
## How far below where it broke the floor may be for the potion to land there.
@export var splash_reach: float

@export_group("Flask smash")
## Her neutral special's hit with each potion (its frames and hitbox are the move's own), and how
## long green stuns, in ticks.
@export var smash_red: MoveData
@export var smash_blue: MoveData
@export var smash_green: MoveData
@export var smash_stun: int

@export_group("Puddles")
## Its area: width × height above the floor, bottom center at the puddle's position.
@export var puddle_width: float
@export var puddle_height: float
@export var puddle_lifetime: int
## Puddles of hers at once; another removes her oldest.
@export var max_puddles: int
## Red: % every `acid_interval` ticks standing in it.
@export var acid_damage: float
@export var acid_interval: int
## Blue: ground grip; green: ground speed and jump (docs/specs/fighter.md#ground-modifiers).
@export var ice_grip: float
@export var glue_speed: float
@export var glue_jump: float

@export_group("Reactions")
## Steam (red + blue): its area (bottom center on the floor), ticks and hit.
@export var steam_size: Vector2
@export var steam_frames: int
@export var steam_hit: MoveData
## Explosion (red + green).
@export var blast_size: Vector2
@export var blast_frames: int
@export var blast_hit: MoveData
## Foam pillar (blue + green): width, full height, ticks rising / standing / sinking, and the
## vertical speed it pops a fighter standing in it up with.
@export var foam_width: float
@export var foam_height: float
@export var foam_rise: int
@export var foam_stand: int
@export var foam_sink: int
@export var foam_pop_speed: float


func create_ability() -> FighterAbility:
	return PotionAbility.new()
