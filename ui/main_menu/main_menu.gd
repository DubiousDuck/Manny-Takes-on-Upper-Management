extends CanvasLayer


func _ready():
	pass
func _on_start_pressed() -> void:
	get_tree().change_scene_to_file("res://overworld/area_1.tscn")

func _on_load_pressed() -> void:
	get_tree().change_scene_to_file("res://ui/save_and_load/load_ui.tscn")
