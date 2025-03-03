class_name Dialogue extends Control

@onready var label = $Label
@onready var anim_player = $AnimationPlayer
@onready var choice_container = $HBoxContainer

const CHOICE = preload("res://ui/dialogue_choice.tscn")

func read_text(text : Array[String]):
	EventBus.ui_element_started.emit()
	anim_player.play("BarsDown")
	await anim_player.animation_finished
	for i : String in text:
		if i.contains("["):
			var options : PackedStringArray = extract_bracketed(i)
			i = remove_bracketed(i)
			for k in options:
				var b = CHOICE.instantiate()
				b.text = k
				choice_container.add_child(b)
			assert(options.size() > 0)
		label.visible_ratio = 0
		label.text = i
		var a = create_tween()
		a.tween_property(label, "visible_ratio", 1, i.length() * 0.02)
		await EventBus.input_advance
	label.queue_free()
	anim_player.play_backwards("BarsDown")
	await anim_player.animation_finished
	EventBus.ui_element_ended.emit()

func extract_bracketed(text: String) -> Array:
	var regex = RegEx.new()
	regex.compile("\\[([^\\]]+)\\]")
	var results = []
	for result in regex.search_all(text):
		results.append(result.get_string(1))
	return results

func remove_bracketed(text: String) -> String:
	var regex = RegEx.new()
	regex.compile("\\[.*?\\]")
	return regex.sub(text, "", true)
