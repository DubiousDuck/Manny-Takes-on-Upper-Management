extends Control

class_name CreditsPage

const MAIN_MENU = "res://ui/main_menu/main_menu.tscn"

func _on_button_pressed():
	AudioPreload.play_sfx("menu_click")
	get_tree().change_scene_to_file(MAIN_MENU)
