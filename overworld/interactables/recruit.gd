extends Interactable

class_name Recruit

@export_file("*.tscn") var scene_to_go
@export var locked=false
@onready var player = $"../Player"

func _interact_call_back():
	if locked:
		Global.start_dialogue(["this door is locked"])
		await EventBus.ui_element_ended
	else:
		Global.start_dialogue(["Hi there!", "Who do you like to recruit?"])
		await EventBus.ui_element_ended
		Global._last_overworld_position = player.position
		Global.player_has_initialized = false
		Global.set_last_overworld_scene(get_tree().current_scene)
		get_tree().change_scene_to_file(scene_to_go)
		
