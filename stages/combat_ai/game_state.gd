extends Resource

class_name GameState

enum POF_STATE {NONE, READY, TRIGGERED}

var position: Dictionary[Unit, Vector2i] = {}
var health: Dictionary[Unit, int] = {}
var stat_bonuses: Dictionary[Unit, Array] = {}  # {Unit: Array of BonusStats}
var status_effects: Dictionary[Unit, StatusEffect] = {}
var action_tokens: Dictionary[Unit, Array] = {} # {Unit: Array of Unit.Action}
var pof_states: Dictionary[Unit, Unit.POF_RECEIVE_STATE] = {}
var cell_effects: Dictionary[Vector2i, String] = {}

func set_state(units: Array[Unit], pos: Array[Vector2i], hp: Array[int]):
	for id in len(units):
		var unit: Unit = units[id]
		position[unit] = pos[id]
		health[unit] = hp[id]
		stat_bonuses[unit] = unit.bonus_stat.duplicate(true)
		if unit.active_status_effect:
			status_effects[unit] = unit.active_status_effect.duplicate(true)
		action_tokens[unit] = unit.actions_avail.duplicate()
		pof_states[unit] = unit.pof_receive_state
	init_cell_effects()

func init_cell_effects():
	var all_cells := HexNavi.get_all_tiles()
	for cell in all_cells:
		var cell_effect = HexNavi.get_cell_custom_data(cell, "effect")
		cell_effects[cell] = cell_effect if cell_effect is String else ""
		
func find_another_cell_of_effect(cell: Vector2i, effect: String):
	for tile in cell_effects.keys():
		if cell_effects.get(tile, "") == effect and tile != cell:
			return tile
	# if no cell with the effect found, return original cell
	return cell
