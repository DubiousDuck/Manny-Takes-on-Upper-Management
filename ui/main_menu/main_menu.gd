class_name MainMenu extends Control

func _ready():
	$AnimationPlayer.play("looping_background")

func _on_start_pressed() -> void:
	Global.scene_transition("res://overworld/area_1.tscn")

func _on_load_pressed() -> void:
	Global.load_screen()
