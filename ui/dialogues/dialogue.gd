class_name Dialogue extends Control

@onready var label = $Label
@onready var speaker_name_tag = $Name
@onready var anim_player = $AnimationPlayer
@onready var choice_container = $Choices

const CHOICE = preload("res://ui/dialogues/dialogue_choice.tscn")
var chosen:String = ""
var question_given = false
		
func _input(_event):
	if not question_given:
		if Input.is_action_just_pressed("Advance"):
			EventBus.input_advance.emit()
			get_viewport().set_input_as_handled()

func set_speaker_name(speaker_name: String):
	speaker_name_tag.text = speaker_name

func read_text(text : Array[String], in_cutscene : bool = false):
	# check if text is empty
	if text.size() <= 0:
		print("ending the parsing early...")
		if !in_cutscene: EventBus.ui_element_ended.emit()
		else: EventBus.dialogue_finished.emit()
		return
	if !in_cutscene: EventBus.ui_element_started.emit()
	anim_player.play("BarsDown")
	await anim_player.animation_finished
	speaker_name_tag.show()
	for i : String in text:
		# Detect inline speaker tag like [SPEAKER:Alice]
		if i.begins_with("[SPEAKER:"):
			var regex = RegEx.new()
			regex.compile("^\\[SPEAKER:(.*?)\\](.*)")
			var result = regex.search(i)
			if result:
				var new_speaker = result.get_string(1)
				i = result.get_string(2)
				set_speaker_name(new_speaker)

		if i.contains("["):
			label.hide()
			question_given=true
			var options : PackedStringArray = extract_bracketed(i)
			i = remove_bracketed(i)
			for k in options:
				var b = CHOICE.instantiate()
				b.text = k
				b.pressed.connect(_on_choice_pressed.bind(k))  # Connect button press signal
				choice_container.add_child(b)
				#choice_container.add_spacer(true)
			assert(options.size() > 0)
			# make the first option as the default choice
			Global.dialogue_choice = options[0]
		label.visible_ratio = 0
		label.text = i
		var a = create_tween()
		a.tween_property(label, "visible_ratio", 1, i.length() * 0.02)
		await EventBus.input_advance
		if label.visible_ratio != 1:
			a.stop()
			label.visible_ratio = 1
			await EventBus.input_advance
	label.queue_free()
	speaker_name_tag.hide()
	anim_player.play_backwards("BarsDown")
	await anim_player.animation_finished
	if !in_cutscene: EventBus.ui_element_ended.emit()
	else: EventBus.dialogue_finished.emit()
	
func _on_choice_pressed(choice_text: String):
	Global.dialogue_choice = choice_text
	for i in $Choices.get_children(): i.queue_free()
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
