class_name Dialogue extends Control

@onready var label = $Label
@onready var anim_player = $AnimationPlayer
@onready var choice_container = $HBoxContainer

const CHOICE = preload("res://ui/dialogue_choice.tscn")
var chosen:String = ""
var question_given = false
		
func _input(_event):
	if not question_given:
		if Input.is_action_just_pressed("ui_accept"):
			EventBus.input_advance.emit()
		elif Input.is_action_just_pressed("LMB"):
			EventBus.input_advance.emit()
func read_text(text : Array[String]):
	EventBus.ui_element_started.emit()
	anim_player.play("BarsDown")
	await anim_player.animation_finished
	for i : String in text:
		if i.contains("["):
			question_given=true
			var options : PackedStringArray = extract_bracketed(i)
			i = remove_bracketed(i)
			for k in options:
				var b = CHOICE.instantiate()
				b.text = k
				b.pressed.connect(_on_choice_pressed.bind(k))  # Connect button press signal
				choice_container.add_child(b)
				choice_container.add_spacer(true)
			assert(options.size() > 0)
		label.visible_ratio = 0
		label.text = i
		var a = create_tween()
		a.tween_property(label, "visible_ratio", 1, i.length() * 0.02)
		await EventBus.input_advance
		print("ANIM PLAY BACK")
	label.queue_free()
	anim_player.play_backwards("BarsDown")
	await anim_player.animation_finished
	print("ANIM FINISHED")
	EventBus.ui_element_ended.emit()
	
func _on_choice_pressed(choice_text: String):
	Global.dialogue_choice = choice_text
	question_given=true
	EventBus.input_advance.emit()
	
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
