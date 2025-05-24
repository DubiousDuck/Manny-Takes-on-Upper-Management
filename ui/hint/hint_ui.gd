extends CanvasLayer

@onready var label = $Label

var is_busy: bool = false

func _ready():
	HintManager.connect("hint_requested", _on_hint_requested)
	HintManager.connect("hint_hide", _hide_hint)
	hide()

func _on_hint_requested(message: String):
	if is_busy and message == label.text:
		return
	is_busy = true
	label.text = message
	show()
	var a = get_tree().create_tween()
	label.modulate.a = 0
	a.tween_property(label, "modulate:a", 1.0, 0.3)
	await a.finished
	await get_tree().create_timer(5.0).timeout
	_hide_hint()

func _hide_hint():
	var a = get_tree().create_tween()
	a.tween_property(label, "modulate:a", 0.0, 0.5)
	await a.finished
	hide()
	is_busy = false
