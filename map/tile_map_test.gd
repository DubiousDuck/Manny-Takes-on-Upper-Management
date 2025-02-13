extends TileMapLayer

#tile map set up tutorial by https://www.youtube.com/watch?v=1qmXFIJU1QE

const GRID_SIZE = 5
const MAIN_ATLAS_ID = 0
const BLUE_CELL := Vector2i(0, 0)
const WHITE_CELL := Vector2i(2, 0)
const RED_CELL := Vector2i(1, 0)

func _ready():
	EventBus.connect("occupy_cell", _on_occupy_cell)
	EventBus.connect("clear_cells", _on_clear_cells)
	
func set_cell_to_variant(id : int, cell : Vector2i):
	var cell_variant
	match id:
		0: cell_variant = WHITE_CELL
		1: cell_variant = RED_CELL
		2: cell_variant = BLUE_CELL
	set_cell(cell, MAIN_ATLAS_ID, cell_variant)

func _on_occupy_cell(pos : Vector2i, unit_type : String):
	var color_cell : Vector2i
	match unit_type:
		"player":
			color_cell = BLUE_CELL
		"enemy":
			color_cell = RED_CELL
		_:
			color_cell = WHITE_CELL
	set_cell(pos, MAIN_ATLAS_ID, color_cell)

func _on_clear_cells():
	for pos in get_used_cells():
		if HexNavi.get_cell_custom_data(pos, "traversible"):
			set_cell(pos, MAIN_ATLAS_ID, WHITE_CELL)
	
func get_all_tilemap_cells() -> Array[Vector2i]:
	var all_cells: Array[Vector2i] = []
	for cell in get_used_cells():
		all_cells.append(cell)
	return all_cells

#func _input(event):
	#if event is InputEventMouseButton:
		#if event.button_index == MOUSE_BUTTON_LEFT and event.is_pressed():
			#clear_path()
			#var pos_clicked = local_to_map(get_local_mouse_position())
			#show_path(pos_clicked)
			#var cur_cell_atlas_coords = get_cell_atlas_coords(pos_clicked)
			#var cur_cell_alt_id = get_cell_alternative_tile(pos_clicked)
			#var alt_counts = tile_set.get_source(MAIN_ATLAS_ID).get_alternative_tiles_count(cur_cell_atlas_coords)
			#set_cell(pos_clicked, MAIN_ATLAS_ID, cur_cell_atlas_coords, (cur_cell_alt_id+1)%alt_counts)
