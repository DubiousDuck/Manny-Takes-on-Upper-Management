extends Node

var tutorial_queue: Array[TutorialContent]

func _ready():
	EventBus.connect("tutorial_trigger", _on_tutorial_triggered)

func _on_tutorial_triggered(trigger: String):
	var queue_to_play: Array[TutorialContent]
	for tutorial in tutorial_queue:
		if tutorial.trigger == trigger and (!tutorial.triggered or !tutorial.only_once):
			queue_to_play.append(tutorial)
			tutorial.triggered = true
	if queue_to_play.size() > 0:
		Global.start_tutorial(queue_to_play)

func set_tutorial_queue(queue: Array[TutorialContent]):
	tutorial_queue = queue

func reset_tutorial_queue():
	for tutorial in tutorial_queue:
		tutorial.triggered = false
