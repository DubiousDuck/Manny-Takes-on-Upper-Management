extends Node2D

class_name UnitGroupController

@export var player_goes_first : bool = true

@onready var player_group = $PlayerGroup
@onready var enemy_group = $EnemyGroup
var is_player_turn : bool = true
	
func init():
	connect_container_signal(player_group)
	connect_container_signal(enemy_group)
	player_group.init()
	enemy_group.init()
	
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
