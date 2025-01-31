extends Node2D

## General class for any overworld
class_name Overworld

func _ready():
	#make the game remember this is the last overworld loaded
	Global.set_last_overworld(get_tree().current_scene.scene_file_path)
