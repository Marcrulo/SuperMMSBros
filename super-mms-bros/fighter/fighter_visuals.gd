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
	"spot_dodge": {"ticks": [3, 12, 5], "loop": false},
	"roll": {"ticks": [6, 6, 6, 6], "loop": false},
	"air_dodge": {"ticks": [4, 4], "loop": false},
	"ledge": {"ticks": [12, 12], "loop": true},
	"ledge_climb": {"ticks": [6, 7, 7], "loop": false},
	"jab": {"ticks": [2, 2, 3, 4, 3], "loop": false},
	"down_tilt": {"ticks": [3, 2, 3, 4, 3], "loop": false},
	"up_tilt": {"ticks": [3, 2, 4, 4, 4], "loop": false},
	"side_tilt": {"ticks": [4, 3, 3, 5, 5], "loop": false},
	"neutral_air": {"ticks": [2, 1, 6, 3, 3], "loop": false},
	"forward_air": {"ticks": [3, 2, 3, 4, 3], "loop": false},
	"back_air": {"ticks": [3, 3, 3, 4, 4], "loop": false},
	"up_air": {"ticks": [2, 2, 4, 4, 3], "loop": false},
	"down_air": {"ticks": [3, 3, 3, 4, 4], "loop": false},
	"neutral_special_charge": {"ticks": [6, 6], "loop": true},
	"neutral_special": {"ticks": [3, 4, 5, 5], "loop": false},
	"down_special_dive": {"ticks": [1], "loop": false},
	"down_special": {"ticks": [5, 5, 6, 6, 6], "loop": false},
	"side_special": {"ticks": [5, 5, 6, 6], "loop": false},
	"up_special": {"ticks": [4, 12, 1], "loop": false},
}
## The shirt's three shades in the drawings (P1), and what P2 wears instead: the team color swap.
const SHIRT_COLORS: Array[Color] = [Color8(177, 62, 83), Color8(128, 40, 62), Color8(214, 92, 106)]
const P2_SHIRT_COLORS: Array[Color] = [Color8(59, 93, 201), Color8(41, 54, 111), Color8(90, 140, 230)]
const HURTBOX_COLOR := Color(0.3, 0.6, 1.0, 0.35)
const HITBOX_ACTIVE_COLOR := Color(1.0, 0.15, 0.15, 0.55)
const HITBOX_IDLE_COLOR := Color(1.0, 0.3, 0.3, 0.5)
## Brightness of the hit flash (values above 1 brighten the sprite).
const FLASH := Color(2.2, 2.2, 2.2)
## While intangible (dodges, ledge): pale and see-through.
const INTANGIBLE := Color(1.6, 1.6, 1.8, 0.55)
## Shield bubble: radius from empty to full, centered on the body; colors per player.
const SHIELD_MIN_RADIUS := 6.0
const SHIELD_MAX_RADIUS := 16.0
const SHIELD_COLORS: Array[Color] = [Color(0.85, 0.3, 0.38, 0.35), Color(0.3, 0.45, 0.95, 0.35)]
## The neutral special's charge glow, at the fists (relative to the feet, facing right).
const CHARGE_GLOW := Color(0.45, 0.94, 0.97, 0.8)
const FIST := Vector2(7, -14)

## Debug view of hurtboxes and hitboxes: F1 toggles it, `--hitboxes` turns it on at start.
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


## The animation for a state (and, during a move, the move's own animation).
static func animation_for(state: Fighter.State, velocity_y: float, move: StringName = &"") -> String:
	match state:
		Fighter.State.ATTACK:
			return String(move) if ANIMATIONS.has(String(move)) else "jab"
		Fighter.State.HITSTUN:
			return "hurt"
		Fighter.State.SHIELD, Fighter.State.SHIELD_DROP:
			return "shield"
		Fighter.State.SHIELD_BREAK:
			return "dizzy"
		Fighter.State.HELPLESS:
			return "helpless"
		Fighter.State.SPOT_DODGE:
			return "spot_dodge"
		Fighter.State.ROLL:
			return "roll"
		Fighter.State.AIR_DODGE:
			return "air_dodge"
		Fighter.State.LEDGE:
			return "ledge"
		Fighter.State.LEDGE_CLIMB:
			return "ledge_climb"
		Fighter.State.RUN:
			return "run"
		Fighter.State.CROUCH:
			return "crouch"
		Fighter.State.AIR:
			return "jump" if velocity_y < 0.0 else "fall"
	return "idle"


## Not drawn while KO'd; while invulnerable, hidden 4 ticks, shown 4 ticks, starting hidden.
static func is_hidden(state: Fighter.State, invulnerable_frames: int) -> bool:
	if state == Fighter.State.KO:
		return true
	return invulnerable_frames > 0 and (Match.INVULNERABLE_FRAMES - invulnerable_frames) / 4 % 2 == 0


## The shield bubble's radius for a given shield health.
static func shield_radius(health: float, max_health: float) -> float:
	return lerpf(SHIELD_MIN_RADIUS, SHIELD_MAX_RADIUS, clampf(health / max_health, 0.0, 1.0))


## Loads every strip and the stock icon; with `shirt` colors given, repaints the shirt's shades.
static func load_textures(shirt: Array[Color]) -> Dictionary:
	var textures := {}
	for animation: String in ANIMATIONS:
		var texture := load(SPRITE_DIR + "fighter_%s.png" % animation) as Texture2D
		textures[animation] = _recolored(texture, shirt)
	textures["stock_icon"] = _recolored(load(SPRITE_DIR + "stock_icon.png") as Texture2D, shirt)
	return textures


## `texture` with the shirt's shades repainted in `shirt` (unchanged if `shirt` is empty).
static func _recolored(texture: Texture2D, shirt: Array[Color]) -> Texture2D:
	if shirt.is_empty():
		return texture
	var image := texture.get_image()
	image.decompress()
	for y in image.get_height():
		for x in image.get_width():
			var index := SHIRT_COLORS.find(image.get_pixel(x, y))
			if index != -1:
				image.set_pixel(x, y, shirt[index])
	return ImageTexture.create_from_image(image)


## Every strip in a player's colors (0 = P1 red, 1 and up = P2 blue), loaded once and shared.
static func textures_for(player_index: int) -> Dictionary:
	if _textures.is_empty():
		_textures = [load_textures([]), load_textures(P2_SHIRT_COLORS)]
	return _textures[mini(player_index, 1)]


func _process(_delta: float) -> void:
	queue_redraw()


func _unhandled_input(event: InputEvent) -> void:
	# Only P1's visuals handle the key, so two fighters don't toggle it twice.
	if _fighter.player_index == 0 and event is InputEventKey and event.pressed \
			and not event.echo and event.keycode == KEY_F1:
		show_boxes = not show_boxes


func _draw() -> void:
	if is_hidden(_fighter.state, _fighter.invulnerable_frames):
		return
	var animation := animation_for(_fighter.state, _fighter.velocity.y, _fighter.move)
	var texture: Texture2D = textures_for(_fighter.player_index)[animation]
	var timing: Dictionary = ANIMATIONS[animation]
	var frame := frame_index(timing.ticks, timing.loop, _fighter.state_frame)
	# Mirror when facing left; the strips are drawn facing right.
	draw_set_transform(Vector2.ZERO, 0.0, Vector2(_fighter.facing, 1))
	draw_texture_rect_region(texture, Rect2(-FRAME / 2.0, -FRAME, FRAME, FRAME),
		Rect2(frame * FRAME, 0, FRAME, FRAME), tint(_is_flashing(), _fighter.is_intangible()))
	draw_set_transform(Vector2.ZERO)
	if _fighter.state == Fighter.State.ATTACK and _fighter.move == &"neutral_special_charge":
		_draw_charge_glow()
	if _fighter.state == Fighter.State.SHIELD:
		_draw_shield()
	if show_boxes:
		_draw_boxes()


## A translucent bubble in the player's color around the body, shrinking as the shield weakens.
func _draw_shield() -> void:
	var color := SHIELD_COLORS[mini(_fighter.player_index, 1)]
	var center := _fighter.get_center() - _fighter.global_position
	var radius := shield_radius(_fighter.shield_health, _fighter.stats.shield_max)
	draw_circle(center, radius, color)
	draw_arc(center, radius, 0.0, TAU, 24, color.lightened(0.5), 1.0)


## A glow on the fists that grows as the neutral special charges.
func _draw_charge_glow() -> void:
	var charge := clampf(_fighter.state_frame / float(_fighter.stats.moveset.neutral_special.charge_frames), 0.0, 1.0)
	var fist := Vector2(FIST.x * _fighter.facing, FIST.y)
	draw_circle(fist, 1.0 + 3.0 * charge, CHARGE_GLOW)


## The sprite's color: pale and see-through while intangible, bright on a hit flash, else as drawn.
static func tint(flashing: bool, intangible: bool) -> Color:
	if intangible:
		return INTANGIBLE
	return FLASH if flashing else Color.WHITE


## On alternate pairs of hitstun ticks (1–2, 5–6, …), so a hit flashes.
func _is_flashing() -> bool:
	return _fighter.state == Fighter.State.HITSTUN and int((_fighter.state_frame - 1) / 2.0) % 2 == 0


## Hurtbox in blue; during a move its hitbox in red, filled on the active frames.
func _draw_boxes() -> void:
	var hurtbox := _fighter.get_hurtbox_rect()
	hurtbox.position -= _fighter.global_position
	draw_rect(hurtbox, HURTBOX_COLOR)
	draw_rect(hurtbox, HURTBOX_COLOR.lightened(0.4), false, 1.0)
	if _fighter.current_move() == null:
		return
	var hitbox := _fighter.get_hitbox_rect()
	hitbox.position -= _fighter.global_position
	if _fighter.is_hitbox_active():
		draw_rect(hitbox, HITBOX_ACTIVE_COLOR)
	draw_rect(hitbox, HITBOX_IDLE_COLOR, false, 1.0)
