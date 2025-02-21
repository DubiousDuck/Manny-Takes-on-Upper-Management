extends Camera2D

func _ready():
	Global.camera_top = $top_margin.global_position.y
	Global.camera_low = $low_margin.global_position.y
