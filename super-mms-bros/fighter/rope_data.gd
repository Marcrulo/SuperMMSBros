class_name RopeData
extends Resource
## Sjippepigen's jump ropes (docs/specs/characters/sjippepigen.md#sjippepigen--jump-ropes): always spinning round
## her; their tips hurt. Two lengths, switched by her down special.

## How many ropes, a 1/count turn apart.
@export var count: int
## What they go round: her body middle, from the feet (facing right).
@export var center: Vector2
## The tip's path: half-width and half-height of the loop (px), short and long.
@export var short_radius: Vector2
@export var long_radius: Vector2
## Ticks per turn, short and long.
@export var short_period: int
@export var long_period: int
## The box round a tip that hurts.
@export var tip_size: Vector2
## After taking a rope hit, a fighter can't be hurt by ropes for this many ticks.
@export var immune_frames: int
## A tip's hit, short and long.
@export var short_hit: MoveData
@export var long_hit: MoveData
## The frenzy (her charged neutral special): this many ticks of the ropes spinning `frenzy_speed`
## times as fast, their hits replaced by `frenzy_hit` (no damage, strong knockback) with
## `frenzy_charge_knockback` × the charge (0…1) added to its base knockback.
@export var frenzy_frames: int
@export var frenzy_speed: float
@export var frenzy_hit: MoveData
@export var frenzy_charge_knockback: float
## The frenzy meter (on her player card): empty at every spawn, it fills up over this many ticks
## (not during a frenzy); the frenzy can only be charged with a full meter, and starting one
## empties it.
@export var frenzy_refill_frames: int
