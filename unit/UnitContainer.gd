extends Node2D

class_name UnitContainer

signal all_units_moved
signal unit_action_done

# Constants
const WAIT_SKILL = preload("res://skills/wait.tres")
const MOVE_SKILL = preload("res://skills/move.tres")

@export_category("General Parameters")
@export var is_player_controlled: bool
## If false, ally parties will not be read from Save Data but instead loaded from the scene editor
@export var read_class_from_data: bool = true
@export var enemy_container: UnitContainer #NOTICE: New feature!

@export_category("Enemy AI Parameters")
@export var aggro_probability: float = 1.0       #Default weights for move decision of AI enemy
@export var neutral_probability: float = 0.0
@export var defensive_probability: float = 0.0

@export_category("TilpMapLayer Related")
@export var tilemap_path: NodePath = NodePath("../../TileMapTest") # Default value (can be overridden in the editor)
@onready var tile_map_test: TileMapLayer = get_node(tilemap_path) as TileMapLayer

# General vars
var units: Array[Unit] = []
var current_unit: Unit
var skill_chosen: SkillInfo = null
var current_actionnable_cells: Dictionary = {}
var in_battle: bool = false
## stores unit in skill range to show animations
var targetted_units: Array[Unit] = []

#flags
var is_waiting_unit_selection: bool = true
## flag that indicates whether the player has chosen the actio "Move" or not
var unit_moving: bool = false
var in_progress: bool = false
var is_aoe_skill: bool = false
var turn_ended: bool = false

func _ready() -> void:
	EventBus.connect("pass_turn", _on_turn_passed)
	EventBus.connect("unit_died", _on_unit_died)
	if is_player_controlled:
		EventBus.connect("skill_chosen", _on_skill_chosen)
		EventBus.connect("cancel_select_unit", _on_cancel_button_pressed)
	
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
	## Enemy container unit assignment logic
	else:
		for unit in units:
			# get the correct data by name and apply level ups
			var template: UnitData = UnitDatabase.get_by_class(unit.unit_data.unit_class)
			if template.level != 1:
				template.level = 1
			while template.level < unit.unit_data.level:
				template.level_up()
			template.item_list = unit.unit_data.item_list.duplicate()
			# assign the correct version back to the unit
			unit.unit_data = template
			unit.load_unit_data()
		

func init():
	for unit in units:
		if unit is Unit:
			unit.container = self
			unit.init()
	
func round_start(): # TODO: need to wait for unit init complete
	in_battle = true
	
	turn_ended = false
	var init_waits = []
	for unit in units:
		print("initializing " + str(unit.unit_data.unit_class))
		unit.init()
		await unit.init_finished
	
	# Filter dead units now
	units = units.filter(func(u): return not u.is_dead)
		
	if is_player_controlled:
		Global.isPlayerTurn = true
		get_available_unit_count()
	else:
		Global.isPlayerTurn = false
		_step_enemy()
	
func get_available_unit_count() -> int:
	var count = 0
	for unit in units:
		if !unit.actions_avail.is_empty():
			count += 1
		else: unit.in_pof = false
	if is_player_controlled: Global.player_units_to_move = count
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
		current_unit.toggle_skill_ui(true, get_usable_skills(current_unit))
	skill_chosen = null
	current_unit.toggle_outline(true)
	connect_current_unit_signals()
	EventBus.tutorial_trigger.emit("unit_selected")
	
func deselect_current_unit():
	if current_unit == null:
		return
	# Set modulate before deselecting
	if current_unit.actions_avail.is_empty() and current_unit.modulate == Color.WHITE:
		current_unit.set_unit_modulate(Color.DARK_GRAY)
	
	current_unit.toggle_skill_ui(false, [])
	current_unit.selected = false
	current_unit.toggle_outline(false)
	current_unit = null
	is_waiting_unit_selection = true
	skill_chosen = null
	EventBus.emit_signal("remove_cell_highlights", name)
	HintManager.hide_hint("")
	unit_moving = false
	
	# set targetted units anim back to normal
	for unit in targetted_units:
		unit.set_targetted_anim(false)
	targetted_units.clear()
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

func estimate_damage(attacker: Unit, skill: SkillInfo, damage: float = 1, stats_bonus: Array[BonusStat] = []) -> int:
	var bonuses = 0
	if skill.affinity == 0:
		for buff in stats_bonus:
			if buff.stat == "attack_power": bonuses += buff.value
	else:
		for buff in stats_bonus:
			if buff.stat == "magic_power": bonuses += buff.value
	
	var attack_power = 0
	if skill.affinity == 0:
		attack_power = (attacker.attack_power + bonuses) * damage
	else: attack_power = (attacker.magic_power + bonuses) * damage
	
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
	return state

## Helper function that returns a state after simulating the outcome of an action #TODO: set up tile info parameter
func simulate_action(state: GameState, unit: Unit, target_cell: Vector2i, action_type: Unit.Action, skill: SkillInfo = null) -> GameState:
	var new_state := GameState.new()
	new_state.position = state.position.duplicate(true)
	new_state.health = state.health.duplicate(true)
	new_state.stat_bonuses = state.stat_bonuses.duplicate(true)
	new_state.cell_effects = state.cell_effects.duplicate(true)
	new_state.status_effects = state.status_effects.duplicate(true)
	new_state.action_tokens = state.action_tokens.duplicate()
	new_state.pof_states = state.pof_states.duplicate()
	
	# Scans each unit and evaluate score based on their position to each other and to other tiles
	if action_type == Unit.Action.MOVE:
		new_state.position[unit] = target_cell
		if new_state.cell_effects[target_cell] == "teleport":
			new_state.position[unit] = new_state.find_another_cell_of_effect(target_cell, "teleport")
		new_state.action_tokens[unit].erase(Unit.Action.MOVE)
	if action_type == Unit.Action.ATTACK:
		if skill == null:
			return new_state
		new_state.action_tokens[unit].erase(Unit.Action.ATTACK)
		#Go through all of the skill's effect
		var effects := skill.skill_effects
		var affected_area := HexNavi.get_all_neighbors_in_range(target_cell, abs(skill.area), 999)
		
		# change affected unit's pof_receive status
		for target in new_state.position.keys():
			if affected_area.has(new_state.position[target]) and target.container != unit.container:
				if new_state.pof_states[target] == Unit.POF_RECEIVE_STATE.NONE:
					new_state.pof_states[target] = Unit.POF_RECEIVE_STATE.READY
				elif new_state.pof_states[target] == Unit.POF_RECEIVE_STATE.READY:
					new_state.pof_states[target] = Unit.POF_RECEIVE_STATE.TRIGGERED
		
		for key in effects.keys():
			match key:
				SkillInfo.EffectType.DAMAGE:
					var damage = estimate_damage(unit, skill, effects[key], new_state.stat_bonuses[unit])
					for victim in new_state.position.keys():
						if affected_area.has(new_state.position[victim]):
							new_state.health[victim] -= damage
				SkillInfo.EffectType.KNOCKBACK:
					var displacement := estimate_knockback(unit, target_cell, skill, effects[key])
					for victim in displacement.keys():
						new_state.position[victim] = displacement[victim]
				SkillInfo.EffectType.HEAL:
					var healing = estimate_damage(unit, skill, effects[key])
					for healed in new_state.position.keys():
						if affected_area.has(new_state.position[healed]):
							new_state.health[healed] = min(new_state.health[healed] + healing, healed.max_health)
				SkillInfo.EffectType.BUFF, SkillInfo.EffectType.DEBUFF:
					for buffed in new_state.position.keys():
						if affected_area.has(new_state.position[buffed]):
							if not new_state.stat_bonuses.has(buffed):
								new_state.stat_bonuses[buffed] = []
							var bonus: BonusStat = load(effects[key]) as BonusStat  # Assume this is a BonusStat object
							new_state.stat_bonuses[buffed].append(bonus)
				SkillInfo.EffectType.SET_TILE:
					match effects[key]:
						"death":
							new_state.cell_effects[target_cell] = "death"
						"heal":
							new_state.cell_effects[target_cell] = "heal"
						"spike":
							new_state.cell_effects[target_cell] = "spike"
						_:
							pass
				SkillInfo.EffectType.STATUS:
					for affected in new_state.position.keys():
						if affected_area.has(new_state.position[affected]):
							if effects[key] and effects[key] is StatusEffect:
								new_state.status_effects[affected] = effects[key]
							else:
								new_state.status_effects.erase(affected)
				SkillInfo.EffectType.DISPLACE:
					match effects[key]:
						2: 
							var displace_origin: Vector2i = new_state.position[unit]
							if abs(skill.area) > 0:
								displace_origin = target_cell
							for affected in new_state.position.keys():
								if affected_area.has(new_state.position[affected]):
									new_state.position[affected] = displace_origin
						3:
							new_state.position[unit] = target_cell
				SkillInfo.EffectType.ACTION_TOKEN:
					match effects[key]:
						Unit.Action.MOVE:
							new_state.action_tokens[unit].append(Unit.Action.MOVE)
						Unit.Action.ATTACK:
							new_state.action_tokens[unit].append(Unit.Action.ATTACK)
				SkillInfo.EffectType.SELF_BUFF:
					var bonus: BonusStat = load(effects[key]) as BonusStat  # Assume this is a BonusStat object
					new_state.stat_bonuses[unit].append(bonus)
				SkillInfo.EffectType.SELF_HEAL:
					var healing = estimate_damage(unit, skill, effects[key])
					new_state.health[unit] += healing
	
	return new_state

func evaluate_state(state: GameState) -> int:
	var dist_score = 0
	var damage_score = 0
	var tile_score = 0
	var buff_score = 0
	var status_score = 0
	var token_score = 0
	var pof_score = 0
	var score = 0
	
	for unit in state.position.keys():
		if !is_instance_valid(unit):
			continue
		
		# Distance related score
		var enemy := get_closest_enemy(unit)
		var distance_score = 0
		if is_instance_valid(enemy):
			# encourages unit to move close to enemies if have the attack token OR if they have damage reduction
			if unit.actions_avail.has(Unit.Action.ATTACK) or unit.damage_reduction > 0:
				distance_score = (unit.cell - enemy.cell).length() - (state.position[unit] - enemy.cell).length()*2
			# else if the unit health is too low and no attack token, encourage them to move away
			elif state.health[unit] <= unit.max_health / 3 and not unit.actions_avail.has(Unit.Action.ATTACK):
				distance_score = (state.position[unit] - enemy.cell).length() - (unit.cell - enemy.cell).length()
		# if nothing else, still encourages to move in (by a moderate amount)
			else: distance_score = (unit.cell - enemy.cell).length() - (state.position[unit] - enemy.cell).length()
			
			#clamping distance score
			distance_score = clamp(distance_score, -5, 5)
			
			if enemy_container.units.has(unit):
				dist_score -= distance_score
			else:
				dist_score += distance_score
		
		# HP related score
		const LOW_HEALTH_BONUS = 50
		var enemy_damage_map := {}
		if enemy_container.units.has(unit):
			# encourages dealing the killing blow
			if state.health[unit] <= 0:
				damage_score += 40
			else:
				# calculates score based on damage dealth
				damage_score += (unit.health - state.health[unit]) * 4
		else:
			# avoid hurting teammates (just a bit)
			damage_score -= (unit.health - state.health[unit])
		
		# cell effect related score
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
			# check if the units are standing on special tiles
			match effect:
				"death":
					# encourages pushing enemies into pits
					if enemy_container.units.has(unit): 
						if cell == state.position[unit]:
							tile_score += 40
					else: # avoids hitting teammates into the pits
						if cell == state.position[unit]:
							tile_score -= 30
				"heal":
					# encourages standing inside healing tiles and keeping enemies away from the healing
					if enemy_container.units.has(unit): 
						if cell == state.position[unit]:
							tile_score -= 10
					else:
						if cell == state.position[unit]:
							tile_score += 15
				"spike":
					if enemy_container.units.has(unit): 
						if cell == state.position[unit]:
							tile_score += 5
					else:
						if cell == state.position[unit]:
							tile_score -= 7
				_:
					tile_score += 0

	## Buff/Debuff Related Score
	const ENEMY_BUFF_PENALTY = 5
	const ALLY_BUFF_PENALTY = 5
	const MAX_REASONABLE_BUFF_COUNT = 1
	for unit in state.stat_bonuses.keys():
		var buffs = state.stat_bonuses[unit]
		for buff in buffs:
			# Already takes into account of buffs or debuffs
			# encourages buffing allies and debuffing enemies
			if enemy_container.units.has(unit):
				buff_score -= buff.value * ENEMY_BUFF_PENALTY
			else:
				buff_score += buff.value * ALLY_BUFF_PENALTY
	
	## Status effect related score
	# generally, all status effects should have roughly the same score at base power * duration
	const SLEEP_MULTIPLIER = 15
	const POISON_MULTIPLIER = 6
	const FORGET_MULTIPLER = 10
	const AUDIT_MULTIPLIER = 20
	const OTHER_MULTIPLIER = 10
	for unit in state.status_effects.keys():
		var effect = state.status_effects[unit]
		var multiplier: int = 1
		match effect.type:
			StatusEffect.Effect.SLEEP:
				multiplier = SLEEP_MULTIPLIER
			StatusEffect.Effect.POISON:
				multiplier = POISON_MULTIPLIER
			StatusEffect.Effect.FORGET:
				multiplier = FORGET_MULTIPLER
			StatusEffect.Effect.AUDITTED:
				multiplier = AUDIT_MULTIPLIER
			_:
				multiplier = OTHER_MULTIPLIER
		if enemy_container.units.has(unit):
			status_score += effect.duration * multiplier
	
	## Token related score
	const ATTACK_TOKEN_MULTIPLIER = 20
	const MOVE_TOKEN_MULTIPLER = 10
	const BASE_TOKEN_COUNT = 1
	# gives points if unit has extra move/attack tokens
	for unit in state.action_tokens.keys():
		var unit_token_score = 0
		var unit_move_count: int = state.action_tokens[unit].count(Unit.Action.MOVE)
		if unit_move_count > BASE_TOKEN_COUNT:
			unit_token_score += (unit_move_count - BASE_TOKEN_COUNT) * MOVE_TOKEN_MULTIPLER
		var unit_atk_count: int = state.action_tokens[unit].count(Unit.Action.ATTACK)
		if unit_atk_count > BASE_TOKEN_COUNT:
			unit_token_score += (unit_atk_count - BASE_TOKEN_COUNT) * MOVE_TOKEN_MULTIPLER
		if enemy_container.units.has(unit):
			unit_token_score = -unit_token_score
		token_score += unit_token_score
		
	## POF related score
	const READY_BONUS = 5
	const TRIGGERED_BONUS = 20
	for unit in state.pof_states.keys():
		if state.pof_states[unit] == Unit.POF_RECEIVE_STATE.READY:
			pof_score += READY_BONUS
		elif state.pof_states[unit] == Unit.POF_RECEIVE_STATE.TRIGGERED:
			pof_score += TRIGGERED_BONUS
	
	score = dist_score + damage_score + tile_score + buff_score + status_score + token_score + pof_score
	#print("final score is %d, with distance: %d, damage: %d, tile: %d, buff: %d, status: %d, pof: %d" %[score, dist_score, damage_score, tile_score, buff_score, status_score, pof_score])
	return score

## NPC movement and action logic; assumes that [member current_unit] is not [code]null[/code]
func unit_action(skill: SkillInfo, target_cell: Vector2i):
	print("action ", target_cell)
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
		EventBus.emit_signal("show_cell_highlights", outbound_array, CellHighlight.ATTACK_HIGHLIGHT, name)
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
	var best_skill: SkillInfo = MOVE_SKILL
	var best_state: GameState = current_state
	
	# Test for move and attack
	if unit.actions_avail.has(Unit.Action.MOVE) and unit.actions_avail.has(Unit.Action.ATTACK):
		for move_cell in get_actionnable_cells(unit, Unit.Action.MOVE):
			var moved_state = simulate_action(current_state, unit, move_cell, Unit.Action.MOVE)
			for skill in valid_skills:
				for attack_cell in get_actionnable_cells(unit, Unit.Action.ATTACK, skill, move_cell):
					var final_state = simulate_action(moved_state, unit, attack_cell, Unit.Action.ATTACK, skill)
					var combo_score = evaluate_state(final_state)
					if combo_score > best_score:
						best_score = combo_score
						best_cell = move_cell
						best_skill = MOVE_SKILL
						best_state = final_state
	
	# Test for attack and move
	if unit.actions_avail.has(Unit.Action.MOVE) and unit.actions_avail.has(Unit.Action.ATTACK):
		for skill in valid_skills:
			for attack_cell in get_actionnable_cells(unit, Unit.Action.ATTACK, skill):
				var attacked_state = simulate_action(current_state, unit, attack_cell, Unit.Action.ATTACK, skill)
				for move_cell in get_actionnable_cells(unit, Unit.Action.MOVE):
					var final_state = simulate_action(attacked_state, unit, move_cell, Unit.Action.MOVE)
					var combo_score = evaluate_state(final_state)
					if combo_score > best_score:
						best_score = combo_score
						best_cell = attack_cell
						best_skill = skill
						best_state = final_state
	
	# Test for only attacking
	if unit.actions_avail.has(Unit.Action.ATTACK):
		for skill in valid_skills:
			var actionnable_cells := get_actionnable_cells(unit, Unit.Action.ATTACK, skill)
			for cell in actionnable_cells:
				var new_state := simulate_action(current_state, unit, cell, Unit.Action.ATTACK, skill)
				var score = evaluate_state(new_state)
				print("Score of " + str(skill.name) + ": " + str(score))
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
				best_skill = MOVE_SKILL
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
	# Safeguar condition
	if !in_battle:
		push_warning("Enemy turn called even when it's not in battle! Something's wrong w the code... -- UnitContainer.gd")
		return
	if get_available_unit_count() <= 0:
		all_unit_moved_func()
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
		await get_tree().create_timer(0.75).timeout
		if current_unit != null:
			unit_action(best_skill, best_cell)
			await unit_action_done
			await get_tree().create_timer(0.75).timeout
			_step_enemy()
		return
	else:
		print("No valid sequence found.")
		all_unit_moved_func()
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
	if !in_battle:
		if event is InputEventMouseButton and event.is_pressed():
			if event.button_index in [MOUSE_BUTTON_LEFT, MOUSE_BUTTON_RIGHT]:
				EventBus.clear_preview.emit()
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
		if event.button_index in [MOUSE_BUTTON_RIGHT]:
			deselect_current_unit()
		if event.button_index in [MOUSE_BUTTON_LEFT, MOUSE_BUTTON_RIGHT]:
			EventBus.clear_preview.emit()
			HintManager.reset_idle_timer()
		if event.button_index == MOUSE_BUTTON_LEFT:
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
					HintManager.hide_hint("level_1_intro")
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
			
			#TODO: Make it so that if a skill is chosen the unit can't move when click on a blue cell?
			if action_type == Unit.Action.MOVE:
				# only moves the unit if no skill is chosen AND player has chosen the "Move" action
				if !unit_moving:
					deselect_current_unit()
					return
				check_and_remove_unit_from_being_held(current_unit)
				
				AudioPreload.play_sfx("confirm")
				
				var full_path = HexNavi.get_navi_path(current_unit.cell, clicked_cell)
				current_unit.move_along_path(full_path)
				in_progress = true
				await current_unit.movement_complete
				deselect_current_unit()
				in_progress = false
			
			if action_type == Unit.Action.ATTACK: #assumes that skill_chosen is not null
				if !skill_chosen:
					in_progress = false
					deselect_current_unit()
					return
				HintManager.hide_hint("skill_selected")
				
				AudioPreload.play_sfx("confirm")
				
				var outbound_array: Array[Vector2i] = [clicked_cell]
				outbound_array.append_array(HexNavi.get_all_neighbors_in_range(clicked_cell, abs(skill_chosen.area), 999))
				# highlight target cells
				EventBus.emit_signal("show_cell_highlights", outbound_array, CellHighlight.ATTACK_HIGHLIGHT, name)
				current_unit.take_action(skill_chosen, clicked_cell)
				#print("# Awaiting attack point (UnitContainer.gd)")
				in_progress = true
				await current_unit.attack_point
				if Global.attack_successful:
					EventBus.emit_signal("attack_used", skill_chosen, current_unit, outbound_array)
				else:
					current_unit.unit_held.map(check_and_remove_unit_from_being_held)
					EventBus.emit_signal("attack_used", WAIT_SKILL, current_unit, outbound_array)
				await current_unit.all_complete
				in_progress = false
				deselect_current_unit()
			
			if get_available_unit_count() <= 0:
				all_unit_moved_func()
			

func highlight_handle():
	EventBus.emit_signal("remove_cell_highlights", name)
	for ac in current_unit.actions_avail:
		match ac:
			Unit.Action.MOVE:
				# Only shows movement highlight if no skill is chosen
				if skill_chosen == null:
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
				else:
					# set the no plz animation for targetted enemies
					for unit in enemy_container.units:
						if unit.cell in all_targets:
							targetted_units.append(unit)
							unit.set_targetted_anim(true)
						
				if abs(skill_chosen.area) > 0:
					EventBus.emit_signal("show_cell_highlights", all_targets, CellHighlight.ATTACK_PREVIEW_HIGHLIGHT, name)
				else:
					EventBus.emit_signal("show_cell_highlights", all_targets, CellHighlight.ATTACK_HIGHLIGHT, name)
			_:
				pass

func get_actionnable_cells(this_unit: Unit, action_type: Unit.Action, skill: SkillInfo = null, from_cell: Vector2i = Vector2i.MIN) -> Array[Vector2i]:
	if from_cell == Vector2i.MIN: from_cell = this_unit.cell
	var tiles: Array[Vector2i] = []
	match action_type:
		Unit.Action.MOVE:
			var all_neighbors := HexNavi.get_all_neighbors_in_range(from_cell, this_unit.movement_range)
			
			var ally_cell: Array[Vector2i] = []
			for ally in units:
				ally_cell.append(ally.cell)
				
			var enemy_cell: Array[Vector2i] = []
			enemy_container.units.map(
				func(unit: Unit):
					if unit != null: enemy_cell.append(unit.cell)
			)
			for neighbor in all_neighbors:
				if HexNavi.get_cell_custom_data(neighbor, "traversable") and neighbor != from_cell and !(neighbor in ally_cell) and !(neighbor in enemy_cell): #only actionnable if tile not occupied
					tiles.append(neighbor)
		Unit.Action.ATTACK:
			if skill == null:
				return []
			var targets = HexNavi.get_all_neighbors_in_range(from_cell, skill.range, 999)
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
		current_actionnable_cells[Unit.Action.ATTACK] = get_actionnable_cells(unit, Unit.Action.ATTACK, WAIT_SKILL)
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
	
func _on_unit_died(unit: Unit):
	refresh_units()

func _on_skill_chosen(skill: SkillInfo):
	current_unit.toggle_skill_ui(false, [])
	skill_chosen = skill
	if skill_chosen.name == "Wait":
		unit_wait()
		return
	if skill_chosen.name == "Move":
		unit_moving = true
		return
	else:
		unit_moving = false
	if abs(skill_chosen.area) > 0:
		is_aoe_skill = true
	else: is_aoe_skill = false
	highlight_handle()
	update_actionnable_cells(current_unit, skill_chosen)
	HintManager.trigger_hint("skill_selected", "Select a target", false)
	
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
		all_unit_moved_func()

func _on_turn_passed():
	if !is_player_controlled or in_progress:
		return
	#Remove all tokens
	if get_available_unit_count() > 0:
		units.map(
			func(unit: Unit):
				unit.actions_avail.clear()
		)
		all_unit_moved_func()
	
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

## Returns an array of skills that can be used at a given unit's cell
func get_usable_skills(unit: Unit):
	var usable_skills: Array[SkillInfo] = []
	for skill in unit.skills:
		var range = HexNavi.get_all_neighbors_in_range(unit.cell, skill.range, 999)
		var valid_targets = get_targets_of_type(range, skill.targets, unit)
		if valid_targets.size() > 0:
			usable_skills.append(skill)
	return usable_skills

func all_unit_moved_func():
	if turn_ended: # prevents this func being called twice
		return
	await get_tree().create_timer(0.25).timeout
	for unit in units:
		unit.turn_end_actions()
	all_units_moved.emit()
	turn_ended = true

func _on_cancel_button_pressed():
	deselect_current_unit()
