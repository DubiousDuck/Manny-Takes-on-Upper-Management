extends Control

class_name SkillUnlockPopup

func _ready():
	EventBus.emit_signal("ui_element_started")

func set_skill_info(unit: UnitData, skill_info: SkillInfo):
	$Panel/Description.text = "%s has learned a new %s: %s!" %[unit.unit_class, skill_info.type, skill_info.name]

func _on_button_pressed():
	AudioPreload.play_sfx("select")
	EventBus.emit_signal("ui_element_ended")
	queue_free()
