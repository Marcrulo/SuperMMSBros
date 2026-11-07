class_name MatchCamera
extends Camera2D
## A smash-style camera (docs/specs/match-and-stage.md#camera): frames every fighter plus the
## middle of the stage, zooming out when they spread apart and in when they're close, and glides
## there smoothly. Presentation only: it reads positions and never changes gameplay.

## The middle of the stage always counts as a point to keep in view.
const STAGE_FOCUS := Vector2(240, 160)
## Empty space kept around the framed points: sideways, and above/below.
const MARGIN := Vector2(120, 80)
## The view's size at zoom 1.
const VIEW := Vector2(480, 270)
const MIN_ZOOM := 0.77
const MAX_ZOOM := 1.4
## How quickly the camera catches up (higher = snappier).
const FOLLOW_SPEED := 4.0

## The first frame jumps straight to the framing; after that the camera glides. (In _ready() the
## fighters aren't at their spawn points yet: the Match places them after.)
var _placed := false


## Where the camera should look and how far it should zoom to frame `points` (and the stage
## focus), without showing anything outside `blast_zone`.
static func target_framing(points: Array[Vector2], blast_zone: Rect2) -> Dictionary:
	var box := Rect2(STAGE_FOCUS, Vector2.ZERO)
	for point in points:
		box = box.expand(point)
	box = box.grow_individual(MARGIN.x, MARGIN.y, MARGIN.x, MARGIN.y)
	var zoom_level := clampf(minf(VIEW.x / box.size.x, VIEW.y / box.size.y), MIN_ZOOM, MAX_ZOOM)
	var half_view := VIEW / zoom_level / 2.0
	var center := box.get_center()
	center.x = clampf(center.x, blast_zone.position.x + half_view.x, blast_zone.end.x - half_view.x)
	center.y = clampf(center.y, blast_zone.position.y + half_view.y, blast_zone.end.y - half_view.y)
	return {"position": center, "zoom": zoom_level}


func _process(delta: float) -> void:
	var match_node := get_parent() as Match
	if match_node == null:
		return
	var points: Array[Vector2] = []
	for fighter: Fighter in match_node.get_node("Fighters").get_children():
		if fighter.state != Fighter.State.KO:
			points.append(fighter.get_center())
	var stage := match_node.get_node("Stage") as Stage
	var target := target_framing(points, stage.blast_zone)
	var weight := 1.0 - exp(-FOLLOW_SPEED * delta) if _placed else 1.0
	_placed = true
	position = position.lerp(target.position, weight)
	var target_zoom: float = target.zoom
	zoom = zoom.lerp(Vector2(target_zoom, target_zoom), weight)
