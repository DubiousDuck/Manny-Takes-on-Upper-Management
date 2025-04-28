extends Resource

class_name GameState

var position: Dictionary[Unit, Vector2i] = {}
var health: Dictionary[Unit, int] = {}
var cell_effects: Dictionary[Vector2i, String] = {}

func set_state(units: Array[Unit], pos: Array[Vector2i], hp: Array[int]):
	for id in len(units):
		var unit: Unit = units[id]
		position[unit] = pos[id]
		health[unit] = hp[id]
	init_cell_effects()

func init_cell_effects():
	var all_cells := HexNavi.get_all_tiles()
	for cell in all_cells:
		cell_effects[cell] = HexNavi.get_cell_custom_data(cell, "effect")
