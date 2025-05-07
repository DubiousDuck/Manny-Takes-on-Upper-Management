extends Unit

class_name EnemyUnit

func _ready():
	super()
	is_player_controlled = false
	move_range_highlight = CellHighlight.ENEMY_RANGE_HIGHLIGHT
	outline_col = Color(1, 0, 0, 1)
	background_icon.sprite_frames = preload("res://unit/unit_ui/enemy_aura.tres")

## Override of base Unit class; enemies no need to emit action command
func emit_action_command_point(game : String):
	return
