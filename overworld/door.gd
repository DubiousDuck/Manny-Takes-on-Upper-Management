extends Interactable

class_name Door

@export_file("*.tscn") var scene_to_go

func _interact_call_back():
	Global.start_dialogue(["test", "hello", "test again"])
	await EventBus.ui_element_ended
	Global.start_battle(self.name, [load("res://unit/params/healer.tres")])
	get_tree().change_scene_to_file(scene_to_go)
