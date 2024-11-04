extends Node2D

class_name UnitContainer

signal all_units_moved

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
	var goal_cell = Navi.get_random_tile_pos() #TODO: placeholder movement
	current_unit.move_along_path(Navi.get_navi_path(current_unit.cell, goal_cell))
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
		if event.button_index == MOUSE_BUTTON_LEFT and is_waiting_unit_selection:
			# if no units have been selected
			var clicked_cell = Navi.global_to_cell(get_global_mouse_position())
			for unit in units:
				if unit.cell == clicked_cell and !unit.moved:
					get_viewport().set_input_as_handled()
					deselect_current_unit()
					current_unit = unit
					connect_current_unit_signals()
					print(current_unit)
					is_waiting_unit_selection = false
					return
		
		if event.button_index == MOUSE_BUTTON_LEFT and current_unit != null:
			#if a unit has already been selected
			var clicked_cell = Navi.global_to_cell(get_global_mouse_position())
			
			get_viewport().set_input_as_handled()
			#deselect if unit is clicked on again
			if current_unit.cell == clicked_cell:
				deselect_current_unit()
				return
			#TODO: another condition to check if the cell is occupied/blocked
			if !in_progress:
				current_unit.move_along_path(Navi.get_navi_path(current_unit.cell, clicked_cell))
				in_progress = true
				await current_unit.movement_complete
				current_unit.moved = true
				deselect_current_unit()
				in_progress = false
				if get_unmoved_unit_count() <= 0:
					all_units_moved.emit()
