extends Interactable

class_name SollicitorInteract

@export_file("*.tscn") var scene_to_go

@export var locked=true
@export var completed = false
@export var req :Array[String] = []
@export var level_name :String

@export var locked_dialogue: Array[String] = ["this door is locked"]
@export var interact_dialogue: Array[String] = ["Hello good sir", "GIVE ME YOUR MONEY![NO][YES]"]
@export var correct_choice: String = "NO"

func check_locked():
	if req.all(func(x): return Global.finished_levels.has(x)):
		locked=false

func check_completed():
	if Global.finished_levels.has(level_name):
		completed = true

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
		print("choice: " + str(choice))
		if choice== correct_choice:
			Global.current_level = level_name
			print("ENTERED LEVEL", level_name)
			Global.start_battle(self.name, [load("res://unit/params/healer.tres")])
			Global.set_last_overworld_scene(get_tree().current_scene)
			Global.dialogue_on_scene_ready = interact_dialogue.duplicate()
			Global.scene_transition(scene_to_go)
