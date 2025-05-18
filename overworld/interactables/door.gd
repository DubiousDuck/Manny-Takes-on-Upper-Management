extends Interactable

class_name Door

@export_file("*.tscn") var scene_to_go

@export var locked=true
@export var req :Array[String] = []
@export var level_name :String

var mouse_on = false

func check_locked():
	if req.all(func(x): return Global.finished_levels.has(x)):
		locked=false
func _interact_call_back():
	super()
	if locked:
		check_locked()
	if locked:
		Global.start_dialogue(["this door is locked"])
		await EventBus.ui_element_ended
	else:
		Global.start_dialogue(["Hello", "Are you sure you want to enter this level?[YES][NO]"])
		await EventBus.ui_element_ended
		var choice = Global.dialogue_choice
		print("choice: " + str(choice))
		if choice=="YES":
			Global.current_level = level_name
			Global.start_battle(self.name, [load("res://unit/params/healer.tres")])
			Global.set_last_overworld_scene(get_tree().current_scene)
			Global.scene_transition(scene_to_go)



func _on_control_mouse_entered() -> void:
	mouse_on = true


func _on_control_mouse_exited() -> void:
	mouse_on = false
