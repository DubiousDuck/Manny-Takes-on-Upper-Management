extends Resource

class_name GameState

var position: Dictionary[Unit, Vector2i] = {}
var health: Dictionary[Unit, int] = {}

func set_state(units: Array[Unit], pos: Array[Vector2i], hp: Array[int]):
	for id in len(units):
		var unit: Unit = units[id]
		position[unit] = pos[id]
		health[unit] = hp[id]
