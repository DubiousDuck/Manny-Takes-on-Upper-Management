class_name Cutscene extends Area2D

@export_multiline var animations : Array[String]
@export var one_shot: bool = false
@export var speaker_name: String = "Manny"

@onready var collision_shape_2d = $CollisionShape2D


var multiple_lines: Array[String] = []

func _on_body_entered(body):
	collision_shape_2d.set_deferred("disabled", true)
	print("Body entered " + str(name))
	if body is Player:
		if has_node("AnimationPlayer"):
			# Wait till previous UI to finish
			if Global.ui_busy:
				#print("Global UI busy now, waiting for other UI to finish -- cutscene.gd")
				await EventBus.ui_element_ended
			multiple_lines.clear()
			for i in animations:
				if i.contains("Dialogue(multiple): "): #multiple dialogue lines
					multiple_lines.append(i.right(-20)) #stores multiple lines
				else:
					#plays the stored multiple lines before parsing the next instruction
					if multiple_lines.size() > 0:
						Global.start_dialogue(multiple_lines, true, speaker_name)
						await EventBus.dialogue_finished
						multiple_lines.clear()
					
					if i.contains("Dialogue: "): #single dialogue line
						Global.start_dialogue([i.right(-10)], true, speaker_name)
						await EventBus.dialogue_finished
					else:
						get_node("AnimationPlayer").play("Cutscenes/" + i)
						await get_node("AnimationPlayer").animation_finished
		if !one_shot:
			collision_shape_2d.set_deferred("disabled", false)
		# If statement to prevent multiple instance of the same events
		if !Global.events.has(self.name):
			post_cutscene_callback(self.name)
			Global.events.append(self.name)
			print(Global.events)

## Helper function that does different things based on what cutscenes have just finished
func post_cutscene_callback(cutscene_name: String):
	match cutscene_name:
		"InitialScene":
			HintManager.trigger_hint("initial_cutscene", "Use WASD to move around!")
		"Area2Intro":
			if Global.current_party.size() < Global.max_party_num and Global.max_party_num > 3:
				HintManager.trigger_hint("more_party_num", "You can now have %d babies on your team at once.\n Remember to add them in Party Manage!" %Global.max_party_num, false)
