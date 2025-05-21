class_name MainMenu extends Control

func _ready():
	$AnimationPlayer.play("looping_background")

func _on_start_pressed() -> void:
	Global.load_new_save()
	Global.scene_transition(Global.last_overworld_path)

func _on_load_pressed() -> void:
	Global.load_screen()
