extends Unit

class_name PlayerUnit

const MOVE_RANGE_HIGHLIGHT : Color = Color(1, 1, 0, 0.3)

func _ready():
	is_player_controlled = true
	#EventBus.emit_signal("occupy_cell", cell, "player")
	
func highlight_emit():
	var all_neighbors = Navi.get_all_neighbors_in_range(cell, movement_range)
	var all_neighbors_cell : Array[Vector2i] = []
	for neighbor in all_neighbors:
		all_neighbors_cell.append(Navi.id_to_tile(neighbor))
	EventBus.emit_signal("show_cell_highlights", all_neighbors_cell, MOVE_RANGE_HIGHLIGHT, name)
