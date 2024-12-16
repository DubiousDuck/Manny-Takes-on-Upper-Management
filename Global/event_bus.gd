extends Node

#Cell Highlights
signal show_cell_highlights(positions : Array, color : Color, emitter_name : String)
signal remove_cell_highlights(emitter_name : String)
signal remove_all_cell_highlights()

#Cell Information
signal occupy_cell(pos : Vector2i, unit_type : String)
signal clear_cells()
signal update_cell_status()

#Unit Actions
signal add_action(action_name: String, action_strength: int, target_tile: Vector2i)
signal execute_actions()
