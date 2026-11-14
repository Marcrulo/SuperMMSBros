class_name FighterAbility
extends RefCounted
## One character mechanic (a vine, jump ropes, a stance switch…), plugged into the Fighter, the
## Match and the visuals through the hooks below (docs/specs/architecture.md#abilities). Shared code
## calls the hooks and never names a mechanic, so a character's mechanics live in its own folder.
## Every hook does nothing by default; an ability overrides the ones it needs.
##
## Abilities are made by the fighter from its move set's AbilityData, in move set order (its moves
## top to bottom, then the move set's own), and every hook is called in that order. Gameplay hooks
## run inside the Match's tick (rules 1, 2 and 6 of the architecture spec apply); presentation
## hooks only read.

var fighter: Fighter
## The move set property its data is on (&"up_special", …), or &"" for the move set's own.
var slot: StringName
var data: AbilityData


## The phases (values of Fighter.move) this ability adds; while one is in progress, the fighter
## asks this ability about it (phase_* hooks).
func phases() -> Array[StringName]:
	return []


# --- The fighter's tick -----------------------------------------------------------------------

## At every spawn: back to the starting state.
func reset() -> void:
	pass


## At the start of every tick the fighter acts (not while KO'd or held).
func before_tick(_input: FighterInput) -> void:
	pass


## At the end of every tick the fighter acts.
func after_tick(_input: FighterInput) -> void:
	pass


## False when the fighter has no normal attacks.
func allows_normals() -> bool:
	return true


## The special to start for this input: `choice` (what the default rules, and the abilities
## before this one, picked; Fighter.NO_MOVE = none), or another.
func pick_special(_input: FighterInput, choice: StringName) -> StringName:
	return choice


## A move or phase has just started (state ATTACK, frame 0).
func on_move_started(_move: StringName) -> void:
	pass


## The neutral special's charge was let go, `charge` 0…1.
func on_charge_released(_charge: float) -> void:
	pass


## True when this ability takes over the default behaviour of move set property `move`: the up
## special's jump boost (&"up_special"), the side special's projectile (&"side_special"), the
## neutral special's charge glow (&"neutral_special_charge").
func replaces(_move: StringName) -> bool:
	return false


## Every tick in ATTACK, for whatever move is in progress (the default moves too). Returns true if
## it handled this tick (no later ability is asked).
func move_tick(_input: FighterInput) -> bool:
	return false


## Ends the phase `move` now? (Checked first thing every tick.)
func phase_finished(_move: StringName) -> bool:
	return false


## The data of phase `move` (its hitbox and hit), or null for none.
func phase_data(_move: StringName) -> MoveData:
	return null


## The hitbox of phase `move` in world coordinates.
func phase_hitbox(_move: StringName, move_data: MoveData) -> Rect2:
	return fighter.hitbox_rect_of(move_data)


## Sets the velocity for phase `move` this tick; false = the default air or ground movement.
func phase_movement(_move: StringName, _input: FighterInput) -> bool:
	return false


## During a move, after moving, when the fighter is in the air. True = handled (ends the check).
func left_floor_in_move() -> bool:
	return false


## During a move, after moving, when the fighter is on the floor. True = handled.
func on_floor_in_move(_input: FighterInput) -> bool:
	return false


## True when this ability places the fighter itself this tick (no physics): then place() runs.
func places_fighter() -> bool:
	return false


func place() -> void:
	pass


## False while this ability makes the fighter unhittable.
func can_be_hit() -> bool:
	return true


## Body size factor (body, hurtbox, hitboxes and sprite scale from the feet).
func size_scale() -> float:
	return 1.0


## Run and air speed factor.
func speed_scale() -> float:
	return 1.0


## A move's hit values as this fighter deals them (`special`: a special move, not a normal).
func modify_hit(move_data: MoveData, _special: bool) -> MoveData:
	return move_data


## A projectile's hit values when thrown now.
func modify_projectile(move_data: MoveData) -> MoveData:
	return move_data


## The share of a landed normal attack's damage that heals the fighter.
func lifesteal() -> float:
	return 0.0


## This fighter's own hit landed on `victim` (not blocked).
func on_hit_dealt(_victim: Fighter) -> void:
	pass


## True while the fighter's hitbox is a grab box (it catches; it never hits).
func is_grab_box() -> bool:
	return false


# --- The Match's step (docs/specs/architecture.md#tick-order) ---------------------------------

## After every fighter ticked, before ledge grabs. Returns true if it moved the fighter this one
## holds (Fighter.throwing); a fighter that holds someone nobody moves lets go.
func advance_held(_match: Match) -> bool:
	return false


## After ledge grabs.
func after_ledges(_match: Match) -> void:
	pass


## After the projectiles and entities moved: add new entities (Match.add_entity()).
func spawn_entities(_match: Match) -> void:
	pass


## Before hits are collected (command grabs).
func resolve_contacts(_match: Match) -> void:
	pass


## Adds this ability's hits for this tick to `hits` (see Match._resolve_hits()).
func collect_hits(_match: Match, _hits: Array[Dictionary]) -> void:
	pass


## At the end of the step, with the other timers.
func end_step(_match: Match) -> void:
	pass


# --- Presentation (only reads) ----------------------------------------------------------------

## The animation for phase `move` (an ANIMATIONS name of FighterVisuals).
func phase_animation(_move: StringName) -> String:
	return "jab"


## The drawing to show of `animation` while in ATTACK (`frame` = the shared timing's).
func drawing(_animation: String, frame: int) -> int:
	return frame


## A different strip to draw with now: [texture, x scale, drawings, frame], or [] for none.
func strip(_textures: Dictionary) -> Array:
	return []


## How the fighter this one holds is drawn: [turn (radians), offset], or [] for upright.
func held_pose(_victim: Fighter) -> Array:
	return []


## Draws this ability's extras over the fighter (its canvas is `visuals`, origin at the feet).
func draw(_visuals: FighterVisuals, _animation: String, _frame: int) -> void:
	pass


## Sounds (docs/specs/sound.md): {"start": {phase: sound}, "hit": [phases that make the burst
## sound when their hitbox comes out], "pop": [phases an up special pops out of]}.
func sounds() -> Dictionary:
	return {}


## Something to show on the fighter's HUD card (a Control the card positions and adds), or null.
func make_card_badge(_card: PlayerCard) -> Control:
	return null
