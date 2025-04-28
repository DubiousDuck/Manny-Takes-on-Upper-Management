class_name Cutscene extends Area2D

@export var animations : Array[String]

func _on_body_entered(body):
	if body is Player:
		if has_node("AnimationPlayer"):
			for i in animations:
				if i.contains("Dialogue: "):
					Global.start_dialogue([i.right(-10)], true)
					await EventBus.dialogue_finished
				else:
					get_node("AnimationPlayer").play("Cutscenes/" + i)
					await get_node("AnimationPlayer").animation_finished
	Global.events.append(self.name)
	print(Global.events)
