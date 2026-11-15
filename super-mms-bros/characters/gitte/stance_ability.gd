class_name StanceAbility
extends FighterAbility
## Gitte's stances (docs/specs/characters/gitte.md#gitte--scissors-and-stances): her down special
## switches stance on its frame `startup` (also in the air): + → − → ÷ → × → +, + at every spawn.
## + makes all her hits knock back harder, − tugs opponents toward her with her normals, ÷ makes
## her small and fast, × makes her big with stronger specials.

## In switching order.
enum Stance { PLUS, MINUS, DIVIDE, MULTIPLY }

## Her hands' glow in + and − (docs/specs/characters/gitte.md#weapon-and-own-drawings).
const PLUS_GLOW := Color("#ff4a3d")
const MINUS_GLOW := Color("#4aa8ff")
const GLOW_HALO := 4.0
const GLOW_CORE := 2.0
## The halo's radius swings ±GLOW_PULSE px over GLOW_PULSE_TICKS ticks.
const GLOW_PULSE := 0.5
const GLOW_PULSE_TICKS := 30

## Each character's fists per drawing (hands.json), looked up once.
static var _hands: Dictionary[String, Dictionary] = {}

## Setting it resizes her body.
var stance: Stance = Stance.PLUS:
	set(value):
		stance = value
		if fighter != null:
			fighter.apply_size()


func _numbers() -> StanceData:
	return data as StanceData


func reset() -> void:
	stance = Stance.PLUS


func pick_special(input: FighterInput, choice: StringName) -> StringName:
	if Fighter.special_direction(input) == slot:
		return slot  # Switches stance, also in the air.
	return choice


func move_tick(_input: FighterInput) -> bool:
	if fighter.move != slot:
		return false
	# On its frame `startup` (state_frame counts up at the end of the tick).
	if fighter.state_frame + 1 == (fighter.stats.moveset.get(slot) as MoveData).startup:
		stance = ((stance + 1) % Stance.size()) as Stance
	return true


func size_scale() -> float:
	match stance:
		Stance.DIVIDE:
			return _numbers().small_scale
		Stance.MULTIPLY:
			return _numbers().large_scale
	return 1.0


func speed_scale() -> float:
	return _numbers().small_speed if stance == Stance.DIVIDE else 1.0


## + makes every hit knock back harder; × makes specials hit harder.
func modify_hit(move_data: MoveData, special: bool) -> MoveData:
	var numbers := _numbers()
	if stance == Stance.PLUS:
		var copy := move_data.duplicate() as MoveData
		copy.base_knockback = move_data.base_knockback * numbers.knockback
		copy.knockback_growth = move_data.knockback_growth * numbers.knockback
		return copy
	if stance == Stance.MULTIPLY and special:
		var copy := move_data.duplicate() as MoveData
		copy.damage = move_data.damage * numbers.large_special
		copy.base_knockback = move_data.base_knockback * numbers.large_special
		return copy
	return move_data


## The volley counts as a special.
func modify_projectile(move_data: MoveData) -> MoveData:
	return modify_hit(move_data, true)


## − : on a normal attack's first active frame, opponents in its cone that its hitbox doesn't
## already touch get a 0-damage tug straight at her (a shield gets the block push toward her
## instead). Called before the Match collects hits; take_hit()/block_hit() directly, so it isn't
## a landed hit (no spark, no hit sound).
func resolve_contacts(match: Match) -> void:
	if stance != Stance.MINUS or fighter.state != Fighter.State.ATTACK \
			or not fighter.move in Fighter.NORMALS or not fighter.is_hitbox_active() \
			or fighter.current_move().is_active_frame(fighter.state_frame - 1):
		return
	var numbers := _numbers()
	var hitbox := fighter.get_hitbox_rect()
	var center := fighter.get_center()
	var aim := hitbox.get_center() - center
	for victim in match.get_fighters():
		if victim == fighter or not victim.can_be_hit() \
				or hitbox.intersects(victim.get_hurtbox_rect()) \
				or not in_cone(center, aim, victim.get_center(), numbers.pull_cone_deg, numbers.pull_reach):
			continue
		var tug := tug_data(victim.get_center(), center)
		if victim.state == Fighter.State.SHIELD:
			victim.block_hit(tug[0], tug[1])
		else:
			victim.take_hit(tug[0], tug[1], fighter.global_position.x)


## True when `target` is at most `reach` from `origin` and within `cone_deg` of the direction `aim`.
static func in_cone(origin: Vector2, aim: Vector2, target: Vector2, cone_deg: float,
		reach: float) -> bool:
	var to_target := target - origin
	if to_target.length() > reach or aim == Vector2.ZERO:
		return false
	return absf(rad_to_deg(aim.angle_to(to_target))) <= cone_deg


## The tug from `from` straight toward `to`: [its MoveData (0 damage, pull_speed, no growth), the
## side it launches toward].
func tug_data(from: Vector2, to: Vector2) -> Array:
	var way := to - from
	var data := MoveData.new()
	data.damage = 0.0
	data.base_knockback = _numbers().pull_speed
	data.knockback_growth = 0.0
	data.angle_deg = rad_to_deg(atan2(-way.y, absf(way.x)))
	var side := fighter.facing if way.x == 0.0 else (1 if way.x > 0.0 else -1)
	return [data, side]


## Her hands' glow color: red in +, blue in −, none otherwise.
func glow_color() -> Color:
	match stance:
		Stance.PLUS:
			return PLUS_GLOW
		Stance.MINUS:
			return MINUS_GLOW
	return Color.TRANSPARENT


## The fists [front, back] in a drawing (game px from the feet, facing right, size 1), from the
## character's hands.json (written by the sprite generator); [] when it isn't there.
static func hands(character_id: String, animation: String, frame: int) -> Array[Vector2]:
	if not _hands.has(character_id):
		var path := FighterVisuals.SPRITES_DIR + character_id + "/hands.json"
		var parsed: Variant = null
		if FileAccess.file_exists(path):
			parsed = JSON.parse_string(FileAccess.get_file_as_string(path))
		_hands[character_id] = parsed if parsed is Dictionary else {}
	var drawings: Array = _hands[character_id].get(animation, [])
	var out: Array[Vector2] = []
	if frame < drawings.size():
		for point: Array in drawings[frame]:
			out.append(Vector2(point[0], point[1]))
	return out


## A small pulsing glow on each fist in + and − (only reads).
func draw(visuals: FighterVisuals, animation: String, frame: int) -> void:
	var color := glow_color()
	if color.a == 0.0:
		return
	var s := fighter.size_scale()
	var phase := float(fighter.state_frame % GLOW_PULSE_TICKS) / GLOW_PULSE_TICKS
	var halo := (GLOW_HALO + GLOW_PULSE * sin(phase * TAU)) * s
	for hand in hands(fighter.character_id, animation, frame):
		var at := Vector2(hand.x * fighter.facing, hand.y) * s
		visuals.draw_circle(at, halo, Color(color, 0.35))
		visuals.draw_circle(at, GLOW_CORE * s, Color(color, 0.8))


## The stance sign on the portrait's bottom-right corner.
func make_card_badge(card: PlayerCard) -> Control:
	var badge := StanceBadge.new()
	badge.ability = self
	badge.border = card.player_color
	var portrait := card.portrait_rect()
	badge.position = portrait.end - Vector2(StanceBadge.SIZE, StanceBadge.SIZE) + Vector2(2, 2)
	return badge
