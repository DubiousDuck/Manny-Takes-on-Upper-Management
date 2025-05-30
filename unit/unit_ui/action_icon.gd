extends Button

class_name ActionIcon

func _process(delta):
	if disabled:
		$DisabledClickCatcher.show()
	else:
		$DisabledClickCatcher.hide()

func _on_pressed():
	AudioPreload.play_sfx("select")
