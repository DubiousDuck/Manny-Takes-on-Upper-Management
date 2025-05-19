extends Button

class_name SkillIcon

@export var skill: SkillInfo

func _ready():
	if skill != null:
		text = skill.name

func set_tooltip(text: String):
	tooltip_text = text
