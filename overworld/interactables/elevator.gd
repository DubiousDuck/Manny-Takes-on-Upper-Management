extends Interactable

class_name Elevator

@export_file("*.tscn") var scene_to_go

@export var locked=true
@export var req :Array[String] = []
@export var scene_name :String

var mouse_on = false

func check_locked():
	if req.all(func(x): return Global.finished_levels.has(x)):
		locked=false
func _interact_call_back():
	if locked:
		check_locked()
	if locked:
		Global.start_dialogue(["this elevator is locked"])
		await EventBus.ui_element_ended
	else:
		Global.start_dialogue(["Hello", "Are you sure you want to go to the next floor?[YES][NO]"])
		await EventBus.ui_element_ended
		var choice = Global.dialogue_choice
		print("choice: " + str(choice))
		if choice=="YES":
			Global.current_level = scene_name
			print("ENTERED LEVEL", scene_name)
			Global.start_battle(self.name, [load("res://unit/params/healer.tres")])
			Global.set_last_overworld_scene(get_tree().current_scene)
			get_tree().change_scene_to_file(scene_to_go)



func _on_control_mouse_entered() -> void:
	mouse_on = true


func _on_control_mouse_exited() -> void:
	mouse_on = false
