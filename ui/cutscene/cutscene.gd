class_name Cutscene extends Area2D

@export_multiline var animations : Array[String]

var multiple_lines: Array[String] = []

func _on_body_entered(body):
	$CollisionShape2D.disabled = true
	if body is Player:
		if has_node("AnimationPlayer"):
			multiple_lines.clear()
			for i in animations:
				if i.contains("Dialogue(multiple): "): #multiple dialogue lines
					multiple_lines.append(i.right(-20)) #stores multiple lines
				else:
					#plays the stored multiple lines before parsing the next instruction
					if multiple_lines.size() > 0:
						Global.start_dialogue(multiple_lines, true)
						await EventBus.dialogue_finished
						multiple_lines.clear()
					
					if i.contains("Dialogue: "): #single dialogue line
						Global.start_dialogue([i.right(-10)], true)
						await EventBus.dialogue_finished
					else:
						get_node("AnimationPlayer").play("Cutscenes/" + i)
						await get_node("AnimationPlayer").animation_finished
	# If statement to prevent multiple instance of the same events
	if !Global.events.has(self.name):
		Global.events.append(self.name)
		print(Global.events)
