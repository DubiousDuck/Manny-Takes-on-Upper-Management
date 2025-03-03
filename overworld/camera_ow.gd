extends Camera2D

func _ready():
	call_deferred("after_ready")

func after_ready() -> void:
	var player = get_parent().get_node("Player")
	if not (player == null):
		offset = player.position
	
func _process(_delta: float) -> void:
	var player = get_parent().get_node("Player")
	#print("offset",offset)
	if not (player == null):
		#transform =player.position
		#offset = player.position
		var t=create_tween()
		t.tween_property(self,"offset", player.position, 1)
	#print("offset",offset)
