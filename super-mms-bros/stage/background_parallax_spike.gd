extends Sprite2D
## THROWAWAY SPIKE: the background stays on screen (it lives on a CanvasLayer, so the camera's
## zoom doesn't shrink it) and drifts a little as the camera pans, so it feels far away.
## The image is 10% larger than the screen, which leaves room to drift.

## How much the background moves per pixel the camera moves.
const DRIFT := 0.06
const SCREEN_CENTER := Vector2(240, 135)
## Where the camera looks when everything is centered on the stage.
const STAGE_FOCUS := Vector2(240, 160)


func _process(_delta: float) -> void:
	var camera := get_viewport().get_camera_2d()
	if camera == null:
		return
	var margin := (texture.get_size() - Vector2(480, 270)) / 2.0
	var drift := (camera.get_screen_center_position() - STAGE_FOCUS) * -DRIFT
	position = SCREEN_CENTER + drift.clamp(-margin, margin)
