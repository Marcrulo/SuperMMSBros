class_name RopeAbility
extends FighterAbility
## Sjippepigen's jump ropes (docs/specs/characters/sjippepigen.md#sjippepigen--jump-ropes): always
## spinning round her (unless she's stunned, held, KO'd, shielding, dodging or using her up
## special), their tips hurting whoever they touch. She has no attacks; her down special switches
## the ropes short ↔ long and her charged neutral special starts their frenzy (faster ropes whose
## hits only knock back), once the frenzy meter has refilled.

## The ropes' colors (unless the character has its own), the outline, where the handles are (her
## hands, near the hips, relative to the feet, facing right) when there's no hands.json.
const ROPE_COLORS: Array[Color] = [Color8(220, 64, 64), Color8(72, 124, 220), Color8(240, 200, 64)]
const ROPE_DARK := Color(0.1, 0.11, 0.17)
const ROPE_HANDS := Vector2(2, -15)
## The frenzy charge meter: a ring this far above her feet, this big.
const FRENZY_METER_AT := Vector2(0, -44)
const FRENZY_METER_RADIUS := 5.0
## How much the rope bows back (radians of the path behind the tip), and how long the faint
## streak behind each tip is (radians).
const ROPE_LAG := 0.6
## How wide a rope's loop swells (share of its length, either side).
const ROPE_WIDTH := 0.5
const ROPE_TRAIL := 0.9
## Where the frenzy meter sits on her player card: along the bottom, under the name and %.
const FRENZY_BAR_AT := Vector2(30, 25)

## Long or short (short at every spawn), and ticks they've spun (only while active; 0 at every
## spawn).
var rope_long: bool = false
var rope_tick: int = 0
## How far the ropes have turned (in turns, from 0 at every spawn); grows by speed / period a tick.
var rope_turns: float = 0.0
## Ticks left of the frenzy, and its hit.
var frenzy_frames_left: int = 0
var _frenzy_hit: MoveData = null
## The frenzy meter, 0…1 (full = the frenzy can be charged); empty at every spawn.
var frenzy_meter: float = 0.0
## Per rope: the turn in which it last hit each fighter (player index → turn).
var _rope_hits: Array[Dictionary] = []
## Ticks left (per player index) in which her ropes can't hurt that fighter (after a rope hit or
## her lasso). Counted down at the end of every step.
var _immune: Dictionary[int, int] = {}

## Each character's hand positions per drawing (hands.json), looked up once.
static var _hands: Dictionary[String, Dictionary] = {}


func ropes() -> RopeData:
	return data as RopeData


func reset() -> void:
	rope_long = false
	rope_tick = 0
	rope_turns = 0.0
	frenzy_frames_left = 0
	_frenzy_hit = null
	frenzy_meter = 0.0
	_rope_hits.clear()
	_immune.clear()


## Ticks left in which her ropes can't hurt fighter `player_index`.
func immune_frames(player_index: int) -> int:
	return _immune.get(player_index, 0)


## The ropes spin (and hurt) unless she's stunned, held, KO'd, shielding, dodging or using her
## up special.
func ropes_active() -> bool:
	if fighter.in_special(&"up_special"):
		return false
	return fighter.state not in [Fighter.State.HITSTUN, Fighter.State.TRIPPED,
		Fighter.State.SHIELD_BREAK, Fighter.State.HELD, Fighter.State.KO, Fighter.State.SHIELD,
		Fighter.State.SHIELD_DROP, Fighter.State.SPOT_DODGE, Fighter.State.ROLL,
		Fighter.State.AIR_DODGE]


## Rope i's position in turns (it starts i / count of a turn on).
func _rope_turns(i: int) -> float:
	return rope_turns + float(i) / ropes().count


func _rope_period() -> int:
	return ropes().long_period if rope_long else ropes().short_period


## Where rope i's tip is (world): round her body middle, over her head, down in front, under her
## feet, up behind.
func rope_tip(i: int, ahead: float = 0.0) -> Vector2:
	var numbers := ropes()
	var radius := numbers.long_radius if rope_long else numbers.short_radius
	var angle := TAU * _rope_turns(i) + ahead
	return fighter.global_position + Vector2(numbers.center.x * fighter.facing, numbers.center.y) \
		+ Vector2(sin(angle) * radius.x * fighter.facing, -cos(angle) * radius.y)


## The box round rope i's tip that hurts.
func rope_box(i: int) -> Rect2:
	var size := ropes().tip_size
	return Rect2(rope_tip(i) - size / 2.0, size)


## The hit of a rope tip at the current length (in a frenzy: the frenzy's hit).
func rope_hit() -> MoveData:
	if frenzy_frames_left > 0 and _frenzy_hit != null:
		return _frenzy_hit
	return ropes().long_hit if rope_long else ropes().short_hit


## Starts the frenzy with a charge of 0…1: faster ropes whose hits only knock back.
func start_frenzy(charge: float) -> void:
	var numbers := ropes()
	_frenzy_hit = numbers.frenzy_hit.duplicate() as MoveData
	_frenzy_hit.base_knockback = numbers.frenzy_hit.base_knockback + numbers.frenzy_charge_knockback * charge
	frenzy_frames_left = numbers.frenzy_frames
	frenzy_meter = 0.0


## Rope i hasn't hit fighter `victim_index` yet in its current turn.
func rope_can_hit(i: int, victim_index: int) -> bool:
	if _rope_hits.size() <= i:
		return true
	return _rope_hits[i].get(victim_index, -1) != floori(_rope_turns(i))


func register_rope_hit(i: int, victim_index: int) -> void:
	while _rope_hits.size() <= i:
		_rope_hits.append({})
	_rope_hits[i][victim_index] = floori(_rope_turns(i))


func allows_normals() -> bool:
	return false


## Only the up special, the rope switch (down special) and the frenzy (neutral special, not while
## a frenzy is on, once the meter is full).
func pick_special(input: FighterInput, _choice: StringName) -> StringName:
	match Fighter.special_direction(input):
		&"up_special":
			return &"up_special" if fighter.up_special_available else Fighter.NO_MOVE
		&"down_special":
			return &"down_special" if ropes().down_special_switches else Fighter.NO_MOVE
		&"neutral_special":
			if ropes().neutral_special_frenzy and frenzy_frames_left == 0 and frenzy_meter >= 1.0:
				return &"neutral_special_charge"
	return Fighter.NO_MOVE


## The rope switch, on the down special's frame `startup`.
func move_tick(_input: FighterInput) -> bool:
	if fighter.move != &"down_special" or not ropes().down_special_switches:
		return false
	if fighter.state_frame + 1 == fighter.stats.moveset.down_special.startup:
		rope_long = not rope_long
		_rope_hits.clear()
	return true


## No punch: the ropes go faster instead (if charged long enough).
func on_charge_released(charge: float) -> void:
	var charge_frames := fighter.stats.moveset.neutral_special.charge_frames
	if ropes().neutral_special_frenzy and charge * charge_frames >= ropes().frenzy_min_charge_frames:
		start_frenzy(charge)


func replaces(move: StringName) -> bool:
	return move == &"neutral_special_charge" and ropes().neutral_special_frenzy


func after_tick(_input: FighterInput) -> void:
	var numbers := ropes()
	if ropes_active():
		rope_tick += 1
		var speed := numbers.frenzy_speed if frenzy_frames_left > 0 else 1.0
		rope_turns += speed / _rope_period()
	if frenzy_frames_left == 0:
		frenzy_meter = minf(frenzy_meter + 1.0 / numbers.frenzy_refill_frames, 1.0)
		if frenzy_meter > 1.0 - 1e-6:
			frenzy_meter = 1.0  # (Adding up 1/n n times can fall just short of 1.)
	frenzy_frames_left = maxi(frenzy_frames_left - 1, 0)


## Her lasso hit `victim`: her ropes don't hit it straight after.
func on_hit_dealt(victim: Fighter) -> void:
	_immune[victim.player_index] = ropes().immune_frames


## At most one rope hit per fighter per tick (the first rope whose tip touches).
func collect_hits(match_: Match, hits: Array[Dictionary]) -> void:
	if not ropes_active():
		return
	for victim in match_.get_fighters():
		if victim == fighter or not victim.can_be_hit() or immune_frames(victim.player_index) > 0:
			continue
		for i in ropes().count:
			if rope_can_hit(i, victim.player_index) \
					and rope_box(i).intersects(victim.get_hurtbox_rect()):
				var dx := victim.get_center().x - fighter.get_center().x
				hits.append({
					"victim": victim,
					"move": rope_hit(),
					"side": fighter.facing if is_zero_approx(dx) else int(signf(dx)),
					"attacker_x": fighter.global_position.x,
					"register": _register_rope_hit.bind(i),
					"landed": on_hit_dealt,
				})
				break


func _register_rope_hit(victim_index: int, i: int) -> void:
	register_rope_hit(i, victim_index)


func end_step(_match: Match) -> void:
	for index in _immune.keys():
		_immune[index] = maxi(_immune[index] - 1, 0)


# --- Presentation ---------------------------------------------------------------------------

## The ropes, and while charging the frenzy, its meter.
func draw(visuals: FighterVisuals, animation: String, frame: int) -> void:
	if ropes_active():
		_draw_ropes(visuals, animation, frame)
	if fighter.state == Fighter.State.ATTACK and fighter.move == &"neutral_special_charge" \
			and ropes().neutral_special_frenzy:
		_draw_frenzy_charge(visuals)


## Each rope as seen from the side while skipping: from one hand of its pair of arms out through
## its tip and back to the pair's other hand (one smooth curve, bowed back a little the way it came:
## the rope lags behind the spin), outlined; and a faint streak along the tip's path behind it.
func _draw_ropes(visuals: FighterVisuals, animation: String, frame: int) -> void:
	var origin := fighter.global_position
	for i in ropes().count:
		var colors := FighterVisuals.rope_colors_for(fighter.character_id)
		if colors.is_empty():
			colors = PackedColorArray(ROPE_COLORS)
		var color := colors[i % colors.size()]
		if frenzy_frames_left > 0:
			color = color.lightened(0.45)  # Whipping round in a frenzy: lit up.
		elif frenzy_charge(fighter) > 0.0:
			color = color.lightened(0.45 * frenzy_charge(fighter))  # Lighting up while charging.
		var tip := rope_tip(i) - origin
		var streak := PackedVector2Array()
		for k in 7:
			streak.append(rope_tip(i, -ROPE_TRAIL * (1.0 - k / 6.0)) - origin)
		visuals.draw_polyline(streak, Color(color, 0.35), 2.0)
		var ends := rope_hands(fighter.character_id, animation, frame, i)
		var a := Vector2(ends[0].x * fighter.facing, ends[0].y) * fighter.size_scale()
		var b := Vector2(ends[1].x * fighter.facing, ends[1].y) * fighter.size_scale()
		var lag := (rope_tip(i, -ROPE_LAG) - origin - tip) * 0.4
		var rope := PackedVector2Array()
		for k in 21:
			rope.append(rope_loop_point(a, b, tip, lag, PI * k / 20.0))
		visuals.draw_polyline(rope, ROPE_DARK, 3.0)
		visuals.draw_polyline(rope, color, 1.0)


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
		var path := FighterVisuals.SPRITES_DIR + character_id + "/hands.json"
		var parsed: Variant = null
		if FileAccess.file_exists(path):
			parsed = JSON.parse_string(FileAccess.get_file_as_string(path))
		_hands[character_id] = parsed if parsed is Dictionary else {}
	var drawings: Array = _hands[character_id].get(animation, [])
	if frame < drawings.size() and pair < (drawings[frame] as Array).size():
		var hands: Array = drawings[frame][pair]
		return [Vector2(hands[0][0], hands[0][1]), Vector2(hands[1][0], hands[1][1])]
	return [ROPE_HANDS, ROPE_HANDS]


## How far `fighter`'s frenzy is charged (0…1), or 0 when it isn't charging it.
static func frenzy_charge(fighter_: Fighter) -> float:
	var ropes_ := fighter_.ability(RopeAbility) as RopeAbility
	if ropes_ == null or not ropes_.ropes().neutral_special_frenzy \
			or fighter_.state != Fighter.State.ATTACK or fighter_.move != &"neutral_special_charge":
		return 0.0
	return clampf(fighter_.state_frame / float(fighter_.stats.moveset.neutral_special.charge_frames), 0.0, 1.0)


## The frenzy's charge meter: a ring above her head filling clockwise from the top, in her rope
## color; dim until the charge counts (frenzy_min_charge_frames), bright after, flashing white when
## full.
func _draw_frenzy_charge(visuals: FighterVisuals) -> void:
	var charge := frenzy_charge(fighter)
	var colors := FighterVisuals.rope_colors_for(fighter.character_id)
	var color: Color = colors[0] if not colors.is_empty() else ROPE_COLORS[0]
	var counts := fighter.state_frame >= ropes().frenzy_min_charge_frames
	if charge >= 1.0 and (fighter.state_frame / 4) % 2 == 0:
		color = Color.WHITE
	elif counts:
		color = color.lightened(0.5)
	else:
		color = Color(color.darkened(0.2), 0.6)
	var at := FRENZY_METER_AT * fighter.size_scale()
	visuals.draw_arc(at, FRENZY_METER_RADIUS, 0.0, TAU, 24, ROPE_DARK, 3.0)
	if charge > 0.0:
		visuals.draw_arc(at, FRENZY_METER_RADIUS, -PI / 2.0, -PI / 2.0 + TAU * charge, 24, color, 2.0)


## The frenzy meter, along the bottom of her player card.
func make_card_badge(card: PlayerCard) -> Control:
	if not ropes().neutral_special_frenzy:
		return null
	var bar := FrenzyBar.new()
	bar.ability = self
	var colors := FighterVisuals.rope_colors_for(fighter.character_id)
	bar.color = colors[0] if not colors.is_empty() else card.player_color
	bar.position = FRENZY_BAR_AT
	return bar
