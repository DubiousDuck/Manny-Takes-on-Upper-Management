extends Resource

class_name TutorialContent

@export_category("Trigger Parameters")
@export var trigger: String = ""
@export var only_once: bool = true
@export var triggered: bool = false

@export_category("Content Parameters")
## Title of the Tutorial page
@export var title: String

## The body text should include BBCode for formatting
@export_multiline var body_text: String

## Image(s) to include with the Tutorial page
@export_file var image_file: String

## Display option for the image
@export var image_param: Dictionary
