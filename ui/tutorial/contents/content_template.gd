extends Resource

class_name TutorialContent

@export_category("Trigger Parameters")
@export var trigger: String = ""
@export var only_once: bool = true
@export var triggered: bool = false

@export_category("Content Parameters")
## Title of the Tutorial page; NOTE: Should be unique to ensure correct saving and loading
@export var title: String

## The body text should include BBCode for formatting
@export_multiline var body_text: String

## Image(s) to include with the Tutorial page
@export_file var image_file: String

## Display option for the image; only need to set either width or height if size_in_percent is true
@export var image_param: Dictionary = {
	"width": 0,
	"height": 0,
	"size_in_percent": false
}
