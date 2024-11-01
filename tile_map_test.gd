extends TileMapLayer

#tile map set up tutorial by https://www.youtube.com/watch?v=1qmXFIJU1QE

const GRID_SIZE = 5
const MAIN_ATLAS_ID = 0
const BLUE_CELL := Vector2i(0, 0)
const WHITE_CELL := Vector2i(2, 0)
const RED_CELL := Vector2i(1, 0)

var astar = AStar2D.new()

func _ready():
	add_all_points()
	print(astar.get_point_count())

func add_all_points():
	var all_used_cells = get_used_cells()
	for cell in all_used_cells:
		astar.add_point(astar.get_available_point_id(), cell)
	for point_id in astar.get_point_ids():
		var pos = astar.get_point_position(point_id)
		var all_possible_neighbors = get_surrounding_cells(pos)
		var valid_neighbor = []
		for neighbor in all_possible_neighbors:
			if get_cell_source_id(neighbor) != -1: #if the cell is not empty
				valid_neighbor.append(neighbor)
		for neighbor in valid_neighbor:
			var neighbor_id = astar.get_closest_point(neighbor)
			astar.connect_points(point_id, neighbor_id)

func show_path(cell_pos : Vector2i):
	var goal_id = tile_to_id(cell_pos)
	var start_id = 0
	var path_taken = astar.get_id_path(start_id, goal_id)
	for cell_id in path_taken:
		var cell = astar.get_point_position(cell_id)
		if cell_id == start_id or cell_id == goal_id:
			set_cell(cell, MAIN_ATLAS_ID, RED_CELL)
		else:
			set_cell(cell, MAIN_ATLAS_ID, BLUE_CELL)

func clear_path():
	var all_cells = get_used_cells()
	for cell in all_cells:
		set_cell(cell, MAIN_ATLAS_ID, WHITE_CELL)
		
func tile_to_id(pos : Vector2i) -> int: #assume that all available tiles are already mapped in astar
	if get_cell_source_id(pos) != -1:
		return astar.get_closest_point(pos)
	else: return -1
	
func _input(event):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.is_pressed():
			clear_path()
			var clicked_global = event.global_position
			var pos_clicked = local_to_map(to_local(clicked_global))
			show_path(pos_clicked)
			#var cur_cell_atlas_coords = get_cell_atlas_coords(pos_clicked)
			#var cur_cell_alt_id = get_cell_alternative_tile(pos_clicked)
			#var alt_counts = tile_set.get_source(MAIN_ATLAS_ID).get_alternative_tiles_count(cur_cell_atlas_coords)
			#set_cell(pos_clicked, MAIN_ATLAS_ID, cur_cell_atlas_coords, (cur_cell_alt_id+1)%alt_counts)
