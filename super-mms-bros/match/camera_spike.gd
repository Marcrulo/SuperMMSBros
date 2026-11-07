extends Camera2D
## THROWAWAY SPIKE: a Smash-style camera. It frames every fighter plus the middle of the stage,
## zooming out when they spread apart and in when they're close, and glides there smoothly.
## Presentation only: it reads fighter positions and never changes gameplay.

## The middle of the stage always counts as a point to keep in view, so the camera doesn't
## leave the stage behind when a fighter wanders off.
const STAGE_FOCUS := Vector2(240, 160)
## Empty space kept around the framed points, in game pixels.
const MARGIN := Vector2(120, 80)
## The screen's size at zoom 1.
const VIEW := Vector2(480, 270)
## Most zoomed out (sees 1 / 0.6 = 1.67× as much) and most zoomed in.
const MIN_ZOOM := 0.6
const MAX_ZOOM := 1.4
## How quickly the camera catches up (higher = snappier).
const FOLLOW_SPEED := 4.0

@onready var _fighters := $"../Fighters"


## The first frame jumps straight to the right framing; after that the camera glides. (In
## _ready() the fighters aren't at their spawn points yet: the Match places them after.)
var _placed := false


func _process(delta: float) -> void:
	_update(1.0 - exp(-FOLLOW_SPEED * delta) if _placed else 1.0)
	_placed = true


## Moves `weight` of the way toward the ideal framing (1 = jump straight there).
func _update(weight: float) -> void:
	var box := Rect2(STAGE_FOCUS, Vector2.ZERO)
	for fighter: Fighter in _fighters.get_children():
		box = box.expand(fighter.get_center())
	box = box.grow_individual(MARGIN.x, MARGIN.y, MARGIN.x, MARGIN.y)
	var target_zoom := clampf(minf(VIEW.x / box.size.x, VIEW.y / box.size.y), MIN_ZOOM, MAX_ZOOM)
	position = position.lerp(box.get_center(), weight)
	zoom = zoom.lerp(Vector2(target_zoom, target_zoom), weight)
