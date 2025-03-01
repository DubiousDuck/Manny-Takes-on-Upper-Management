extends Button

@export var index = -99

signal save_pressed(index)

func initialize(data : Resource):
	text = data.player_name + " " + str(data.index)

func _on_pressed():
	save_pressed.emit(index)
