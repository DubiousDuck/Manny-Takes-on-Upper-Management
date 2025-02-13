extends Node2D

class_name UnitContainer

signal all_units_moved
signal unit_action_done

#information
@export var is_player_controlled: bool
var units: Array[Unit] = []
var current_unit: Unit
var skill_chosen: SkillInfo = null
var current_actionnable_cells: Dictionary = {}

@export var aggro_probability: float = 1.0       #Default weights for move decision of AI enemy
@export var neutral_probability: float = 0.0
@export var defensive_probability: float = 0.0

@export var tilemap_path: NodePath = NodePath("../../TileMapTest") # Default value (can be overridden in the editor)
@onready var tile_map_test: TileMapLayer = get_node(tilemap_path) as TileMapLayer

#flags
var is_waiting_unit_selection: bool = true
var in_progress: bool = false

func _ready() -> void:
	EventBus.connect("unit_died", _on_unit_died)
	if is_player_controlled:
		EventBus.connect("skill_chosen", _on_skill_chosen)
	
	if !tile_map_test: # Always check for null!
		push_warning("TileMap not found at path: " + str(tilemap_path)) # More informative warning

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
	
func get_available_unit_count() -> int:
	var count = 0
	for unit in units:
		if !unit.actions_avail.is_empty():
			count += 1
	return count

func is_all_unit_on_standby() -> bool:
	for unit in units:
		if unit.is_on_standby == false:
			return false
	return true

func select_unit(unit: Unit):
	unit.selected = true
	current_unit = unit
	is_waiting_unit_selection = false
	if is_player_controlled and current_unit.actions_avail.has(Unit.Action.ATTACK):
		current_unit.check_if_can_throw()
		current_unit.toggle_skill_ui(true)
	skill_chosen = null
	connect_current_unit_signals()
	
func deselect_current_unit():
	if current_unit == null:
		return
	current_unit.toggle_skill_ui(false)
	current_unit.selected = false
	current_unit = null
	is_waiting_unit_selection = true
	skill_chosen = null
	disconnect_current_unit_signals()

func connect_current_unit_signals():
	pass

func disconnect_current_unit_signals():
	pass

func distances_to_player_array(action_cells: Array[Vector2i]):
	var all_cells: Array[Vector2i] = tile_map_test.get_all_tilemap_cells()
	var players_exhibiting_cells: Array[Vector2i] = get_targets_of_type(all_cells, SkillInfo.TargetType.ENEMIES)
	var position_distances_array: Array[float]
	# This for loop considers every move and compiles a position_distances_array containing the resulting closest distance to players
	for vector in action_cells:
		var dist_to_player: float = 99999
		for player_vector in players_exhibiting_cells:
			var dist_to_cur_player: float = sqrt(pow(player_vector.x-vector.x,2) + pow(player_vector.y-vector.y,2))
			if dist_to_cur_player < dist_to_player: dist_to_player = dist_to_cur_player
		position_distances_array.append(dist_to_player)
	return position_distances_array

func aggro_actionnable_cells(available_actionnable_cells):
	var output_actionnable_cells: Array[Vector2i]
	var position_distances_array: Array[float] = distances_to_player_array(available_actionnable_cells)
	# This line is where the most aggressive (closest to player) move is selected
	output_actionnable_cells.append(available_actionnable_cells[position_distances_array.find(position_distances_array.min())])
	return output_actionnable_cells

func neutral_actionnable_cells(available_actionnable_cells):
	var output_actionnable_cells: Array[Vector2i]
	var position_distances_array: Array[float] = distances_to_player_array(available_actionnable_cells)
	# This line is where the positional (medium distance to player) moves are selected
	output_actionnable_cells.append(available_actionnable_cells[position_distances_array.find(get_median(position_distances_array))])
	return output_actionnable_cells

func defensive_actionable_cells(available_actionnable_cells):
	var output_actionnable_cells: Array[Vector2i]
	var position_distances_array: Array[float] = distances_to_player_array(available_actionnable_cells)
	# This line is where the most defensive (farthest distance to player) move is selected
	output_actionnable_cells.append(available_actionnable_cells[position_distances_array.find(position_distances_array.max())])
	return output_actionnable_cells

# This was useful for the neutral_actionable_cells function
func get_median(arr: Array[float]) -> float:
	if arr.is_empty():
		return 0.0  # Handle empty array case
	var sorted_arr = arr.duplicate()  # Duplicate to avoid modifying the original array
	sorted_arr.sort()  # Sort the array in ascending order
	var n = sorted_arr.size()
	var mid = n / 2
	return sorted_arr[mid]  # Return middle element

func unit_action():
	#handle npc movement and attack logic here
	#Place holder for now (largely identical to player logic)
	#TODO: Smarter enemy AI
	
	#check for attack targets; if none, choose wait
	for skill in current_unit.skills:
		skill_chosen = skill #assumes that if all fail, wait is always an option
		var targets = HexNavi.get_all_neighbors_in_range(current_unit.cell, skill_chosen.range)
		if get_targets_of_type(targets, skill_chosen.targets).size() > 0:
			break
	
	#get all actionnable cells and pick a random one #TODO: Give weights to different actions so enemy can make better choices
	get_actionnable_cells()
	var all_actionnable_cells: Array[Vector2i] = []
	current_actionnable_cells.values().map(
		func(array):
			all_actionnable_cells.append_array(array)
	)
	
	var clicked_cell: Vector2i
	var action_options: Array[Vector2i]
	
	var action_roll: float = randf() * (aggro_probability + neutral_probability + defensive_probability)
	
	if (action_roll < aggro_probability):
		action_options = aggro_actionnable_cells(all_actionnable_cells)
		#print("PICKED AGGRO MOVE")
	elif (action_roll < aggro_probability + neutral_probability):
		action_options = neutral_actionnable_cells(all_actionnable_cells)
		#print("PICKED POSITIONAL MOVE")
	else:
		action_options = defensive_actionable_cells(all_actionnable_cells)
		#print("PICKED DEFENSIVE MOVE")
	
	if !action_options.is_empty():
		clicked_cell = action_options.pick_random()
	else:
		clicked_cell = all_actionnable_cells.pick_random()
	
	
	#execute action according to the cell chosen
	var action_type := find_action(clicked_cell)
	
	if action_type == Unit.Action.NONE:
		deselect_current_unit()
		return
		
	if action_type == Unit.Action.MOVE and !in_progress:
		var full_path = HexNavi.get_navi_path(current_unit.cell, clicked_cell)
		current_unit.move_along_path(full_path)
		if !current_unit.unit_held.is_empty(): #if unit is carrying other units
			current_unit.unit_held.map(
				func(unit): #assume all units held are of class Unit
					unit.move_along_path(full_path)
			)
		in_progress = true
		await current_unit.movement_complete
		#print("# " + str(current_unit.name) + " moved" + " (UnitContainer.gd)")
		deselect_current_unit()
		in_progress = false
	
	if action_type == Unit.Action.ATTACK and !in_progress: #assumes that skill_chosen is not null
		#print("# " + str(current_unit.name) + " USED: " + str(skill_chosen.name) + " (UnitContainer.gd)")
		var outbound_array: Array[Vector2i] = [clicked_cell]
		current_unit.take_action(skill_chosen)
		#print("# Awaiting attack point (UnitContainer.gd)")
		in_progress = true
		await current_unit.attack_point
		in_progress = false
		EventBus.emit_signal("attack_used", skill_chosen, current_unit, outbound_array)
		await current_unit.all_complete
		deselect_current_unit()
	
	unit_action_done.emit()
	return
	
func _step_enemy():
	if get_available_unit_count() <= 0:
		all_units_moved.emit()
		return
	for unit in units:
		if !unit.actions_avail.is_empty():
			select_unit(unit)
			break
	if current_unit != null:
		unit_action()
		await unit_action_done
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
					highlight_handle()
					get_actionnable_cells()
					return
		
		if event.button_index == MOUSE_BUTTON_LEFT and current_unit != null and !in_progress:
			#if a unit has already been selected
			var clicked_cell = HexNavi.global_to_cell(get_global_mouse_position())
			
			get_viewport().set_input_as_handled()
				
			var action_type := find_action(clicked_cell)
			
			#deselect if unit is clicked on again; select held units
			if current_unit != null and current_unit.cell == clicked_cell:
				var next_unit = get_next_unit_of_same_cell(current_unit)
				deselect_current_unit()
				if next_unit != null:
					select_unit(next_unit)
					highlight_handle()
					get_actionnable_cells()
				return
			
			if action_type == Unit.Action.NONE:
				deselect_current_unit()
				return
			
			#FIXME: attack won't be carried out if enemy and ally are stacked on the same cell
			if action_type == Unit.Action.MOVE:
				check_and_remove_unit_from_being_held(current_unit)
				
				var full_path = HexNavi.get_navi_path(current_unit.cell, clicked_cell)
				current_unit.move_along_path(full_path)
				in_progress = true
				await current_unit.movement_complete
				EventBus.emit_signal("update_cell_status", true)
				deselect_current_unit()
				in_progress = false
			
			if action_type == Unit.Action.ATTACK: #assumes that skill_chosen is not null
				var outbound_array: Array[Vector2i] = [clicked_cell]
				current_unit.take_action(skill_chosen)
				#print("# Awaiting attack point (UnitContainer.gd)")
				in_progress = true
				await current_unit.attack_point
				EventBus.emit_signal("attack_used", skill_chosen, current_unit, outbound_array)
				await current_unit.all_complete
				in_progress = false
				deselect_current_unit()
			
			if get_available_unit_count() <= 0:
				all_units_moved.emit()
			

func highlight_handle():
	EventBus.emit_signal("remove_cell_highlights", name)
	for ac in current_unit.actions_avail:
		match ac:
			Unit.Action.MOVE:
				var all_neighbors := HexNavi.get_all_neighbors_in_range(current_unit.cell, current_unit.movement_range)
				EventBus.emit_signal("show_cell_highlights", all_neighbors, CellHighlight.MOVE_RANGE_HIGHLIGHT, name)
			Unit.Action.ATTACK:
				#TODO: Highlights the range of attack when hovering over Skill Select
				if skill_chosen == null:
					return
				var targets = HexNavi.get_all_neighbors_in_range(current_unit.cell, skill_chosen.range)
				var all_targets: Array[Vector2i] = get_targets_of_type(targets, skill_chosen.targets) #shows only valid targets
				#var all_targets: Array[Vector2i] = targets #this shows the range instead of valid targets
				if all_targets.size() == 0:
					return
				EventBus.emit_signal("show_cell_highlights", all_targets, CellHighlight.ATTACK_HIGHLIGHT, name)
			_:
				pass

func get_actionnable_cells():
	current_actionnable_cells = {}
	for ac in current_unit.actions_avail:
		var tiles: Array[Vector2i] = []
		match ac:
			Unit.Action.MOVE:
				var all_neighbors = HexNavi.get_all_neighbors_in_range(current_unit.cell, current_unit.movement_range)
				for neighbor in all_neighbors:
					if !HexNavi.get_cell_custom_data(neighbor, "occupied") and HexNavi.get_cell_custom_data(neighbor, "traversible"): #only actionnable if tile not occupied
						tiles.append(neighbor)
			Unit.Action.ATTACK:
				if skill_chosen == null:
					return
				var targets = HexNavi.get_all_neighbors_in_range(current_unit.cell, skill_chosen.range)
				tiles.append_array(get_targets_of_type(targets, skill_chosen.targets))
			_:
				pass
		current_actionnable_cells[ac] = tiles

func find_action(cell: Vector2i) -> Unit.Action:
	#given a clicked cell, return the action with highest priority that is legal on that cell
	var possible_ac: Array[Unit.Action] = [Unit.Action.NONE]
	for ac in current_actionnable_cells.keys():
		var cells = current_actionnable_cells.get(ac)
		if cells.has(cell):
			possible_ac.append(ac)
	return possible_ac.max() #returns the action with highest priority

func get_targets_of_type(targets: Array[Vector2i], type: int): #return cells among targets that are of a specific target type
	var correct_targets: Array[Vector2i] = []
	var allied_cells: Array[Vector2i] = []
	units.map(
		func(unit):
			allied_cells.append(unit.cell)
	)
	for target in targets:
		if HexNavi.get_cell_custom_data(target, "occupied"):
			match type:
				SkillInfo.TargetType.ALLIES:
					if allied_cells.has(target): correct_targets.append(target)
				SkillInfo.TargetType.ENEMIES:
					if !allied_cells.has(target): correct_targets.append(target)
				SkillInfo.TargetType.SELF:
					if target == current_unit.cell: correct_targets.append(target)
				SkillInfo.TargetType.ANY_UNIT:
					correct_targets.append(target)
				SkillInfo.TargetType.EXCEPT_SELF:
					if target != current_unit.cell: correct_targets.append(target)
				SkillInfo.TargetType.ALLIES_EXCEPT_SELF:
					if allied_cells.has(target) and target != current_unit.cell: correct_targets.append(target)
				SkillInfo.TargetType.ANY_CELL_EXCEPT_SELF:
					if target != current_unit.cell: correct_targets.append(target)
				_:
					pass
		else:
			match type:
				SkillInfo.TargetType.ANY_CELL:
					correct_targets.append(target)
				SkillInfo.TargetType.ANY_CELL_EXCEPT_SELF:
					if target != current_unit.cell: correct_targets.append(target)
				_: pass
	
	return correct_targets
	
func _on_unit_died():
	refresh_units()
	
func _on_skill_chosen(skill: SkillInfo):
	current_unit.toggle_skill_ui(false)
	skill_chosen = skill
	if skill_chosen.name == "Wait":
		unit_wait()
		return
	highlight_handle()
	get_actionnable_cells()
	
func get_next_unit_of_same_cell(curr_unit: Unit):
	for unit in units:
		if unit.cell == curr_unit.cell and unit != curr_unit:
			return unit
	return null

func unit_wait(): #special case for when WAIT is chosen
	var outbound_array: Array[Vector2i] = [current_unit.cell]
	current_unit.take_action(skill_chosen)
	in_progress = true
	await current_unit.attack_point
	in_progress = false
	EventBus.emit_signal("attack_used", skill_chosen, current_unit, outbound_array)
	deselect_current_unit()
	
	if get_available_unit_count() <= 0:
		all_units_moved.emit()

func check_and_remove_unit_from_being_held(this_unit: Unit):
	for unit in units:
		if unit.unit_held.has(this_unit):
			unit.unit_held.erase(this_unit)
			this_unit.is_held = false

func refresh_units():
	#recount how many children unit this group has
	units = []
	for unit in get_children():
		if !unit.is_dead:
			units.append(unit)
