extends Interactable

class_name Door

@export_file("*.tscn") var scene_to_go
@export var locked=false

func _interact_call_back():
	if locked:
		Global.start_dialogue(["this door is locked"])
		await EventBus.ui_element_ended
	else:
		Global.start_dialogue(["Hello", "Are you sure you want to enter this level?[YES][NO]"])
		var choice = await EventBus.ui_choice_chosen
		print(choice)
		if choice=="YES":
			Global.start_battle(self.name, [load("res://unit/params/healer.tres")])
			Global.set_last_overworld_scene(get_tree().current_scene)
			get_tree().change_scene_to_file(scene_to_go)
		
