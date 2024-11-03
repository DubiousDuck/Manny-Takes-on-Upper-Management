extends Node2D

class_name UnitContainer

@export var is_player_controlled : bool
var units : Array[Unit] = []
var current_unit : Unit
var is_waiting_unit_selection = true

func init():
	for unit in get_children():
		units.append(unit)
		if unit is Unit:
			unit.init()
	print(name + " has " + str(units.size()) + " units")

func _unhandled_input(event):
	if !is_player_controlled:
		return
		
	if event is InputEventMouseButton and event.is_pressed():
		if event.button_index == MOUSE_BUTTON_LEFT and is_waiting_unit_selection:
			var clicked_cell = Navi.global_to_cell(get_global_mouse_position())
			for unit in units:
				if unit.cell == clicked_cell:
					get_viewport().set_input_as_handled()
					current_unit = unit
					print(current_unit)
					is_waiting_unit_selection = false
					return
		
		if event.button_index == MOUSE_BUTTON_LEFT and current_unit != null:
			var clicked_cell = Navi.global_to_cell(get_global_mouse_position())
			
			get_viewport().set_input_as_handled()
			if current_unit.cell == clicked_cell:
				current_unit = null
				is_waiting_unit_selection = true
				return
			#another condition to check if the cell is occupied/blocked
			current_unit.move_along_path(Navi.get_navi_path(current_unit.cell, clicked_cell))
			
