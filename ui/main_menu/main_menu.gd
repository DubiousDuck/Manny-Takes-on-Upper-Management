class_name MainMenu extends Control

const OVERWORLD1 = "res://overworld/area_1.tscn"

func _ready():
	$AnimationPlayer.play("looping_background")

func _on_start_pressed() -> void:
	AudioPreload.play_sfx("menu_click")
	Global.load_new_save()
	Global.scene_transition(OVERWORLD1)

func _on_load_pressed() -> void:
	AudioPreload.play_sfx("menu_click")
	Global.load_screen()
