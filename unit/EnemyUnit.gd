extends Unit

class_name EnemyUnit

const MOVE_RANGE_HIGHLIGHT : Color = Color(1, 0, 0, 0.3)

func _ready():
	is_player_controlled = false
	#EventBus.emit_signal("occupy_cell", cell, "enemy")
	
func highlight_emit():
	var all_neighbors = HexNavi.get_all_neighbors_in_range(cell, movement_range)
	var all_neighbors_cell : Array[Vector2i] = []
	for neighbor in all_neighbors:
		all_neighbors_cell.append(HexNavi.id_to_tile(neighbor))
	EventBus.emit_signal("show_cell_highlights", all_neighbors_cell, MOVE_RANGE_HIGHLIGHT, name)
