extends Camera2D

func _ready():
	Global.camera_top = $top_margin.global_position.y
	Global.camera_low = $low_margin.global_position.y

func _process(delta: float) -> void:
	var player = get_parent().get_node("Player")
	#print("offset",offset)
	if not (player == null):
		transform =player.position
		offset = player.position
	#print("offset",offset)
