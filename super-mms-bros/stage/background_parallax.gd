extends Sprite2D
## The stage background: it lives on a CanvasLayer, so the camera's zoom doesn't shrink it, and
## drifts a little as the camera pans, so it feels far away (docs/specs/match-and-stage.md).
## Presentation only.

## How much the background moves per pixel the camera moves.
const DRIFT := 0.06
const SCREEN_CENTER := Vector2(240, 135)
const SCREEN_SIZE := Vector2(480, 270)
## Where the camera looks when everything is centered on the stage.
const STAGE_FOCUS := Vector2(240, 160)


func _process(_delta: float) -> void:
	var camera := get_viewport().get_camera_2d()
	if camera == null or texture == null:
		return
	var margin := (texture.get_size() - SCREEN_SIZE) / 2.0
	var drift := (camera.get_screen_center_position() - STAGE_FOCUS) * -DRIFT
	position = SCREEN_CENTER + drift.clamp(-margin, margin)
