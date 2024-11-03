extends Node2D

class_name Level

@export var tile_map : TileMapLayer
@onready var player_group = $PlayerGroup
@onready var unit = $PlayerGroup/Unit

func _ready():
	Navi.set_current_map(tile_map)
	print(tile_map)
	player_group.init()
	
