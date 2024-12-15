extends Node2D

class_name UnitContainer

signal all_units_moved

const MOVE_RANGE_HIGHLIGHT : Color = Color(0, 0, 1, 0.5)

@export var is_player_controlled : bool
var units : Array[Unit] = []
var current_unit : Unit
var is_waiting_unit_selection : bool = true
var in_progress : bool = false

func init():
	for unit in get_children():
		units.append(unit)
		if unit is Unit:
			unit.init()
	print(name + " has " + str(units.size()) + " units")
	
func round_start():
	for unit in units:
		unit.moved = false
	if !is_player_controlled:
		_step_enemy()
	
func get_unmoved_unit_count():
	var count = 0
	for unit in units:
		if unit.moved == false:
			count += 1
	return count
	
func deselect_current_unit():
	current_unit = null
	is_waiting_unit_selection = true
	disconnect_current_unit_signals()

func connect_current_unit_signals():
	pass

func disconnect_current_unit_signals():
	pass

func move_unit():
	#handle npc movement and attack logic here
	#TODO: placeholder movement
	var all_possible_cell_ids = HexNavi.get_all_neighbors_in_range(current_unit.cell, current_unit.movement_range)
	var all_available_cells = [] 
	for id in all_possible_cell_ids:
		var tile = HexNavi.id_to_tile(id)
		if !HexNavi.get_cell_custom_data(tile, "occupied"):
			all_available_cells.append(tile)
	var goal_cell = all_available_cells.pick_random() #TODO: Fix potential bug when the unit has no where to go
	current_unit.move_along_path(HexNavi.get_navi_path(current_unit.cell, goal_cell))
	return
	
func _step_enemy():
	if get_unmoved_unit_count() <= 0:
		all_units_moved.emit()
		return
	for unit in units:
		if unit.moved == false:
			current_unit = unit
			break
	if current_unit != null:
		move_unit()
		await current_unit.movement_complete
		current_unit.moved = true
		_step_enemy()
		return

func _unhandled_input(event):
	if !is_player_controlled:
		return
		
	if event is InputEventMouseButton and event.is_pressed():
		EventBus.emit_signal("remove_all_cell_highlights")
		if event.button_index == MOUSE_BUTTON_LEFT and is_waiting_unit_selection:
			# if no units have been selected
			var clicked_cell = HexNavi.global_to_cell(get_global_mouse_position())
			for unit in units:
				if unit.cell == clicked_cell and !unit.moved:
					get_viewport().set_input_as_handled()
					deselect_current_unit()
					current_unit = unit
					connect_current_unit_signals()
					print(current_unit)
					is_waiting_unit_selection = false
					
					#would love to use map() but return type doesn't match
					var all_neighbors = HexNavi.get_all_neighbors_in_range(unit.cell, unit.movement_range)
					var all_neighbors_cell : Array[Vector2i] = []
					for neighbor in all_neighbors:
						all_neighbors_cell.append(HexNavi.id_to_tile(neighbor))
					EventBus.emit_signal("show_cell_highlights", all_neighbors_cell, MOVE_RANGE_HIGHLIGHT, name)
					return
		
		if event.button_index == MOUSE_BUTTON_LEFT and current_unit != null:
			#if a unit has already been selected
			var clicked_cell = HexNavi.global_to_cell(get_global_mouse_position())
			
			get_viewport().set_input_as_handled()
			#deselect if unit is clicked on again
			if current_unit.cell == clicked_cell:
				deselect_current_unit()
				return
			
			if HexNavi.get_cell_custom_data(clicked_cell, "occupied"):
				deselect_current_unit()
				return
			if HexNavi.get_distance(current_unit.cell, clicked_cell) > current_unit.movement_range:
				deselect_current_unit()
				return
			if !in_progress:
				current_unit.move_along_path(HexNavi.get_navi_path(current_unit.cell, clicked_cell))
				in_progress = true
				await current_unit.movement_complete
				#TODO: fix a bug where you clck the units too quickly before the previous one ends
				current_unit.moved = true
				deselect_current_unit()
				in_progress = false
				if get_unmoved_unit_count() <= 0:
					all_units_moved.emit()
