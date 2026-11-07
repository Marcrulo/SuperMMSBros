class_name MoveData
extends Resource
## One move's timing, hitbox and knockback (docs/specs/moves.md#movedata).
## Frames count from 1 on the tick the move starts.

## FACING: launched toward the attacker's facing side. AWAY: away from the attacker's center
## (for moves that hit on both sides).
enum Direction { FACING, AWAY }

@export_group("Frames")
@export var startup: int
@export var active: int
@export var recovery: int

@export_group("Hitbox")
## Relative to the feet, facing right; mirrored when facing left.
@export var hitbox_center: Vector2
@export var hitbox_size: Vector2

@export_group("Hit")
## % added to the victim.
@export var damage: float
## Launch speed = base_knockback + knockback_growth × the victim's % after this hit, in px/s.
@export var base_knockback: float
@export var knockback_growth: float
## Launch angle above horizontal.
@export var angle_deg: float
@export var direction: Direction = Direction.FACING


func total_frames() -> int:
	return startup + active + recovery


## True on the frames the hitbox is out.
func is_active_frame(frame: int) -> bool:
	return frame > startup and frame <= startup + active
