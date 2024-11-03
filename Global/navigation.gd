extends Node

class_name Navigation #named Navi

var current_map : TileMapLayer
var astar = AStar2D.new()

func set_current_map(map : TileMapLayer):
	current_map = map
	if current_map != null:
		add_all_point()
	print("there are " + str(astar.get_point_count()) + " points in this map")
	
func add_all_point():
	var all_used_cells = current_map.get_used_cells()
	for cell in all_used_cells:
		astar.add_point(astar.get_available_point_id(), cell)
	for point_id in astar.get_point_ids():
		var pos = astar.get_point_position(point_id)
		var all_possible_neighbors = current_map.get_surrounding_cells(pos)
		var valid_neighbor = []
		for neighbor in all_possible_neighbors:
			if current_map.get_cell_source_id(neighbor) != -1: #if the cell is not empty
				valid_neighbor.append(neighbor)
		for neighbor in valid_neighbor:
			var neighbor_id = astar.get_closest_point(neighbor)
			astar.connect_points(point_id, neighbor_id)

#general process of converting global position to a cell position
	#1. convert global position to map node's local
	#2. convert map node's local to map coordinates
	#3. use the map coordinate to locate the closest cell in astar
	#do the other way around to convert cell position to global position
	
func cell_to_global(cell_pos : Vector2): #returns another global position
	return current_map.map_to_local(current_map.to_global(cell_pos))

func global_to_cell(global_pos : Vector2): #returns local cell position
	var closest_point_id = astar.get_closest_point(current_map.local_to_map(current_map.to_local(global_pos)))
	return astar.get_point_position(closest_point_id)

func get_navi_path(start_pos : Vector2i, end_pos : Vector2i):
	var start_id = tile_to_id(start_pos)
	var goal_id = tile_to_id(end_pos)
	var path_taken = astar.get_point_path(start_id, goal_id)
	return path_taken
	
func show_path(cell_pos : Vector2i):
	var goal_id = tile_to_id(cell_pos)
	var start_id = 0
	var path_taken = astar.get_id_path(start_id, goal_id)
	for cell_id in path_taken:
		var cell = astar.get_point_position(cell_id)
		if cell_id == start_id or cell_id == goal_id:
			current_map.set_cell_to_variant(1, cell) #variant depends on each map layer
		else:
			current_map.set_cell_to_variant(2, cell)

func clear_path(): #clear all markings on the map
	var all_cells = current_map.get_used_cells()
	for cell in all_cells:
		current_map.set_cell_to_variant(0, cell)

func tile_to_id(pos : Vector2i) -> int: #assume that all available tiles are already mapped in astar
	if current_map.get_cell_source_id(pos) != -1:
		return astar.get_closest_point(pos)
	else: return -1

#func _unhandled_input(event):
	#if event is InputEventMouseButton:
		#if event.button_index == MOUSE_BUTTON_LEFT and event.is_pressed():
			#clear_path()
			#var pos_clicked = current_map.local_to_map(current_map.get_local_mouse_position())
			#print(pos_clicked)
			#show_path(pos_clicked)
