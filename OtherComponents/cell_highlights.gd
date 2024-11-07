extends Node2D

class_name CellHighlight

@onready var highlight_tile = preload("res://OtherComponents/highight_tile.tscn")
var all_current_highlights : Array = []

func _ready():
	EventBus.connect("show_cell_highlights", _on_show_cell_highlights)
	EventBus.connect("remove_all_cell_highlights", _on_remove_all_cell_highlights)

func show_highlight_at(positions : Array[Vector2i], variant : int): #cell positions
	for pos in positions:
		var a = highlight_tile.instantiate()
		a.global_position = Navi.cell_to_global(pos)
		
		match variant:
			0: #red
				a.modulate = Color(1, 0, 0, 0.5)
			1: #yellow
				a.modulate = Color(1, 1, 0, 0.5)
			_:
				a.modulate = Color(1, 1, 1, 0.5)
				
		all_current_highlights.append(a)
		add_child(a)

func remove_all_highlights():
	for highlight in all_current_highlights:
		remove_child(highlight)
	all_current_highlights.clear()

func clear_all_highlights():
	all_current_highlights.clear()

func _on_show_cell_highlights(positions : Array[Vector2i]):
	show_highlight_at(positions, 1)

func _on_remove_all_cell_highlights():
	remove_all_highlights()
