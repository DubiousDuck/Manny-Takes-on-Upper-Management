extends Node2D

class_name Level

@onready var battle_outcome = preload("res://ui/battle_outcome.tscn")

@export var tile_map : TileMapLayer
@onready var unit_group_control : UnitGroupController = $Units

func _ready():
	EventBus.connect("battle_ended", _on_battle_ended)
	
	HexNavi.set_current_map(tile_map)
	unit_group_control.init()

func _on_battle_ended(result: int):
	var a = battle_outcome.instantiate()
	a.init(result)
	$CanvasLayer.add_child(a)
	a.display()
