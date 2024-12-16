extends Unit

class_name EnemyUnit

func _ready():
	is_player_controlled = false
	move_range_highlight = Color(1, 0, 0, 0.3)
	#EventBus.emit_signal("occupy_cell", cell, "enemy")
