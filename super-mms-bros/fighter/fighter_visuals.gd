class_name FighterVisuals
extends Node2D
## Draws the parent Fighter from its sprite strips (docs/specs/fighter.md#visuals-fightervisuals,
## docs/specs/art-guide.md: 48×48 frames, feet at the bottom center, facing right). The animation
## comes from the fighter's state and the frame from its state_frame (ticks), so the drawing stays
## in step with the gameplay. Only reads the fighter's state; never changes it.

const SPRITE_DIR := "res://assets/fighters/default/"
const FRAME := 48
## Ticks each drawing is shown, per animation (art guide). A non-looping animation holds its last
## drawing. For moves, the strike drawing covers exactly the move's active frames.
const ANIMATIONS := {
	"idle": {"ticks": [8, 8, 8, 8], "loop": true},
	"run": {"ticks": [5, 5, 5, 5, 5, 5], "loop": true},
	"crouch": {"ticks": [2, 2], "loop": false},
	"jump": {"ticks": [4, 4], "loop": false},
	"fall": {"ticks": [6, 6], "loop": true},
	"helpless": {"ticks": [6, 6], "loop": true},
	"shield": {"ticks": [1], "loop": false},
	"dizzy": {"ticks": [10, 10], "loop": true},
	"hurt": {"ticks": [4, 4], "loop": true},
	"jab": {"ticks": [2, 2, 3, 6, 6], "loop": false},
	"down_tilt": {"ticks": [3, 2, 3, 6, 6], "loop": false},
	"up_tilt": {"ticks": [3, 2, 4, 7, 7], "loop": false},
	"side_tilt": {"ticks": [4, 3, 3, 8, 8], "loop": false},
	"neutral_special_charge": {"ticks": [6, 6], "loop": true},
	"neutral_special": {"ticks": [3, 4, 9, 9], "loop": false},
	"down_special_dive": {"ticks": [1], "loop": false},
	"down_special": {"ticks": [5, 5, 6, 10, 10], "loop": false},
	"side_special": {"ticks": [5, 5, 10, 10], "loop": false},
	"up_special": {"ticks": [4, 12, 1], "loop": false},
}
## The shirt's three shades in the drawings (P1), and what P2 wears instead: the team color swap.
const SHIRT_COLORS: Array[Color] = [Color8(177, 62, 83), Color8(128, 40, 62), Color8(214, 92, 106)]
const P2_SHIRT_COLORS: Array[Color] = [Color8(59, 93, 201), Color8(41, 54, 111), Color8(90, 140, 230)]
const HURTBOX_COLOR := Color(0.3, 0.6, 1.0, 0.35)

## Debug view of hurtboxes (and, from M5, hitboxes): F1 toggles it, `--hitboxes` turns it on.
static var show_boxes := "--hitboxes" in OS.get_cmdline_user_args()
## Textures per player color (index 0 = P1, 1 = P2), then per animation name.
static var _textures: Array[Dictionary] = []

@onready var _fighter := get_parent() as Fighter


## Which drawing of an animation to show after `ticks` ticks in the state (1 = the first tick).
static func frame_index(durations: Array, loop: bool, ticks: int) -> int:
	var total := 0
	for duration: int in durations:
		total += duration
	var t := maxi(ticks - 1, 0)
	if loop:
		t %= total
	for i in durations.size():
		t -= durations[i]
		if t < 0:
			return i
	return durations.size() - 1


## The animation for a movement state (moves are added in M5–M6).
static func animation_for(state: Fighter.State, velocity_y: float) -> String:
	match state:
		Fighter.State.RUN:
			return "run"
		Fighter.State.CROUCH:
			return "crouch"
		Fighter.State.AIR:
			return "jump" if velocity_y < 0.0 else "fall"
	return "idle"


## Loads every strip; with `shirt` colors given, repaints the shirt's shades in them.
static func load_textures(shirt: Array[Color]) -> Dictionary:
	var textures := {}
	for animation: String in ANIMATIONS:
		var texture := load(SPRITE_DIR + "fighter_%s.png" % animation) as Texture2D
		if not shirt.is_empty():
			var image := texture.get_image()
			image.decompress()
			for y in image.get_height():
				for x in image.get_width():
					var index := SHIRT_COLORS.find(image.get_pixel(x, y))
					if index != -1:
						image.set_pixel(x, y, shirt[index])
			texture = ImageTexture.create_from_image(image)
		textures[animation] = texture
	return textures


func _ready() -> void:
	if _textures.is_empty():
		_textures = [load_textures([]), load_textures(P2_SHIRT_COLORS)]


func _process(_delta: float) -> void:
	queue_redraw()


func _unhandled_input(event: InputEvent) -> void:
	# Only P1's visuals handle the key, so two fighters don't toggle it twice.
	if _fighter.player_index == 0 and event is InputEventKey and event.pressed \
			and not event.echo and event.keycode == KEY_F1:
		show_boxes = not show_boxes


func _draw() -> void:
	var animation := animation_for(_fighter.state, _fighter.velocity.y)
	var texture: Texture2D = _textures[mini(_fighter.player_index, 1)][animation]
	var timing: Dictionary = ANIMATIONS[animation]
	var frame := frame_index(timing.ticks, timing.loop, _fighter.state_frame)
	# Mirror when facing left; the strips are drawn facing right.
	draw_set_transform(Vector2.ZERO, 0.0, Vector2(_fighter.facing, 1))
	draw_texture_rect_region(texture, Rect2(-FRAME / 2.0, -FRAME, FRAME, FRAME),
		Rect2(frame * FRAME, 0, FRAME, FRAME))
	draw_set_transform(Vector2.ZERO)
	if show_boxes:
		var hurtbox := _fighter.get_hurtbox_rect()
		hurtbox.position -= _fighter.global_position
		draw_rect(hurtbox, HURTBOX_COLOR)
		draw_rect(hurtbox, HURTBOX_COLOR.lightened(0.4), false, 1.0)
