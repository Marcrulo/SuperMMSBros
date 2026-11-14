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
## Pia's cake (her neutral_special drawings): the last tick of each stretch and the drawing shown in
## it (taking it out, bite, chew, bite, chew); after that, happy (3).
const CAKE_ENDS: Array[int] = [10, 19, 28, 37, 45]
const CAKE_DRAWINGS: Array[int] = [0, 1, 2, 1, 2]
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
## The vine: its colors, and where it leaves the hands (relative to the feet, facing right).
const VINE := Color(0.24, 0.54, 0.23)
const VINE_DARK := Color(0.1, 0.11, 0.17)
const VINE_HANDS := Vector2(2, -36)
## Stig's cross smash: the burst of light (burst.png, 4 drawings) in front of him from the move's
## first active frame, each drawing shown this many ticks, its near end this far ahead of his feet
## (game px, facing right), standing on the floor.
const BURST_TICKS := 3
const BURST_DRAWINGS := 4
const BURST_X := 7.0
## Pia's belly-flop dust (dust.png): drawings, and how far out from her feet each side starts.
const DUST_DRAWINGS := 4
const DUST_X := 6.0
## Trine's iPad break: ticks per watching drawing (2 and 3 alternate), how long one watch-and-sip
## round lasts and how much of it is the sip (drawing 4), and the heal "+": how long
## one shows, how high it rises, where it starts (above her head), its colors.
## Sjippepigen's ropes: their colors, the outline, where the handles are (her hands, near the
## hips, relative to the feet, facing right), and how wide each loop is at its widest.
const ROPE_COLORS: Array[Color] = [Color8(220, 64, 64), Color8(72, 124, 220), Color8(240, 200, 64)]
const ROPE_DARK := Color(0.1, 0.11, 0.17)
const ROPE_HANDS := Vector2(2, -15)
## Sjippepigen's frenzy charge meter: a ring this far above her feet, this big.
const FRENZY_METER_AT := Vector2(0, -44)
const FRENZY_METER_RADIUS := 5.0
## How much the rope bows back (radians of the path behind the tip), and how long the faint
## streak behind each tip is (radians).
const ROPE_LAG := 0.6
## How wide a rope's loop swells (share of its length, either side).
const ROPE_WIDTH := 0.5
const ROPE_TRAIL := 0.9
## A grappler's throw strip: the last tick of each drawing but the last (catch, lift, overhead,
## turned round, slam; then straightening up).
const THROW_ENDS: Array[int] = [3, 8, 14, 18, 30]
const THROW_DRAWINGS := 6
const IPAD_WATCH_TICKS := 15
const IPAD_SIP_CYCLE := 60
const IPAD_SIP_TICKS := 30
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
## Each character's hand positions per drawing (hands.json), looked up once.
static var _hands: Dictionary[String, Dictionary] = {}
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


## The animation for a state (and, during a move, the move's own animation).
static func animation_for(state: Fighter.State, velocity_y: float, move: StringName = &"") -> String:
	match state:
		Fighter.State.ATTACK:
			if move in Fighter.VINE_PHASES or move == &"pyramid_rise":
				return "up_special"
			if move in Fighter.IPAD_PHASES:
				return "down_special"
			if move == &"grab_throw":
				return "side_special"
			if move == &"belly_hop":
				return "jump"
			if move == &"belly_dive":
				return "down_special_dive"
			if move == &"belly_flop":
				return "down_special"
			if move == &"cake":
				return "neutral_special"
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


## Which drawing of Pia's neutral_special strip (the cake) to show `ticks` ticks into it.
static func cake_frame(ticks: int) -> int:
	for i in CAKE_ENDS.size():
		if ticks <= CAKE_ENDS[i]:
			return CAKE_DRAWINGS[i]
	return 3


## Which drawing of the down_special strip Trine's iPad break shows, `ticks` ticks into `phase`:
## bending down then seated (0, 1); watching: 1 and 2 alternating, then a sip of coffee (3) at the
## end of every round; getting up (4).
static func ipad_frame(phase: StringName, ticks: int) -> int:
	match phase:
		&"ipad_watch":
			var t := maxi(ticks - 1, 0) % IPAD_SIP_CYCLE
			if t >= IPAD_SIP_CYCLE - IPAD_SIP_TICKS:
				return 3
			return 1 + (t / IPAD_WATCH_TICKS) % 2
		&"ipad_stand":
			return 4
	return 0 if ticks <= 5 else 1


## The strip to draw an animation with and whether to mirror it: facing left, a character's own
## facing-left strip (`<animation>_left`, already mirrored, lettering readable) unmirrored, else the
## usual strip mirrored. Returns [texture, x scale].
static func strip_for(textures: Dictionary, animation: String, facing: int) -> Array:
	if facing < 0 and textures.has(animation + "_left"):
		return [textures[animation + "_left"], 1]
	return [textures[animation], facing]


## Which drawing of a grappler's throw strip (fighter_grab_throw.png, docs/specs/art-guide.md,
## Mads's slam) to show `ticks` ticks into the throw: the last tick of each drawing in THROW_ENDS.
static func throw_frame(ticks: int) -> int:
	for i in THROW_ENDS.size():
		if ticks <= THROW_ENDS[i]:
			return i
	return THROW_ENDS.size()


## How far a held fighter is turned over (radians), `ticks` ticks into the throw: half a turn by
## the slam.
static func held_turn(ticks: int, grab: GrabData) -> float:
	return PI * clampf(float(ticks) / grab.slam_frame, 0.0, 1.0)


## How many ticks ago each heal "+" still showing appeared, oldest first, `ticks` ticks into
## watching (a heal every `ipad.heal_every` ticks).
static func heal_plus_ages(ipad: IpadData, ticks: int) -> Array[int]:
	var ages: Array[int] = []
	var heal := (ticks / ipad.heal_every) * ipad.heal_every
	while heal >= ipad.heal_every and ticks - heal < HEAL_PLUS_TICKS:
		ages.push_front(ticks - heal)
		heal -= ipad.heal_every
	return ages


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


## Loads every strip and the stock icon of a character.
static func load_textures(character_id: String) -> Dictionary:
	var dir := SPRITES_DIR + character_id + "/"
	var textures := {}
	for animation: String in ANIMATIONS:
		textures[animation] = load(dir + "fighter_%s.png" % animation) as Texture2D
		# A strip drawn for facing left (lettering that must not be mirrored), if there is one.
		var left := dir + "fighter_%s_left.png" % animation
		if ResourceLoader.exists(left):
			textures[animation + "_left"] = load(left) as Texture2D
	textures["stock_icon"] = load(dir + "stock_icon.png") as Texture2D
	if ResourceLoader.exists(dir + "fighter_grab_throw.png"):
		textures["grab_throw"] = load(dir + "fighter_grab_throw.png") as Texture2D
	if ResourceLoader.exists(dir + "burst.png"):
		textures["burst"] = load(dir + "burst.png") as Texture2D
	if ResourceLoader.exists(dir + "dust.png"):
		textures["dust"] = load(dir + "dust.png") as Texture2D
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
	# A held fighter is drawn behind its thrower, whose hands and head hold it.
	z_index = -1 if _fighter.state == Fighter.State.HELD else 0
	if is_hidden(_fighter.state, _fighter.invulnerable_frames):
		return
	var animation := animation_for(_fighter.state, _fighter.velocity.y, _fighter.move)
	var strip := strip_for(textures_for(_fighter.character_id), animation, _fighter.facing)
	var texture: Texture2D = strip[0]
	var mirror: int = strip[1]
	var timing: Dictionary = ANIMATIONS[animation]
	var frame := frame_index(timing.ticks, timing.loop, _fighter.state_frame)
	var vine := _fighter.state == Fighter.State.ATTACK and _fighter.move in Fighter.VINE_PHASES
	if vine:
		frame = timing.ticks.size() - 1  # Arms up, holding the vine.
	elif _fighter.state == Fighter.State.ATTACK and _fighter.move == &"pyramid_rise":
		frame = 1  # Arms up, riding the pyramid's tip.
	var drawings: int = timing.ticks.size()
	var textures := textures_for(_fighter.character_id)
	if _fighter.state == Fighter.State.ATTACK and _fighter.move == &"grab_throw" \
			and textures.has("grab_throw"):
		texture = textures["grab_throw"]
		mirror = _fighter.facing
		drawings = THROW_DRAWINGS
		frame = throw_frame(_fighter.state_frame)
	var ipad := _fighter.state == Fighter.State.ATTACK and animation == "down_special" \
		and _fighter.stats.moveset.down_special.ipad != null
	if ipad:
		frame = ipad_frame(_fighter.move, _fighter.state_frame)
	var cake := _fighter.state == Fighter.State.ATTACK and _fighter.move == &"cake"
	if cake:
		frame = cake_frame(_fighter.state_frame)
	var width := frame_width(texture, drawings)
	var height := frame_size(texture)
	# Mirror when facing left; the strips are drawn facing right. Tripped: tipped over backward.
	var tipped := 0.0
	if _fighter.state == Fighter.State.TRIPPED:
		tipped = minf(_fighter.state_frame / TRIP_TICKS, 1.0)
	var turn := -_fighter.facing * PI / 2.0 * tipped
	var offset := Vector2(0.0, -TRIP_LIFT * tipped)
	if _fighter.state == Fighter.State.HELD and _fighter.held_by != null \
			and _fighter.held_by.stats.moveset.side_special.grab != null:
		# Turned over round the middle of the body as the thrower swings it (head first over him).
		var holder := _fighter.held_by
		turn = holder.throw_facing * -held_turn(_fighter.state_frame,
			holder.stats.moveset.side_special.grab)
		var middle := Vector2(0.0, -holder.stats.moveset.side_special.grab.held_middle)
		offset = middle - middle.rotated(turn)
	draw_set_transform(offset, turn, Vector2(mirror, 1))
	# Drawn at the fighter's size (Gitte's ÷ / × stances), from the feet.
	var rect := frame_rect(width, height)
	var s := _fighter.size_scale()
	draw_texture_rect_region(texture, Rect2(rect.position * s, rect.size * s),
		Rect2(frame * width, 0, width, height), tint(_is_flashing(), _fighter.is_intangible()))
	draw_set_transform(Vector2.ZERO)
	if vine:
		_draw_vine()
	if _fighter.ropes_active():
		_draw_ropes(animation, frame)
	if _fighter.state == Fighter.State.ATTACK and _fighter.move == &"neutral_special_charge":
		if _fighter.stats.moveset.neutral_special.rope_frenzy:
			_draw_frenzy_charge()
		else:
			_draw_charge_glow()
	if _fighter.state == Fighter.State.ATTACK and _fighter.move == &"down_special":
		_draw_burst()
	if _fighter.state == Fighter.State.ATTACK and _fighter.move == &"belly_flop":
		_draw_dust()
	if cake:
		var since := _fighter.state_frame - _fighter.cake_data().heal_frame
		if since >= 0 and since < HEAL_PLUS_TICKS:
			_draw_plus(since)
	if ipad and _fighter.move == &"ipad_watch":
		_draw_heal_plus()
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


## Each rope as seen from the side while skipping: from one hand of its pair of arms out through
## its tip and back to the pair's other hand (one smooth curve, bowed back a little the way it came:
## the rope lags behind the spin), outlined; and a faint streak along the tip's path behind it.
func _draw_ropes(animation: String, frame: int) -> void:
	var origin := _fighter.global_position
	for i in _fighter.ropes().count:
		var colors := rope_colors_for(_fighter.character_id)
		if colors.is_empty():
			colors = PackedColorArray(ROPE_COLORS)
		var color := colors[i % colors.size()]
		if _fighter.frenzy_frames_left > 0:
			color = color.lightened(0.45)  # Whipping round in a frenzy: lit up.
		elif frenzy_charge(_fighter) > 0.0:
			color = color.lightened(0.45 * frenzy_charge(_fighter))  # Lighting up while charging.
		var tip := _fighter.rope_tip(i) - origin
		var streak := PackedVector2Array()
		for k in 7:
			streak.append(_fighter.rope_tip(i, -ROPE_TRAIL * (1.0 - k / 6.0)) - origin)
		draw_polyline(streak, Color(color, 0.35), 2.0)
		var ends := rope_hands(_fighter.character_id, animation, frame, i)
		var a := Vector2(ends[0].x * _fighter.facing, ends[0].y) * _fighter.size_scale()
		var b := Vector2(ends[1].x * _fighter.facing, ends[1].y) * _fighter.size_scale()
		var lag := (_fighter.rope_tip(i, -ROPE_LAG) - origin - tip) * 0.4
		var rope := PackedVector2Array()
		for k in 21:
			rope.append(rope_loop_point(a, b, tip, lag, PI * k / 20.0))
		draw_polyline(rope, ROPE_DARK, 3.0)
		draw_polyline(rope, color, 1.0)


## A character's rope colors (CharacterData.rope_colors; empty = the defaults).
static func rope_colors_for(character_id: String) -> PackedColorArray:
	if not _rope_colors.has(character_id):
		var character := Game.roster().find(character_id)
		_rope_colors[character_id] = character.rope_colors if character else PackedColorArray()
	return _rope_colors[character_id]


## A point of a rope's loop at u (0 = hand a, π/2 = the tip, π = hand b): out from the hands to the
## tip and back, swelling to ROPE_WIDTH of its length either side (a rounded loop, not a V), bowed
## back by `lag` (most at the tip).
static func rope_loop_point(a: Vector2, b: Vector2, tip: Vector2, lag: Vector2, u: float) -> Vector2:
	var base := a.lerp(b, (1.0 - cos(u)) / 2.0)
	var mid := (a + b) / 2.0
	var out := tip - mid
	var across := out.orthogonal().normalized()
	if (a - b).dot(across) < 0.0:
		across = -across  # Hand a on the + side, so the loop swells outward on both sides.
	return base + out * sin(u) + across * out.length() * ROPE_WIDTH * sin(u) * cos(u) \
		+ lag * sin(u) * sin(u)


## Where pair `pair`'s two hands are in a drawing (front, back; game px from the feet, facing
## right), from the character's hands.json (written by the sprite generator); both at ROPE_HANDS
## when there's none.
static func rope_hands(character_id: String, animation: String, frame: int, pair: int) -> Array[Vector2]:
	if not _hands.has(character_id):
		var path := SPRITES_DIR + character_id + "/hands.json"
		var parsed: Variant = null
		if FileAccess.file_exists(path):
			parsed = JSON.parse_string(FileAccess.get_file_as_string(path))
		_hands[character_id] = parsed if parsed is Dictionary else {}
	var drawings: Array = _hands[character_id].get(animation, [])
	if frame < drawings.size() and pair < (drawings[frame] as Array).size():
		var hands: Array = drawings[frame][pair]
		return [Vector2(hands[0][0], hands[0][1]), Vector2(hands[1][0], hands[1][1])]
	return [ROPE_HANDS, ROPE_HANDS]


## The vine from the hands to where it hangs: the ledge corner, or on up past the anchor.
func _draw_vine() -> void:
	var hands := Vector2(VINE_HANDS.x * _fighter.facing, VINE_HANDS.y)
	var to := _fighter.vine_anchor - _fighter.global_position
	if _fighter.move == &"vine_swing":
		to += (to - hands).normalized() * 400.0
	elif _fighter.move == &"lasso_miss":
		# Out and back from her hands, 45° up and forward (moving with her as she falls), reaching
		# furthest halfway through.
		var vine := _fighter.stats.moveset.up_special.vine
		var reach := clampf(1.0 - absf(1.0 - 2.0 * _fighter.state_frame / float(vine.miss_frames)), 0.0, 1.0)
		to = hands + Vector2(_fighter.facing, -1.0).normalized() * vine.grab_range * reach
	var colors := rope_colors_for(_fighter.character_id)
	draw_line(hands, to, VINE_DARK, 4.0)
	draw_line(hands, to, colors[0] if not colors.is_empty() else VINE, 2.0)


## Which drawing of the light burst to show `ticks` ticks into `move`, or -1 for none: from its
## first active frame, BURST_TICKS ticks per drawing.
static func burst_frame(move_data: MoveData, ticks: int) -> int:
	var t := ticks - move_data.startup - 1
	if t < 0 or t >= BURST_TICKS * BURST_DRAWINGS:
		return -1
	return int(t / float(BURST_TICKS))


## Stig's light burst along the floor in front of him, if the character has one.
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


## Pia's belly-flop dust, rolling out along the floor on both sides of her, if she has it.
func _draw_dust() -> void:
	var textures := textures_for(_fighter.character_id)
	if not textures.has("dust"):
		return
	var frame := burst_frame(_fighter.current_move(), _fighter.state_frame)
	if frame < 0:
		return
	var texture: Texture2D = textures["dust"]
	var width := frame_width(texture, DUST_DRAWINGS)
	var height := frame_size(texture)
	var size := Vector2(width, height) * DRAWN_SIZE / 64.0 * _fighter.size_scale()
	for side in [1, -1]:
		draw_set_transform(Vector2.ZERO, 0.0, Vector2(side, 1))
		draw_texture_rect_region(texture, Rect2(Vector2(DUST_X, -size.y), size),
			Rect2(frame * width, 0, width, height))
	draw_set_transform(Vector2.ZERO)


## Trine's heal "+" signs, rising and fading above her head while she watches.
func _draw_heal_plus() -> void:
	for age in heal_plus_ages(_fighter.stats.moveset.down_special.ipad, _fighter.state_frame):
		_draw_plus(age)


## One heal "+", `age` ticks after its heal: rising and fading above the head.
func _draw_plus(age: int) -> void:
	var s := _fighter.size_scale()
	var t := age / float(HEAL_PLUS_TICKS)
	var at := (HEAL_PLUS_AT - Vector2(0, HEAL_PLUS_RISE * t)) * s
	var fade := Color(1, 1, 1, 1.0 - t)
	for part in [Rect2(at.x - 3, at.y - 1, 7, 3), Rect2(at.x - 1, at.y - 3, 3, 7)]:
		draw_rect(part, HEAL_PLUS_DARK * fade)
	for part in [Rect2(at.x - 2, at.y, 5, 1), Rect2(at.x, at.y - 2, 1, 5)]:
		draw_rect(part, HEAL_PLUS * fade)


## How far Sjippepigen's frenzy is charged (0…1), or 0 when she isn't charging it.
static func frenzy_charge(fighter: Fighter) -> float:
	var b := fighter.stats.moveset.neutral_special
	if not b.rope_frenzy or fighter.state != Fighter.State.ATTACK \
			or fighter.move != &"neutral_special_charge":
		return 0.0
	return clampf(fighter.state_frame / float(b.charge_frames), 0.0, 1.0)


## Her frenzy's charge meter: a ring above her head filling clockwise from the top, in her rope
## color; dim until the charge counts (min_charge_frames), bright after, flashing white when full.
func _draw_frenzy_charge() -> void:
	var b := _fighter.stats.moveset.neutral_special
	var charge := frenzy_charge(_fighter)
	var colors := rope_colors_for(_fighter.character_id)
	var color: Color = colors[0] if not colors.is_empty() else ROPE_COLORS[0]
	var counts := _fighter.state_frame >= b.min_charge_frames
	if charge >= 1.0 and (_fighter.state_frame / 4) % 2 == 0:
		color = Color.WHITE
	elif counts:
		color = color.lightened(0.5)
	else:
		color = Color(color.darkened(0.2), 0.6)
	var at := FRENZY_METER_AT * _fighter.size_scale()
	draw_arc(at, FRENZY_METER_RADIUS, 0.0, TAU, 24, ROPE_DARK, 3.0)
	if charge > 0.0:
		draw_arc(at, FRENZY_METER_RADIUS, -PI / 2.0, -PI / 2.0 + TAU * charge, 24, color, 2.0)


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
