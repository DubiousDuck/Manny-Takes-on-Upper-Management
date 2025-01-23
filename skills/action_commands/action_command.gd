class_name ActionCommand extends Control

signal finished(passed : bool)

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
		$AnimationPlayer.stop()
		if $ProgressBar.value >= 70:
			finished.emit(true)
		else:
			finished.emit(false)
		get_tree().paused = false
		queue_free()
