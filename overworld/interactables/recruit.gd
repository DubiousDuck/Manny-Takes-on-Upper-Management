extends Interactable

class_name Recruit

@export_file("*.tscn") var scene_to_go

func _interact_call_back():
	if Global.recruit_token <= 0:
		Global.start_dialogue(["I'm sorry, you don't have enough recruit tokens."])
		await EventBus.ui_element_ended
	else:
		Global.start_dialogue(["Hi there!", "In exchange for one recruit token,", "who do you like to recruit?"])
		await EventBus.ui_element_ended
		Global.recruit_token -= 1
		Global.set_last_overworld_scene(get_tree().current_scene)
		get_tree().change_scene_to_file(scene_to_go)
		
