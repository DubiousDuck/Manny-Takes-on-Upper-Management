extends Unit

class_name EnemyUnit

const BUFF_COLOR := Color("#dba8ab")
const DEBUFF_COLOR := Color("#b66a70")

func _ready():
	super()
	is_player_controlled = false
	move_range_highlight = CellHighlight.ENEMY_RANGE_HIGHLIGHT
	outline_col = Color(1, 0, 0, 1)
	background_icon.sprite_frames = preload("res://unit/unit_ui/enemy_aura.tres")
	$Sprite2D/BuffParticles.color = BUFF_COLOR
	$Sprite2D/DebuffParticles.color = DEBUFF_COLOR

## Override of base Unit class; enemies no need to emit action command
func emit_action_command_point(game : String):
	return
