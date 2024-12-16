extends Node2D

class_name UnitContainer

signal all_units_moved

const MOVE_RANGE_HIGHLIGHT : Color = Color(0, 0, 1, 0.5)
const ATTACK_HIGHLIGHT: Color = Color(1, 1, 0, 0.5)

#information
@export var is_player_controlled: bool
var units: Array[Unit] = []
var current_unit: Unit
var current_actions: Array[Unit.Action] = []
var current_skills: Array[SkillInfo] = []
var current_actionnable_cells: Dictionary = {}

#flags
var is_waiting_unit_selection: bool = true
var in_progress: bool = false

func _ready() -> void:
	EventBus.connect("unit_died", _on_unit_died)

func init():
	for unit in get_children():
		units.append(unit)
		if unit is Unit:
			unit.init()
	print(name + " has " + str(units.size()) + " units")
	
func round_start():
	for unit in units:
		unit.init()
	if !is_player_controlled:
		_step_enemy()
	
func get_available_unit_count():
	var count = 0
	for unit in units:
		if !unit.actions_avail.is_empty():
			count += 1
	return count

func select_unit(unit: Unit):
	current_unit = unit
	is_waiting_unit_selection = false
	current_actions = current_unit.actions_avail
	current_skills = current_unit.skills
	connect_current_unit_signals()
	
func deselect_current_unit():
	current_unit = null
	is_waiting_unit_selection = true
	current_actions = []
	current_skills = []
	disconnect_current_unit_signals()

func connect_current_unit_signals():
	pass

func disconnect_current_unit_signals():
	pass

func move_unit():
	#handle npc movement and attack logic here
	#TODO: placeholder movement
	var possible_cells = HexNavi.get_all_neighbors_in_range(current_unit.cell, current_unit.movement_range)
	var available_cells = [] 
	for cell in possible_cells:
		if !HexNavi.get_cell_custom_data(cell, "occupied"):
			available_cells.append(cell)
	var goal_cell = available_cells.pick_random() #TODO: Fix potential bug when the unit has no where to go
	current_unit.move_along_path(HexNavi.get_navi_path(current_unit.cell, goal_cell))
	return
	
func _step_enemy():
	if get_available_unit_count() <= 0:
		all_units_moved.emit()
		return
	for unit in units:
		if !unit.actions_avail.is_empty():
			current_unit = unit
			break
	if current_unit != null:
		move_unit()
		await current_unit.movement_complete
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
				if unit.cell == clicked_cell and !unit.actions_avail.is_empty(): #select this unit as the current_unit if the unit has actions remaining
					get_viewport().set_input_as_handled()
					select_unit(unit)
					#call action UI
					highlight_handle()
					get_actionnable_cells()
					return
		
		if event.button_index == MOUSE_BUTTON_LEFT and current_unit != null:
			#if a unit has already been selected
			var clicked_cell = HexNavi.global_to_cell(get_global_mouse_position())
			
			get_viewport().set_input_as_handled()
			#deselect if unit is clicked on again
			if current_unit.cell == clicked_cell:
				deselect_current_unit()
				return
			
			var action_type := find_action(clicked_cell)
			
			if action_type == Unit.Action.NONE:
				deselect_current_unit()
				return
				
			if action_type == Unit.Action.MOVE and !in_progress:
				current_unit.move_along_path(HexNavi.get_navi_path(current_unit.cell, clicked_cell))
				in_progress = true
				await current_unit.movement_complete
				#TODO: fix a bug where you clck the units too quickly before the previous one ends
				deselect_current_unit()
				in_progress = false
			
			if action_type == Unit.Action.ATTACK:
				var skill_used = current_skills.front()
				var outbound_array: Array[Vector2i] = [clicked_cell]
				EventBus.emit_signal("attack_used", skill_used, current_unit, outbound_array)
				current_unit.take_action(skill_used)
				deselect_current_unit()
				
			if get_available_unit_count() <= 0:
				all_units_moved.emit()

func highlight_handle():
	for ac in current_actions:
		match ac:
			Unit.Action.MOVE:
				var all_neighbors := HexNavi.get_all_neighbors_in_range(current_unit.cell, current_unit.movement_range)
				EventBus.emit_signal("show_cell_highlights", all_neighbors, MOVE_RANGE_HIGHLIGHT, name)
			Unit.Action.ATTACK:
				var all_targets: Array[Vector2i] = []
				for skill in current_skills:
					var targets = HexNavi.get_all_neighbors_in_range(current_unit.cell, skill.range)
					for target in targets:
						if HexNavi.get_cell_custom_data(target, "occupant_type") == skill.targets: #Only include if tile has the corresponding target
							all_targets.append(target)
				EventBus.emit_signal("show_cell_highlights", all_targets, ATTACK_HIGHLIGHT, name)
			_:
				pass

func get_actionnable_cells():
	current_actionnable_cells = {}
	for ac in current_actions:
		var tiles: Array[Vector2i] = []
		match ac:
			Unit.Action.MOVE:
				var all_neighbors = HexNavi.get_all_neighbors_in_range(current_unit.cell, current_unit.movement_range)
				for neighbor in all_neighbors:
					if !HexNavi.get_cell_custom_data(neighbor, "occupied"): #only actionnable if tile not occupied
						tiles.append(neighbor)
			Unit.Action.ATTACK:
				for skill in current_skills:
					var targets = HexNavi.get_all_neighbors_in_range(current_unit.cell, skill.range)
					for target in targets:
						if HexNavi.get_cell_custom_data(target, "occupant_type") == skill.targets: #Only include if tile has the corresponding target
							tiles.append(target)
			_:
				pass
		current_actionnable_cells[ac] = tiles

func find_action(cell: Vector2i) -> Unit.Action:
	var possible_ac: Array[Unit.Action] = [Unit.Action.NONE]
	for ac in current_actionnable_cells.keys():
		var cells = current_actionnable_cells.get(ac)
		if cells.has(cell):
			possible_ac.append(ac)
	return possible_ac.max() #returns the action with highest priority

func _on_unit_died():
	#recount how many children unit this group has
	units = []
	for unit in get_children():
		if unit.health > 0:
			units.append(unit)
