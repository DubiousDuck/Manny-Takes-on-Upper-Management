extends Node

signal show_cell_highlights(positions : Array[Vector2i], color : Color, emitter_name : String)
signal remove_cell_highlights(emitter_name : String)
signal remove_all_cell_highlights()

signal occupy_cell(pos : Vector2i, unit_type : String)
