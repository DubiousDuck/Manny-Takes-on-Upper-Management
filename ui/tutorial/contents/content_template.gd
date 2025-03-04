extends Resource

class_name TutorialContent

## Title of the Tutorial page
@export var title: String

## The body text should include BBCode for formatting
@export_multiline var body_text: String

## Image(s) to include with the Tutorial page
@export_file var image_file: String

## Display option for the image
@export var image_param: Dictionary
