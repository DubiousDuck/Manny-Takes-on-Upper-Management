extends Button

class_name ActionIcon

func _process(delta):
	if disabled:
		$DisabledClickCatcher.show()
	else:
		$DisabledClickCatcher.hide()
