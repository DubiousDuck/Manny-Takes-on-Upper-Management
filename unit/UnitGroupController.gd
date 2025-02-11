extends Node2D

class_name UnitGroupController

signal effect_complete
signal attack_process_complete

@export var player_goes_first : bool = true

@onready var player_group: UnitContainer = $PlayerGroup
@onready var enemy_group: UnitContainer = $EnemyGroup
var is_player_turn : bool = true
var all_units: Array[Unit] = []
var occupied_cells = {}

var in_progress: bool = false:
	set(value):
		if value == false: attack_process_complete.emit()

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
	_on_update_cell_status()
	
	is_player_turn = player_goes_first
	if is_player_turn:
		player_group.round_start()
	else: enemy_group.round_start()
	
func connect_container_signal(unit_group : UnitContainer):
	unit_group.connect("all_units_moved", _on_unit_container_all_moved)
	
func _on_unit_container_all_moved():
	check_if_win()
	is_player_turn = !is_player_turn
	#TODO: Fix bug where anonther group starts before all previous actions are resolved
	if is_player_turn:
		print("player's turn")
		player_group.round_start()
	else:
		print("enemy's turn")
		enemy_group.round_start()

func _on_attack_used(attack: SkillInfo, attacker: Unit, targets: Array[Vector2i]):
	#print("# " + str(attacker.name) + " USED: " + str(attack.name) + " (UnitGroupController.gd)")
	in_progress = true
	
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
				affected_units.map(
					func(unit : Unit):
						unit.health -= floor((effect.y * attacker_power) * (1-unit.damage_reduction))
						unit.animation_state("hurt_initial")
				)
				
			SkillInfo.EffectType.KNOCKBACK:
				if affected_units.is_empty(): return
				
				var move_tween = get_tree().create_tween().set_parallel()
				move_tween.set_ease(Tween.EASE_OUT)
				move_tween.set_trans(Tween.TRANS_CUBIC)
				affected_units.map(
					func(unit : Unit): #NOTICE: Use global position directly here since hex grid coords is less intuitive
						#calculate the direction of knockback
						var dir: Vector2 = unit.global_position - attacker.global_position
						#apply the direction by strength of knockback
						var new_location: Vector2 = unit.global_position + dir*effect.y
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
				
			SkillInfo.EffectType.HEAL:
				affected_units.map(
					func(unit : Unit):
						if unit.health + effect.y * attacker_power >= unit.unit_data.get_attribute("HP"):
							unit.health = unit.unit_data.get_attribute("HP")
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
						projectile.animation_state("side_idle")
						projectile.cell = HexNavi.global_to_cell(projectile.global_position)
					_:
						print("nothing to displace yet")
				attacker.check_if_can_throw()
			_:
				print("nothing happens yet")
				
		_on_update_cell_status()
	# print("# AFFECTED UNITS: " + str(affected_units) + " (UnitGroupController.gd)")
	affected_units.map(func(unit : Unit): unit.check_if_dead()) # TODO: rare bug here? trying to call on already freed node
	in_progress = false

func _on_update_cell_status(): #scan all units and update cell color accordingly
	all_units = []
	occupied_cells = {}
	EventBus.emit_signal("clear_cells")
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
		
	#adjusting position of units to accomodate for unit stacking
	for cell in occupied_cells:
		var displacement = 100/(occupied_cells[cell].size());
		for i in occupied_cells[cell].size():
			var unit = occupied_cells[cell][i]
			var vect = Vector2(displacement/2 + displacement*i-100/2, 0)
			
			var displace_tween = get_tree().create_tween()
			displace_tween.set_ease(Tween.EASE_OUT)
			displace_tween.set_trans(Tween.TRANS_CUBIC)
			displace_tween.tween_property(
							unit,
							'global_position',
							HexNavi.cell_to_global(cell) + vect,
							0.5
						)

func _on_unit_died():
	_on_update_cell_status()
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
