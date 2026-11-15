class_name Puddle
extends MatchEntity
## A puddle of Mette's potion on the floor (docs/specs/characters/mette.md#mette--potions): red
## acid burns, blue ice is slippery, green glue is sticky, for everyone standing in it (her too).
## Made by Puddle.splash(); advanced by the Match one tick at a time; drawing only reads.

## States in which a fighter on the floor doesn't count as standing in a puddle.
const NOT_STANDING: Array[Fighter.State] = [Fighter.State.LEDGE, Fighter.State.LEDGE_CLIMB,
		Fighter.State.KO, Fighter.State.HELD]

var potion: PotionAbility.Potion
var data: PotionData
## Ticks since it was made (or last refilled).
var age: int = 0
## Ticks since the match started, for its look (bubbles, glint).
var shown_ticks: int = 0
## Per player index: ticks it has stood in this puddle without a break (for the acid).
var _standing: Dictionary = {}


## A splash of `potion` on the floor at `at` (on that floor's top), thrown by player `owner`: onto
## a puddle (its point within the puddle's width, on the same floor) of the same colour it refills
## it, of another it sets off a reaction there (the puddle is gone); otherwise a new puddle, and
## past `max_puddles` of the owner's, the oldest goes.
static func splash(match_: Match, owner: int, at: Vector2, potion: PotionAbility.Potion,
		potion_data: PotionData) -> void:
	for entity in match_.get_entities(Puddle):
		var puddle := entity as Puddle
		if absf(puddle.global_position.y - at.y) > 0.5 \
				or absf(puddle.global_position.x - at.x) > puddle.data.puddle_width / 2.0:
			continue
		if puddle.potion == potion:
			puddle.age = 0
		else:
			var reaction := Reaction.new()
			match_.add_entity(reaction)
			reaction.setup(owner, puddle.global_position,
					Reaction.kind_for(puddle.potion, potion), potion_data)
			match_.remove_entity(puddle)
		return
	var puddle := Puddle.new()
	match_.add_entity(puddle)
	puddle.setup(owner, at, potion, potion_data)
	var own := match_.get_entities(Puddle, owner)
	if own.size() > potion_data.max_puddles:
		match_.remove_entity(own[0])


func setup(owner: int, at: Vector2, contents: PotionAbility.Potion, potion_data: PotionData) -> void:
	owner_index = owner
	global_position = at
	potion = contents
	data = potion_data


func behind_fighters() -> bool:
	return true


func advance(_match: Match) -> void:
	age += 1
	shown_ticks += 1
	queue_redraw()


func is_finished(_match: Match) -> bool:
	return age >= data.puddle_lifetime


## Its area: puddle_width × puddle_height, bottom center at its position.
func get_area_rect() -> Rect2:
	return Rect2(global_position - Vector2(data.puddle_width / 2.0, data.puddle_height),
			Vector2(data.puddle_width, data.puddle_height))


## True if `fighter` stands in it: on the floor (not hanging, climbing, KO'd or held), its hurtbox
## touching the area.
func is_standing_in(fighter: Fighter) -> bool:
	return fighter.is_on_floor() and fighter.state not in NOT_STANDING \
			and get_area_rect().intersects(fighter.get_hurtbox_rect())


## Everyone standing in it feels it this tick (the ground modifiers apply on their next tick).
func interact(match_: Match) -> void:
	for fighter in match_.get_fighters():
		if not is_standing_in(fighter):
			_standing.erase(fighter.player_index)
			continue
		match potion:
			PotionAbility.Potion.RED:
				var ticks: int = _standing.get(fighter.player_index, 0) + 1
				_standing[fighter.player_index] = ticks
				if ticks % data.acid_interval == 0 and fighter.can_be_hit():
					fighter.percent = minf(fighter.percent + data.acid_damage, Fighter.MAX_PERCENT)
			PotionAbility.Potion.BLUE:
				fighter.ground_grip = minf(fighter.ground_grip, data.ice_grip)
			PotionAbility.Potion.GREEN:
				fighter.ground_speed = minf(fighter.ground_speed, data.glue_speed)
				fighter.ground_jump = minf(fighter.ground_jump, data.glue_jump)


func _draw() -> void:
	PotionLook.draw_puddle(self, potion, data.puddle_width, shown_ticks,
			float(data.puddle_lifetime - age) / data.puddle_lifetime)
	if FighterVisuals.show_boxes:
		var box := get_area_rect()
		box.position -= global_position
		draw_rect(box, FighterVisuals.HITBOX_IDLE_COLOR)
