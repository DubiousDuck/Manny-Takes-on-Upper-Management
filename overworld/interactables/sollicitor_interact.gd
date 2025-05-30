extends Interactable

class_name SollicitorInteract

@export_file("*.tscn") var scene_to_go

@export var locked=true
@export var completed = false
@export var req :Array[String] = []
@export var level_name :String
@export var interact_count: int = 0

@export var locked_dialogue: Array[String] = ["this door is locked"]
@export var interact_dialogue: Array[String] = ["Hello good sir", "GIVE ME YOUR MONEY![NO][YES]"]
@export var repeat_dialogue: Array[String] = []
@export var correct_choice: String = "NO"
@export var win_dialogue: Array[String] = []
@export var lose_dialogue: Array[String] = []
@export var speaker_name: String = ""

func check_locked():
	if req.all(func(x): return Global.finished_levels.has(x)):
		locked=false

func check_completed():
	if Global.finished_levels.has(level_name):
		completed = true

func _interact_call_back():
	super()
	if locked:
		check_locked()
	if locked:
		Global.start_dialogue(locked_dialogue, false, speaker_name)
		await EventBus.ui_element_ended
	else:
		if interact_count <= 0:
			Global.start_dialogue(interact_dialogue, false, speaker_name)
		else:
			Global.start_dialogue(repeat_dialogue, false, speaker_name)
		await EventBus.ui_element_ended
		var choice = Global.dialogue_choice
		print("choice: " + str(choice))
		if choice== correct_choice:
			Global.current_level = level_name
			print("ENTERED LEVEL", level_name)
			Global.start_battle(self.name, [load("res://unit/params/healer.tres")])
			Global.set_last_overworld_scene(get_tree().current_scene)
			Global.win_dialogue = win_dialogue.duplicate()
			Global.lose_dialogue = lose_dialogue.duplicate()
			Global.scene_transition(scene_to_go)
		interact_count += 1
