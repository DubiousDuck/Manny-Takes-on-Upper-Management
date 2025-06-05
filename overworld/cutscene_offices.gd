extends Node2D

class_name CutsceneOffice

@export_file("*.tscn") var scene_to_go: String

func end_cutscene_and_go():
	Global.scene_transition(scene_to_go)
