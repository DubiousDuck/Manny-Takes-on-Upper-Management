extends CanvasLayer

@onready var label = $Label

var current_timer: Timer
var current_message: String = ""
var fade_tween: Tween

func _ready():
	HintManager.connect("hint_requested", _on_hint_requested)
	HintManager.connect("hint_hide", _hide_hint)
	hide()

func _on_hint_requested(message: String):
	if message == current_message:
		# Same message: just refresh the timer
		if current_timer:
			current_timer.start()
		return

	# New message: cancel everything
	current_message = message
	_reset_timers()
	_show_message(message)

func _show_message(message: String):
	label.text = message
	show()

	# Fade in
	label.modulate.a = 0
	if fade_tween:
		fade_tween.kill()
	fade_tween = get_tree().create_tween()
	fade_tween.tween_property(label, "modulate:a", 1.0, 0.3)

	# Start countdown
	current_timer = Timer.new()
	current_timer.wait_time = 5.0
	current_timer.one_shot = true
	current_timer.timeout.connect(_hide_hint)
	add_child(current_timer)
	current_timer.start()

func _hide_hint():
	if fade_tween:
		fade_tween.kill()
	fade_tween = get_tree().create_tween()
	fade_tween.tween_property(label, "modulate:a", 0.0, 0.5)
	await fade_tween.finished
	hide()
	current_message = ""

func _reset_timers():
	if current_timer and is_instance_valid(current_timer):
		current_timer.stop()
		current_timer.queue_free()
		current_timer = null
	if fade_tween:
		fade_tween.kill()
