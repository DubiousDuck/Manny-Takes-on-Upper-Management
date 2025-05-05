extends Control

func play_run_in_from_left(text: String):
	$Label.text = text
	$AnimationPlayer.play("run_in_from_left")
