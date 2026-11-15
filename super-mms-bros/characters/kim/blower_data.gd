class_name BlowerData
extends AbilityData
## Kim's leaf blower (docs/specs/characters/kim.md#kim--handyman), on his down special. Its
## frames and push are the move's own (damage 0, growth 0); this is only how the gust is drawn.

## Wind lines streaming out of the nozzle while the gust is out.
@export var wind_lines: int = 5


func create_ability() -> FighterAbility:
	return BlowerAbility.new()
