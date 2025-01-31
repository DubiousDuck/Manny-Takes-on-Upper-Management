extends Node

## Global script with utility functions

# Overworld
var _last_overworld: String = ""

func set_last_overworld(file_name: String):
	#TODO: check if the file_name is a valid scene path
	_last_overworld = file_name

func get_last_overworld() -> String:
	return _last_overworld
