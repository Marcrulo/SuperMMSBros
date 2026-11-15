class_name Hose
extends RefCounted
## A hose drawn by Kim's tools (the blower's and the torch's): a smooth curve from one point to
## another, bending toward a control point. Presentation only.


## The points of a quadratic curve from `from` to `to`, bent toward `control`.
static func curve(from: Vector2, control: Vector2, to: Vector2, steps := 8) -> PackedVector2Array:
	var points := PackedVector2Array()
	for i in steps + 1:
		var t := float(i) / steps
		points.append(from.lerp(control, t).lerp(control.lerp(to, t), t))
	return points
