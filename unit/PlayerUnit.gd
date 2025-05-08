extends Unit

class_name PlayerUnit

const BUFF_COLOR: Color = Color("#76d7da")
const DEBUFF_COLOR: Color = Color("#3098b3")

func _ready():
	super()
	is_player_controlled = true
	move_range_highlight = CellHighlight.MOVE_RANGE_HIGHLIGHT
	outline_col = Color(0, 0, 1, 1)
	background_icon.sprite_frames = preload("res://unit/unit_ui/ally_aura.tres")
	$Sprite2D/BuffParticles.color = BUFF_COLOR
	$Sprite2D/DebuffParticles.color = DEBUFF_COLOR
