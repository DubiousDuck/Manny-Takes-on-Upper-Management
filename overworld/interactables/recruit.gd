extends Interactable

class_name Recruit

@export_file("*.tscn") var scene_to_go

@onready var warning = $Warning

func _process(delta):
	#print(Global.recruit_token)
	if Global.recruit_token > 0:
		warning.visible = true
		if !$AnimationPlayer.is_playing() or $AnimationPlayer.current_animation != "warning_idle":
			$AnimationPlayer.play("warning_idle")
	else:
		warning.visible = false
		if !$AnimationPlayer.is_playing() or $AnimationPlayer.current_animation != "idle":
			$AnimationPlayer.play("idle")

func _interact_call_back():
	if Global.recruit_token <= 0:
		Global.start_dialogue(["I'm sorry, you don't have enough recruit tokens."])
		await EventBus.ui_element_ended
	else:
		Global.start_dialogue(["Hi there!", "In exchange for one recruit token,", "who do you like to recruit?"])
		await EventBus.ui_element_ended
		Global.recruit_token -= 1
		Global.set_last_overworld_scene(get_tree().current_scene)
		Global.scene_transition(scene_to_go)
		
