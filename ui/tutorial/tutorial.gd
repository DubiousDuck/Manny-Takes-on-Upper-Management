extends Control

class_name Tutorial

@onready var test_page = preload("res://ui/tutorial/contents/test_tutorial.tres")

@onready var title = $Window/MarginContainer/VBoxContainer/Title
@onready var content = $Window/MarginContainer/VBoxContainer/Content
@onready var next = $Window/MarginContainer/VBoxContainer/Next

const NORMAL_PAGE: String = "Next Page"
const LAST_PAGE: String = "Done"

func _ready():
	content.append_text("[center]This is an example text. This color is [color=green]green[/color][/center].")

func init(page_queue: Array[TutorialContent]):
	EventBus.ui_element_started.emit()
	content.clear()
	for index in range(page_queue.size()):
		var page: TutorialContent = page_queue[index]
		title.text = page.title
		content.append_text(page.body_text)
		var image = load(page.image_file)
		#TODO: Read and apply image parameters
		content.add_image(image)
		if index == page_queue.size() - 1:
			next.text = LAST_PAGE
		else: next.text = NORMAL_PAGE
		
		await next.pressed
	content.clear()
	EventBus.ui_element_ended.emit()
