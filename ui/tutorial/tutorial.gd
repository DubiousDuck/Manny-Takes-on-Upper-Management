extends Control

class_name Tutorial

@onready var test_page = preload("res://ui/tutorial/contents/test_tutorial.tres")

@onready var title = $Window/Title
@onready var content = $Window/MarginContainer/VBoxContainer/Content
@onready var next = $Window/MarginContainer/VBoxContainer/Next
@onready var fade = $Window/Fade

const NORMAL_PAGE: String = "Next Page"
const LAST_PAGE: String = "Done"

func _ready():
	content.append_text("[center]This is an example text. This color is [color=green]green[/color][/center].")

func init(page_queue: Array[TutorialContent]):
	EventBus.ui_element_started.emit()
	content.clear()
	for index in range(page_queue.size()):
		$Window/MarginContainer/VBoxContainer/Content.scroll_to_line(0)
		content.clear()
		var page: TutorialContent = page_queue[index]
		title.text = page.title
		content.append_text(page.body_text)
		if page.image_file:
			var image = load(page.image_file)
			#TODO: Read and apply image parameters
			if page.image_param.size() != 0:
				var img_width: int = page.image_param.get("width", 50)
				var img_height: int = page.image_param.get("height", 30)
				var size_in_percent: bool = page.image_param.get("size_in_percent", true)
				content.add_image(image, img_width, img_height,Color(1, 1, 1, 1),5,Rect2(0,0,0,0),null,false,"",size_in_percent)
			else:
				content.add_image(image)
		if index == page_queue.size() - 1:
			next.text = LAST_PAGE
		else: next.text = NORMAL_PAGE
		
		await next.pressed
	content.clear()
	EventBus.ui_element_ended.emit()
	
	
func _input(event):
	if event.is_action_pressed("ui_cancel"):
		content.clear()
		EventBus.ui_element_ended.emit()

func _process(_delta):
	var visible_height = content.custom_minimum_size.y
	var total_height = content.get_v_scroll_bar().max_value
	var scroll_value = content.get_v_scroll_bar().value

	# If we can scroll and we haven't reached the bottom
	if total_height > visible_height and scroll_value < total_height - visible_height - 1:
		fade.visible = true
	else:
		fade.visible = false

func _on_next_pressed():
	AudioPreload.play_sfx("select")
