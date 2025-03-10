extends Unit

class_name EnemyUnit

func _custom_ready():
	is_player_controlled = false
	move_range_highlight = CellHighlight.ENEMY_RANGE_HIGHLIGHT

## Override of base Unit class; enemies no need to emit action command
func emit_action_command_point(game : String):
	return
