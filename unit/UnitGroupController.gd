extends Node2D

class_name UnitGroupController

signal attack_complete
signal status_update_complete
signal switch_turn(is_player: bool)

@export var player_goes_first : bool = true

@onready var player_group: UnitContainer = $PlayerGroup
@onready var enemy_group: UnitContainer = $EnemyGroup

var is_player_turn : bool = true
var all_units: Array[Unit] = []
var occupied_cells: Dictionary = {}
var attack_processing: bool = false
var is_waiting_for_turn_switch: bool = false
var is_battle_over: bool = false

var turn_attack_log: Dictionary[Unit, Array] = {} #Key: Unit (target), value: Array[Unit] (attackers)
var pof_triggered_on: Array[Unit] = []

func _ready():
	EventBus.connect("update_cell_status", _on_update_cell_status)
	EventBus.connect("attack_used", _on_attack_used)
	EventBus.connect("unit_died", _on_unit_died)
	
func init():
	connect_container_signal(player_group)
	connect_container_signal(enemy_group)
	player_group.init()
	enemy_group.init()
	all_units.append_array(player_group.units)
	all_units.append_array(enemy_group.units)
	
	# assign unit id
	for id in all_units.size():
		all_units[id].unit_id = id

	_on_update_cell_status(true)

func battle_start():
	is_player_turn = player_goes_first
	if is_player_turn:
		player_group.round_start()
	else: enemy_group.round_start()
	
func connect_container_signal(unit_group : UnitContainer):
	unit_group.connect("all_units_moved", _on_unit_container_all_moved)
	
func _on_unit_container_all_moved():
	if !Global.is_attack_resolved:
		await attack_complete
	var should_cont: bool =  check_if_win()
	if should_cont:
		is_waiting_for_turn_switch = true
		_on_update_cell_status(true)
	else:
		# if the level should end, disable all children processing to prevent bugs
		for child in get_children():
			child.process_mode = Node.PROCESS_MODE_DISABLED
	
func _on_status_update_complete():
	if is_waiting_for_turn_switch:
		is_waiting_for_turn_switch = false
		is_player_turn = !is_player_turn
		Global.isPlayerTurn = is_player_turn
		await round_end_actions()
		if is_player_turn:
			switch_turn.emit(true)
		else:
			switch_turn.emit(false)

## Called by Level.gd to start next turn
func start_next_turn():
	turn_attack_log.clear()
	pof_triggered_on.clear()
	for unit in all_units:
		unit.set_pof_icon_state("none")
	
	if is_player_turn:
		player_group.round_start()
		Global.battle_log.append("Player's Turn")
	else:
		enemy_group.round_start()
		Global.battle_log.append("Enemy's Turn")

func _on_attack_used(attack: SkillInfo, attacker: Unit, targets: Array[Vector2i]):
	Global.is_attack_resolved = false
	print("# " + str(attacker.name) + " USED: " + str(attack.name) + " (UnitGroupController.gd)")
	
	#get effect multiplier based on affinity
	var attacker_power = 1
	if attack.affinity == 0:
		attacker_power = attacker.attack_power
	elif attack.affinity == 1:
		attacker_power = attacker.magic_power
	
	#get all target units
	var affected_units: Array[Unit] = []
	for unit in all_units:
		if targets.has(unit.cell):
			if attack.area < 0 and unit.cell == attacker.cell: #if the skill should exclude origin
				pass
			else:
				affected_units.append(unit)

	# Log victims and attackers (only triggers if the attacker's team has more than 1 unit)
	if attacker.container.units.size() > 1:
		affected_units.map(
			func(victim: Unit):
				if victim.is_player_controlled != attacker.is_player_controlled:
					log_attack(victim, attacker)
		)
		
	# use for loop here and break at the first trigger since we only want one PoF trigger per attack
	for victim in affected_units:
		if try_trigger_pof(victim, attacker):
			break
			
			
	var move_suffix : Array[String] = []

	#for each skill effect, apply it on every affected units
	var effects := attack.skill_effects
	var execution_order: Array = attack.effect_execution_order if !attack.effect_execution_order.is_empty() else effects.keys()
	for key in execution_order: 
		match key: #Skill effect translator
			SkillInfo.EffectType.DAMAGE:
				var damage : int = 0
				if affected_units.is_empty(): break
				for unit in affected_units:
					damage = floor((effects[key] * attacker_power) * (1-unit.damage_reduction))
					unit.take_damage(damage, attacker, false)
				move_suffix.append("dealing " + str(damage) + " damage")
				
			SkillInfo.EffectType.KNOCKBACK:
				if affected_units.is_empty(): break
				
				#treats the first target as the knockback origin if it's an AOE knockback
				var knockback_origin: Vector2 = attacker.global_position
				if abs(attack.area) > 0:
					knockback_origin = HexNavi.cell_to_global(targets.front())
					
				var move_tween = get_tree().create_tween().set_parallel()
				move_tween.set_ease(Tween.EASE_OUT)
				move_tween.set_trans(Tween.TRANS_CUBIC)
				affected_units.map(
					func(unit : Unit): #NOTICE: Use global position directly here since hex grid coords is less intuitive
						#calculate the direction of knockback
						var dir: Vector2 = HexNavi.cell_to_global(unit.cell) - knockback_origin
						# get all (if any) knockback modifiers
						var knockback_multiplier: float = 1
						var knockback_increment: int = 0
						## If unit has the unsteady status effect
						if unit.active_status_effect != null:
							if unit.active_status_effect.type == StatusEffect.Effect.UNSTEADY:
								knockback_increment += 1
						#apply the direction by strength of knockback
						var new_location: Vector2 = unit.global_position + dir*effects[key]*knockback_multiplier + dir*knockback_increment 
						if HexNavi.global_to_cell(new_location) == Vector2i(-999, -999): ## pretends there's a wall
							new_location = HexNavi.cell_to_global(HexNavi.get_closest_cell_by_global_pos(new_location))
						move_tween.tween_property(
							unit,
							'global_position',
							new_location,
							0.5
						)
						#Snap the unit to the cell if necessary (no need now)
				)
				await move_tween.finished
				affected_units.map(
					func(unit):
						if unit == null:
							return
						unit.cell = HexNavi.global_to_cell(unit.global_position)
						await unit.tile_action()
				)
				move_suffix.append("knocking them back")
				
			SkillInfo.EffectType.HEAL:
				affected_units.map(
					func(unit : Unit):
							unit.regain_health(effects[key] * attacker_power)
						#TODO: needs animation
				)
				move_suffix.append("healing them by " + str(effects[key] * attacker_power))
			
			SkillInfo.EffectType.WAIT:
				attacker.actions_avail.erase(Unit.Action.MOVE)
				attacker.actions_avail.erase(Unit.Action.ATTACK)
			
			SkillInfo.EffectType.DISPLACE:
				match effects[key]:
					0: #displace to attacker position (pick up)
						var v_offset: int = -30
						var a = get_tree().create_tween().set_parallel().set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_QUINT)
						affected_units.map(
							func(unit : Unit): #TODO: Handle holding multiple units properly
								a.tween_property(unit, 'global_position', attacker.global_position + Vector2(0, v_offset*(attacker.unit_held.size()+1)), 0.3)
								unit.cell = attacker.cell
								unit.animation_state("thrown")
								unit.is_held = true
						)
						await a.finished
						attacker.unit_held.append_array(affected_units)
						attacker.actions_avail.append(Unit.Action.ATTACK) #give back attack token
						
					1: #displace linearly target location (throw)
						var projectiles = attacker.unit_held
						var a = get_tree().create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUINT).set_parallel()
						for projectile in projectiles:
							a.tween_property(projectile, "global_position", HexNavi.cell_to_global(targets.front()), 0.3) 
						await a.finished
						for projectile in projectiles:
							projectile.is_held = false
							projectile.animation_state("side_idle")
							projectile.cell = targets.front()
						attacker.unit_held.clear()
						#print("shooting complete")
					2: #displace to target location (blackhole)
						if affected_units.is_empty(): break
						var displace_origin: Vector2 = attacker.global_position
						if abs(attack.area) > 0:
							displace_origin = HexNavi.cell_to_global(targets.front())

						var a = get_tree().create_tween().set_parallel().set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUINT)
						affected_units.map(
							func(unit : Unit):
								a.tween_property(unit, 'global_position', displace_origin, 0.4)
								unit.cell = HexNavi.global_to_cell(displace_origin)
						)
						await a.finished
					3: # attacker displace to target location (teleport-like effect)
						var displace_origin: Vector2 = Vector2.ZERO
						displace_origin = HexNavi.cell_to_global(targets.front())
						var a = get_tree().create_tween().set_parallel().set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUINT)
						a.tween_property(attacker, 'global_position', displace_origin, 0.4)
						attacker.cell = HexNavi.global_to_cell(displace_origin)
						await a.finished
					_:
						print("nothing to displace yet")
				attacker.check_if_can_throw()
			SkillInfo.EffectType.SET_TILE:
				match effects[key]:
					"death":
						for tile in targets:
							EventBus.emit_signal("set_cell", tile, MyMapLayer.CELL_TYPE.PIT)
						await EventBus.set_cell_done
					"heal":
						for tile in targets:
							EventBus.emit_signal("set_cell", tile, MyMapLayer.CELL_TYPE.HEAL)
						await EventBus.set_cell_done
					"spike":
						for tile in targets:
							EventBus.emit_signal("set_cell", tile, MyMapLayer.CELL_TYPE.SPIKE)
						# no need to wait as there are no animation
				move_suffix.append("setting the tile to " + str(effects[key]))
					
			SkillInfo.EffectType.BUFF, SkillInfo.EffectType.DEBUFF:
				var buff = load(effects[key])
				if buff is BonusStat:
					for unit in affected_units:
						unit.apply_stat_modifer(buff)
				else:
					print(buff.name + " of " + attack.name + " is not a BonusStat! -- UnitGroupContainer.gd")
				match buff.stat:
					"max_health":
						if buff.value > 0:
							move_suffix.append("boosting their max health by " + str(buff.value))
						elif buff.value < 0:
							move_suffix.append("reducing their max health by " + str(buff.value))
						else:
							print("Stat buff/debuff is zero")
					"attack_power":
						if buff.value > 0:
							move_suffix.append("boosting their attack power by " + str(buff.value))
						elif buff.value < 0:
							move_suffix.append("reducing their attack power by " + str(buff.value))
						else:
							print("Stat buff/debuff is zero")
					"magic_power":
						if buff.value > 0:
							move_suffix.append("boosting their magic power by " + str(buff.value))
						elif buff.value < 0:
							move_suffix.append("reducing their magic power by " + str(buff.value))
						else:
							print("Stat buff/debuff is zero")
					"movement_range":
						if buff.value > 0:
							move_suffix.append("boosting their movement range by " + str(buff.value))
						elif buff.value < 0:
							move_suffix.append("reducing their movement range by " + str(buff.value))
						else:
							print("Stat buff/debuff is zero")
					"damage_reduction":
						if buff.value > 0:
							move_suffix.append("boosting their damage by " + str(buff.value))
						elif buff.value < 0:
							move_suffix.append("reducing their damage by " + str(buff.value))
						else:
							print("Stat buff/debuff is zero")
				#@export_enum("max_health", "attack_power", "magic_power", "movement_range", "damage_reduction")
			SkillInfo.EffectType.STATUS:
				if effects[key] is StatusEffect:
					for unit in affected_units:
						unit.apply_status(effects[key])
						move_suffix.append("applying " + effects[key].name)
				elif effects[key] == null:
					for unit in affected_units:
						unit.remove_status_effect()
					move_suffix.append("removing their status effects")
				else:
					print(effects[key].name + " of " + attack.name + " is not a StatusEffect! -- UnitGroupContainer.gd")
			# exclusively for attacker gaining token
			SkillInfo.EffectType.ACTION_TOKEN:
				match effects[key]:
					Unit.Action.MOVE:
						attacker.actions_avail.append(Unit.Action.MOVE)
					Unit.Action.ATTACK:
						attacker.actions_avail.append(Unit.Action.ATTACK)
			SkillInfo.EffectType.SELF_BUFF:
				var buff = load(effects[key])
				if buff is BonusStat:
					attacker.apply_stat_modifer(buff)
				match buff.stat:
					"max_health":
						if buff.value > 0:
							move_suffix.append("boosting their max health by " + str(buff.value))
						elif buff.value < 0:
							move_suffix.append("reducing their max health by " + str(buff.value))
						else:
							print("Stat buff/debuff is zero")
					"attack_power":
						if buff.value > 0:
							move_suffix.append("boosting their attack power by " + str(buff.value))
						elif buff.value < 0:
							move_suffix.append("reducing their attack power by " + str(buff.value))
						else:
							print("Stat buff/debuff is zero")
					"magic_power":
						if buff.value > 0:
							move_suffix.append("boosting their magic power by " + str(buff.value))
						elif buff.value < 0:
							move_suffix.append("reducing their magic power by " + str(buff.value))
						else:
							print("Stat buff/debuff is zero")
					"movement_range":
						if buff.value > 0:
							move_suffix.append("boosting their movement range by " + str(buff.value))
						elif buff.value < 0:
							move_suffix.append("reducing their movement range by " + str(buff.value))
						else:
							print("Stat buff/debuff is zero")
					"damage_reduction":
						if buff.value > 0:
							move_suffix.append("boosting their damage by " + str(buff.value))
						elif buff.value < 0:
							move_suffix.append("reducing their damage by " + str(buff.value))
						else:
							print("Stat buff/debuff is zero")
			SkillInfo.EffectType.SELF_HEAL:
				attacker.regain_health(effects[key] * attacker_power)
				move_suffix.append("healing them by " + str(effects[key] * attacker_power))
			_:
				print("nothing happens yet")
	
	process_battle_log(attacker, affected_units, attack, move_suffix)
				
	if !all_units.is_empty():
		all_units.map(
			func(unit : Unit): 
				unit.check_if_dead()
		)
	
	_on_update_cell_status(true)
	Global.is_attack_resolved = true
	attack_complete.emit()
	

func _on_update_cell_status(stacking: bool): #scan all units and update cell color accordingly
	all_units = []
	occupied_cells = {}
	EventBus.emit_signal("clear_cells")
	player_group.refresh_units()
	enemy_group.refresh_units()
	all_units.append_array(player_group.units)
	all_units.append_array(enemy_group.units)
			#print("signal received")
	
	for unit in player_group.units:
		if !occupied_cells.has(unit.cell):
			occupied_cells[unit.cell] = []
		occupied_cells[unit.cell].append(unit)
		if HexNavi.get_cell_custom_data(unit.cell, "effect") == "":
			EventBus.emit_signal("occupy_cell", unit.cell, "player")
	for unit in enemy_group.units:
		if !occupied_cells.has(unit.cell):
			occupied_cells[unit.cell] = []
		occupied_cells[unit.cell].append(unit)
		if HexNavi.get_cell_custom_data(unit.cell, "effect") == "":
			EventBus.emit_signal("occupy_cell", unit.cell, "enemy")
	
	if stacking: #only stacks units if stacking is true
		#print("stacking")
		#adjusting position of units to accomodate for unit stacking
		
		for cell in occupied_cells.keys():
			if !occupied_cells.keys().has(cell):
				continue
			var displacement = 100/(occupied_cells[cell].size())
			var num_stacked = 0
			for unit: Unit in occupied_cells[cell]:
				if !unit.is_held:
					num_stacked += 1
					
			var displace_tween = get_tree().create_tween().set_parallel()
			displace_tween.set_ease(Tween.EASE_OUT)
			displace_tween.set_trans(Tween.TRANS_CUBIC)
				
			if num_stacked > 1:
				for i in range(occupied_cells[cell].size()):
					var unit = occupied_cells[cell][i]
					var vect = Vector2(displacement/2 + displacement*i-100/2, 0)
					
					displace_tween.tween_property(
									unit,
									'global_position',
									HexNavi.cell_to_global(cell) + vect,
									0.5
								)
				await displace_tween.finished
			else:
				occupied_cells[cell].map(
					func(unit: Unit):
						#for some reason keeping the tween time to 0.1 is very important in not causing visual bug
						if !unit.is_held: displace_tween.tween_property(unit, 'global_position', HexNavi.cell_to_global(cell), 0.1)
				)
	# Update status icon
	for unit in all_units:
		if unit in turn_attack_log.keys() and unit not in pof_triggered_on:
			unit.set_pof_icon_state("can_trigger")
		elif unit in pof_triggered_on:
			unit.set_pof_icon_state("already_triggered")
		else:
			unit.set_pof_icon_state("none")

	status_update_complete.emit()

func _on_unit_died(unit: Unit):
	if unit.is_player_controlled:
		Global.battle_log.append("[color=blue]" + unit.unit_data.unit_class + "[/color] has retreated from the battle.")
	else:
		Global.battle_log.append("[color=red]" + unit.unit_data.unit_class + "[/color] has retreated from the battle.")
	var should_cont := check_if_win()
	if !should_cont:
		# if the level should end, disable all children processing to prevent bugs
		for child in get_children():
			child.process_mode = Node.PROCESS_MODE_DISABLED
	else: _on_update_cell_status(true)

func check_if_win() -> bool:
	if is_battle_over:
		return false
	var win_flag: int = 0
	if player_group.units.size() <= 0:
		win_flag -=1
	if enemy_group.units.size() <= 0:
		win_flag += 2
	match win_flag:
		-1:	#Enemy won
			EventBus.emit_signal("battle_ended", EventBus.BattleResult.ENEMY_VICTORY)
			print("Enemy won!")
			is_battle_over = true
			return false
		0:	#no result
			print("no result yet")
			return true
		1:	#Tie
			EventBus.emit_signal("battle_ended", EventBus.BattleResult.TIE)
			print("It is a tie")
			is_battle_over = true
			return false
		2:	#Player won
			EventBus.emit_signal("battle_ended", EventBus.BattleResult.PLAYER_VICTORY)
			print("Player won!")
			is_battle_over = true
			return false
		_:
			print("winflag is " + str(win_flag) + ", which shouldn't happen. Something is wrong with UnitGroupController.gd!")
			return false

func round_end_actions():
	#examine the cells occupied by each unit and execute the cell passives
	for unit in all_units:
		var effect = HexNavi.get_cell_custom_data(unit.cell, "effect")
		var cell_effect: String = effect if effect is String else ""
		match cell_effect:
			_:
				continue

# For Power of Friendship mechanic

func log_attack(target: Unit, attacker: Unit):
	if !turn_attack_log.has(target):
		turn_attack_log[target] = []
	turn_attack_log[target].append(attacker)

func try_trigger_pof(target: Unit, attacker: Unit) -> bool:
	var result: bool = false
	if target in pof_triggered_on:
		return result
		
	var previous_attackers = turn_attack_log.get(target, [])
	for unit in previous_attackers:
		if unit.is_player_controlled == attacker.is_player_controlled and unit != attacker:
			AudioPreload.play_sfx("pof")
			grant_extra_turn(attacker)
			result = true
			pof_triggered_on.append(target)
			break
	return result

func grant_extra_turn(unit: Unit):
	if !unit.actions_avail.has(Unit.Action.MOVE):
		# only grants Move token if not inflicted with Forget
		if !unit.active_status_effect or unit.active_status_effect.type != StatusEffect.Effect.FORGET:
			unit.actions_avail.append(Unit.Action.MOVE)
	if !unit.actions_avail.has(Unit.Action.ATTACK):
		unit.actions_avail.append(Unit.Action.ATTACK)
	Global.play_label_slide_from_left("Power of Friendship!")
	unit.in_pof = true

func process_battle_log(attacker: Unit, affected_units: Array[Unit], attack: SkillInfo, suffix : Array[String]):
	print(attack)
	var affected_names_arr = []
	for i in affected_units:
		if i.is_player_controlled:
			affected_names_arr.append(str("[color=blue]", i.unit_data.unit_class, "[/color]"))
		else:
			affected_names_arr.append(str("[color=red]", i.unit_data.unit_class, "[/color]"))
			
	var affected_names = ", ".join(PackedStringArray(affected_names_arr))
	
	var target_color = ""
	if attacker.is_player_controlled: target_color = "blue"
	else: target_color = "red"
	
	var log_entry = "[color=" + target_color + "]" + attacker.unit_data.unit_class + "[/color] used " + attack.name + " on " + affected_names
	
	if affected_units.size() == 1 and affected_units.front() == attacker:
		log_entry = affected_names_arr[0] + " used " + attack.name + " on themselves"
	
	if suffix.size() > 0:
		if suffix.size() == 1:
			log_entry += ", " + suffix[0] + "!"
		else:
			var last_effect = suffix.pop_back()
			log_entry += ", " + ", ".join(PackedStringArray(suffix)) + " and " + last_effect + "!"
	else:
		log_entry += "!"

	Global.battle_log.append(log_entry)
