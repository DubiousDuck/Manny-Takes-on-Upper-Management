extends CanvasLayer

@onready var label = $Label

func _ready():
	HintManager.connect("hint_requested", _on_hint_requested)
	HintManager.connect("hint_hide", _hide_hint)
	hide()

func _on_hint_requested(message: String):
	label.text = message
	show()
	var a = get_tree().create_tween()
	label.modulate.a = 0
	a.tween_property(label, "modulate:a", 1.0, 0.3)
	await a.finished
	await get_tree().create_timer(5.0).timeout
	_hide_hint()

func _hide_hint(message: String = ""):
	# only hide hint if the requester and hider is the same message
	# empty string means to hide the hint regardless of content
	if message != "" and message != label.text:
		return

	var a = get_tree().create_tween()
	a.tween_property(label, "modulate:a", 0.0, 0.5)
	await a.finished
	hide()
