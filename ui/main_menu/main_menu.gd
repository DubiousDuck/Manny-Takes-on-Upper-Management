class_name MainMenu extends Control

const OVERWORLD1 = "res://overworld/area_1.tscn"

func _ready():
	$AnimationPlayer.play("looping_background")

func _on_start_pressed() -> void:
	Global.load_new_save()
	Global.scene_transition(OVERWORLD1)

func _on_load_pressed() -> void:
	Global.load_screen()
