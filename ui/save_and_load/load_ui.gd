extends Control

@onready var save_container : VBoxContainer = $VScrollBar/VBoxContainer

const SAVE_FILE = preload("res://ui/save_and_load/save_file.tscn")

func _ready():
	var loaded_saves = Global.find_all_saves()
	
	for i in loaded_saves.size():
		var a = SAVE_FILE.instantiate()
		a.index = i
		if loaded_saves[i] != null: a.initialize(loaded_saves[i])
		save_container.add_child(a)
		a.connect("save_pressed", loader)

func loader(index : int):
	Global.load_player_data(index)
	for i in save_container.get_children(): i.queue_free()
	_ready()

func _on_close_pressed():
	EventBus.ui_element_ended.emit()
	queue_free()
