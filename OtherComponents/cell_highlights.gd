extends Node2D

class_name CellHighlight

@onready var highlight_tile = preload("res://OtherComponents/highight_tile.tscn")
var all_current_highlights : Dictionary = {}

func _ready():
	EventBus.connect("show_cell_highlights", _on_show_cell_highlights)
	EventBus.connect("remove_cell_highlights", _on_remove_cell_highlights)
	EventBus.connect("remove_all_cell_highlights", _on_remove_all_cell_highlights)

func show_highlight_at(positions : Array[Vector2i], color : Color, emitter_name : String): #cell positions
	var highlight_group : Array = []
	for pos in positions:
		var a = highlight_tile.instantiate()
		a.global_position = Navi.cell_to_global(pos)
		a.modulate = color
		highlight_group.append(a)
		add_child(a)
	all_current_highlights[emitter_name] = highlight_group

func remove_cell_highlights(emitter_name : String):
	var children = all_current_highlights.get(emitter_name)
	if children != null:
		for child in children:
			child.queue_free()
	all_current_highlights.erase(emitter_name)

func remove_all_highlights():
	for child in get_children():
		child.queue_free()
	all_current_highlights.clear()

func clear_all_highlights():
	all_current_highlights.clear()

func _on_show_cell_highlights(positions : Array[Vector2i], color : Color, emitter_name : String):
	show_highlight_at(positions, color, emitter_name)

func _on_remove_cell_highlights(emitter_name : String):
	remove_cell_highlights(emitter_name)
	
func _on_remove_all_cell_highlights():
	remove_all_highlights()
