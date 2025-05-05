extends Control

@onready var label = $CenterContainer/Label

func play_run_in_from_left(text: String):
	label.text = text
	$AnimationPlayer.play("run_in_from_left")
