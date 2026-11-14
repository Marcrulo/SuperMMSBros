class_name FighterVisuals
extends Node2D
## Draws the parent Fighter from its sprite strips (docs/specs/fighter.md#visuals-fightervisuals,
## docs/specs/art-guide.md: 48×48 or 64×64 frames, feet at the bottom center, facing right; both
## drawn into 48×48 game pixels). The animation
## comes from the fighter's state and the frame from its state_frame (ticks), so the drawing stays
## in step with the gameplay. Only reads the fighter's state; never changes it.

## Each character's strips are in <SPRITES_DIR><character id>/.
const SPRITES_DIR := "res://assets/fighters/"
## The game pixels every frame is drawn into (a 64 px frame at 3/4 size).
const DRAWN_SIZE := 48.0
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
## The neutral special's charge glow, by default at the fists (relative to the feet, facing right;
## a character can set its own: CharacterData.charge_glow).
const CHARGE_GLOW := Color(0.45, 0.94, 0.97, 0.8)
const FIST := Vector2(7, -14)
## A tripped fighter tips over backward onto the floor in this many ticks, lifted this much so the
## lying body rests on the floor.
const TRIP_TICKS := 6.0
const TRIP_LIFT := 8.0
## The down special's light burst (burst.png, 4 drawings, for a character that has one) in front of
## the fighter from the move's first active frame, each drawing shown this many ticks, its near end
## this far ahead of the feet (game px, facing right), standing on the floor.
const BURST_TICKS := 3
const BURST_DRAWINGS := 4
const BURST_X := 7.0
## A heal "+" (an ability's heal: presentation only): how long one shows, how high it rises,
## where it starts (above the head), its colors.
const HEAL_PLUS_TICKS := 20
const HEAL_PLUS_RISE := 12.0
const HEAL_PLUS_AT := Vector2(0, -46)
const HEAL_PLUS := Color(0.39, 0.78, 0.3)
const HEAL_PLUS_DARK := Color(0.1, 0.11, 0.17)

## Debug view of hurtboxes and hitboxes: F1 toggles it, `--hitboxes` turns it on at start.
static var show_boxes := "--hitboxes" in OS.get_cmdline_user_args()
## Textures per character id, then per animation name (and "stock_icon").
static var _textures: Dictionary[String, Dictionary] = {}
## Each character's rope colors (CharacterData.rope_colors), looked up once.
static var _rope_colors: Dictionary[String, PackedColorArray] = {}
## Each character's charge glow point (CharacterData.charge_glow), looked up once.
static var _charge_glows: Dictionary[String, Vector2] = {}

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


## The animation for a state (and, during a move, the move's own animation); an ability's phase
## uses the animation `phase_animations` gives it (phase_animations_of()).
static func animation_for(state: Fighter.State, velocity_y: float, move: StringName = &"",
		phase_animations: Dictionary = {}) -> String:
	match state:
		Fighter.State.ATTACK:
			if phase_animations.has(move):
				return phase_animations[move]
			return String(move) if ANIMATIONS.has(String(move)) else "jab"
		Fighter.State.HITSTUN, Fighter.State.TRIPPED, Fighter.State.HELD:
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


## The strip to draw an animation with and whether to mirror it: facing left, a character's own
## facing-left strip (`<animation>_left`, already mirrored, lettering readable) unmirrored, else the
## usual strip mirrored. Returns [texture, x scale].
static func strip_for(textures: Dictionary, animation: String, facing: int) -> Array:
	if facing < 0 and textures.has(animation + "_left"):
		return [textures[animation + "_left"], 1]
	return [textures[animation], facing]


## Not drawn while KO'd; while invulnerable, hidden 4 ticks, shown 4 ticks, starting hidden.
static func is_hidden(state: Fighter.State, invulnerable_frames: int) -> bool:
	if state == Fighter.State.KO:
		return true
	return invulnerable_frames > 0 and (Match.INVULNERABLE_FRAMES - invulnerable_frames) / 4 % 2 == 0


## The shield bubble's radius for a given shield health.
static func shield_radius(health: float, max_health: float) -> float:
	return lerpf(SHIELD_MIN_RADIUS, SHIELD_MAX_RADIUS, clampf(health / max_health, 0.0, 1.0))


## A strip's frame height (48 or 64, or a bigger canvas for a character with a weapon).
static func frame_size(texture: Texture2D) -> int:
	return int(texture.get_height())


## A strip's frame width: the strip's width shared by its drawings (side by side).
static func frame_width(texture: Texture2D, drawings: int) -> int:
	return int(texture.get_width()) / drawings


## Game pixels per frame pixel: a 48 px frame 1:1, the 64 px style (any canvas) at 3/4.
static func pixel_scale(height: int) -> float:
	return 1.0 if height == 48 else DRAWN_SIZE / 64.0


## Where a frame is drawn: at pixel_scale, feet (bottom center) at the fighter's origin
## (a 64×64 frame fills DRAWN_SIZE square).
static func frame_rect(width: int = 64, height: int = 64) -> Rect2:
	var s := pixel_scale(height)
	return Rect2(-width * s / 2.0, -height * s, width * s, height * s)


## Loads every picture of a character, by name: each animation's strip (`fighter_<animation>.png`
## as "<animation>"; a facing-left one as "<animation>_left"), the stock icon, and any other
## picture in its folder (an ability's own strip or effect, e.g. `burst.png` as "burst").
static func load_textures(character_id: String) -> Dictionary:
	var dir := SPRITES_DIR + character_id + "/"
	var textures := {}
	for animation: String in ANIMATIONS:
		textures[animation] = load(dir + "fighter_%s.png" % animation) as Texture2D
	for file in ResourceLoader.list_directory(dir):
		if file.get_extension() == "png":
			var key := file.get_basename().trim_prefix("fighter_")
			if not textures.has(key):
				textures[key] = load(dir + file) as Texture2D
	return textures


## A character's strips, drawn in its own colors (no recoloring), loaded once and shared.
static func textures_for(character_id: String) -> Dictionary:
	if not _textures.has(character_id):
		_textures[character_id] = load_textures(character_id)
	return _textures[character_id]


## Where a character's charge glow is drawn (relative to the feet, facing right).
static func charge_glow_for(character_id: String) -> Vector2:
	if not _charge_glows.has(character_id):
		var character := Game.roster().find(character_id)
		_charge_glows[character_id] = character.charge_glow if character else FIST
	return _charge_glows[character_id]


func _process(_delta: float) -> void:
	queue_redraw()


func _unhandled_input(event: InputEvent) -> void:
	# Only P1's visuals handle the key, so two fighters don't toggle it twice.
	if _fighter.player_index == 0 and event is InputEventKey and event.pressed \
			and not event.echo and event.keycode == KEY_F1:
		show_boxes = not show_boxes


func _draw() -> void:
	# A held fighter is drawn behind its holder, whose hands and head hold it.
	z_index = -1 if _fighter.state == Fighter.State.HELD else 0
	if is_hidden(_fighter.state, _fighter.invulnerable_frames):
		return
	var animation := animation_for(_fighter.state, _fighter.velocity.y, _fighter.move,
		phase_animations_of(_fighter))
	var textures := textures_for(_fighter.character_id)
	var strip := strip_for(textures, animation, _fighter.facing)
	var texture: Texture2D = strip[0]
	var mirror: int = strip[1]
	var timing: Dictionary = ANIMATIONS[animation]
	var frame := frame_index(timing.ticks, timing.loop, _fighter.state_frame)
	var drawings: int = timing.ticks.size()
	var attacking := _fighter.state == Fighter.State.ATTACK
	if attacking:
		for ability in _fighter.abilities:
			frame = ability.drawing(animation, frame)
		for ability in _fighter.abilities:
			var own := ability.strip(textures)
			if not own.is_empty():
				texture = own[0]
				mirror = own[1]
				drawings = own[2]
				frame = own[3]
	var width := frame_width(texture, drawings)
	var height := frame_size(texture)
	# Mirror when facing left; the strips are drawn facing right. Tripped: tipped over backward.
	var tipped := 0.0
	if _fighter.state == Fighter.State.TRIPPED:
		tipped = minf(_fighter.state_frame / TRIP_TICKS, 1.0)
	var turn := -_fighter.facing * PI / 2.0 * tipped
	var offset := Vector2(0.0, -TRIP_LIFT * tipped)
	if _fighter.state == Fighter.State.HELD and _fighter.held_by != null:
		# Turned the way the holder's ability swings it (upright if it doesn't).
		for ability in _fighter.held_by.abilities:
			var pose := ability.held_pose(_fighter)
			if not pose.is_empty():
				turn = pose[0]
				offset = pose[1]
				break
	draw_set_transform(offset, turn, Vector2(mirror, 1))
	# Drawn at the fighter's size (an ability can change it), from the feet.
	var rect := frame_rect(width, height)
	var s := _fighter.size_scale()
	draw_texture_rect_region(texture, Rect2(rect.position * s, rect.size * s),
		Rect2(frame * width, 0, width, height), tint(_is_flashing(), _fighter.is_intangible()))
	draw_set_transform(Vector2.ZERO)
	for ability in _fighter.abilities:
		ability.draw(self, animation, frame)
	if attacking and _fighter.move == &"neutral_special_charge" \
			and not _fighter.replaced(&"neutral_special_charge"):
		_draw_charge_glow()
	if attacking and _fighter.move == &"down_special":
		_draw_burst()
	if _fighter.state == Fighter.State.SHIELD:
		_draw_shield()
	if show_boxes:
		_draw_boxes()


## The animations of `fighter`'s abilities' phases: {phase: animation}.
static func phase_animations_of(fighter: Fighter) -> Dictionary:
	var table := {}
	for ability in fighter.abilities:
		for phase in ability.phases():
			table[phase] = ability.phase_animation(phase)
	return table


## A translucent bubble in the player's color around the body, shrinking as the shield weakens.
func _draw_shield() -> void:
	var color := SHIELD_COLORS[mini(_fighter.player_index, 1)]
	var center := _fighter.get_center() - _fighter.global_position
	var radius := shield_radius(_fighter.shield_health, _fighter.stats.shield_max)
	draw_circle(center, radius, color)
	draw_arc(center, radius, 0.0, TAU, 24, color.lightened(0.5), 1.0)


## A character's rope colors (CharacterData.rope_colors, for the ropes and vines the game draws;
## empty = the drawer's defaults).
static func rope_colors_for(character_id: String) -> PackedColorArray:
	if not _rope_colors.has(character_id):
		var character := Game.roster().find(character_id)
		_rope_colors[character_id] = character.rope_colors if character else PackedColorArray()
	return _rope_colors[character_id]


## Which drawing of an effect strip (the down special's light burst) to show `ticks` ticks into
## `move`, or -1 for none: from its first active frame, BURST_TICKS ticks per drawing.
static func burst_frame(move_data: MoveData, ticks: int) -> int:
	var t := ticks - move_data.startup - 1
	if t < 0 or t >= BURST_TICKS * BURST_DRAWINGS:
		return -1
	return int(t / float(BURST_TICKS))


## The down special's light burst along the floor in front of the fighter, if the character has
## one (burst.png).
func _draw_burst() -> void:
	var textures := textures_for(_fighter.character_id)
	if not textures.has("burst"):
		return
	var frame := burst_frame(_fighter.current_move(), _fighter.state_frame)
	if frame < 0:
		return
	var texture: Texture2D = textures["burst"]
	var width := frame_width(texture, BURST_DRAWINGS)
	var height := frame_size(texture)
	var size := Vector2(width, height) * DRAWN_SIZE / 64.0 * _fighter.size_scale()
	draw_set_transform(Vector2.ZERO, 0.0, Vector2(_fighter.facing, 1))
	draw_texture_rect_region(texture, Rect2(Vector2(BURST_X, -size.y), size),
		Rect2(frame * width, 0, width, height))
	draw_set_transform(Vector2.ZERO)


## One heal "+", `age` ticks after its heal: rising and fading above the head (for abilities that
## heal).
func draw_heal_plus(age: int) -> void:
	var s := _fighter.size_scale()
	var t := age / float(HEAL_PLUS_TICKS)
	var at := (HEAL_PLUS_AT - Vector2(0, HEAL_PLUS_RISE * t)) * s
	var fade := Color(1, 1, 1, 1.0 - t)
	for part in [Rect2(at.x - 3, at.y - 1, 7, 3), Rect2(at.x - 1, at.y - 3, 3, 7)]:
		draw_rect(part, HEAL_PLUS_DARK * fade)
	for part in [Rect2(at.x - 2, at.y, 5, 1), Rect2(at.x, at.y - 2, 1, 5)]:
		draw_rect(part, HEAL_PLUS * fade)


## A glow that grows as the neutral special charges, at the character's charge glow point.
func _draw_charge_glow() -> void:
	var charge := clampf(_fighter.state_frame / float(_fighter.stats.moveset.neutral_special.charge_frames), 0.0, 1.0)
	var point := charge_glow_for(_fighter.character_id) * _fighter.size_scale()
	draw_circle(Vector2(point.x * _fighter.facing, point.y), 1.0 + 3.0 * charge, CHARGE_GLOW)


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
