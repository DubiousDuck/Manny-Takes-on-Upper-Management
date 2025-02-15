class_name Dialogue extends Control

@onready var label = $Label
@onready var anim_player = $AnimationPlayer

func read_text(text : Array[String]):
	EventBus.ui_element_started.emit()
	anim_player.play("BarsDown")
	await anim_player.animation_finished
	for i : String in text:
		label.visible_ratio = 0
		label.text = i
		var a = create_tween()
		a.tween_property(label, "visible_ratio", 1, i.length() * 0.02)
		await EventBus.input_advance
	label.queue_free()
	anim_player.play_backwards("BarsDown")
	await anim_player.animation_finished
	EventBus.ui_element_ended.emit()
