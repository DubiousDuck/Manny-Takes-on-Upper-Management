extends Node2D

class_name UnitGroupController

signal effect_complete

@export var player_goes_first : bool = true

@onready var player_group: UnitContainer = $PlayerGroup
@onready var enemy_group: UnitContainer = $EnemyGroup
var is_player_turn : bool = true
var all_units: Array[Unit] = []

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
	
func connect_container_signal(unit_group : UnitContainer):
	unit_group.connect("all_units_moved", _on_unit_container_all_moved)
	
func _on_unit_container_all_moved():
	is_player_turn = !is_player_turn
	if is_player_turn:
		player_group.round_start()
		print("player's turn")
	else:
		enemy_group.round_start()
		print("enemy's turn")

func _on_attack_used(attack: SkillInfo, attacker: Unit, targets: Array[Vector2i]):
	#get all target units
	var affected_units: Array[Unit] = []
	for unit in all_units:
		if targets.has(unit.cell):
			affected_units.append(unit)
	#for each skill effect, apply it on every affected units
	for effect in attack.skill_effects:
		match effect.x:
			SkillInfo.EffectType.DAMAGE:
				affected_units.map(
					func(unit):
						unit.health -= effect.y
				)
				
			SkillInfo.EffectType.KNOCKBACK:
				var move_tween = get_tree().create_tween()
				move_tween.set_ease(Tween.EASE_OUT)
				move_tween.set_trans(Tween.TRANS_CUBIC)
				affected_units.map(
					func(unit):
						#calculate the direction of knockback
						var dir: Vector2i = unit.cell - attacker.cell
						#apply the direction by strength of knockback
						var new_location: Vector2i = unit.cell + dir*effect.y
						move_tween.tween_property(
							unit,
							'global_position',
							HexNavi.cell_to_global(new_location),
							0.5
						)
				)
				await move_tween.finished
				affected_units.map(
					func(unit):
						unit.cell = HexNavi.global_to_cell(unit.global_position)
				)
				
			_:
				print("nothing happens yet")
				
		_on_update_cell_status()
	affected_units.map(func(unit): unit.check_if_dead())

func _on_update_cell_status(): #scan all units and update cell color accordingly
	var units : Array[Unit] = []
	EventBus.emit_signal("clear_cells")
	units.append_array(player_group.units)
	for unit in units:
		EventBus.emit_signal("occupy_cell", unit.cell, "player")
	units.clear()
	units.append_array(enemy_group.units)
	for unit in units:
		EventBus.emit_signal("occupy_cell", unit.cell, "enemy")

func _on_unit_died():
	_on_update_cell_status()
