class_name MainMenu extends Control

const OVERWORLD1 = "res://overworld/area_1.tscn"
const PAUSE_LAYER = preload("res://ui/pause_menu/pause_canvas_layer.tscn")

func _ready():
	$AnimationPlayer.play("looping_background")

func _on_start_pressed() -> void:
	AudioPreload.play_sfx("menu_click")
	Global.load_new_save()
	Global.scene_transition(OVERWORLD1)

func _on_load_pressed() -> void:
	AudioPreload.play_sfx("menu_click")
	Global.load_screen()

func _on_options_pressed():
	AudioPreload.play_sfx("menu_click")
	var a = PAUSE_LAYER.instantiate()
	GlobalUI.add_child(a)
	a.flipMenuDisplay()
