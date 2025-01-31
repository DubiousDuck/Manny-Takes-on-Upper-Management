extends Interactable

class_name Door

@export_file("*.tscn") var scene_to_go

func _interact_call_back():
	get_tree().change_scene_to_file(scene_to_go)
