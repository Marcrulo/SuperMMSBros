class_name Burn
extends MatchEntity
## A fighter set on fire by Kim's torch (docs/specs/characters/kim.md#kim--handyman): it takes
## `burn_damage` every `burn_interval` ticks for `burn_ticks` ticks, with no knockback. One burn
## per fighter: lighting it again restarts it (Burn.ignite()). A KO puts it out. Advanced by the
## Match one tick at a time; drawing only reads.

const FLAME := TorchAbility.FLAME
const FLAME_CORE := TorchAbility.FLAME_CORE
const SPARK := Color(1.0, 0.8, 0.3)
## Where the flames sit on the body: x as a share of the hurtbox width from its center, y as a
## share of its height from the feet; and how tall each one is.
const SPOTS: Array[Vector3] = [Vector3(-0.3, 0.25, 6), Vector3(0.25, 0.45, 7),
		Vector3(-0.1, 0.7, 5), Vector3(0.35, 0.05, 5)]

## Player index of the burning fighter.
var victim_index: int
var data: TorchData
## Ticks it has burned (since it was lit, or last lit again).
var age: int = 0
## The burning fighter, for its look.
var _victim: Fighter


## Sets `victim` burning for player `owner` (a burn already on it starts over instead).
static func ignite(match_: Match, owner: int, victim: Fighter, torch_data: TorchData) -> void:
	if victim.state == Fighter.State.KO:
		return
	for entity in match_.get_entities(Burn):
		var burn := entity as Burn
		if burn.victim_index == victim.player_index:
			burn.owner_index = owner
			burn.data = torch_data
			burn.age = 0
			return
	var burn := Burn.new()
	burn.owner_index = owner
	burn.victim_index = victim.player_index
	burn.data = torch_data
	burn._victim = victim
	burn.global_position = victim.global_position
	match_.add_entity(burn)


func advance(match_: Match) -> void:
	age += 1
	_victim = match_.get_fighter(victim_index)
	global_position = _victim.global_position
	if age % data.burn_interval == 0 and _victim.can_be_hit():
		_victim.percent = minf(_victim.percent + data.burn_damage, Fighter.MAX_PERCENT)
	queue_redraw()


func is_finished(match_: Match) -> bool:
	return age >= data.burn_ticks or match_.get_fighter(victim_index).state == Fighter.State.KO


## Small flickering flames over the fighter's body, sparks rising off them; they shrink in the
## last half second.
func _draw() -> void:
	if _victim == null:
		return
	var body := _victim.get_hurtbox_rect()
	body.position -= global_position
	var left := data.burn_ticks - age
	var fade := clampf(left / 30.0, 0.3, 1.0)
	for i in SPOTS.size():
		var spot := SPOTS[i]
		var base := Vector2(body.get_center().x + spot.x * body.size.x, body.end.y - spot.y * body.size.y)
		var flicker := 0.75 + 0.25 * sin(age * 0.8 + i * 2.1)
		var height := roundf(spot.z * flicker * fade)
		# A flame of pixel rows, widest at the bottom; the core inside the lower half.
		for row in int(height):
			var t := float(row) / maxf(height, 1.0)
			var half := roundf(2.0 * (1.0 - t) + 0.4)
			var sway := roundf(sin(age * 0.5 + i + t * 3.0) * t)
			draw_rect(Rect2(base.x - half + sway, base.y - row - 1, half * 2.0, 1), FLAME)
			if t < 0.5 and half > 1.0:
				draw_rect(Rect2(base.x - half + 1.0 + sway, base.y - row - 1, half * 2.0 - 2.0, 1),
						FLAME_CORE)
		# A spark that rises off it and goes out.
		var rise := (age * 2 + i * 7) % 12
		draw_rect(Rect2(base.x + (i % 2) * 2 - 1, base.y - height - rise, 1, 1),
				Color(SPARK, 1.0 - rise / 12.0))
