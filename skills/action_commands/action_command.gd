class_name ActionCommand extends Control

signal finished(passed : bool)

var is_visible: bool = false

func _process(delta):
	if $ProgressBar.value <= 69:
		$ProgressBar.get("theme_override_styles/fill").bg_color = Color("ff5847")
	else:
		$ProgressBar.get("theme_override_styles/fill").bg_color = Color("00ba1b")
	$ProgressBar.get("theme_override_styles/fill").border_color = Color("15151500")
	$ProgressBar.get("theme_override_styles/fill").border_width_left = 3
	$ProgressBar.get("theme_override_styles/fill").border_width_right = 3
	$ProgressBar.get("theme_override_styles/fill").border_width_bottom = 3
	$ProgressBar.get("theme_override_styles/fill").border_width_top = 3
	
func _input(event):
	if Input.is_action_just_pressed("LMB"):
		$AnimationPlayer.pause() #stop will make value = 0
		if $ProgressBar.value >= 70:
			finished.emit(true)
		else:
			Global.attack_successful = false
			finished.emit(false)
		get_tree().paused = false
		queue_free()
