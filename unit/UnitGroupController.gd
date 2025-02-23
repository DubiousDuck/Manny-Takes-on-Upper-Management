extends Node2D

class_name UnitGroupController

signal effect_complete
signal status_update_complete

@export var player_goes_first : bool = true

@onready var player_group: UnitContainer = $PlayerGroup
@onready var enemy_group: UnitContainer = $EnemyGroup

var is_player_turn : bool = true
var waiting
var all_units: Array[Unit] = []
var occupied_cells: Dictionary = {}
var is_waiting_for_turn_switch: bool = false

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
	_on_update_cell_status(true)
	
	is_player_turn = player_goes_first
	if is_player_turn:
		player_group.round_start()
	else: enemy_group.round_start()
	
func connect_container_signal(unit_group : UnitContainer):
	unit_group.connect("all_units_moved", _on_unit_container_all_moved)
	
func _on_unit_container_all_moved():
	check_if_win()
	is_waiting_for_turn_switch = true
	_on_update_cell_status(true)	
	
func _on_status_update_complete():
	if is_waiting_for_turn_switch:
		is_player_turn = !is_player_turn
		if is_player_turn:
			player_group.round_start()
			print("player's turn")
		else:
			enemy_group.round_start()
			print("enemy's turn")
		is_waiting_for_turn_switch = false

func _on_attack_used(attack: SkillInfo, attacker: Unit, targets: Array[Vector2i]):
	#print("# " + str(attacker.name) + " USED: " + str(attack.name) + " (UnitGroupController.gd)")
	
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
			affected_units.append(unit)
	#for each skill effect, apply it on every affected units
	for effect in attack.skill_effects: 
		match effect.x: #Skill effect translator
			SkillInfo.EffectType.DAMAGE:
				if affected_units.is_empty(): break
				
				affected_units.map(
					func(unit : Unit):
						unit.health -= floor((effect.y * attacker_power) * (1-unit.damage_reduction))
						if !unit.unit_held.is_empty():
							for held in unit.unit_held:
								held.is_held = false
						unit.unit_held.clear()
						unit.animation_state("hurt_initial")
				)
				
			SkillInfo.EffectType.KNOCKBACK:
				if affected_units.is_empty(): break
				
				#treats the first target as the knockback origin if it's an AOE knockback
				var knockback_origin: Vector2 = attacker.global_position
				if attack.area > 0:
					knockback_origin = HexNavi.cell_to_global(targets.front())
					
				var move_tween = get_tree().create_tween().set_parallel()
				move_tween.set_ease(Tween.EASE_OUT)
				move_tween.set_trans(Tween.TRANS_CUBIC)
				affected_units.map(
					func(unit : Unit): #NOTICE: Use global position directly here since hex grid coords is less intuitive
						#calculate the direction of knockback
						var dir: Vector2 = HexNavi.cell_to_global(unit.cell) - knockback_origin
						#apply the direction by strength of knockback
						var new_location: Vector2 = unit.global_position + dir*effect.y
						if HexNavi.global_to_cell(new_location) == Vector2i(-999, -999): ## pretends there's a wall
							new_location = HexNavi.cell_to_global(HexNavi.get_closest_cell_by_global_pos(new_location))
						move_tween.tween_property(
							unit,
							'global_position',
							new_location,
							0.5
						)
						unit.animation_state("hurt_initial")
						#Snap the unit to the cell if necessary (no need now)
				)
				await move_tween.finished
				affected_units.map(
					func(unit):
						if unit == null:
							return
						unit.cell = HexNavi.global_to_cell(unit.global_position)
				)
				# FIXME: when knockback is the last action before player turn ends, weird things happen
				
			SkillInfo.EffectType.HEAL:
				affected_units.map(
					func(unit : Unit):
						if unit.health + effect.y * attacker_power >= unit.max_health:
							unit.health = unit.max_health
						else:
							unit.health += (effect.y * attacker_power)
						#TODO: needs animation
				)
				
			SkillInfo.EffectType.DAMAGE_REDUCTION:
				affected_units.map(
					func(unit: Unit):
						unit.damage_reduction = 0.5
				)
			
			SkillInfo.EffectType.WAIT:
				attacker.actions_avail.erase(Unit.Action.MOVE)
				attacker.actions_avail.erase(Unit.Action.ATTACK)
			
			SkillInfo.EffectType.DISPLACE:
				match effect.y:
					0: #displace to attacker position (pick up)
						var v_offset: int = -30
						var a = get_tree().create_tween().set_parallel().set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_QUINT)
						affected_units.map(
							func(unit : Unit): #TODO: Handle holding multiple units properly
								a.tween_property(unit, 'global_position', attacker.global_position + Vector2(0, v_offset), 0.3)
								unit.cell = attacker.cell
								unit.animation_state("thrown")
								unit.is_held = true
						)
						await a.finished
						attacker.unit_held.append_array(affected_units)
						attacker.actions_avail.append(Unit.Action.ATTACK) #give back attack token
						
					1: #displace linearly target location (assumes only one affected target) (throw)
						var projectile = attacker.unit_held.pop_front()
						var a = get_tree().create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUINT)
						if affected_units.is_empty(): #if thrown at an empty cell
							a.tween_property(projectile, "global_position", HexNavi.cell_to_global(targets.front()), 0.3) 
						else: a.tween_property(projectile, "global_position", affected_units.front().global_position, 0.3) 
						await a.finished
						projectile.is_held = false
						projectile.animation_state("side_idle")
						projectile.cell = HexNavi.global_to_cell(projectile.global_position)
						#print("shooting complete")
					_:
						print("nothing to displace yet")
				attacker.check_if_can_throw()
			_:
				print("nothing happens yet")
				
	# print("# AFFECTED UNITS: " + str(affected_units) + " (UnitGroupController.gd)")
	if !all_units.is_empty(): all_units.map(func(unit : Unit): unit.check_if_dead()) # TODO: rare bug here? trying to call on already freed node
	_on_update_cell_status(true)

func _on_update_cell_status(stacking: bool): #scan all units and update cell color accordingly
	all_units = []
	occupied_cells = {}
	EventBus.emit_signal("clear_cells")
	player_group.refresh_units()
	enemy_group.refresh_units()
	all_units.append_array(player_group.units)
	all_units.append_array(enemy_group.units)
	for unit in player_group.units:
		if !occupied_cells.has(unit.cell):
			occupied_cells[unit.cell] = []
		occupied_cells[unit.cell].append(unit)
		EventBus.emit_signal("occupy_cell", unit.cell, "player")
	for unit in enemy_group.units:
		if !occupied_cells.has(unit.cell):
			occupied_cells[unit.cell] = []
		occupied_cells[unit.cell].append(unit)
		EventBus.emit_signal("occupy_cell", unit.cell, "enemy")
	
	if stacking: #only stacks units if stacking is true
		#print("stacking")
		#adjusting position of units to accomodate for unit stacking
		
		for cell in occupied_cells.keys():
			var displacement = 100/(occupied_cells[cell].size())
			var num_stacked = 0
			for unit in occupied_cells[cell]:
				if(unit.unit_held.is_empty()):
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

	#print("status update complete")	
	status_update_complete.emit()

func _on_unit_died():
	_on_update_cell_status(false)
	check_if_win()

func check_if_win():
	var win_flag: int = 0
	if player_group.units.size() <= 0:
		win_flag -=1
	if enemy_group.units.size() <= 0:
		win_flag += 2
	match win_flag:
		-1:	#Enemy won
			EventBus.emit_signal("battle_ended", EventBus.BattleResult.ENEMY_VICTORY)
			print("Enemy won!")
		0:	#no result
			print("no result yet")
		1:	#Tie
			EventBus.emit_signal("battle_ended", EventBus.BattleResult.TIE)
			print("It is a tie")
		2:	#Player won
			EventBus.emit_signal("battle_ended", EventBus.BattleResult.PLAYER_VICTORY)
			print("Player won!")
