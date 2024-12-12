extends Node2D

class_name Level

@export var tile_map : TileMapLayer
@onready var unit_group_control : UnitGroupController = $Units

func _ready():
	HexNavi.set_current_map(tile_map)
	print(tile_map)
	unit_group_control.init()
	
