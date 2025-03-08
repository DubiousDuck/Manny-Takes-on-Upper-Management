extends Interactable

class_name SollicitorInteract

@export_file("*.tscn") var scene_to_go

@export var locked=true
@export var req :Array[String] = []
@export var level_name :String

func check_locked():
	if req.all(func(x): return Global.finished_levels.has(x)):
		locked=false
func _interact_call_back():
	if locked:
		check_locked()
	if locked:
		Global.start_dialogue(["this door is locked"])
		await EventBus.ui_element_ended
	else:
		Global.start_dialogue(["Hello good sir", "GIVE ME YOUR MONEY![NO][YES]"])
		var choice = await EventBus.ui_choice_chosen
		if choice=="NO":
			Global.current_level = level_name
			print("ENTERED LEVEL", level_name)
			Global.start_battle(self.name, [load("res://unit/params/healer.tres")])
			Global.set_last_overworld_scene(get_tree().current_scene)
			get_tree().change_scene_to_file(scene_to_go)
