extends Resource

class_name GameState

@export var units: Array[UnitData] = []
@export var tiles: Array[Vector2i] = []
var turn_owner: String = "" # "AI" or "player"

func clone():
	pass
	
func get_unit_by_id(id: int) -> UnitData:
	for unit in units:
		if unit.id == id:
			return unit
	push_warning("No unit of id " + str(id) + " is found. -- GameState.gd")
	return null

func get_units_by_ids(ids: Array[int]) -> Array[UnitData]:
	var output: Array[UnitData] = []
	for id in ids:
		output.append(get_unit_by_id(id))
	return output

func remove_unit(id: int):
	var new_units: Array[UnitData] = []
	for unit in units:
		if unit.id != id:
			new_units.append(unit)
	units = new_units
