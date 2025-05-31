extends Control

class_name SkillPreview

@onready var color_rect = $ColorRect
@onready var label = $Label

var skill: SkillInfo

func set_tooltip(text: String):
	color_rect.tooltip_text = text
