extends Button

@export var index = -99

signal save_pressed(index)

func initialize(data : Dictionary):
	text = data.get("player_name", "No name") + " " + str(data.get("index", 0))

func _on_pressed():
	save_pressed.emit(index)
