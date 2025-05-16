extends Interactable

class_name Elevator

@export_file("*.tscn") var scene_to_go

@export var locked=true
@export var req: Array[String] = []
@export var scene_name :String
@export_multiline var locked_dialogue: Array[String] = ["Sorry, this elevator is locked.", "Try again later."]
@export_multiline var interact_dialogue: Array[String] = ["Hello", "Are you sure you want to go to the next floor?", "[Yes][No]"]

var mouse_on = false

func check_locked():
	if req.all(func(x): return Global.finished_levels.has(x)):
		locked=false
func _interact_call_back():
	if locked:
		check_locked()
	if locked:
		Global.start_dialogue(locked_dialogue)
		await EventBus.ui_element_ended
	else:
		Global.start_dialogue(interact_dialogue)
		await EventBus.ui_element_ended
		var choice = Global.dialogue_choice
		if choice=="Yes":
			print("Entering next area... -- Elevator.gd")
			Global.set_last_overworld_scene(get_tree().current_scene)
			Global.scene_transition(scene_to_go)


func _on_control_mouse_entered() -> void:
	mouse_on = true

func _on_control_mouse_exited() -> void:
	mouse_on = false
