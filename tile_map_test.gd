extends TileMapLayer

const MAIN_ATLAS_ID = 0

func _input(event):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.is_pressed():
			var clicked_global = event.global_position
			var pos_clicked = local_to_map(to_local(clicked_global))
			#print(pos_clicked)
			var cur_cell_atlas_coords = get_cell_atlas_coords(pos_clicked)
			var cur_cell_alt_id = get_cell_alternative_tile(pos_clicked)
			var alt_counts = tile_set.get_source(MAIN_ATLAS_ID).get_alternative_tiles_count(cur_cell_atlas_coords)
			set_cell(pos_clicked, MAIN_ATLAS_ID, cur_cell_atlas_coords, (cur_cell_alt_id+1)%alt_counts)
