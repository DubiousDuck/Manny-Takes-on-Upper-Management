extends Node2D

class_name CellHighlight

## Color constants
const ATTACK_HIGHLIGHT: Color = Color(0.996, 0.663, 0.0, 0.8)
const ATTACK_PREVIEW_HIGHLIGHT: Color = Color(0.35, 0.35, 0, 0.5)
const MOVE_RANGE_HIGHLIGHT : Color = Color(0, 0, 1, 0.3)
const ENEMY_RANGE_HIGHLIGHT: Color = Color(1, 0, 0, 0.3)
const VALID_TARGET_HIGHLIGHT: Color = Color(1, 0.2, 0, 0.6)
const VALID_ALLY_HIGHLIGHT: Color = Color(0, 0.2, 1, 0.6)

@onready var highlight_tile = preload("res://other_map_components/highlight_tile.tscn")
var all_current_highlights : Dictionary = {}

func _ready():
	EventBus.connect("show_cell_highlights", _on_show_cell_highlights)
	EventBus.connect("remove_cell_highlights", _on_remove_cell_highlights)
	EventBus.connect("remove_all_cell_highlights", _on_remove_all_cell_highlights)

func show_highlight_at(positions : Array[Vector2i], color : Color, emitter_name : String): #cell positions
	var highlight_group : Array = []
	for pos in positions:
		var a = highlight_tile.instantiate()
		a.global_position = HexNavi.cell_to_global(pos)
		a.modulate = color
		highlight_group.append(a)
		add_child(a)
	all_current_highlights[emitter_name] = highlight_group

func ids_to_tile_pos(ids: Array) -> Array[Vector2i]: #function with no use now but kept just in case
	var positions: Array[Vector2i] = []
	for id in ids:
		if id is int:
			positions.append(HexNavi.id_to_tile(id))
		elif id is Vector2i:
			positions.append(id)
		else: push_warning("id is not an int nor Vector2i!")
	return positions

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
