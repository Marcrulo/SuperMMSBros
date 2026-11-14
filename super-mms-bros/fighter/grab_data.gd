class_name GrabData
extends Resource
## A command grab's throw (docs/specs/characters/mads.md#mads--grappler): Mads's over-the-head slam.

## Frames of the throw from the catch; the thrower is free after the last.
@export var throw_frames: int
## The frame the thrower turns round (the victim overhead).
@export var turn_frame: int
## The frame the victim hits the floor and is launched (`slam_hit`).
@export var slam_frame: int
## Where the middle of the victim's body is (in the thrower's grip), relative to the thrower's
## feet, x toward the side he faced at the catch: evenly spaced keyframes from the catch (frame 0)
## to the slam, followed in straight lines between them.
@export var path: PackedVector2Array
## How far above the victim's feet the middle of its body is (px).
@export var held_middle: float
## The slam's hit (damage and knockback; launched away from the thrower).
@export var slam_hit: MoveData
