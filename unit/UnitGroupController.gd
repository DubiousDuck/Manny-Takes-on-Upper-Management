extends Node2D

class_name UnitGroupController

@export var player_goes_first : bool = true

@onready var player_group = $PlayerGroup
@onready var enemy_group = $EnemyGroup
var is_player_turn : bool = true

func _ready():
	EventBus.connect("update_cell_status", _on_update_cell_status)
	
func init():
	connect_container_signal(player_group)
	connect_container_signal(enemy_group)
	player_group.init()
	enemy_group.init()
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

func _on_update_cell_status(): #scan all units and update cell color accordingly
	var all_units : Array[Unit] = []
	EventBus.emit_signal("clear_cells")
	all_units.append_array(player_group.units)
	for unit in all_units:
		EventBus.emit_signal("occupy_cell", unit.cell, "player")
	all_units.clear()
	all_units.append_array(enemy_group.units)
	for unit in all_units:
		EventBus.emit_signal("occupy_cell", unit.cell, "enemy")
