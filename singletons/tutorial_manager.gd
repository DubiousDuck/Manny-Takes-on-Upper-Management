extends Node

var tutorial_queue: Array[TutorialContent]
var tutorial_contents: Array[TutorialContent] = []
var tutorial_seen: Dictionary[String, bool] = {}

func _ready():
	EventBus.connect("tutorial_trigger", _on_tutorial_triggered)
	load_all_tutorials()

func _on_tutorial_triggered(trigger: String):
	var queue_to_play: Array[TutorialContent]
	for tutorial in tutorial_queue:
		if tutorial.trigger == trigger and (!tutorial.triggered or !tutorial.only_once):
			queue_to_play.append(tutorial)
			tutorial.triggered = true
			tutorial_seen[tutorial.title] = true
	if queue_to_play.size() > 0:
		Global.start_tutorial(queue_to_play)		

func set_tutorial_queue(queue: Array[TutorialContent]):
	tutorial_queue = queue

func reset_tutorial_queue():
	for tutorial in tutorial_queue:
		tutorial.triggered = false
		tutorial_seen[tutorial.title] = false

func load_all_tutorials(directory_path: String = "res://ui/tutorial/contents/"):
	var dir = DirAccess.open(directory_path)
	if not dir:
		push_error("Cannot open tutorial directory: " + directory_path)
		return

	dir.list_dir_begin()
	var file_name = dir.get_next()

	while file_name != "":
		if not dir.current_is_dir() and file_name.ends_with(".tres"):
			var path = directory_path + file_name
			var tutorial = load(path)
			if tutorial is TutorialContent:
				if tutorial in tutorial_contents:
					push_warning("Duplicate tutorial found: " + tutorial)
				if tutorial.title in tutorial_seen.keys():
					push_warning("Duplicate tutorial title found: " + tutorial.title)
				else:
					tutorial_contents.append(tutorial)
					tutorial_seen[tutorial.title] = false
		file_name = dir.get_next()

	dir.list_dir_end()

## Updates whether the contents have been seen based on the seen dictionary
func update_tutorial_seen():
	for tutorial in tutorial_contents:
		tutorial.triggered = tutorial_seen.get(tutorial.title, false)
