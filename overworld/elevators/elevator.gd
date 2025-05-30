extends Node2D
class_name ElevatorScene

@export_file("*.tscn") var scene_to_go: String
func _ready():
	AudioPreload.stop()

func go_to_next_scene():
	Global.scene_transition(scene_to_go)
