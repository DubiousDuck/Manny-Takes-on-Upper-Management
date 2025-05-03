extends Unit

class_name PlayerUnit

func _ready():
	super()
	is_player_controlled = true
	move_range_highlight = CellHighlight.MOVE_RANGE_HIGHLIGHT
	outline_col = Color(0, 0, 1, 1)
