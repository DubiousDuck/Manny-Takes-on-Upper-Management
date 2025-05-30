extends Control

func _on_gui_input(event):
	if event is InputEventMouseButton and event.is_pressed():
		HintManager.trigger_hint("disabled_button_click", "This skill is unavailable right now.", false)
		AudioPreload.play_sfx("error")
