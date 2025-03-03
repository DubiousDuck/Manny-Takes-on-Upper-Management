class_name ActionCommand extends Control

signal finished(passed : bool)

@export var action_command_type: String

#for mashing timer
var timer_started = false
var timer : SceneTreeTimer
@export var mashing_time : float

var is_visible: bool = false

func _process(_delta):
	if $ProgressBar.value <= 69:
		$ProgressBar.get("theme_override_styles/fill").bg_color = Color("ff5847")
	else:
		$ProgressBar.get("theme_override_styles/fill").bg_color = Color("00ba1b")
	$ProgressBar.get("theme_override_styles/fill").border_color = Color("15151500")
	$ProgressBar.get("theme_override_styles/fill").border_width_left = 3
	$ProgressBar.get("theme_override_styles/fill").border_width_right = 3
	$ProgressBar.get("theme_override_styles/fill").border_width_bottom = 3
	$ProgressBar.get("theme_override_styles/fill").border_width_top = 3
	
	#failed timing for mashing
	if(timer_started):
		$TimeLeft.text =  str(snapped(timer.time_left, 0.01)) + "s"
		if(timer.time_left <= 0):
			action_command_completed(false)

func _input(_event):
	match action_command_type:
		"throw":
			if Input.is_action_just_pressed("LMB"):
				$AnimationPlayer.pause() #stop will make value = 0
				if $ProgressBar.value >= 70:
					finished.emit(true)
				else:
					Global.attack_successful = false
					finished.emit(false)
				get_tree().paused = false
				queue_free()
		"mash":
			if Input.is_action_just_pressed("ui_select"):
				if(!timer_started):
					timer = get_tree().create_timer(mashing_time)
					$TimeLeft.text = str(mashing_time) + "s"
					timer_started = true
				$ProgressBar.value += 5;
				if($ProgressBar.value >= 100):
					action_command_completed(true)
		_:
			pass

func action_command_completed(completion_success: bool):
	Global.attack_successful = completion_success
	finished.emit(completion_success)
	get_tree().paused = false
	queue_free()
	pass
