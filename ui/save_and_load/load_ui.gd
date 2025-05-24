extends Control

@onready var save_container : VBoxContainer = $VScrollBar/VBoxContainer

const SAVE_FILE = preload("res://ui/save_and_load/save_file.tscn")
const OVERWORLD1 = "res://overworld/area_1.tscn"

func _ready():
	var loaded_saves = Global.find_all_saves()
	
	for i in loaded_saves.size():
		var a = SAVE_FILE.instantiate()
		a.index = i
		if loaded_saves[i] != null: a.initialize(loaded_saves[i])
		save_container.add_child(a)
		a.connect("save_pressed", loader)

func loader(index : int):
	AudioPreload.play_sfx("menu_click")
	if Global.load_player_data(index):
		var overworld_path: String
		if Global.last_overworld_path == "":
			overworld_path = OVERWORLD1
			push_warning("overworld path is empty; defaulting to Area 1! -- load_ui.gd")
		else: overworld_path = Global.last_overworld_path
		Global.scene_transition(overworld_path)
		queue_free()
	for i in save_container.get_children(): i.queue_free()
	_ready()

func _on_close_pressed():
	AudioPreload.play_sfx("menu_click")
	EventBus.ui_element_ended.emit()
	queue_free()
