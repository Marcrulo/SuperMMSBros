class_name MoveData
extends Resource
## One move's timing, hitbox and knockback (docs/specs/moves.md#movedata).
## Frames count from 1 on the tick the move starts.

## FACING: launched toward the attacker's facing side. AWAY: away from the attacker's center
## (for moves that hit on both sides or behind).
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
## Launch angle above horizontal; negative launches downward (a spike).
@export var angle_deg: float
@export var direction: Direction = Direction.FACING


@export_group("Special")
## Neutral special: ticks of charging for a full charge, and what a full charge adds.
@export var charge_frames: int
@export var charge_damage: float
@export var charge_knockback: float
## Up special: upward launch speed and the sideways speed it starts with (× move_x).
@export var launch_speed: float
@export var drift_speed: float
## Down special in the air: diving speed.
@export var dive_speed: float
## Neutral special as a belly flop (Pia): the belly's hit while diving; set = this neutral
## special is a belly flop (on the ground a hop at `hop_speed`, then a dive at `dive_speed`, then
## the flop on landing, which is this move's own hit).
@export var dive_hit: MoveData
## Belly flop: hops up this fast first on the ground (`belly_hop`), then dives.
@export var hop_speed: float
## Down special as eating (Pia's cake; no hitbox, ground only): heals this many % on frame
## `heal_frame`, then can't be used again for `cooldown_frames` ticks.
@export var heal: float
@export var heal_frame: int
@export var cooldown_frames: int
## Side special: the projectile (its size, damage and knockback are this move's hitbox and hit
## values; it appears at hitbox_center on frame `startup`).
@export var projectile_speed: float
@export var projectile_lifetime: int
## Side special: a fixed launch angle (degrees, up) and gravity (px/s², 0 = none) for a thrown
## projectile; it's gone when it lands on a floor top.
@export var projectile_angle_deg: float
@export var projectile_gravity: float
## Side special: the projectile flies at an angle within ±aim_cone_deg (0 = straight ahead):
## at the nearest other fighter in that cone within aim_range px, else at a random angle.
@export var aim_cone_deg: float
@export var aim_range: float
## Side special: how many projectiles at once, fanned out this many degrees apart (0 or 1 = one).
@export var projectile_count: int
@export var projectile_spread_deg: float
## Down special: switches stance (no dive, no hitbox) on frame `startup`.
@export var stances: StanceData
## Down special: places a banana peel (no dive).
@export var peel: PeelData
## Up special: a vine (to a nearby ledge, or a swing) instead of the jump boost.
@export var vine: VineData
## Up special: a pyramid rises out of the floor below (or a hop) instead of the jump boost.
@export var pyramid: PyramidData
## Down special: sits down and watches an iPad, healing (no dive, no hitbox; ground only).
@export var ipad: IpadData
## Down special: switches the fighter's jump ropes short ↔ long on frame `startup` (no dive, no
## hitbox).
@export var rope_switch: bool
## Neutral special: charged like the punch, but releasing it starts the jump ropes' frenzy
## (RopeData) instead of punching (no hitbox).
@export var rope_frenzy: bool
## Neutral special: let go before this many ticks of charging and nothing happens (0 = any charge).
@export var min_charge_frames: int
## A command grab: the hitbox is a grab box (catches through shields, never hits) and a catch
## starts this throw.
@export var grab: GrabData
## Neutral special as a summon (no charge): the hand it summons on frame `startup`.
@export var hand: HandData

func total_frames() -> int:
	return startup + active + recovery


## True on the frames the hitbox is out.
func is_active_frame(frame: int) -> bool:
	return frame > startup and frame <= startup + active
