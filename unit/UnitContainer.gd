extends Node2D

class_name UnitContainer

signal all_units_moved
signal unit_action_done

@export_category("General Parameters")
@export var is_player_controlled: bool
## If false, ally parties will not be read from Save Data but instead loaded from the scene editor
@export var read_class_from_data: bool = true
@export var enemy_container: UnitContainer #NOTICE: New feature!
var units: Array[Unit] = []
var current_unit: Unit
var skill_chosen: SkillInfo = null
var current_actionnable_cells: Dictionary = {}

@export_category("Enemy AI Parameters")
@export var aggro_probability: float = 1.0       #Default weights for move decision of AI enemy
@export var neutral_probability: float = 0.0
@export var defensive_probability: float = 0.0

@export_category("TilpMapLayer Related")
@export var tilemap_path: NodePath = NodePath("../../TileMapTest") # Default value (can be overridden in the editor)
@onready var tile_map_test: TileMapLayer = get_node(tilemap_path) as TileMapLayer

#flags
var is_waiting_unit_selection: bool = true
var in_progress: bool = false
var is_aoe_skill: bool = false

func _ready() -> void:
	EventBus.connect("pass_turn", _on_turn_passed)
	EventBus.connect("unit_died", _on_unit_died)
	if is_player_controlled:
		EventBus.connect("skill_chosen", _on_skill_chosen)
	
	if !tile_map_test: # Always check for null!
		push_warning("TileMap not found at path: " + str(tilemap_path)) # More informative warning
	
	if !enemy_container:
		push_warning("No enemy container assigned to " + name)
	
	for unit in get_children():
		units.append(unit)
		
	##Read and assign unit data
	if is_player_controlled and read_class_from_data:
		var unit_data_array: Array[UnitData] = Global.current_party.duplicate(true)
		#unit_data_array.erase(preload("res://unit/params/protagonist.tres"))
		var unassigned: Array[Unit] = units.duplicate(true)
		#unassigned.erase(find_child("Protag")) #NOTICE Assumes that protag has been set up in the editor already
		
		for index in range(unit_data_array.size()):
			if index >= unassigned.size():
				break
			unassigned[index].unit_data = unit_data_array[index]
		
		var valid_units: Array[Unit] = []
		for unit in units:
			if unit.unit_data == null:
				unit.hide()
				unit.queue_free()
			else:
				unit.load_unit_data()
				valid_units.append(unit)
		units = valid_units
	else:
		#TODO: Dynamically set enemies based on parameters
		for unit in units:
			unit.load_unit_data()
		
	print(name + " has " + str(units.size()) + " units")

func init():
	for unit in units:
		if unit is Unit:
			unit.init()
	
func round_start():
	Global.isPlayerTurn = true
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

func get_available_units() -> Array[Unit]:
	var output: Array[Unit] = []
	for unit in units:
		if !unit.actions_avail.is_empty():
			output.append(unit)
	return output

func is_all_unit_on_standby() -> bool:
	for unit in units:
		if unit.is_on_standby == false:
			return false
	return true

func select_unit(unit: Unit):
	unit.selected = true
	current_unit = unit
	is_waiting_unit_selection = false
	if is_player_controlled:
		if current_unit.actions_avail.has(Unit.Action.ATTACK):
			current_unit.check_if_can_throw()
			current_unit.toggle_skill_ui(true)
		else:
			current_unit.toggle_skill_ui(true, true)
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
	EventBus.emit_signal("remove_cell_highlights", name)
	disconnect_current_unit_signals()

func connect_current_unit_signals():
	pass

func disconnect_current_unit_signals():
	pass

# ---- Enemy AI related ----
func get_closest_enemy(unit: Unit) -> Unit:
	var closest_distance = INF
	var closest_enemy: Unit
	var target_container = enemy_container
	if unit.is_player_controlled:
		target_container = self
	for enemy in target_container.units:
		if (unit.cell - enemy.cell).length() < closest_distance:
			closest_distance = (unit.cell - enemy.cell).length()
			closest_enemy = enemy
	return closest_enemy

func estimate_knockback(attacker, target: Vector2i, skill: SkillInfo, kb_distance: int) -> Dictionary[Unit, Vector2i]:
	var dict: Dictionary[Unit, Vector2i] = {}
	var affected_area := HexNavi.get_all_neighbors_in_range(target, abs(skill.area), 999)
	var knockback_origin: Vector2 = affected_area.front() if skill.area > 0 else attacker.cell
	var affected_units: Array[Unit] = []
	
	for unit in enemy_container.units:
		if affected_area.has(unit.cell): affected_units.append(unit)
	for unit in units:
		if affected_area.has(unit.cell): affected_units.append(unit)
	
	affected_units.map(
		func(unit: Unit):
			var dir: Vector2 = HexNavi.cell_to_global(unit.cell) - knockback_origin
			#apply the direction by strength of knockback
			var new_location: Vector2 = unit.global_position + dir*kb_distance
			if HexNavi.global_to_cell(new_location) == Vector2i(-999, -999): ## pretends there's a wall
				new_location = HexNavi.cell_to_global(HexNavi.get_closest_cell_by_global_pos(new_location))
			dict[unit] = Vector2i(new_location)
	)
	return dict

func estimate_damage(attacker: Unit, skill: SkillInfo, damage: int = 1, reversed: bool = false) -> int:
	var attack_power = 0
	if skill.affinity == 0:
		attack_power = attacker.attack_power * damage
	else: attack_power = attacker.magic_power * damage
	
	return attack_power

func construct_state() -> GameState:
	var all_units: Array[Unit] = []
	all_units.append_array(units)
	all_units.append_array(enemy_container.units)
	var all_pos: Array[Vector2i] = []
	var all_health: Array[int] = []
	all_units.map(
		func(unit: Unit):
			all_pos.append(unit.cell)
			all_health.append(unit.health)
	)
	var state := GameState.new()
	state.set_state(all_units, all_pos, all_health)
	state.init_cell_effects()
	return state

## Helper function that returns a state after simulating the outcome of an action #TODO: set up tile info parameter
func simulate_action(state: GameState, unit: Unit, target_cell: Vector2i, action_type: Unit.Action, skill: SkillInfo = null) -> GameState:
	var new_state := GameState.new()
	new_state.position = state.position.duplicate(true)
	new_state.health = state.health.duplicate(true)
	
	# Scans each unit and evaluate score based on their position to each other and to other tiles
	if action_type == Unit.Action.MOVE:
		new_state.position[unit] = target_cell
	if action_type == Unit.Action.ATTACK:
		if skill == null:
			return new_state
		#Go through all of the skill's effect and calculate score
		for effect in skill.skill_effects:
			match effect.x:
				SkillInfo.EffectType.DAMAGE:
					var damage = estimate_damage(unit, skill, effect.y)
					var affected_area := HexNavi.get_all_neighbors_in_range(target_cell, abs(skill.area), 999)
					for victim in new_state.position.keys():
						if affected_area.has(new_state.position[victim]):
							new_state.health[victim] -= damage
				SkillInfo.EffectType.KNOCKBACK:
					var displacement := estimate_knockback(unit, target_cell, skill, effect.y)
					for victim in displacement.keys():
						new_state.position[victim] = displacement[victim]
				SkillInfo.EffectType.HEAL:
					var healing = estimate_damage(unit, skill, effect.y)
					var affected_area := HexNavi.get_all_neighbors_in_range(target_cell, abs(skill.area), 999)
					for healed in new_state.position.keys():
						if affected_area.has(new_state.position[healed]):
							new_state.health[healed] += healing
				SkillInfo.EffectType.DAMAGE_REDUCTION:
					var affected_area := HexNavi.get_all_neighbors_in_range(target_cell, abs(skill.area), 999)
					for buffed in new_state.position.keys():
						if affected_area.has(new_state.position[buffed]):
							new_state.health[buffed] *= 1.5
				SkillInfo.EffectType.SET_TILE:
					match effect.y:
						1:
							new_state.cell_effects[target_cell] = "death"
						_:
							pass
	
	return new_state

func evaluate_state(state: GameState) -> int:
	var score = 0
	
	for unit in state.position.keys():
		if !unit: continue
		if unit.actions_avail.has(Unit.Action.ATTACK):
			score += (unit.cell - get_closest_enemy(unit).cell).length() - (state.position[unit] - get_closest_enemy(unit).cell).length()
		else: score += (state.position[unit] - get_closest_enemy(unit).cell).length() - (unit.cell - get_closest_enemy(unit).cell).length()
		
		#Encourages moving into if HP is high; encourages moving away if HP is low
		if state.health[unit] <= unit.max_health/3:
			score += (state.position[unit] - get_closest_enemy(unit).cell).length() - (unit.cell - get_closest_enemy(unit).cell).length()
		else: score += (unit.cell - get_closest_enemy(unit).cell).length() - (state.position[unit] - get_closest_enemy(unit).cell).length()
		
		if enemy_container.units.has(unit):
			score += unit.health - state.health[unit]
		else:
			score -= (unit.health - state.health[unit]) * 0.5
		
		var nearby_cell := HexNavi.get_all_neighbors_in_range(state.position[unit], 1, 999)
		for cell in nearby_cell:
			# Instead of looking at the current board, look at the simulated board state
			var target_key: Vector2i = Vector2i(-999, -999)
			# Save way of comparing the two values (dictionary shenanigans)
			for pair in state.cell_effects.keys():
				if is_same(pair, cell):
					target_key = pair
			if target_key == Vector2i(-999, -999): continue
			
			var effect = state.cell_effects[Vector2i(target_key)]
			match effect:
				"death":
					if enemy_container.units.has(unit): 
						if cell == state.position[unit]: score += 10
						else: score += 3
					else:
						if cell == state.position[unit]: score -= 10
						else: score -= 3
				"heal":
					if enemy_container.units.has(unit): 
						if cell == state.position[unit]: score -= 5
						else: score -= 2
					else:
						if cell == state.position[unit]: score += 5
						else: score += 2
				_:
					score += 0
	return score

## NPC movement and action logic; assumes that [member current_unit] is not [code]null[/code]
func unit_action(skill: SkillInfo, target_cell: Vector2i):
	
	var skill_chosen := skill
	var clicked_cell: Vector2i = target_cell
	update_actionnable_cells(current_unit, skill_chosen)
	var action_type := find_action(clicked_cell)
	
	if action_type == Unit.Action.NONE:
		deselect_current_unit()
		unit_action_done.emit()
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
		outbound_array.append_array(HexNavi.get_all_neighbors_in_range(clicked_cell, abs(skill_chosen.area), 999))
		current_unit.take_action(skill_chosen, clicked_cell)
		#print("# Awaiting attack point (UnitContainer.gd)")
		in_progress = true
		await current_unit.attack_point
		in_progress = false
		EventBus.emit_signal("attack_used", skill_chosen, current_unit, outbound_array)
		await current_unit.all_complete
		deselect_current_unit()
	
	unit_action_done.emit()
	return

## Helper function of the recurstive AI function
func find_best_move(current_state: GameState, unit: Unit) -> Dictionary:
	var valid_skills: Array = []
	
	for skill in unit.skills:
		var targets = HexNavi.get_all_neighbors_in_range(unit.cell, skill.range)
		if get_targets_of_type(targets, skill.targets, unit).size() > 0:
			valid_skills.append(skill)
	
	#find the best skill
	var best_score = -INF
	var best_cell: Vector2i = unit.cell
	var best_skill: SkillInfo = preload("res://skills/wait.tres")
	var best_state: GameState = current_state
	if unit.actions_avail.has(Unit.Action.ATTACK):
		for skill in valid_skills:
			var actionnable_cells := get_actionnable_cells(unit, Unit.Action.ATTACK, skill)
			for cell in actionnable_cells:
				var new_state := simulate_action(current_state, unit, cell, Unit.Action.ATTACK, skill)
				var score = evaluate_state(new_state)
				if score > best_score:
					best_score = score
					best_cell = cell
					best_skill = skill
					best_state = new_state
	# Find best movement and compare with best skill
	if unit.actions_avail.has(Unit.Action.MOVE):
		var actionnable_cells := get_actionnable_cells(unit, Unit.Action.MOVE)
		for cell in actionnable_cells:
			var new_state := simulate_action(current_state, unit, cell, Unit.Action.MOVE)
			var score = evaluate_state(new_state)
			if score > best_score:
				best_score = score
				best_cell = cell
				best_skill = preload("res://skills/wait.tres")
				best_state = new_state
	return {"score": best_score, "cell": best_cell, "skill": best_skill, "state": best_state}

## Recursive function that finds the best move taking the team into consideration
func find_best_team_sequence(units: Array[Unit], state: GameState) -> Dictionary:
	if units.is_empty():
		return {
			"score": evaluate_state(state),
			"sequence": []
		}
	
	var unit = units[0]
	var remaining_units = units.slice(1, units.size())

	# Use your existing helper
	var move_data := find_best_move(state, unit)
	var new_state = move_data.state
	var action_info = {
		"unit": unit,
		"cell": move_data.cell,
		"skill": move_data.skill
	}

	# Recursively get best future moves
	var result = find_best_team_sequence(remaining_units, new_state)
	var total_score = result.score

	return {
		"score": total_score,
		"sequence": [action_info] + result.sequence
	}

func _step_enemy():
	if !Global.is_attack_resolved:
		await EventBus.attack_resolved
	if get_available_unit_count() <= 0:
		all_units_moved.emit()
		return
	
	var initial_state := construct_state()
	var best_results := find_best_team_sequence(get_available_units(), initial_state)
	
	if best_results.sequence.size() > 0:
		var first_action = best_results.sequence[0]
		var best_unit: Unit = first_action.unit
		var best_cell: Vector2i = first_action.cell
		var best_skill: SkillInfo = first_action.skill
	
		# Then do something with them
		print("Unit: ", best_unit.name, "; Skill: ", best_skill.name, "; Cell: ", best_cell)
		
		select_unit(best_unit)
		if current_unit != null:
			unit_action(best_skill, best_cell)
			await unit_action_done
			await get_tree().create_timer(0.75).timeout
			_step_enemy()
		return
	else:
		print("No valid sequence found.")
		all_units_moved.emit()
		return
	
## Helper function to determine which enemy unit to move; prioritize furtherest unit
func unit_pos_score(unit: Unit):
	var largest_distance: int = -INF
	for enemy in enemy_container.units:
		var distance := (unit.cell - enemy.cell).length()
		if distance > largest_distance:
			largest_distance = distance
	return largest_distance

# ---- Player Input ----
func _unhandled_input(event):
	if !is_player_controlled or !Global.is_attack_resolved:
		return
	
	if is_aoe_skill and skill_chosen != null:
		EventBus.emit_signal("remove_cell_highlights", name+"_AOE")
		var mouse_cell :=  HexNavi.global_to_cell(get_global_mouse_position())
		var skill_range := HexNavi.get_all_neighbors_in_range(current_unit.cell, skill_chosen.range, 999)
		if mouse_cell in skill_range and mouse_cell in get_targets_of_type(skill_range, skill_chosen.targets):
			var outbound: Array[Vector2i] = [mouse_cell]
			var skill_area := HexNavi.get_all_neighbors_in_range(mouse_cell, abs(skill_chosen.area), 999)
			outbound.append_array(skill_area)
			EventBus.emit_signal("show_cell_highlights", outbound, CellHighlight.ATTACK_HIGHLIGHT, name+"_AOE")
	else: EventBus.emit_signal("remove_cell_highlights", name+"_AOE")
	
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
					update_actionnable_cells(current_unit)
					return
		
		if event.button_index == MOUSE_BUTTON_LEFT and current_unit != null and !in_progress:
			#if a unit has already been selected
			var clicked_cell = HexNavi.global_to_cell(get_global_mouse_position())
			
			get_viewport().set_input_as_handled()
				
			var action_type := find_action(clicked_cell)
			
			if action_type == Unit.Action.NONE:
				#deselect if unit is clicked on again; select held units
				if current_unit != null and current_unit.cell == clicked_cell:
					var next_unit = get_next_unit_of_same_cell(current_unit)
					if next_unit != null:
						deselect_current_unit()
						select_unit(next_unit)
						highlight_handle()
						update_actionnable_cells(current_unit)
						return
				deselect_current_unit()
				return
			
			#FIXME: attack won't be carried out if enemy and ally are stacked on the same cell
			if action_type == Unit.Action.MOVE:
				check_and_remove_unit_from_being_held(current_unit)
				
				var full_path = HexNavi.get_navi_path(current_unit.cell, clicked_cell)
				current_unit.move_along_path(full_path)
				in_progress = true
				await current_unit.movement_complete
				deselect_current_unit()
				in_progress = false
			
			if action_type == Unit.Action.ATTACK: #assumes that skill_chosen is not null
				var outbound_array: Array[Vector2i] = [clicked_cell]
				outbound_array.append_array(HexNavi.get_all_neighbors_in_range(clicked_cell, abs(skill_chosen.area), 999))
				current_unit.take_action(skill_chosen, clicked_cell)
				#print("# Awaiting attack point (UnitContainer.gd)")
				in_progress = true
				await current_unit.attack_point
				if Global.attack_successful:
					EventBus.emit_signal("attack_used", skill_chosen, current_unit, outbound_array)
				else:
					current_unit.unit_held.map(check_and_remove_unit_from_being_held)
					EventBus.emit_signal("attack_used", preload("res://skills/wait.tres"), current_unit, outbound_array)
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
				var targets = HexNavi.get_all_neighbors_in_range(current_unit.cell, skill_chosen.range, 999)
				var all_targets: Array[Vector2i] = get_targets_of_type(targets, skill_chosen.targets) #shows only valid targets
				#var all_targets: Array[Vector2i] = targets #this shows the range instead of valid targets
				if all_targets.size() == 0:
					return
				EventBus.emit_signal("show_cell_highlights", all_targets, CellHighlight.ATTACK_HIGHLIGHT, name)
			_:
				pass

func get_actionnable_cells(this_unit: Unit, action_type: Unit.Action, skill: SkillInfo = null) -> Array[Vector2i]:
	var tiles: Array[Vector2i] = []
	match action_type:
		Unit.Action.MOVE:
			var all_neighbors := HexNavi.get_all_neighbors_in_range(this_unit.cell, this_unit.movement_range)
			var enemy_cell: Array[Vector2i] = []
			enemy_container.units.map(
				func(unit: Unit):
					if unit != null: enemy_cell.append(unit.cell)
			)
			for neighbor in all_neighbors:
				if HexNavi.get_cell_custom_data(neighbor, "traversable") and neighbor != this_unit.cell and !(neighbor in enemy_cell): #only actionnable if tile not occupied
					tiles.append(neighbor)
		Unit.Action.ATTACK:
			if skill == null:
				return []
			var targets = HexNavi.get_all_neighbors_in_range(this_unit.cell, skill.range, 999)
			tiles.append_array(get_targets_of_type(targets, skill.targets, this_unit))
		_:
			pass
	return tiles

func update_actionnable_cells(unit: Unit, skill: SkillInfo = null):
	current_actionnable_cells = {}
	for ac in unit.actions_avail:
		match ac:
			Unit.Action.MOVE:
				current_actionnable_cells[ac] = get_actionnable_cells(unit, ac)
			Unit.Action.ATTACK:
				if skill == null:
					return
				current_actionnable_cells[ac] = get_actionnable_cells(unit, ac, skill)
	if !(unit.actions_avail.has(Unit.Action.ATTACK)):
		current_actionnable_cells[Unit.Action.ATTACK] = get_actionnable_cells(unit, Unit.Action.ATTACK, preload("res://skills/wait.tres"))
	print(current_actionnable_cells)
	
func find_action(cell: Vector2i) -> Unit.Action:
	#given a clicked cell, return the action with highest priority that is legal on that cell
	var possible_ac: Array[Unit.Action] = [Unit.Action.NONE]
	for ac in current_actionnable_cells.keys():
		var cells = current_actionnable_cells.get(ac)
		if cells.has(cell):
			possible_ac.append(ac)
	return possible_ac.max() #returns the action with highest priority

func get_targets_of_type(targets: Array[Vector2i], type: int, unit: Unit = current_unit): #return cells among targets that are of a specific target type
	var correct_targets: Array[Vector2i] = []
	var allied_cells: Array[Vector2i] = []
	var enemy_cells: Array[Vector2i] = []
	units.map(
		func(unit):
			allied_cells.append(unit.cell)
	)
	enemy_container.units.map(
		func(unit):
			if unit != null:
				enemy_cells.append(unit.cell)
	)
	for target in targets:
		match type:
			SkillInfo.TargetType.ALLIES:
				if allied_cells.has(target): correct_targets.append(target)
			SkillInfo.TargetType.ENEMIES:
				if enemy_cells.has(target): correct_targets.append(target)
			SkillInfo.TargetType.SELF:
				if target == unit.cell: correct_targets.append(target)
			SkillInfo.TargetType.ANY_UNIT:
				if target in allied_cells or target in enemy_cells:
					correct_targets.append(target)
			SkillInfo.TargetType.EXCEPT_SELF:
				if target in allied_cells or target in enemy_cells:
					if target != unit.cell: correct_targets.append(target)
			SkillInfo.TargetType.ALLIES_EXCEPT_SELF:
				if allied_cells.has(target) and target != unit.cell: correct_targets.append(target)
			SkillInfo.TargetType.ANY_CELL:
				correct_targets.append(target)
			SkillInfo.TargetType.ANY_CELL_EXCEPT_SELF:
				if target != unit.cell: correct_targets.append(target)
			SkillInfo.TargetType.ANY_CELL_EXCEPT_ALLIES:
				if !(target in allied_cells):
					correct_targets.append(target)
			_:
				pass
	
	return correct_targets
	
func _on_unit_died():
	refresh_units()

func _on_skill_chosen(skill: SkillInfo):
	current_unit.toggle_skill_ui(false)
	skill_chosen = skill
	if skill_chosen.name == "Wait":
		unit_wait()
		return
	if abs(skill_chosen.area) > 0:
		is_aoe_skill = true
	else: is_aoe_skill = false
	highlight_handle()
	update_actionnable_cells(current_unit, skill_chosen)
	
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

func _on_turn_passed():
	if !is_player_controlled:
		return
	#Remove all tokens
	units.map(
		func(unit: Unit):
			unit.actions_avail.clear()
	)
	all_units_moved.emit()
	
	print("passing turn")

func check_and_remove_unit_from_being_held(this_unit: Unit):
	for unit in units:
		if unit.unit_held.has(this_unit):
			unit.unit_held.erase(this_unit)
			this_unit.is_held = false
			this_unit.animation_state("side_idle")

func refresh_units():
	#recount how many children unit this group has
	units = []
	for unit in get_children():
		if !unit.is_dead and unit.unit_data != null:
			units.append(unit)
