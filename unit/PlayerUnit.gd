extends Unit

class_name PlayerUnit

func _ready():
	is_player_controlled = true
	move_range_highlight = Color(0, 0, 1, 0.3)
	#EventBus.emit_signal("occupy_cell", cell, "player")
