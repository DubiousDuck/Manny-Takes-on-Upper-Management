extends Resource

class_name GameState

var position: Dictionary[Unit, Vector2i] = {}
var health: Dictionary[Unit, int] = {}
var stat_bonuses: Dictionary[Unit, Array] = {}  # {Unit: Array of BonusStats}
var status_effects: Dictionary[Unit, StatusEffect] = {}
var cell_effects: Dictionary[Vector2i, String] = {}

func set_state(units: Array[Unit], pos: Array[Vector2i], hp: Array[int]):
	for id in len(units):
		var unit: Unit = units[id]
		position[unit] = pos[id]
		health[unit] = hp[id]
		stat_bonuses[unit] = unit.bonus_stat.duplicate(true)
		if unit.active_status_effect:
			status_effects[unit] = unit.active_status_effect.duplicate(true)
	init_cell_effects()

func init_cell_effects():
	var all_cells := HexNavi.get_all_tiles()
	for cell in all_cells:
		cell_effects[cell] = HexNavi.get_cell_custom_data(cell, "effect")
