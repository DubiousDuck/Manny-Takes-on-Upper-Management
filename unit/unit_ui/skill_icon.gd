extends Button

class_name SkillIcon

@export var skill: SkillInfo

func _ready():
	if skill != null:
		text = skill.name

func set_tooltip(text: String):
	tooltip_text = text

func _process(delta):
	if disabled:
		$DisabledClickCatcher.show()
	else:
		$DisabledClickCatcher.hide()

func _on_pressed():
	AudioPreload.play_sfx("select")
