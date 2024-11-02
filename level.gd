extends Node2D

class_name Level

@export var tile_map : TileMapLayer

func _ready():
	Navi.set_current_map(tile_map)
