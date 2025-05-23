extends Button

@export var index = -99

signal save_pressed(index)

func initialize(data : Dictionary):
	var finished_level_count = data.get("finished_levels", {}).keys().size()
	text = data.get("player_name", "No name") + " " + str(int(data.get("index", 0))) + " Levels Done: " + str(finished_level_count)

func _on_pressed():
	save_pressed.emit(index)
